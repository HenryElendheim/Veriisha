// The config IS the game. Every number the simulation uses lives here, in one
// object. Difficulty is multipliers over this object and nothing else. If tuning
// ever needs a logic edit somewhere in lib/systems, the config is wrong, not the
// system.
//
// Design note: these knobs are plain fields, not magic numbers scattered through
// the code. A system reads config.decay.hungerPerDay - never a literal 12.

/// Summer length, action counts, winter length bounds.
class TimeConfig {
  final int summerDays; // fixed at 7, never randomised
  final int summerActions; // 4 per day
  final int winterActions; // 3 per day
  final int winterLenMin; // rolled in [min, max] at run start
  final int winterLenMax;

  const TimeConfig({
    this.summerDays = 7,
    this.summerActions = 4,
    this.winterActions = 3,
    this.winterLenMin = 100,
    this.winterLenMax = 130,
  });
}

/// The loan: borrow effort now, pay it back with interest soon after.
class LoanConfig {
  final int upBonus; // +1 action
  final int upDays; // for 3 days
  final int downPenalty; // then -1 action
  final int downDays; // for 3 days

  const LoanConfig({
    this.upBonus = 1,
    this.upDays = 3,
    this.downPenalty = 1,
    this.downDays = 3,
  });
}

/// How fast the four needs fall, and the thresholds that start doing harm.
class DecayConfig {
  final double hungerPerDay;
  final double thirstPerDay;
  final double
      warmthPerColdDegree; // warmth lost per degree the room is below neutral
  final double
      warmthRecoveryInWarmth; // warmth regained per day in a heated room
  final int harmThreshold; // at or below this, a need starts damaging health
  final double
      healthDamagePerNeed; // health lost per day per need under threshold

  const DecayConfig({
    this.hungerPerDay = 12,
    this.thirstPerDay = 15,
    this.warmthPerColdDegree = 1.5,
    this.warmthRecoveryInWarmth = 10,
    this.harmThreshold = 20,
    this.healthDamagePerNeed = 8,
  });
}

/// Reactor, fuel, biofuel, and the cost of synthesising a medical supply.
class PowerConfig {
  final int reactorOutput; // total power available per day at full fuel
  final int fuelDays; // days of fuel the reactor starts with
  final double biomassToFuelDays; // fuel-days gained per unit of biomass burned
  final int supplySynthCost; // power to synthesise one medical supply
  final int neutralRoomTemp; // room temperature with heat fully powered

  const PowerConfig({
    this.reactorOutput = 100,
    this.fuelDays = 35,
    this.biomassToFuelDays = 0.5,
    this.supplySynthCost = 25,
    this.neutralRoomTemp = 20,
  });
}

/// Food and water: how much people need, what the greenhouse gives back.
class FoodConfig {
  final double foodPerPersonPerDay;
  final double waterPerPersonPerDay;
  final double greenhouseYieldPerLevel; // food per day per greenhouse level
  final double forageWinterReturn; // near nothing - the biosphere is dormant
  final double forageSummerReturn;
  final double
      dirtyWaterSickChance; // chance a person drinking unfiltered water sickens

  const FoodConfig({
    this.foodPerPersonPerDay = 10,
    this.waterPerPersonPerDay = 10,
    this.greenhouseYieldPerLevel = 22,
    this.forageWinterReturn = 3,
    this.forageSummerReturn = 18,
    this.dirtyWaterSickChance = 0.15,
  });
}

/// The three answers to sickness, priced.
class MedicalConfig {
  final double treatBase; // treatment success without a medic
  final double treatWithMedic; // treatment success with a medic
  final double
      sicknessWorsenPerDay; // health lost per day while sick, untreated
  final double
      contagionChance; // chance sickness spreads to a shared-quarters crewmate

  const MedicalConfig({
    this.treatBase = 0.40,
    this.treatWithMedic = 1.00,
    this.sicknessWorsenPerDay = 6,
    this.contagionChance = 0.25,
  });
}

/// The wreck and the pod bay.
class PodConfig {
  final int wreckStart; // 220 frozen colonists
  final int wreckDeathsPerDay; // exactly one, every day, never slowed
  final int fetchActionsSummer; // 1 action to fetch a pod in summer
  final int fetchActionsWinter; // 3 actions in winter
  final double fetchWinterInjuryChance; // risk of injury on a winter fetch
  final int bayCapacitySummer; // powered pod slots at camp in summer
  final int
      bayCapacityWinter; // fewer slots once solar drops - a real day-8 squeeze

  const PodConfig({
    this.wreckStart = 220,
    this.wreckDeathsPerDay = 1,
    this.fetchActionsSummer = 1,
    this.fetchActionsWinter = 3,
    this.fetchWinterInjuryChance = 0.25,
    this.bayCapacitySummer = 6,
    this.bayCapacityWinter = 3,
  });
}

/// The creatures. They are starving, not evil.
class CreatureConfig {
  final int feedPeaceDays; // heavy rations buy about three days of quiet
  final int feedRationCost; // food spent to feed them once
  final double baseAttackSeverity;
  final double severityPerWinterTenth; // attacks worsen as winter deepens

  const CreatureConfig({
    this.feedPeaceDays = 3,
    this.feedRationCost = 30,
    this.baseAttackSeverity = 6,
    this.severityPerWinterTenth = 2,
  });
}

/// How far ahead every threat is telegraphed. The minimum being at least 1 is
/// what makes an untelegraphed hit structurally impossible.
class ThreatConfig {
  final int warningMinDays;
  final int warningMaxDays;

  const ThreatConfig({this.warningMinDays = 1, this.warningMaxDays = 2});
}

/// The one config object. Build the Normal baseline with `GameConfig.normal()`,
/// then fold difficulty in with `applyModifiers` to get the effective config the
/// systems actually read.
class GameConfig {
  final TimeConfig time;
  final LoanConfig loan;
  final DecayConfig decay;
  final PowerConfig power;
  final FoodConfig food;
  final MedicalConfig medical;
  final PodConfig pods;
  final CreatureConfig creatures;
  final ThreatConfig threat;

  const GameConfig({
    this.time = const TimeConfig(),
    this.loan = const LoanConfig(),
    this.decay = const DecayConfig(),
    this.power = const PowerConfig(),
    this.food = const FoodConfig(),
    this.medical = const MedicalConfig(),
    this.pods = const PodConfig(),
    this.creatures = const CreatureConfig(),
    this.threat = const ThreatConfig(),
  });

  /// The Normal baseline - every number exactly as the design specifies.
  const GameConfig.normal() : this();
}
