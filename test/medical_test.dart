import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';
import 'package:veriisha/systems/medical_system.dart';

// The medic must be worth something, and a failed treatment must still cost the
// supply - otherwise forty percent is just "retry until it works".

void main() {
  const c = GameConfig.normal();

  Crew patient() => Crew(
        id: 'p',
        name: 'Pat',
        roles: const [Role.engineer],
        awake: true,
        alive: true,
        able: true,
        conditions: [Condition.sick],
        stats: Stats(health: 50),
      );

  test('a medic makes treatment certain', () {
    final p = patient();
    final medic = Crew(
        id: 'm',
        name: 'Med',
        roles: const [Role.medic],
        awake: true,
        alive: true,
        able: true);
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter),
      crew: [p, medic],
      resources: Resources(medSupplies: 30),
    );
    final rng = SeededRng(1);
    // Twenty sick spells, twenty certain cures.
    var cured = 0;
    for (var i = 0; i < 20; i++) {
      p.conditions
        ..clear()
        ..add(Condition.sick);
      MedicalSystem.treat(s, c, rng, p);
      if (!p.hasCondition(Condition.sick)) cured++;
    }
    expect(cured, 20, reason: 'a medic is a sure thing');
    expect(s.resources.medSupplies, 10,
        reason: 'each treatment spent one supply');
  });

  test(
      'without a medic treatment sometimes fails, and always spends the supply',
      () {
    final p = patient();
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter),
      crew: [p],
      resources: Resources(medSupplies: 100),
    );
    final rng = SeededRng(20260720);
    const trials = 100;
    var cured = 0;
    for (var i = 0; i < trials; i++) {
      p.conditions
        ..clear()
        ..add(Condition.sick);
      MedicalSystem.treat(s, c, rng, p);
      if (!p.hasCondition(Condition.sick)) cured++;
    }
    // No medic means 40% - so well short of certain, but not zero either.
    expect(cured, lessThan(trials));
    expect(cured, greaterThan(0));
    // Every trial spent exactly one supply, hit or miss.
    expect(s.resources.medSupplies, 100 - trials);
  });

  test('treating with no supplies does nothing', () {
    final p = patient();
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter),
      crew: [p],
      resources: Resources(medSupplies: 0),
    );
    final r = MedicalSystem.treat(s, c, SeededRng(1), p);
    expect(r.ok, isFalse);
    expect(p.hasCondition(Condition.sick), isTrue);
  });
}
