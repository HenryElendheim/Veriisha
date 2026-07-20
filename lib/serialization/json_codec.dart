import 'dart:convert';
import '../models/run.dart';
import '../models/profile.dart';

// Turning game state into text and back. The engine stays pure - it hands you a
// string, and the shell (a UI, or the console harness) decides where that string
// lives. This is what backs autosave, resume, and the profile export/import the
// settings menu will offer.

class SaveCodec {
  /// A run in progress, as a JSON string. Field order is fixed by the models, so
  /// the same state always encodes to the same text - which the replay test needs.
  static String encodeRun(RunSave s) => jsonEncode(s.toJson());

  static RunSave decodeRun(String text) =>
      RunSave.fromJson(jsonDecode(text) as Map<String, dynamic>);

  /// The persistent profile, as a single JSON string. This is the one file the
  /// settings menu exports and imports.
  static String encodeProfile(PersistentProfile p) => jsonEncode(p.toJson());

  static PersistentProfile decodeProfile(String text) =>
      PersistentProfile.fromJson(jsonDecode(text) as Map<String, dynamic>);

  /// A stable fingerprint of a run's state. Used to prove that a reloaded run
  /// replays to exactly the same place. FNV-1a over the canonical JSON, so it is
  /// fully deterministic and does not depend on hash-set ordering.
  static int fingerprint(RunSave s) => _fnv1a(encodeRun(s));

  static int _fnv1a(String text) {
    const int prime = 0x100000001b3;
    const int mask = 0xFFFFFFFFFFFFFFFF;
    var hash = 0xcbf29ce484222325;
    for (final unit in text.codeUnits) {
      hash = (hash ^ unit) & mask;
      hash = (hash * prime) & mask;
    }
    return hash;
  }
}
