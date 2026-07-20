import 'enums.dart';

// The world outside the people: what you have, what you have built, what is
// coming for you.

/// Clean water is safe; dirty water carries alien microbes until it is filtered.
class Water {
  double clean;
  double dirty;
  Water({this.clean = 0, this.dirty = 0});

  Map<String, dynamic> toJson() => {'clean': clean, 'dirty': dirty};
  factory Water.fromJson(Map<String, dynamic> j) => Water(
      clean: (j['clean'] as num).toDouble(),
      dirty: (j['dirty'] as num).toDouble());
}

/// Reactor output and the fuel that drives it. Power is heat, so this is also
/// survival.
class Power {
  int output; // available this day
  double fuel; // fuel-days remaining
  Power({this.output = 0, this.fuel = 0});

  Map<String, dynamic> toJson() => {'output': output, 'fuel': fuel};
  factory Power.fromJson(Map<String, dynamic> j) =>
      Power(output: j['output'] as int, fuel: (j['fuel'] as num).toDouble());
}

/// Everything the larder and stores hold.
class Resources {
  double food;
  Water water;
  Power power;
  int medSupplies;
  int scrap;
  double biomass;

  Resources({
    this.food = 0,
    Water? water,
    Power? power,
    this.medSupplies = 0,
    this.scrap = 0,
    this.biomass = 0,
  })  : water = water ?? Water(),
        power = power ?? Power();

  Map<String, dynamic> toJson() => {
        'food': food,
        'water': water.toJson(),
        'power': power.toJson(),
        'medSupplies': medSupplies,
        'scrap': scrap,
        'biomass': biomass,
      };

  factory Resources.fromJson(Map<String, dynamic> j) => Resources(
        food: (j['food'] as num).toDouble(),
        water: Water.fromJson(j['water'] as Map<String, dynamic>),
        power: Power.fromJson(j['power'] as Map<String, dynamic>),
        medSupplies: j['medSupplies'] as int,
        scrap: j['scrap'] as int,
        biomass: (j['biomass'] as num).toDouble(),
      );
}

/// One name in the wreck's frozen manifest.
class ManifestEntry {
  final String crewId;
  final String name;
  final List<Role> roles;
  final Rarity rarity;
  final List<Trait> traits;

  const ManifestEntry({
    required this.crewId,
    required this.name,
    required this.roles,
    required this.rarity,
    required this.traits,
  });

  Map<String, dynamic> toJson() => {
        'crewId': crewId,
        'name': name,
        'roles': roles.map((r) => r.name).toList(),
        'rarity': rarity.name,
        'traits': traits.map((t) => t.name).toList(),
      };

  factory ManifestEntry.fromJson(Map<String, dynamic> j) => ManifestEntry(
        crewId: j['crewId'] as String,
        name: j['name'] as String,
        roles: (j['roles'] as List)
            .map((r) => Role.values.byName(r as String))
            .toList(),
        rarity: Rarity.values.byName(j['rarity'] as String),
        traits: (j['traits'] as List)
            .map((t) => Trait.values.byName(t as String))
            .toList(),
      );
}

/// The wrecked ship. Its manifest is read for free; its people die one a day.
class Wreck {
  int count; // pods still frozen and intact
  List<ManifestEntry> manifest; // the named order the clock works through
  bool manifestRead; // reading reveals names, roles and rarity - free to do
  int nextDeathIndex; // which name the clock takes next

  Wreck({
    this.count = 0,
    List<ManifestEntry>? manifest,
    this.manifestRead = false,
    this.nextDeathIndex = 0,
  }) : manifest = manifest ?? [];

  Map<String, dynamic> toJson() => {
        'count': count,
        'manifest': manifest.map((m) => m.toJson()).toList(),
        'manifestRead': manifestRead,
        'nextDeathIndex': nextDeathIndex,
      };

  factory Wreck.fromJson(Map<String, dynamic> j) => Wreck(
        count: j['count'] as int,
        manifest: (j['manifest'] as List)
            .map((m) => ManifestEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
        manifestRead: j['manifestRead'] as bool,
        nextDeathIndex: j['nextDeathIndex'] as int,
      );
}

/// A powered slot at camp holding one carried-home pod until it is woken.
class PodSlot {
  bool occupied;
  bool powered;
  String? crewId; // who is in it, once fetched
  PodSlot({this.occupied = false, this.powered = true, this.crewId});

  Map<String, dynamic> toJson() =>
      {'occupied': occupied, 'powered': powered, 'crewId': crewId};
  factory PodSlot.fromJson(Map<String, dynamic> j) => PodSlot(
        occupied: j['occupied'] as bool,
        powered: j['powered'] as bool,
        crewId: j['crewId'] as String?,
      );
}

/// The camp bay plus the wreck it draws from.
class Pods {
  List<PodSlot> bay;
  Wreck wreck;
  Pods({List<PodSlot>? bay, Wreck? wreck})
      : bay = bay ?? [],
        wreck = wreck ?? Wreck();

  Map<String, dynamic> toJson() =>
      {'bay': bay.map((s) => s.toJson()).toList(), 'wreck': wreck.toJson()};
  factory Pods.fromJson(Map<String, dynamic> j) => Pods(
        bay: (j['bay'] as List)
            .map((s) => PodSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
        wreck: Wreck.fromJson(j['wreck'] as Map<String, dynamic>),
      );
}

/// Something built in summer whose effect persists into winter. The beacon is
/// just a building with a particular id. A build is progressive - each build
/// action adds one to `progress` until it reaches the building's action cost.
class Building {
  final String id;
  bool built;
  int level;
  int progress; // build actions put in so far, before it is finished

  Building(
      {required this.id,
      this.built = false,
      this.level = 0,
      this.progress = 0});

  Map<String, dynamic> toJson() =>
      {'id': id, 'built': built, 'level': level, 'progress': progress};
  factory Building.fromJson(Map<String, dynamic> j) => Building(
        id: j['id'] as String,
        built: j['built'] as bool,
        level: j['level'] as int,
        progress: j['progress'] as int? ?? 0,
      );
}

/// Research that runs over several days and needs a qualified body.
class Research {
  final String id;
  int progress; // days of work put in
  bool complete;
  Research({required this.id, this.progress = 0, this.complete = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'progress': progress, 'complete': complete};
  factory Research.fromJson(Map<String, dynamic> j) => Research(
        id: j['id'] as String,
        progress: j['progress'] as int,
        complete: j['complete'] as bool,
      );
}

/// A queued danger. It becomes visible one to two days before it lands - that
/// telegraph is a hard rule, not a courtesy.
class Threat {
  final ThreatType type;
  final String source; // which chain or cause raised it
  int daysUntil; // days before it lands; never created at less than 1
  bool visible; // has the in-world sign appeared yet
  double severity;

  Threat({
    required this.type,
    required this.source,
    required this.daysUntil,
    this.visible = false,
    this.severity = 0,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'source': source,
        'daysUntil': daysUntil,
        'visible': visible,
        'severity': severity,
      };

  factory Threat.fromJson(Map<String, dynamic> j) => Threat(
        type: ThreatType.values.byName(j['type'] as String),
        source: j['source'] as String,
        daysUntil: j['daysUntil'] as int,
        visible: j['visible'] as bool,
        severity: (j['severity'] as num).toDouble(),
      );
}
