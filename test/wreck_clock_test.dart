import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';
import 'package:veriisha/systems/wreck_system.dart';

// The spine of the game: one frozen colonist dies every day, from day one, by
// name, and nothing slows it.

void main() {
  const c = GameConfig.normal();

  RunSave freshWreck() {
    final roster = buildRoster();
    final rng = SeededRng(7);
    final manifest = WreckSystem.buildManifest(roster, rng);
    return RunSave(
      run: RunMeta(seed: 7, phase: Phase.winter, day: 1, winterLength: 130),
      pods: Pods(wreck: Wreck(count: c.pods.wreckStart, manifest: manifest)),
    );
  }

  test('exactly one wreck death per day, by a distinct name', () {
    final s = freshWreck();
    final names = <String>{};
    for (var day = 1; day <= 137; day++) {
      final deaths = WreckSystem.killDaily(s, c, day);
      expect(deaths.length, 1, reason: 'exactly one death on day $day');
      expect(deaths.first.fromWreck, isTrue);
      expect(names.add(deaths.first.name), isTrue,
          reason: 'names never repeat');
    }
    // 137 gone from 220 leaves 83, and every death is on the memorial by name.
    expect(s.pods.wreck.count, c.pods.wreckStart - 137);
    expect(s.memorial.where((m) => m.cause == Cause.wreckClock).length, 137);
  });

  test('the clock cannot be slowed - the count tracks the days exactly', () {
    final s = freshWreck();
    for (var day = 1; day <= 100; day++) {
      WreckSystem.killDaily(s, c, day);
      expect(s.pods.wreck.count, c.pods.wreckStart - day);
    }
  });

  test('endless mode outside hard switches the clock off', () {
    final s = freshWreck();
    s.run.mode = GameMode.endless;
    s.run.difficulty = Difficulty.normal;
    final deaths = WreckSystem.killDaily(s, c, 1);
    expect(deaths, isEmpty);
    expect(s.pods.wreck.count, c.pods.wreckStart);
  });

  test('over a full run the memorial genuinely needs a deep manifest', () {
    // Seven summer days plus a 100+ day winter is well over a hundred names.
    final s = freshWreck();
    for (var day = 1; day <= 107; day++) {
      WreckSystem.killDaily(s, c, day);
    }
    expect(s.memorial.length, greaterThan(100));
  });
}
