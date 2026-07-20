import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/run.dart';
import 'power_system.dart';

// The four needs falling, and the harm they do once they run out. Warmth falls
// by how cold the room is, which is decided by power - so heat, food and medicine
// are all wired to the same reactor.

class NeedsSystem {
  /// Decay every awake person's needs for the day. Hunger and thirst always fall
  /// and are restored by eating and drinking. Warmth tracks the room: a cold room
  /// bleeds it, a heated one lets it recover - so keeping power on heat is what
  /// pulls people back from a bad night.
  static void decay(RunSave s, GameConfig c) {
    final campTemp = PowerSystem.campTemp(s, c);
    final coldness = c.power.neutralRoomTemp - campTemp;
    // Below neutral the room takes warmth; at or above neutral it gives it back.
    final warmthDelta = coldness > 0
        ? -coldness * c.decay.warmthPerColdDegree
        : c.decay.warmthRecoveryInWarmth;

    for (final person in s.livingAwake) {
      // Efficient colonists burn through hunger and thirst noticeably slower.
      final slow = person.hasTrait(Trait.efficient) ? 0.6 : 1.0;
      person.stats.hunger -= (c.decay.hungerPerDay * slow).round();
      person.stats.thirst -= (c.decay.thirstPerDay * slow).round();
      person.stats.warmth += warmthDelta.round();
      person.stats.clamp();
    }
  }

  /// Turn empty needs into lost health. Anything at or below the harm threshold
  /// bleeds health each day; a low warmth also risks frostbite.
  static void applyDamage(RunSave s, GameConfig c) {
    for (final person in s.livingAwake) {
      var damage = 0.0;
      if (person.stats.hunger <= c.decay.harmThreshold) {
        damage += c.decay.healthDamagePerNeed;
      }
      if (person.stats.thirst <= c.decay.harmThreshold) {
        damage += c.decay.healthDamagePerNeed;
      }
      if (person.stats.warmth <= c.decay.harmThreshold) {
        damage += c.decay.healthDamagePerNeed;
        // Deep cold turns into frostbite, which takes someone out of the count.
        if (person.stats.warmth <= 5 &&
            !person.hasCondition(Condition.frostbitten)) {
          person.conditions.add(Condition.frostbitten);
        }
      }
      person.stats.health -= damage.round();
      person.stats.clamp();
    }
  }
}
