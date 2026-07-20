// A headless full run. Plays a complete game with a fixed seed and a simple set
// of priorities, printing a daily digest, and ends on one of the two endings with
// the plain count line. This is the proof that the simulation works - the whole
// game is decisions and numbers, and here they are, with no interface at all.
//
// ignore_for_file: avoid_print

import 'package:veriisha/veriisha.dart';

void main() {
  final engine =
      GameEngine.newRun(seed: 20260720, difficulty: Difficulty.normal);

  print('== VERIISHA - headless full run ==');
  print(engine.chooseCharacter('rusher').message);
  print(engine.chooseSite(SiteId.cave).message);
  print(
      'Winter length this run: ${engine.state.run.winterLength} days (hidden in game until the observatory).');
  print('');

  var guard = 0;
  while (engine.phase != Phase.ending && guard < 400) {
    guard++;
    _playDay(engine);
  }

  _printEnding(engine);
}

// Play one day: spend the action budget on the highest-priority thing available,
// then resolve the day and print what changed.
void _playDay(GameEngine e) {
  final phase = e.phase;
  final day = e.state.run.day;
  print('-- ${phase.name} day $day - ${e.actionsLeft} action(s), '
      '${e.state.ableCrew.length} able, food ${e.state.resources.food.toStringAsFixed(0)}, '
      'fuel ${e.state.resources.power.fuel.toStringAsFixed(1)} --');

  // Once, at the top of winter, set a standing order and take the loan when it
  // becomes available - this exercises pacing and the loan machine.
  if (phase == Phase.winter && day == 1) {
    final me = e.state.crewById(e.state.control.controlledCrewId ?? '');
    if (me != null) {
      print(
          '  order: ${e.setStandingOrder(me.id, StandingTask.rest, 6).message}');
    }
  }
  if (phase == Phase.winter && day == 15) {
    print('  loan: ${e.takeLoan().message}');
  }

  // Spend the day's actions.
  var safety = 0;
  while (e.actionsLeft > 0 && safety < 20) {
    safety++;
    final acted = phase == Phase.summer ? _summerAction(e) : _winterAction(e);
    if (acted == null) break;
    print('  $acted');
  }

  // In quiet deep winter, skip a few days at once to show advance-days pacing.
  if (phase == Phase.winter && e.actionsLeft == 0 && _quiet(e)) {
    final span = e.advanceDays(4);
    print(
        '  ...advanced to day ${span.toDay} (${span.stopReason ?? 'ran the span'})');
    _printDigest(span);
    return;
  }

  final digest = e.endDay();
  _printDigest(digest);
}

// Nothing pressing to react to, so it is safe to fast-forward.
bool _quiet(GameEngine e) {
  final sick = e.state.livingAwake.any((c) => c.hasCondition(Condition.sick));
  final telegraph = e.state.threats.any((t) => t.visible);
  return !sick && !telegraph && e.state.resources.food > 40;
}

// Summer: build the capacity to act, then the things that must persist into winter.
String? _summerAction(GameEngine e) {
  final s = e.state;
  final awakeAble = s.ableCrew.length;

  // Grow the crew first - wake a fetched pod, or fetch one to wake.
  final sleepingSlot = s.pods.bay.where((sl) {
    if (!sl.occupied) return false;
    final c = s.crewById(sl.crewId ?? '');
    return c != null && !c.awake;
  }).toList();
  if (awakeAble < 3 && sleepingSlot.isNotEmpty) {
    return e.wake(sleepingSlot.first.crewId!).message;
  }
  if (awakeAble < 3 && s.pods.wreck.count > 0 && e.actionsLeft >= 1) {
    final r = e.fetchPod();
    if (r.ok) return r.message;
  }

  // Then the prep list, in priority order. Site must-buys first.
  final plan = [
    ...siteDef(s.run.siteId).mustBuy,
    'greenhouse', // extra levels for yield
    'biofuel_converter',
    'water_filter',
    'observatory',
  ];
  for (final id in plan) {
    final b = s.buildingById(id);
    final needsWork =
        b == null || !b.built || (id == 'greenhouse' && b.level < 2);
    if (needsWork) {
      final r = e.build(id);
      if (r.ok) return r.message;
    }
  }
  // Research biotic adaptation if a botanist is on hand.
  if (!s.isResearched('biotic_adaptation') &&
      s.ableCrew.any((c) => c.hasRole(Role.botanist))) {
    final r = e.research('biotic_adaptation');
    if (r.ok) return r.message;
  }
  // Otherwise stock up: scrap if short, food otherwise.
  if (s.resources.scrap < 20) return e.scavenge().message;
  return e.forage().message;
}

// Winter: react to sickness and shortage, keep the fires lit, buy peace if pressed.
String? _winterAction(GameEngine e) {
  final s = e.state;

  final sick = s.livingAwake.firstWhere(
    (c) => c.hasCondition(Condition.sick) || c.hasCondition(Condition.injured),
    orElse: () => s.crew.first,
  );
  final someoneSick =
      sick.hasCondition(Condition.sick) || sick.hasCondition(Condition.injured);

  if (someoneSick && s.resources.medSupplies > 0) {
    return e.treat(sick.id).message;
  }
  if (someoneSick &&
      s.resources.medSupplies == 0 &&
      s.resources.power.fuel > 2) {
    return e.synthesize().message;
  }
  if (s.resources.food < 25) return e.forage().message;
  if (s.resources.power.fuel < 8 && s.resources.biomass >= 10) {
    return e.burnBiomass().message;
  }

  // A predator telegraph with food to spare - buy a few days of quiet.
  final predatorComing =
      s.threats.any((t) => t.visible && t.type == ThreatType.predator);
  if (predatorComing && s.resources.food > 45) {
    final r = e.feedCreatures();
    if (r.ok) return r.message;
  }

  // Nothing urgent - top up the larder.
  return e.forage().message;
}

void _printDigest(DayDigest d) {
  for (final line in d.lines) {
    print('     $line');
  }
  if (d.runEnded) print('     [run ended]');
}

void _printEnding(GameEngine e) {
  print('');
  print('== END ==');
  final outcome = e.finalOutcome ?? e.endingOutcome();
  final ending = e.finalEnding ?? outcome.ending;
  print(endingText(ending));
  print(endingCountLine(ending, woke: outcome.woke, saved: outcome.saved));
  print('');
  print('Memorial holds ${e.state.memorial.length} names.');
  print(
      'Wreck deaths recorded: ${e.state.memorial.where((m) => m.cause == Cause.wreckClock).length}.');
}
