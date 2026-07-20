import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/crew.dart';
import '../models/run.dart';
import '../engine/rng.dart';
import '../engine/result.dart';

// Conditions and the deaths they lead to. A person who is quarantined, frostbitten
// or injured is out of the action count; a person who is merely sick still works,
// and still spreads it.

class ConditionSystem {
  // The conditions that take someone out of the able-body count.
  static const _unable = {
    Condition.quarantined,
    Condition.frostbitten,
    Condition.injured,
    Condition.dead,
  };

  /// Recompute who counts as an able body. Called each morning before the action
  /// pool is worked out.
  static void recomputeAble(RunSave s) {
    for (final person in s.crew) {
      final blocked = person.conditions.any(_unable.contains);
      person.able =
          person.awake && person.alive && !blocked && person.stats.health > 0;
    }
  }

  /// Untreated sickness worsens on a curve, and can spread to a shared-quarters
  /// crewmate. Treatments taken during the day already happened in the action
  /// phase, so this is only the untreated progression.
  static void progress(RunSave s, GameConfig c, SeededRng rng) {
    final sickPeople =
        s.livingAwake.where((p) => p.hasCondition(Condition.sick)).toList();
    for (final person in sickPeople) {
      if (person.hasCondition(Condition.quarantined)) {
        continue; // sealed off, no spread
      }
      person.stats.health -= c.medical.sicknessWorsenPerDay.round();
      person.stats.clamp();
      // Contagion to a healthy, un-quarantined crewmate.
      final targets = s.livingAwake
          .where((p) =>
              p.id != person.id &&
              !p.hasCondition(Condition.sick) &&
              !p.hasCondition(Condition.quarantined))
          .toList();
      if (targets.isNotEmpty && rng.chance(c.medical.contagionChance)) {
        final victim = targets[rng.nextInt(targets.length)];
        victim.conditions.remove(Condition.healthy);
        victim.conditions.add(Condition.sick);
      }
    }
  }

  /// Anyone whose health has hit zero dies now. Returns the deaths so the caller
  /// can write the memorial and digest. Crew deaths resolve before the wreck
  /// death so the day's mortality is deterministic and the two never race.
  static List<DeathRecord> resolveDeaths(RunSave s, int day) {
    final deaths = <DeathRecord>[];
    for (final person in s.crew) {
      if (person.alive && person.awake && person.stats.health <= 0) {
        person.alive = false;
        person.able = false;
        person.conditions
          ..clear()
          ..add(Condition.dead);
        final cause = _causeFor(person);
        deaths.add(DeathRecord(person.name, cause));
        s.memorial
            .add(MemorialEntry(name: person.name, cause: cause, day: day));
      }
    }
    return deaths;
  }

  static Cause _causeFor(Crew p) {
    if (p.stats.warmth <= 0) return Cause.froze;
    if (p.stats.hunger <= 0 || p.stats.thirst <= 0) return Cause.starved;
    if (p.hasCondition(Condition.injured)) return Cause.injury;
    return Cause.illness;
  }
}
