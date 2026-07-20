import '../config/game_config.dart';
import '../content/sites.dart';
import '../models/enums.dart';
import '../models/run.dart';
import '../engine/rng.dart';
import 'threat_system.dart';

// The creatures are not monsters, they are starving. Their food went under with
// the rest of the biosphere, so they come to the wall - more often and harder as
// winter deepens and their hunger worsens. You can feed them for a few days of
// peace. At spring they simply stop, because they never wanted you.

class CreatureSystem {
  /// Feed the creatures a heavy ration for about three days of quiet. How you
  /// feed them - early while they still had strength, or only once desperate -
  /// is recorded, and decides which colony epilogue you get.
  static bool feed(RunSave s, GameConfig c) {
    if (s.resources.food < c.creatures.feedRationCost) return false;
    s.resources.food -= c.creatures.feedRationCost;
    final r = s.creatureRelations;
    r.timesFed += 1;
    r.peaceDaysRemaining = c.creatures.feedPeaceDays;
    // Early is while winter is young and they still have strength; desperate is
    // late, when they are already at the wall.
    if (ThreatSystem.winterProgress(s) <= 0.4) {
      r.fedEarly += 1;
    } else {
      r.fedDesperate += 1;
    }
    return true;
  }

  /// The daily creature pressure. During bought peace, nothing comes. Otherwise
  /// there is a chance - higher at the Basin, and rising with winter depth - of a
  /// predator attack, which is raised as a telegraphed threat like anything else.
  static void dailyPressure(RunSave s, GameConfig c, SeededRng rng) {
    if (s.run.phase != Phase.winter) return;
    final r = s.creatureRelations;
    if (r.peaceDaysRemaining > 0) {
      r.peaceDaysRemaining -= 1;
      return;
    }
    final progress = ThreatSystem.winterProgress(s);
    final basin = siteDef(s.run.siteId).threat == ThreatType.predator;
    final chance = (basin ? 0.22 : 0.10) + progress * 0.25;
    if (rng.chance(chance)) {
      final severity = c.creatures.baseAttackSeverity +
          c.creatures.severityPerWinterTenth * (progress * 10);
      ThreatSystem.raise(s, c, rng, ThreatType.predator, 'creatures',
          severity: severity);
    }
  }
}
