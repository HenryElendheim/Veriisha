// A single competent strategy, shared by the sim (which narrates one run) and the
// balance tool (which plays hundreds and counts outcomes). Keeping it in one place
// means both tools measure the same player.
//
// ignore_for_file: avoid_print

import 'package:veriisha/veriisha.dart';

/// The tidy result of a finished run, for the balance report.
class RunOutcome {
  final SiteId site;
  final Difficulty difficulty;
  final Ending ending;
  final int woke;
  final int saved;
  final int memorialNames;
  final int wreckDeaths;
  final bool reachedSpring;

  const RunOutcome({
    required this.site,
    required this.difficulty,
    required this.ending,
    required this.woke,
    required this.saved,
    required this.memorialNames,
    required this.wreckDeaths,
    required this.reachedSpring,
  });
}

/// Play a run to its end from summer day one (character and site already chosen).
/// Pass an `out` sink to narrate; leave it null to run silently.
RunOutcome playRun(GameEngine e, {void Function(String)? out}) {
  var guard = 0;
  while (e.phase != Phase.ending && guard < 400) {
    guard++;
    _playDay(e, out);
  }
  final ending = e.finalEnding ?? e.endingOutcome().ending;
  final outcome = e.finalOutcome ?? e.endingOutcome();
  return RunOutcome(
    site: e.state.run.siteId,
    difficulty: e.state.run.difficulty,
    ending: ending,
    woke: outcome.woke,
    saved: outcome.saved,
    memorialNames: e.state.memorial.length,
    wreckDeaths:
        e.state.memorial.where((m) => m.cause == Cause.wreckClock).length,
    reachedSpring: ending != Ending.death,
  );
}

void _playDay(GameEngine e, void Function(String)? out) {
  final phase = e.phase;
  final day = e.state.run.day;
  out?.call('-- ${phase.name} day $day - ${e.actionsLeft} action(s), '
      '${e.state.ableCrew.length} able, food ${e.state.resources.food.toStringAsFixed(0)}, '
      'fuel ${e.state.resources.power.fuel.toStringAsFixed(1)} --');

  // Set a standing order at the top of winter, and take the loan once it is safe.
  if (phase == Phase.winter && day == 1) {
    final me = e.state.crewById(e.state.control.controlledCrewId ?? '');
    if (me != null) e.setStandingOrder(me.id, StandingTask.rest, 6);
  }
  if (phase == Phase.winter &&
      day == 12 &&
      e.state.isResearched('biotic_adaptation')) {
    final r = e.takeLoan();
    if (out != null && r.ok) out('  loan: ${r.message}');
  }

  var safety = 0;
  while (e.actionsLeft > 0 && safety < 25) {
    safety++;
    final acted = phase == Phase.summer ? _summerAction(e) : _winterAction(e);
    if (acted == null) break;
    out?.call('  $acted');
  }

  final digest = e.endDay();
  if (out != null) {
    for (final line in digest.lines) {
      out('     $line');
    }
    if (digest.runEnded) out('     [run ended]');
  }
}

// Summer: grow the crew so there are hands to act, then build the things that
// have to persist into winter.
String? _summerAction(GameEngine e) {
  final s = e.state;
  final ableCount = s.ableCrew.length;

  final sleeping = s.pods.bay.where((sl) {
    if (!sl.occupied) return false;
    final c = s.crewById(sl.crewId ?? '');
    return c != null && !c.awake;
  }).toList();
  if (ableCount < 4 && sleeping.isNotEmpty) {
    return e.wake(sleeping.first.crewId!).message;
  }
  if (ableCount < 4 && s.pods.wreck.count > 0 && e.actionsLeft >= 1) {
    final r = e.fetchPod();
    if (r.ok) return r.message;
  }

  // Survival first, and each essential only to level one before moving on - food
  // and fuel are both mandatory for a hundred-day winter, so a working greenhouse
  // and a converter come before extra greenhouse yield. Each entry is a building
  // and the level to reach before the next thing is touched.
  final plan = <(String, int)>[
    ('greenhouse', 1),
    ('biofuel_converter', 1),
    // The site's own defence comes before the filter: a total avalanche or a
    // predator breach kills faster than the filter's slow bleed of illness.
    ...siteDef(s.run.siteId).mustBuy.map((id) => (id, 1)),
    ('water_filter', 1),
    ('observatory', 1),
    ('greenhouse', 2), // headroom, only once the essentials are up
  ];
  for (final (id, level) in plan) {
    final b = s.buildingById(id);
    final needsWork = b == null || !b.built || b.level < level;
    if (needsWork) {
      final r = e.build(id);
      if (r.ok) return r.message;
    }
  }
  if (!s.isResearched('biotic_adaptation') &&
      s.ableCrew.any((c) => c.hasRole(Role.botanist))) {
    final r = e.research('biotic_adaptation');
    if (r.ok) return r.message;
  }
  if (s.resources.scrap < 25) return e.scavenge().message;
  return e.forage().message;
}

// Winter: keep people healthy and warm, keep the reactor fed, buy peace when the
// creatures press, and build the beacon if there is room to.
String? _winterAction(GameEngine e) {
  final s = e.state;

  final hurt = s.livingAwake.firstWhere(
    (c) => c.hasCondition(Condition.sick) || c.hasCondition(Condition.injured),
    orElse: () => s.crew.first,
  );
  final someoneHurt =
      hurt.hasCondition(Condition.sick) || hurt.hasCondition(Condition.injured);

  if (someoneHurt && s.resources.medSupplies > 0) {
    return e.treat(hurt.id).message;
  }
  if (s.resources.medSupplies < 2 && s.resources.power.fuel > 4) {
    return e.synthesize().message;
  }
  if (s.resources.power.fuel < 12 && s.resources.biomass >= 10) {
    return e.burnBiomass().message;
  }
  if (s.resources.food < s.livingAwake.length * 12.0) return e.forage().message;

  final predatorComing =
      s.threats.any((t) => t.visible && t.type == ThreatType.predator);
  if (predatorComing && s.resources.food > 50) {
    final r = e.feedCreatures();
    if (r.ok) return r.message;
  }

  // Room to spare - reach for the beacon, so some runs end in rescue.
  final beacon = s.buildingById('beacon');
  final beaconDone = beacon != null && beacon.built;
  if (!beaconDone &&
      s.resources.food > 60 &&
      s.resources.power.fuel > 15 &&
      s.resources.scrap >= 40) {
    final r = e.build('beacon');
    if (r.ok) return r.message;
  }
  if (s.resources.scrap < 40) return e.scavenge().message;
  return e.forage().message;
}
