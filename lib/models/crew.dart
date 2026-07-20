import 'enums.dart';

// The people. A crew member is the same kind of thing whether they are the one
// you play or the two hundredth name in the wreck: they eat, freeze, sicken and
// die by the same rules.

/// The kind of task a standing order carries out over several days.
enum StandingTask { tendCrop, holdWall, research, teach, standWatch, rest }

/// The four needs. All run 0..100, where 100 is fine and 0 is dying.
class Stats {
  int hunger;
  int thirst;
  int warmth;
  int health;

  Stats(
      {this.hunger = 100,
      this.thirst = 100,
      this.warmth = 100,
      this.health = 100});

  /// Keep every need inside 0..100 after any change.
  void clamp() {
    hunger = hunger.clamp(0, 100);
    thirst = thirst.clamp(0, 100);
    warmth = warmth.clamp(0, 100);
    health = health.clamp(0, 100);
  }

  Map<String, dynamic> toJson() =>
      {'hunger': hunger, 'thirst': thirst, 'warmth': warmth, 'health': health};

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        hunger: j['hunger'] as int,
        thirst: j['thirst'] as int,
        warmth: j['warmth'] as int,
        health: j['health'] as int,
      );
}

/// A multi-day instruction, so a hundred-day winter is not a hundred clicks.
class StandingOrder {
  StandingTask task;
  int daysRemaining;
  String? targetId; // e.g. which crop, which trainee

  StandingOrder(
      {required this.task, required this.daysRemaining, this.targetId});

  Map<String, dynamic> toJson() =>
      {'task': task.name, 'daysRemaining': daysRemaining, 'targetId': targetId};

  factory StandingOrder.fromJson(Map<String, dynamic> j) => StandingOrder(
        task: StandingTask.values.byName(j['task'] as String),
        daysRemaining: j['daysRemaining'] as int,
        targetId: j['targetId'] as String?,
      );
}

/// A single colonist.
class Crew {
  final String id;
  final String name;
  final List<Role> roles;
  final Rarity rarity;
  final List<Trait> traits;

  bool awake;
  bool alive;
  bool
      able; // derived each morning: awake, alive, and not sick/quarantined/injured-unable
  Stats stats;
  List<Condition> conditions;
  String? assignedTo; // which station or task this person is on
  StandingOrder? standingOrder;
  int daysAwake;

  Crew({
    required this.id,
    required this.name,
    required this.roles,
    this.rarity = Rarity.common,
    List<Trait>? traits,
    this.awake = false,
    this.alive = true,
    this.able = false,
    Stats? stats,
    List<Condition>? conditions,
    this.assignedTo,
    this.standingOrder,
    this.daysAwake = 0,
  })  : traits = traits ?? const [],
        stats = stats ?? Stats(),
        conditions = conditions ?? [Condition.healthy];

  bool get isDead => !alive || conditions.contains(Condition.dead);
  bool hasRole(Role r) => roles.contains(r);
  bool hasTrait(Trait t) => traits.contains(t);
  bool hasCondition(Condition c) => conditions.contains(c);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roles': roles.map((r) => r.name).toList(),
        'rarity': rarity.name,
        'traits': traits.map((t) => t.name).toList(),
        'awake': awake,
        'alive': alive,
        'able': able,
        'stats': stats.toJson(),
        'conditions': conditions.map((c) => c.name).toList(),
        'assignedTo': assignedTo,
        'standingOrder': standingOrder?.toJson(),
        'daysAwake': daysAwake,
      };

  factory Crew.fromJson(Map<String, dynamic> j) => Crew(
        id: j['id'] as String,
        name: j['name'] as String,
        roles: (j['roles'] as List)
            .map((r) => Role.values.byName(r as String))
            .toList(),
        rarity: Rarity.values.byName(j['rarity'] as String),
        traits: (j['traits'] as List)
            .map((t) => Trait.values.byName(t as String))
            .toList(),
        awake: j['awake'] as bool,
        alive: j['alive'] as bool,
        able: j['able'] as bool,
        stats: Stats.fromJson(j['stats'] as Map<String, dynamic>),
        conditions: (j['conditions'] as List)
            .map((c) => Condition.values.byName(c as String))
            .toList(),
        assignedTo: j['assignedTo'] as String?,
        standingOrder: j['standingOrder'] == null
            ? null
            : StandingOrder.fromJson(
                j['standingOrder'] as Map<String, dynamic>),
        daysAwake: j['daysAwake'] as int,
      );
}
