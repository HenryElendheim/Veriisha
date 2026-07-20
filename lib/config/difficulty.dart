import 'game_config.dart';
import '../models/enums.dart';

// Difficulty is multipliers folded into the config ONCE, at run start. After
// that the whole engine reads a single effective GameConfig and does identical
// arithmetic no matter the difficulty. No system ever reads Difficulty. The only
// place difficulty is consulted again is character select, where hard refuses
// unlocked colonists - a content rule, not a logic branch.

/// A bag of multipliers over the tunable knobs. 1.0 means "leave it alone".
class DifficultyModifiers {
  final double forageMult; // kinder or harsher forage returns
  final double treatRollMult; // luck on treatment rolls
  final double eventSeverityMult; // how hard events land
  final double decayMult; // how fast needs fall
  final double injuryChanceMult; // expedition and fetch injury risk
  final double contagionMult; // how readily sickness spreads

  const DifficultyModifiers({
    this.forageMult = 1.0,
    this.treatRollMult = 1.0,
    this.eventSeverityMult = 1.0,
    this.decayMult = 1.0,
    this.injuryChanceMult = 1.0,
    this.contagionMult = 1.0,
  });

  /// Luck tilted your way.
  static const easy = DifficultyModifiers(
    forageMult: 1.4,
    treatRollMult: 1.25,
    eventSeverityMult: 0.75,
    decayMult: 0.85,
    injuryChanceMult: 0.7,
    contagionMult: 0.7,
  );

  /// The game exactly as specified.
  static const normal = DifficultyModifiers();

  /// Everything tighter, luck against you.
  static const hard = DifficultyModifiers(
    forageMult: 0.7,
    treatRollMult: 0.85,
    eventSeverityMult: 1.3,
    decayMult: 1.15,
    injuryChanceMult: 1.3,
    contagionMult: 1.35,
  );

  static DifficultyModifiers forDifficulty(Difficulty d) => switch (d) {
        Difficulty.easy => easy,
        Difficulty.normal => normal,
        Difficulty.hard => hard,
      };
}

/// Fold a set of modifiers into a base config, producing the effective config
/// the systems read. The wreck death clock is deliberately untouched here - it
/// is the spine of the game and no difficulty may slow it.
GameConfig applyModifiers(GameConfig base, DifficultyModifiers m) {
  return GameConfig(
    time: base.time, // time is structural, not tuned by difficulty
    loan: base.loan,
    decay: DecayConfig(
      hungerPerDay: base.decay.hungerPerDay * m.decayMult,
      thirstPerDay: base.decay.thirstPerDay * m.decayMult,
      warmthPerColdDegree: base.decay.warmthPerColdDegree * m.decayMult,
      harmThreshold: base.decay.harmThreshold,
      healthDamagePerNeed: base.decay.healthDamagePerNeed,
    ),
    power: base.power,
    food: FoodConfig(
      foodPerPersonPerDay: base.food.foodPerPersonPerDay,
      waterPerPersonPerDay: base.food.waterPerPersonPerDay,
      greenhouseYieldPerLevel: base.food.greenhouseYieldPerLevel,
      forageWinterReturn: base.food.forageWinterReturn * m.forageMult,
      forageSummerReturn: base.food.forageSummerReturn * m.forageMult,
      dirtyWaterSickChance: base.food.dirtyWaterSickChance * m.contagionMult,
    ),
    medical: MedicalConfig(
      treatBase: base.medical.treatBase * m.treatRollMult,
      treatWithMedic:
          base.medical.treatWithMedic, // a medic is always a sure thing
      sicknessWorsenPerDay: base.medical.sicknessWorsenPerDay,
      contagionChance: base.medical.contagionChance * m.contagionMult,
    ),
    pods: PodConfig(
      wreckStart: base.pods.wreckStart,
      wreckDeathsPerDay: base.pods.wreckDeathsPerDay, // never tuned - the spine
      fetchActionsSummer: base.pods.fetchActionsSummer,
      fetchActionsWinter: base.pods.fetchActionsWinter,
      fetchWinterInjuryChance:
          base.pods.fetchWinterInjuryChance * m.injuryChanceMult,
      bayCapacitySummer: base.pods.bayCapacitySummer,
      bayCapacityWinter: base.pods.bayCapacityWinter,
    ),
    creatures: CreatureConfig(
      feedPeaceDays: base.creatures.feedPeaceDays,
      feedRationCost: base.creatures.feedRationCost,
      baseAttackSeverity:
          base.creatures.baseAttackSeverity * m.eventSeverityMult,
      severityPerWinterTenth:
          base.creatures.severityPerWinterTenth * m.eventSeverityMult,
    ),
    threat: base.threat,
  );
}
