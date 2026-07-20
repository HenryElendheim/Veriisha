import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/run.dart';
import '../engine/rng.dart';

// Food and water. Snowmelt is everywhere; potable water is not. The greenhouse is
// the only reliable winter food, because the biosphere hibernates and foraging
// returns almost nothing once winter sets in.

class FoodWaterSystem {
  /// Passive production for the day: greenhouse crops, and snowmelt that the
  /// filter (if built and powered) turns from dirty to clean.
  static void produce(RunSave s, GameConfig c) {
    final greenhouse = s.buildingById('greenhouse');
    if (greenhouse != null && greenhouse.built) {
      s.resources.food += c.food.greenhouseYieldPerLevel * greenhouse.level;
    }
    // Snowmelt is endless but dirty.
    s.resources.water.dirty += 40;
    // The filter cleans a share of it, but only while there is power to run it.
    if (s.isBuilt('water_filter') && s.resources.power.output > 0) {
      final cleaned = s.resources.water.dirty * 0.8;
      s.resources.water.dirty -= cleaned;
      s.resources.water.clean += cleaned;
    }
  }

  /// Feed and water everyone awake. Eating restores hunger; drinking restores
  /// thirst. Unfiltered water can make a person sick. Anything the larder cannot
  /// cover simply is not eaten, and the decay step will bite.
  static void consume(RunSave s, GameConfig c, SeededRng rng) {
    for (final person in s.livingAwake) {
      // Food.
      if (s.resources.food >= c.food.foodPerPersonPerDay) {
        s.resources.food -= c.food.foodPerPersonPerDay;
        person.stats.hunger = (person.stats.hunger + 45).clamp(0, 100);
      }
      // Water: clean first, then dirty at a risk, then nothing.
      final need = c.food.waterPerPersonPerDay;
      if (s.resources.water.clean >= need) {
        s.resources.water.clean -= need;
        person.stats.thirst = (person.stats.thirst + 45).clamp(0, 100);
      } else if (s.resources.water.dirty >= need) {
        s.resources.water.dirty -= need;
        person.stats.thirst = (person.stats.thirst + 45).clamp(0, 100);
        if (rng.chance(c.food.dirtyWaterSickChance) &&
            !person.hasCondition(Condition.sick)) {
          person.conditions.remove(Condition.healthy);
          if (!person.hasCondition(Condition.sick)) {
            person.conditions.add(Condition.sick);
          }
        }
      }
    }
  }

  /// A foraging expedition. Rich in summer, near-worthless in winter - the food
  /// web has gone under. Returns the amount of food gathered.
  static double forage(RunSave s, GameConfig c, SeededRng rng) {
    final base = s.run.phase == Phase.winter
        ? c.food.forageWinterReturn
        : c.food.forageSummerReturn;
    // A little spread so a good forage is a real event.
    final amount = base * (0.7 + rng.nextDouble() * 0.6);
    s.resources.food += amount;
    // Summer foraging also turns up biomass for the biofuel converter.
    if (s.run.phase != Phase.winter) s.resources.biomass += amount * 0.5;
    return amount;
  }
}
