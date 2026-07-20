// The persistent profile survives death and carries between runs. It is a
// separate serialisation root from the run save, and it is the single file the
// settings menu exports and imports. Losing forty runs of unlocks to a reinstall
// is unacceptable, so this stays small, plain, and easy to move.

class PersistentProfile {
  static const int schemaVersion = 1;

  final List<String> unlockedCharacterIds;
  int runsPlayed;
  Map<String, int> endingsSeen; // ending name -> how many times reached
  int bestEndless; // best endless-mode day count

  PersistentProfile({
    List<String>? unlockedCharacterIds,
    this.runsPlayed = 0,
    Map<String, int>? endingsSeen,
    this.bestEndless = 0,
  })  : unlockedCharacterIds = unlockedCharacterIds ?? [],
        endingsSeen = endingsSeen ?? {};

  bool isUnlocked(String crewId) => unlockedCharacterIds.contains(crewId);

  /// Record an unlock, ignoring duplicates so the list stays a set.
  void unlock(String crewId) {
    if (!unlockedCharacterIds.contains(crewId)) {
      unlockedCharacterIds.add(crewId);
    }
  }

  void recordEnding(String endingName) {
    endingsSeen[endingName] = (endingsSeen[endingName] ?? 0) + 1;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'unlockedCharacterIds': unlockedCharacterIds,
        'runsPlayed': runsPlayed,
        'endingsSeen': endingsSeen,
        'bestEndless': bestEndless,
      };

  factory PersistentProfile.fromJson(Map<String, dynamic> j) =>
      PersistentProfile(
        unlockedCharacterIds: (j['unlockedCharacterIds'] as List)
            .map((e) => e as String)
            .toList(),
        runsPlayed: j['runsPlayed'] as int? ?? 0,
        endingsSeen: (j['endingsSeen'] as Map?)
                ?.map((k, v) => MapEntry(k as String, v as int)) ??
            {},
        bestEndless: j['bestEndless'] as int? ?? 0,
      );
}
