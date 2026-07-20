import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';

// Difficulty is multipliers folded into the config once, and nothing else. The
// spine of the game - the wreck clock - and the structure of time never move.

void main() {
  const base = GameConfig.normal();
  final easy = applyModifiers(base, DifficultyModifiers.easy);
  final hard = applyModifiers(base, DifficultyModifiers.hard);

  test('the wreck clock is identical on every difficulty', () {
    expect(base.pods.wreckDeathsPerDay, 1);
    expect(easy.pods.wreckDeathsPerDay, 1);
    expect(hard.pods.wreckDeathsPerDay, 1);
  });

  test('the shape of time never changes with difficulty', () {
    for (final cfg in [easy, hard]) {
      expect(cfg.time.summerDays, base.time.summerDays);
      expect(cfg.time.summerActions, base.time.summerActions);
      expect(cfg.time.winterActions, base.time.winterActions);
      expect(cfg.pods.wreckStart, base.pods.wreckStart);
    }
  });

  test('tunable knobs move in the expected direction', () {
    // Easy is kinder forage, harder is meaner.
    expect(easy.food.forageWinterReturn,
        greaterThan(base.food.forageWinterReturn));
    expect(
        hard.food.forageWinterReturn, lessThan(base.food.forageWinterReturn));
    // Easy tilts treatment luck up, hard tilts it down.
    expect(easy.medical.treatBase, greaterThan(base.medical.treatBase));
    expect(hard.medical.treatBase, lessThan(base.medical.treatBase));
    // A medic is always a sure thing, whatever the difficulty.
    expect(easy.medical.treatWithMedic, 1.0);
    expect(hard.medical.treatWithMedic, 1.0);
  });

  test('hard mode refuses unlocked colonists but keeps the three engineers',
      () {
    final profile = PersistentProfile()..unlock('c001');
    // A base engineer is always selectable.
    expect(UnlockSystem.canSelect('rusher', Difficulty.hard, profile), isTrue);
    // An unlocked colonist is fine on normal, refused on hard.
    expect(UnlockSystem.canSelect('c001', Difficulty.normal, profile), isTrue);
    expect(UnlockSystem.canSelect('c001', Difficulty.hard, profile), isFalse);
  });
}
