// A tiny determinism check you can watch. It plays a run partway, saves it to a
// string, reloads from that string, and confirms that continuing from the reload
// lands in exactly the same place as continuing the original. This is what lets a
// run be replayed for balance testing, and what makes resume safe.
//
// ignore_for_file: avoid_print

import 'package:veriisha/veriisha.dart';

void main() {
  const seed = 20260720;

  // Original: play ten days, snapshot, then play ten more.
  final original = _start(seed);
  for (var i = 0; i < 10 && original.phase != Phase.ending; i++) {
    original.endDay();
  }
  final snapshot = SaveCodec.encodeRun(original.state);
  for (var i = 0; i < 10 && original.phase != Phase.ending; i++) {
    original.endDay();
  }

  // Reloaded: resume from the snapshot and play the same ten days.
  final reloaded = GameEngine.fromSave(SaveCodec.decodeRun(snapshot));
  for (var i = 0; i < 10 && reloaded.phase != Phase.ending; i++) {
    reloaded.endDay();
  }

  final a = SaveCodec.fingerprint(original.state);
  final b = SaveCodec.fingerprint(reloaded.state);
  print('original fingerprint: $a');
  print('reloaded fingerprint: $b');
  print(a == b
      ? 'OK - the run replays exactly from the save.'
      : 'MISMATCH - determinism broke.');
}

GameEngine _start(int seed) {
  final e = GameEngine.newRun(seed: seed);
  e.chooseCharacter('rusher');
  e.chooseSite(SiteId.cave);
  return e;
}
