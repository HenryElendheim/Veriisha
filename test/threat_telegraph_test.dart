import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';
import 'package:veriisha/systems/threat_system.dart';
import 'package:veriisha/systems/creature_system.dart';

// The telegraph guarantee: every threat is visible at least a full day before it
// lands. Being killed by something you had no chance to see is a bug, not
// difficulty - so this drives the queue directly and proves no threat ever lands
// unseen.

void main() {
  const c = GameConfig.normal();

  RunSave winterCamp(SiteId site) {
    final crew = List.generate(
      4,
      (i) => Crew(
        id: 'c$i',
        name: 'C$i',
        roles: const [Role.engineer],
        awake: true,
        alive: true,
        able: true,
      ),
    );
    return RunSave(
      run: RunMeta(
          seed: 99,
          phase: Phase.winter,
          day: 1,
          winterLength: 130,
          siteId: site),
      crew: crew,
      resources: Resources(food: 500, power: Power(output: 100, fuel: 100)),
    );
  }

  test('no threat ever lands without having been telegraphed first', () {
    // Run every site, so the avalanche, predator and generic chains all fire.
    for (final site in SiteId.values) {
      final s = winterCamp(site);
      final rng = SeededRng(2026);
      for (var day = 1; day <= 130; day++) {
        s.run.day = day;
        // This mirrors the day-end order in the resolver.
        ThreatSystem.advance(s);
        // Anything at or past its day is about to land - it MUST already be visible.
        for (final t in s.threats.where((t) => t.daysUntil <= 0)) {
          expect(t.visible, isTrue,
              reason: 'a ${t.type.name} on the ${site.name} landed unseen');
        }
        ThreatSystem.land(s, c, day, <DeathRecord>[]);
        ThreatSystem.spawnEvents(s, c, rng);
        CreatureSystem.dailyPressure(s, c, rng);
        ThreatSystem.updateTelegraphs(s, c);
      }
    }
  });

  test('a freshly raised threat is never allowed to land the same day', () {
    final s = winterCamp(SiteId.basin);
    final rng = SeededRng(5);
    // Raise a batch of threats and confirm none is due in less than the minimum
    // warning.
    for (var i = 0; i < 50; i++) {
      ThreatSystem.spawnEvents(s, c, rng);
    }
    for (final t in s.threats) {
      expect(t.daysUntil, greaterThanOrEqualTo(c.threat.warningMinDays));
    }
  });
}
