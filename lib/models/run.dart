import 'enums.dart';
import 'crew.dart';
import 'world.dart';

// The run save: one object holding everything a game in progress is. It is the
// single serialisation root - autosave writes this, resume reads it back.

/// The loan's live state. Borrow effort for a few days, then pay it back.
class LoanState {
  bool active;
  int daysRemaining; // days left in the current phase
  bool inDebt; // true once the up-phase ends and repayment begins
  int debtRemaining; // repayment days still owed

  LoanState({
    this.active = false,
    this.daysRemaining = 0,
    this.inDebt = false,
    this.debtRemaining = 0,
  });

  /// The loan cannot be re-taken while it is running or still owed.
  bool get busy => active || inDebt || debtRemaining > 0;

  Map<String, dynamic> toJson() => {
        'active': active,
        'daysRemaining': daysRemaining,
        'inDebt': inDebt,
        'debtRemaining': debtRemaining,
      };

  factory LoanState.fromJson(Map<String, dynamic> j) => LoanState(
        active: j['active'] as bool,
        daysRemaining: j['daysRemaining'] as int,
        inDebt: j['inDebt'] as bool,
        debtRemaining: j['debtRemaining'] as int,
      );
}

/// The day's action budget: how many verbs you get, and how many you have spent.
class ActionsToday {
  int total;
  int spent;
  LoanState loan;

  ActionsToday({this.total = 0, this.spent = 0, LoanState? loan})
      : loan = loan ?? LoanState();

  int get remaining => total - spent;

  Map<String, dynamic> toJson() =>
      {'total': total, 'spent': spent, 'loan': loan.toJson()};
  factory ActionsToday.fromJson(Map<String, dynamic> j) => ActionsToday(
        total: j['total'] as int,
        spent: j['spent'] as int,
        loan: LoanState.fromJson(j['loan'] as Map<String, dynamic>),
      );
}

/// The record of how you have treated the creatures. It decides which colony
/// epilogue you get - fed early is an understanding, fed desperate is a truce.
class CreatureRelations {
  int timesFed;
  int fedEarly; // fed while they still had strength
  int fedDesperate; // fed only when they were at the wall
  int peaceDaysRemaining; // days of quiet a recent feeding has bought

  CreatureRelations({
    this.timesFed = 0,
    this.fedEarly = 0,
    this.fedDesperate = 0,
    this.peaceDaysRemaining = 0,
  });

  Map<String, dynamic> toJson() => {
        'timesFed': timesFed,
        'fedEarly': fedEarly,
        'fedDesperate': fedDesperate,
        'peaceDaysRemaining': peaceDaysRemaining,
      };

  factory CreatureRelations.fromJson(Map<String, dynamic> j) =>
      CreatureRelations(
        timesFed: j['timesFed'] as int,
        fedEarly: j['fedEarly'] as int,
        fedDesperate: j['fedDesperate'] as int,
        peaceDaysRemaining: j['peaceDaysRemaining'] as int,
      );
}

/// One notable thing that happened, for the run summary.
class LogEntry {
  final int day;
  final String type;
  final String text;
  const LogEntry({required this.day, required this.type, required this.text});

  Map<String, dynamic> toJson() => {'day': day, 'type': type, 'text': text};
  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
      day: j['day'] as int,
      type: j['type'] as String,
      text: j['text'] as String);
}

/// One name lost, and how. Wreck-clock deaths are written here too.
class MemorialEntry {
  final String name;
  final Cause cause;
  final int day;
  const MemorialEntry(
      {required this.name, required this.cause, required this.day});

  Map<String, dynamic> toJson() =>
      {'name': name, 'cause': cause.name, 'day': day};
  factory MemorialEntry.fromJson(Map<String, dynamic> j) => MemorialEntry(
        name: j['name'] as String,
        cause: Cause.values.byName(j['cause'] as String),
        day: j['day'] as int,
      );
}

/// Who you are currently playing, and whether your one succession is spent.
class Control {
  String? controlledCrewId;
  bool successionUsed;
  Control({this.controlledCrewId, this.successionUsed = false});

  Map<String, dynamic> toJson() =>
      {'controlledCrewId': controlledCrewId, 'successionUsed': successionUsed};
  factory Control.fromJson(Map<String, dynamic> j) => Control(
        controlledCrewId: j['controlledCrewId'] as String?,
        successionUsed: j['successionUsed'] as bool,
      );
}

/// The run's top-level bookkeeping, including the live RNG cursor.
class RunMeta {
  final int seed;
  Phase phase;
  int day;
  int winterLength; // rolled once at run start
  bool winterLengthKnown; // true only if the observatory was built
  SiteId siteId;
  Difficulty difficulty;
  GameMode mode;
  int rngState; // the serialised RNG cursor - what makes a run replayable

  RunMeta({
    required this.seed,
    this.phase = Phase.characterSelect,
    this.day = 1,
    this.winterLength = 0,
    this.winterLengthKnown = false,
    this.siteId = SiteId.ridge,
    this.difficulty = Difficulty.normal,
    this.mode = GameMode.standard,
    int? rngState,
  }) : rngState = rngState ?? seed;

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'phase': phase.name,
        'day': day,
        'winterLength': winterLength,
        'winterLengthKnown': winterLengthKnown,
        'siteId': siteId.name,
        'difficulty': difficulty.name,
        'mode': mode.name,
        'rngState': rngState,
      };

  factory RunMeta.fromJson(Map<String, dynamic> j) => RunMeta(
        seed: j['seed'] as int,
        phase: Phase.values.byName(j['phase'] as String),
        day: j['day'] as int,
        winterLength: j['winterLength'] as int,
        winterLengthKnown: j['winterLengthKnown'] as bool,
        siteId: SiteId.values.byName(j['siteId'] as String),
        difficulty: Difficulty.values.byName(j['difficulty'] as String),
        mode: GameMode.values.byName(j['mode'] as String),
        rngState: j['rngState'] as int,
      );
}

/// The whole game in progress.
class RunSave {
  static const int schemaVersion = 1;

  RunMeta run;
  Control control;
  List<Crew> crew;
  Pods pods;
  Resources resources;
  List<Building> buildings;
  List<Research> research;
  List<Threat> threats;
  ActionsToday actionsToday;
  CreatureRelations creatureRelations;
  List<LogEntry> log;
  List<MemorialEntry> memorial;

  RunSave({
    required this.run,
    Control? control,
    List<Crew>? crew,
    Pods? pods,
    Resources? resources,
    List<Building>? buildings,
    List<Research>? research,
    List<Threat>? threats,
    ActionsToday? actionsToday,
    CreatureRelations? creatureRelations,
    List<LogEntry>? log,
    List<MemorialEntry>? memorial,
  })  : control = control ?? Control(),
        crew = crew ?? [],
        pods = pods ?? Pods(),
        resources = resources ?? Resources(),
        buildings = buildings ?? [],
        research = research ?? [],
        threats = threats ?? [],
        actionsToday = actionsToday ?? ActionsToday(),
        creatureRelations = creatureRelations ?? CreatureRelations(),
        log = log ?? [],
        memorial = memorial ?? [];

  /// Everyone who is awake, alive and able right now - the pool people are drawn
  /// from for the action count.
  Iterable<Crew> get ableCrew =>
      crew.where((c) => c.awake && c.alive && c.able);

  /// Everyone awake and alive, able or not.
  Iterable<Crew> get livingAwake => crew.where((c) => c.awake && c.alive);

  Crew? crewById(String id) {
    for (final c in crew) {
      if (c.id == id) return c;
    }
    return null;
  }

  Building? buildingById(String id) {
    for (final b in buildings) {
      if (b.id == id) return b;
    }
    return null;
  }

  Research? researchById(String id) {
    for (final r in research) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool isBuilt(String id) => buildingById(id)?.built ?? false;
  bool isResearched(String id) => researchById(id)?.complete ?? false;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'run': run.toJson(),
        'control': control.toJson(),
        'crew': crew.map((c) => c.toJson()).toList(),
        'pods': pods.toJson(),
        'resources': resources.toJson(),
        'buildings': buildings.map((b) => b.toJson()).toList(),
        'research': research.map((r) => r.toJson()).toList(),
        'threats': threats.map((t) => t.toJson()).toList(),
        'actionsToday': actionsToday.toJson(),
        'creatureRelations': creatureRelations.toJson(),
        'log': log.map((l) => l.toJson()).toList(),
        'memorial': memorial.map((m) => m.toJson()).toList(),
      };

  factory RunSave.fromJson(Map<String, dynamic> j) => RunSave(
        run: RunMeta.fromJson(j['run'] as Map<String, dynamic>),
        control: Control.fromJson(j['control'] as Map<String, dynamic>),
        crew: (j['crew'] as List)
            .map((c) => Crew.fromJson(c as Map<String, dynamic>))
            .toList(),
        pods: Pods.fromJson(j['pods'] as Map<String, dynamic>),
        resources: Resources.fromJson(j['resources'] as Map<String, dynamic>),
        buildings: (j['buildings'] as List)
            .map((b) => Building.fromJson(b as Map<String, dynamic>))
            .toList(),
        research: (j['research'] as List)
            .map((r) => Research.fromJson(r as Map<String, dynamic>))
            .toList(),
        threats: (j['threats'] as List)
            .map((t) => Threat.fromJson(t as Map<String, dynamic>))
            .toList(),
        actionsToday:
            ActionsToday.fromJson(j['actionsToday'] as Map<String, dynamic>),
        creatureRelations: CreatureRelations.fromJson(
            j['creatureRelations'] as Map<String, dynamic>),
        log: (j['log'] as List)
            .map((l) => LogEntry.fromJson(l as Map<String, dynamic>))
            .toList(),
        memorial: (j['memorial'] as List)
            .map((m) => MemorialEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
