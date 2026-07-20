import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/crew.dart';
import '../models/run.dart';
import '../engine/rng.dart';
import '../engine/result.dart';

// Three answers to sickness, none safe. Wait it out (free, it spreads), quarantine
// (one action, they leave the count), or treat (one action and one supply, forty
// percent without a medic and a hundred with). A failed treatment still burns the
// supply - otherwise forty percent is just "retry until it works".

class MedicalSystem {
  /// Synthesise one medical supply from power. Power is heat, so this quietly
  /// makes the shelter colder - nothing here is paid for out of its own pocket.
  static ActionResult synthesize(RunSave s, GameConfig c) {
    // Model the 25-power cost as reactor fuel, since fuel is what power (and heat)
    // is drawn from.
    final fuelCost = c.power.supplySynthCost / c.power.reactorOutput;
    if (s.resources.power.fuel < fuelCost) {
      return const ActionResult.fail(
          'Not enough power to synthesise a supply.');
    }
    s.resources.power.fuel -= fuelCost;
    s.resources.medSupplies += 1;
    return const ActionResult.success(
        'Synthesised a medical supply. The shelter is a little colder for it.');
  }

  /// Seal someone away. Stops them spreading, takes them out of the able count.
  static ActionResult quarantine(RunSave s, Crew person) {
    if (person.hasCondition(Condition.quarantined)) {
      return const ActionResult.fail('Already quarantined.');
    }
    person.conditions.add(Condition.quarantined);
    person.able = false;
    return ActionResult.success(
        '${person.name} is quarantined. The spread stops here.');
  }

  /// Treat a sickness. Consumes a supply whether it works or not.
  static ActionResult treat(
      RunSave s, GameConfig c, SeededRng rng, Crew person) {
    if (s.resources.medSupplies <= 0) {
      return const ActionResult.fail('No medical supplies to treat with.');
    }
    if (!person.hasCondition(Condition.sick) &&
        !person.hasCondition(Condition.injured)) {
      return ActionResult.fail('${person.name} needs no treatment.');
    }
    // The supply is spent up front, before the roll. This is the load-bearing rule.
    s.resources.medSupplies -= 1;

    final hasMedic = s.livingAwake.any((p) => p.hasRole(Role.medic));
    var odds = hasMedic ? c.medical.treatWithMedic : c.medical.treatBase;
    // Field medicine research lifts the no-medic odds.
    if (!hasMedic && s.isResearched('field_medicine')) odds += 0.2;

    if (rng.chance(odds)) {
      person.conditions
          .removeWhere((cd) => cd == Condition.sick || cd == Condition.injured);
      if (!person.conditions.contains(Condition.healthy)) {
        person.conditions.add(Condition.healthy);
      }
      person.stats.health = (person.stats.health + 30).clamp(0, 100);
      return ActionResult.success('Treated ${person.name}. It took.');
    }
    return ActionResult.success(
        'Treated ${person.name}, but it did not take. The supply is gone.');
  }
}

/// The odds a treatment would have, exposed for a screen-reader label later
/// ("Treat Ru, forty percent, one action and one supply").
double treatOddsFor(RunSave s, GameConfig c) {
  final hasMedic = s.livingAwake.any((p) => p.hasRole(Role.medic));
  var odds = hasMedic ? c.medical.treatWithMedic : c.medical.treatBase;
  if (!hasMedic && s.isResearched('field_medicine')) odds += 0.2;
  return odds;
}
