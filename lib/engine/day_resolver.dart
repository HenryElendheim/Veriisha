import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/crew.dart';
import '../models/run.dart';
import '../systems/food_water_system.dart';
import '../systems/needs_system.dart';
import '../systems/condition_system.dart';
import '../systems/threat_system.dart';
import '../systems/creature_system.dart';
import '../systems/wreck_system.dart';
import '../systems/research_system.dart';
import 'action_economy.dart';
import 'rng.dart';
import 'result.dart';

// The day-end pipeline. Everything that happens overnight runs here, in one place,
// in one strict order. The order is chosen to honour the guardrails: a threat is
// always visible before it lands, the wreck death is unconditional, and crew
// deaths resolve before the wreck death so the day's mortality never races.

class DayResolver {
  static DayDigest resolveDayEnd(RunSave s, GameConfig c, SeededRng rng) {
    final day = s.run.day;
    final digest = DayDigest(fromDay: day, toDay: day);

    // 1. Production, then consumption. The larder is filled by the greenhouse and
    //    snowmelt before anyone eats, so a shortfall shows up as decay, not as
    //    double counting.
    FoodWaterSystem.produce(s, c);
    FoodWaterSystem.consume(s, c, rng);

    // 2. Needs decay - hunger, thirst, and warmth by how cold the room is.
    NeedsSystem.decay(s, c);

    // 3. Empty needs turn into lost health.
    NeedsSystem.applyDamage(s, c);

    // 4. Untreated conditions worsen and can spread.
    ConditionSystem.progress(s, c, rng);

    // 5. Crew deaths from stats and conditions - resolved BEFORE the wreck death so
    //    the day's mortality is deterministic and the two never race.
    final crewDeaths = ConditionSystem.resolveDeaths(s, day);
    digest.deaths.addAll(crewDeaths);
    for (final d in crewDeaths) {
      digest.lines.add('${d.name} died - ${d.cause.name}.');
    }

    // 6. The one wreck death. Unconditional, exactly one, by name.
    final wreckDeaths = WreckSystem.killDaily(s, c, day);
    digest.deaths.addAll(wreckDeaths);
    for (final d in wreckDeaths) {
      digest.lines.add('The wreck lost ${d.name}.');
    }

    // 7. Threats draw a day closer, then any that reached their day land. Every
    //    landed threat must have been visible already - if one is not, the
    //    telegraph guarantee has broken.
    ThreatSystem.advance(s);
    final landed = ThreatSystem.land(s, c);
    for (final l in landed) {
      digest.lines.add(l.line);
      assert(l.wasVisible,
          'Telegraph guarantee broken: a ${l.threat.type.name} landed unseen.');
    }

    // 8. New troubles are rolled, and the creatures press at the wall. Anything
    //    raised here is given at least a full day of warning, so nothing can land
    //    the same day it is born.
    ThreatSystem.spawnEvents(s, c, rng);
    CreatureSystem.dailyPressure(s, c, rng);

    // 9. Telegraphs: flip on the sign for anything now inside the warning window.
    final signs = ThreatSystem.updateTelegraphs(s, c);
    digest.newTelegraphs.addAll(signs);
    digest.lines.addAll(signs);

    // 10. The loan clock ticks - a day up, or a day of the debt coming due.
    ActionEconomy.tickLoan(s, c);

    // 11. Standing orders carry out their work and count down.
    _progressStandingOrders(s);

    // 12. Advance the day and check for a phase change or the end of the run.
    _advance(s, c, digest);

    return digest;
  }

  // Standing orders let one decision cover many days. Here they do their passive
  // work and tick down; a completed order is a reason to stop an advance-days run.
  static void _progressStandingOrders(RunSave s) {
    for (final person in s.crew) {
      final order = person.standingOrder;
      if (order == null || !person.able) continue;
      switch (order.task) {
        case StandingTask.research:
          if (order.targetId != null) ResearchSystem.work(s, order.targetId!);
          break;
        case StandingTask.rest:
          person.stats.health = (person.stats.health + 8).clamp(0, 100);
          break;
        case StandingTask.tendCrop:
        case StandingTask.holdWall:
        case StandingTask.standWatch:
        case StandingTask.teach:
          break; // effects are read live by the relevant system
      }
      order.daysRemaining -= 1;
      if (order.daysRemaining <= 0) person.standingOrder = null;
    }
  }

  // Move the calendar on and handle summer -> winter -> spring, plus the two ways
  // a run ends early.
  static void _advance(RunSave s, GameConfig c, DayDigest digest) {
    // A run ends the moment nobody is left awake and alive.
    if (s.livingAwake.isEmpty) {
      s.run.phase = Phase.ending;
      digest
        ..runEnded = true
        ..ending = Ending.death
        ..phaseChanged = true
        ..newPhase = Phase.ending;
      return;
    }

    if (s.run.phase == Phase.summer) {
      if (s.run.day >= c.time.summerDays) {
        _enterWinter(s, c, digest);
      } else {
        s.run.day += 1;
      }
    } else if (s.run.phase == Phase.winter) {
      if (s.run.day >= s.run.winterLength) {
        s.run.phase =
            Phase.ending; // spring - the ending is decided by the engine
        digest
          ..phaseChanged = true
          ..newPhase = Phase.ending;
      } else {
        s.run.day += 1;
      }
    }
  }

  // Summer to winter. Solar drops, so the powered bay shrinks - any pod beyond the
  // smaller capacity loses power, and an unpowered pod at camp is a death timer.
  static void _enterWinter(RunSave s, GameConfig c, DayDigest digest) {
    s.run.phase = Phase.winter;
    s.run.day = 1;
    digest
      ..phaseChanged = true
      ..newPhase = Phase.winter;

    final capacity = c.pods.bayCapacityWinter;
    final occupied = s.pods.bay.where((slot) => slot.occupied).toList();
    if (occupied.length > capacity) {
      final losing = occupied.sublist(capacity);
      for (final slot in losing) {
        slot.powered = false;
        final person = s.crewById(slot.crewId ?? '');
        if (person != null && !person.awake) {
          person.alive = false;
          slot.occupied = false;
          s.memorial.add(MemorialEntry(
              name: person.name, cause: Cause.froze, day: s.run.day));
          digest.deaths.add(DeathRecord(person.name, Cause.froze));
          digest.lines.add(
              '${person.name} lost power in the bay when winter cut the slots.');
        }
      }
    }
  }
}
