import '../config/game_config.dart';
import '../models/enums.dart';
import '../models/crew.dart';
import '../models/world.dart';
import '../models/run.dart';
import '../engine/rng.dart';
import '../engine/result.dart';

// The wreck and its clock. One frozen colonist dies every day, from day one, and
// nothing in the game slows it. Two crew carry one pod, so fetching costs the very
// thing you are fetching. Waking is one-way.

class WreckSystem {
  /// Order the roster into the wreck's manifest for this run. Shuffled with the
  /// run RNG so the death order and who is reachable vary per seed, but exactly.
  static List<ManifestEntry> buildManifest(List<Crew> roster, SeededRng rng) {
    final entries = roster
        .map((c) => ManifestEntry(
              crewId: c.id,
              name: c.name,
              roles: c.roles,
              rarity: c.rarity,
              traits: c.traits,
            ))
        .toList();
    // Fisher-Yates with the seeded RNG - deterministic for a given seed.
    for (var i = entries.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = entries[i];
      entries[i] = entries[j];
      entries[j] = tmp;
    }
    return entries;
  }

  /// The daily wreck death. UNCONDITIONAL - exactly wreckDeathsPerDay, every day,
  /// drawn by name from the manifest and written to the memorial. The only thing
  /// that can switch it off is the documented endless-mode flag, checked here and
  /// nowhere else.
  static List<DeathRecord> killDaily(RunSave s, GameConfig c, int day) {
    final deaths = <DeathRecord>[];
    // Endless mode (outside hard) turns the clock off so the run stays about heat
    // and food, not running out of people.
    final clockOff =
        s.run.mode == GameMode.endless && s.run.difficulty != Difficulty.hard;
    if (clockOff) return deaths;

    final wreck = s.pods.wreck;
    for (var n = 0; n < c.pods.wreckDeathsPerDay; n++) {
      if (wreck.count <= 0 || wreck.nextDeathIndex >= wreck.manifest.length) {
        break;
      }
      final entry = wreck.manifest[wreck.nextDeathIndex];
      wreck.nextDeathIndex += 1;
      wreck.count -= 1;
      s.memorial.add(
          MemorialEntry(name: entry.name, cause: Cause.wreckClock, day: day));
      deaths.add(DeathRecord(entry.name, Cause.wreckClock, fromWreck: true));
    }
    return deaths;
  }

  /// Read the manifest. Free, always - actions are for verbs, not for finding out.
  static List<ManifestEntry> readManifest(RunSave s) {
    s.pods.wreck.manifestRead = true;
    // Only the colonists the clock has not yet reached are still out there.
    return s.pods.wreck.manifest.sublist(s.pods.wreck.nextDeathIndex);
  }

  /// Current powered bay capacity - generous in summer, cut back in winter.
  static int bayCapacity(RunSave s, GameConfig c) => s.run.phase == Phase.winter
      ? c.pods.bayCapacityWinter
      : c.pods.bayCapacitySummer;

  static int occupiedSlots(RunSave s) =>
      s.pods.bay.where((slot) => slot.occupied).length;

  /// Fetch a pod from the wreck into a camp slot. Optionally name who to fetch;
  /// otherwise the frontmost reachable colonist is carried home. Winter carries
  /// risk injury to whoever went out.
  static ActionResult fetch(RunSave s, GameConfig c, SeededRng rng,
      {String? crewId}) {
    final wreck = s.pods.wreck;
    if (occupiedSlots(s) >= bayCapacity(s, c)) {
      return const ActionResult.fail('No powered slot free in the bay.');
    }
    final available = wreck.manifest.sublist(wreck.nextDeathIndex);
    if (available.isEmpty) {
      return const ActionResult.fail('No pods left to fetch.');
    }

    final entry = crewId == null
        ? available.first
        : available.firstWhere((e) => e.crewId == crewId,
            orElse: () => available.first);

    // Move them out of the wreck and into a slot. They are no longer on the clock.
    wreck.manifest.remove(entry);
    wreck.count -= 1;
    final slot = s.pods.bay.firstWhere((sl) => !sl.occupied);
    slot.occupied = true;
    slot.powered = true;
    slot.crewId = entry.crewId;
    s.crew.add(Crew(
      id: entry.crewId,
      name: entry.name,
      roles: entry.roles,
      rarity: entry.rarity,
      traits: entry.traits,
      awake: false,
      alive: true,
    ));

    // A winter fetch can hurt the carriers.
    if (s.run.phase == Phase.winter &&
        rng.chance(c.pods.fetchWinterInjuryChance)) {
      final carriers = s.ableCrew.toList();
      if (carriers.isNotEmpty) {
        carriers.first.conditions.add(Condition.injured);
      }
    }
    return ActionResult.success(
        'Carried ${entry.name} home. They wait in a pod.');
  }

  /// Wake a fetched colonist. Frees the slot, adds a permanent mouth, and cannot
  /// be undone - no re-freezing.
  static ActionResult wake(RunSave s, String crewId) {
    final slot = s.pods.bay.firstWhere(
      (sl) => sl.occupied && sl.crewId == crewId,
      orElse: () => PodSlot(occupied: false),
    );
    if (!slot.occupied) return const ActionResult.fail('No such pod at camp.');
    final person = s.crewById(crewId);
    if (person == null) return const ActionResult.fail('No such colonist.');
    slot.occupied = false;
    slot.crewId = null;
    person.awake = true;
    person.able = true;
    return ActionResult.success(
        'Woke ${person.name}. Another pair of hands, another mouth.');
  }
}
