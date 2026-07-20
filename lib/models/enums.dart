// The fixed vocabulary of the game. Everything else is built from these.
// Enums serialize by their `name`, so ordering here is not load bearing but the
// spelling is - renaming a value would break old save files.

/// The phases a run moves through, in order.
enum Phase { characterSelect, siteSelect, summer, winter, ending }

/// The three difficulty settings. Difficulty is only ever a bag of multipliers
/// over the one config object (see config.dart) plus the one content rule that
/// hard refuses unlocked characters. It never branches game logic.
enum Difficulty { easy, normal, hard }

/// Play modes. Only `standard` ships in v1; the rest are reserved so save files
/// written now stay readable when the modes land.
enum GameMode { standard, endless, daily, ironman, custom }

/// A crew member's job. Roles gate specific actions - a repair needs an
/// engineer, a full-strength treatment needs a medic, and so on.
enum Role {
  engineer,
  medic,
  botanist,
  hunter,
  cook,
  scout,
  mechanic,
  quartermaster
}

/// Rare qualities that make an exceptional colonist worth a winter trip.
enum Trait { tireless, efficient, dualTrained }

/// How common a colonist is on any given manifest.
enum Rarity { common, uncommon, rare }

/// A crew member's health condition. `dead` is terminal.
enum Condition { healthy, sick, injured, frostbitten, quarantined, dead }

/// The kinds of threat that can queue up against the camp.
enum ThreatType {
  avalanche, // Ridge
  predator, // Basin
  starvation, // Cave and everywhere late winter
  storm,
  equipmentFailure,
  fuelLeak,
  cropBlight,
}

/// Why a name ended up on the memorial.
enum Cause { froze, starved, illness, injury, avalanche, predator, wreckClock }

/// The two ways a run can end at spring, plus the death screen.
enum Ending { rescue, colonyUnderstanding, colonyTruce, death }

/// The site a run is played on. Chosen once, permanent.
enum SiteId { ridge, basin, cave }
