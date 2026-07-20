import '../config/game_config.dart';
import '../content/buildings.dart';
import '../content/sites.dart';
import '../models/enums.dart';
import '../models/run.dart';

// Power and heat. The rule that makes the game tense is that power IS heat: every
// watt spent on medicine or the beacon is a watt not warming the shelter. Nothing
// is paid for out of its own pocket.

class PowerSystem {
  /// Fuel burned per day, before biomass top-ups. The cave's rock retains heat,
  /// so its fuel effectively lasts longer (a smaller burn per day).
  static double dailyFuelBurn(RunSave s, GameConfig c) {
    final retention = siteDef(s.run.siteId).heatRetention;
    return 1.0 / retention;
  }

  /// Total power the built stations want each winter day, plus a heat baseline.
  static int powerDemand(RunSave s) {
    var demand = 30; // baseline heat for the core shelter
    for (final b in s.buildings) {
      if (b.built) demand += buildingDef(b.id).powerDraw;
    }
    return demand;
  }

  /// The power the reactor can actually put out today. No fuel -> nothing, and a
  /// cold shelter.
  static int availableOutput(RunSave s, GameConfig c) {
    return s.resources.power.fuel > 0 ? c.power.reactorOutput : 0;
  }

  /// How well heat demand is met, 0..1. Below 1, something goes dark and the camp
  /// gets colder.
  static double heatSatisfaction(RunSave s, GameConfig c) {
    final demand = powerDemand(s);
    if (demand <= 0) return 1.0;
    final output = availableOutput(s, c);
    final ratio = output / demand;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  /// Outside temperature. Mild in summer, falling as winter deepens.
  static double outsideTemp(RunSave s, GameConfig c) {
    if (s.run.phase != Phase.winter) return 8;
    final len = s.run.winterLength <= 0 ? 1 : s.run.winterLength;
    final progress = (s.run.day / len).clamp(0.0, 1.0);
    // From about -8 early to about -30 at the deepest, then it is spring's problem.
    final t = -8 - 22 * progress;
    return t < -30 ? -30 : t;
  }

  /// The camp temperature crew actually live in - the outside cold pulled up
  /// toward neutral by however much heat the reactor is delivering.
  static double campTemp(RunSave s, GameConfig c) {
    final outside = outsideTemp(s, c);
    final neutral = c.power.neutralRoomTemp.toDouble();
    return outside + (neutral - outside) * heatSatisfaction(s, c);
  }

  /// Burn the day's fuel, then let a built converter top it back up from biomass.
  /// This is why the greenhouse and the converter together are the winter engine:
  /// crop waste becomes fuel, and fuel is heat. Called once at day-end.
  static void burnDailyFuel(RunSave s, GameConfig c) {
    s.resources.power.fuel -= dailyFuelBurn(s, c);
    if (s.resources.power.fuel < 0) s.resources.power.fuel = 0;
    if (s.isBuilt('biofuel_converter') && s.resources.biomass > 0) {
      final processed = s.resources.biomass < c.power.biofuelDailyCap
          ? s.resources.biomass
          : c.power.biofuelDailyCap;
      s.resources.biomass -= processed;
      s.resources.power.fuel += processed * c.power.biomassToFuelDays;
    }
    s.resources.power.output = availableOutput(s, c);
  }

  /// Burn a unit of biomass into reactor fuel-days. Needs the converter built.
  static bool burnBiomass(RunSave s, GameConfig c, {double biomassUnits = 10}) {
    if (!s.isBuilt('biofuel_converter')) return false;
    if (s.resources.biomass < biomassUnits) return false;
    s.resources.biomass -= biomassUnits;
    s.resources.power.fuel += biomassUnits * c.power.biomassToFuelDays;
    return true;
  }
}
