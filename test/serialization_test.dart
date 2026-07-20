import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';

// Saves must round-trip exactly, and a run must be perfectly replayable from its
// seed. Losing forty runs of unlocks to a reinstall is unacceptable, and balance
// testing needs a run to replay to the same place every time.

void main() {
  GameEngine started(int seed, {int days = 0}) {
    final e = GameEngine.newRun(seed: seed);
    e.chooseCharacter('athena');
    e.chooseSite(SiteId.basin);
    for (var i = 0; i < days && e.phase != Phase.ending; i++) {
      e.endDay();
    }
    return e;
  }

  test('a run save round-trips to an identical fingerprint', () {
    final e = started(5, days: 12);
    final text = SaveCodec.encodeRun(e.state);
    final restored = SaveCodec.decodeRun(text);
    expect(SaveCodec.fingerprint(restored), SaveCodec.fingerprint(e.state));
  });

  test('the profile round-trips - the one file the settings menu exports', () {
    final p = PersistentProfile()
      ..unlock('c001')
      ..unlock('c042')
      ..recordEnding('rescue')
      ..runsPlayed = 7
      ..bestEndless = 88;
    final restored = SaveCodec.decodeProfile(SaveCodec.encodeProfile(p));
    expect(restored.unlockedCharacterIds, p.unlockedCharacterIds);
    expect(restored.runsPlayed, 7);
    expect(restored.endingsSeen['rescue'], 1);
    expect(restored.bestEndless, 88);
  });

  test('the same seed and decisions replay to the same state', () {
    int fingerprintAfter(int days) {
      final e = started(4242, days: days);
      return SaveCodec.fingerprint(e.state);
    }

    expect(fingerprintAfter(25), fingerprintAfter(25));
  });

  test('resuming from a mid-run save continues exactly', () {
    // Play A ten days, snapshot, then play A ten more.
    final a = started(7, days: 10);
    final snapshot = SaveCodec.encodeRun(a.state);
    for (var i = 0; i < 10 && a.phase != Phase.ending; i++) {
      a.endDay();
    }

    // Resume B from the snapshot and play the same ten days.
    final b = GameEngine.fromSave(SaveCodec.decodeRun(snapshot));
    for (var i = 0; i < 10 && b.phase != Phase.ending; i++) {
      b.endDay();
    }

    expect(SaveCodec.fingerprint(b.state), SaveCodec.fingerprint(a.state));
  });
}
