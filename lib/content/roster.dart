import '../models/enums.dart';
import '../models/crew.dart';
import '../engine/rng.dart';

// The 220 named colonists, plus the three playable presets. This is generated
// deterministically from fixed syllable pools and a fixed internal seed, so the
// roster is identical on every machine and every run - which matters, because a
// profile stores unlocked colonists by id and those ids must never drift.
//
// The names keep a short, soft register on purpose: Ru, Bee, Ish, Ti, Ven, Oda.

// Two syllable pools. Names are an onset, sometimes with a coda, built by index.
const List<String> _onsets = [
  'Ru',
  'Bee',
  'Ish',
  'Ti',
  'Ven',
  'Oda',
  'Sel',
  'Tov',
  'Mai',
  'Ka',
  'Nel',
  'Ori',
  'Ash',
  'Wyn',
  'Lio',
  'Sen',
  'Fen',
  'Dov',
  'Isa',
  'Rue',
  'Cael',
  'Bry',
  'Nia',
  'Sol',
  'Tam',
  'Eli',
  'Rho',
  'Vel',
  'Ona',
  'Sib',
  'Loe',
  'Hale',
  'Ivo',
  'Mira',
  'Oona',
];

const List<String> _codas = [
  '',
  '',
  '',
  'n',
  'sh',
  'a',
  'en',
  'ry',
  'is',
  'ov',
  'la',
  'el',
  'wyn',
  'to',
  'na',
  'ket',
  'ser',
];

// A handful of full surnames for texture, in the same soft register.
const List<String> _fullNames = [
  'Fletcher',
  'Rusk',
  'Cove',
  'Marlow',
  'Ash',
  'Wren',
  'Vale',
  'Orr',
  'Sable',
  'Fenn',
  'Locke',
  'Brey',
  'Noor',
  'Sana',
  'Teel',
];

const List<Role> _roles = [
  Role.engineer,
  Role.medic,
  Role.botanist,
  Role.hunter,
  Role.cook,
  Role.scout,
  Role.mechanic,
  Role.quartermaster,
];

/// Build the full manifest of 220 colonists. Deterministic: no run RNG here.
List<Crew> buildRoster() {
  final names = _generateNames(220);
  // A fixed seed so rarity, roles and traits fall the same way every time.
  final rng = SeededRng(0x5657524941); // "VRIA" in hex-ish, just a constant
  final roster = <Crew>[];

  for (var i = 0; i < 220; i++) {
    final id = 'c${(i + 1).toString().padLeft(3, '0')}';
    final rarity = _rollRarity(rng);
    final traits = _rollTraits(rng, rarity);
    final roles = _rollRoles(rng, traits);
    roster.add(Crew(
      id: id,
      name: names[i],
      roles: roles,
      rarity: rarity,
      traits: traits,
      awake: false,
      alive: true,
    ));
  }
  return roster;
}

// Rarity distribution: most ordinary, a few exceptional. Roughly 78 / 18 / 4.
Rarity _rollRarity(SeededRng rng) {
  final r = rng.nextDouble();
  if (r < 0.78) return Rarity.common;
  if (r < 0.96) return Rarity.uncommon;
  return Rarity.rare;
}

// Common colonists have no traits, uncommon have one, the rarest may have two.
List<Trait> _rollTraits(SeededRng rng, Rarity rarity) {
  final pool = [Trait.tireless, Trait.efficient, Trait.dualTrained];
  switch (rarity) {
    case Rarity.common:
      return const [];
    case Rarity.uncommon:
      return [pool[rng.nextInt(pool.length)]];
    case Rarity.rare:
      // Pick one, then maybe a distinct second.
      final first = pool[rng.nextInt(pool.length)];
      final traits = [first];
      if (rng.chance(0.5)) {
        final rest = pool.where((t) => t != first).toList();
        traits.add(rest[rng.nextInt(rest.length)]);
      }
      return traits;
  }
}

// Roles: one for most, two if dual-trained.
List<Role> _rollRoles(SeededRng rng, List<Trait> traits) {
  final first = _roles[rng.nextInt(_roles.length)];
  if (traits.contains(Trait.dualTrained)) {
    final rest = _roles.where((r) => r != first).toList();
    return [first, rest[rng.nextInt(rest.length)]];
  }
  return [first];
}

// Deterministically build a list of unique names by walking the syllable pools.
List<String> _generateNames(int count) {
  final out = <String>[];
  final seen = <String>{};

  // A few full names first, for texture.
  for (final n in _fullNames) {
    if (out.length >= count) break;
    if (seen.add(n)) out.add(n);
  }

  // Then onset + coda combinations, in a fixed order.
  for (final coda in _codas) {
    for (final onset in _onsets) {
      if (out.length >= count) break;
      final name = onset + coda;
      if (seen.add(name)) out.add(name);
    }
    if (out.length >= count) break;
  }

  // If the pools ran dry, extend with a numbered suffix - still deterministic.
  var suffix = 2;
  while (out.length < count) {
    for (final onset in _onsets) {
      if (out.length >= count) break;
      final name = '$onset$suffix';
      if (seen.add(name)) out.add(name);
    }
    suffix++;
  }
  return out;
}

/// A playable preset - who you can wake up as.
class Preset {
  final String id;
  final String name;
  const Preset(this.id, this.name);
}

// The three starting engineers. The choice is identity, not advantage: fixing the
// role means no starting pick can hollow out a system.
const List<Preset> kPresets = [
  Preset('rusher', 'Rusher'),
  Preset('chasefield', 'Chasefield'),
  Preset('athena', 'Athena'),
];

/// Build the crew member for a chosen preset. Always an engineer, common rarity,
/// no traits.
Crew buildPreset(String presetId) {
  final preset = kPresets.firstWhere((p) => p.id == presetId);
  return Crew(
    id: preset.id,
    name: preset.name,
    roles: const [Role.engineer],
    rarity: Rarity.common,
    traits: const [],
    awake: true,
    alive: true,
    able: true,
  );
}
