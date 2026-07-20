import '../models/enums.dart';
import '../models/run.dart';
import '../models/profile.dart';

// Unlocks. A colonist is earned only if all three are true: carried home, alive at
// spring, and the run was beaten. Saving someone who then starves in week nine
// unlocks nobody. Hard mode reads the profile only to refuse it.

class UnlockSystem {
  /// Apply end-of-run unlocks to the profile. `beaten` means the run reached
  /// spring (not a death ending). Only carried colonists from the manifest unlock;
  /// the three starting engineers are always available anyway.
  static List<String> applyUnlocks(RunSave s, PersistentProfile profile,
      {required bool beaten}) {
    final newlyUnlocked = <String>[];
    if (beaten) {
      for (final c in s.crew) {
        // Roster colonists carry ids like c001; the presets do not.
        final isRosterColonist = c.id.startsWith('c') && c.id.length == 4;
        if (isRosterColonist &&
            c.awake &&
            c.alive &&
            !profile.isUnlocked(c.id)) {
          profile.unlock(c.id);
          newlyUnlocked.add(c.id);
        }
      }
    }
    return newlyUnlocked;
  }

  /// Whether an unlocked colonist may be picked at character select. Hard mode
  /// refuses everyone but the three base engineers - the one place difficulty
  /// touches content, and it is not a logic branch in the simulation.
  static bool canSelect(
      String crewId, Difficulty difficulty, PersistentProfile profile) {
    const presets = {'rusher', 'chasefield', 'athena'};
    if (presets.contains(crewId)) return true;
    if (difficulty == Difficulty.hard) return false;
    return profile.isUnlocked(crewId);
  }
}
