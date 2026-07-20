import '../config/game_config.dart';
import '../config/difficulty.dart';
import '../content/roster.dart';
import '../content/sites.dart';
import '../models/enums.dart';
import '../models/crew.dart';
import '../models/world.dart';
import '../models/run.dart';
import '../models/profile.dart';
import '../systems/building_system.dart';
import '../systems/condition_system.dart';
import '../systems/research_system.dart';
import '../systems/medical_system.dart';
import '../systems/food_water_system.dart';
import '../systems/wreck_system.dart';
import '../systems/creature_system.dart';
import '../systems/power_system.dart';
import '../systems/ending_system.dart';
import '../systems/unlock_system.dart';
import 'action_economy.dart';
import 'day_resolver.dart';
import 'rng.dart';
import 'result.dart';

// The facade the outside world (a UI, or the console harness) talks to. It owns
// the one RNG for the run, folds difficulty into the config once, drives the phase
// machine, applies actions, and runs the day-end resolver. Inspection is free:
// reading state off `state` never costs an action.

class GameEngine {
  RunSave state;
  final GameConfig config; // effective config, difficulty already folded in
  final PersistentProfile profile;
  SeededRng _rng;

  // Set once the run ends, so the ending screen reports what actually happened
  // rather than recomputing it (a death is not a colony).
  Ending? finalEnding;
  EndingOutcome? finalOutcome;

  GameEngine._(this.state, this.config, this.profile, this._rng);

  /// Start a new run. Difficulty is folded into the config here and nowhere else.
  factory GameEngine.newRun({
    required int seed,
    Difficulty difficulty = Difficulty.normal,
    GameMode mode = GameMode.standard,
    PersistentProfile? profile,
  }) {
    final rng = SeededRng(seed);
    final cfg = applyModifiers(
      const GameConfig.normal(),
      DifficultyModifiers.forDifficulty(difficulty),
    );
    final meta = RunMeta(
        seed: seed,
        difficulty: difficulty,
        mode: mode,
        phase: Phase.characterSelect);
    return GameEngine._(
        RunSave(run: meta), cfg, profile ?? PersistentProfile(), rng);
  }

  /// Resume a run from a saved state. The RNG is rebuilt from the saved cursor and
  /// the config is re-derived from the run's difficulty, so play continues exactly
  /// where it left off.
  factory GameEngine.fromSave(RunSave save, {PersistentProfile? profile}) {
    final cfg = applyModifiers(
      const GameConfig.normal(),
      DifficultyModifiers.forDifficulty(save.run.difficulty),
    );
    return GameEngine._(save, cfg, profile ?? PersistentProfile(),
        SeededRng.fromState(save.run.rngState));
  }

  SeededRng get rng => _rng;
  Phase get phase => state.run.phase;
  int get actionsLeft => state.actionsToday.remaining;

  // --- phase machine ---

  /// Choose who you wake up as. Always one of the three engineers, or an unlocked
  /// colonist (hard mode refuses the unlocked ones).
  ActionResult chooseCharacter(String characterId) {
    if (state.run.phase != Phase.characterSelect) {
      return const ActionResult.fail('Not at character select.');
    }
    if (!UnlockSystem.canSelect(characterId, state.run.difficulty, profile)) {
      return const ActionResult.fail('That colonist is not selectable here.');
    }
    final me = buildPreset(characterId);
    state.crew.add(me);
    state.control.controlledCrewId = me.id;
    state.run.phase = Phase.siteSelect;
    return ActionResult.success('You wake as ${me.name}, alone.');
  }

  /// Choose the site. Permanent. This rolls the hidden winter length (the first
  /// run-defining draw) and lays out the starting camp and the wreck.
  ActionResult chooseSite(SiteId site) {
    if (state.run.phase != Phase.siteSelect) {
      return const ActionResult.fail('Not at site select.');
    }
    state.run.siteId = site;

    // Winter length: rolled once, hidden until the observatory is built.
    state.run.winterLength =
        _rng.nextRange(config.time.winterLenMin, config.time.winterLenMax);
    state.run.winterLengthKnown = false;

    // The wreck: 220 names in a seed-shuffled order.
    final roster = buildRoster();
    final manifest = WreckSystem.buildManifest(roster, _rng);
    state.pods.wreck = Wreck(count: config.pods.wreckStart, manifest: manifest);

    // The camp bay, powered slots empty for now.
    state.pods.bay = List.generate(
        config.pods.bayCapacitySummer, (_) => PodSlot(occupied: false));

    // Starting stores - enough to begin, never enough to coast.
    state.resources = Resources(
      food: 80,
      water: Water(clean: 40, dirty: 0),
      power: Power(
          output: config.power.reactorOutput,
          fuel: config.power.fuelDays.toDouble()),
      medSupplies: 1,
      scrap: 60,
      biomass: 0,
    );

    state.run.phase = Phase.summer;
    state.run.day = 1;
    _beginDay();
    _log('site', 'Made camp at ${siteDef(site).name}.');
    return ActionResult.success(
        'You chose the ${siteDef(site).name}. Seven days of summer begin.');
  }

  // --- the morning ---

  void _beginDay() {
    ConditionSystem.recomputeAble(state);
    state.actionsToday
      ..total = ActionEconomy.computePool(state, config)
      ..spent = 0;
  }

  // --- actions (verbs cost, nouns are free) ---

  ActionResult _spend(int cost, ActionResult Function() body) {
    if (state.run.phase != Phase.summer && state.run.phase != Phase.winter) {
      return const ActionResult.fail('No actions to spend right now.');
    }
    if (state.actionsToday.remaining < cost) {
      return const ActionResult.fail('Not enough actions left today.');
    }
    final result = body();
    if (result.ok) state.actionsToday.spent += cost;
    return result;
  }

  ActionResult build(String buildingId) => _spend(1, () {
        final r = BuildingSystem.build(state, buildingId);
        if (r.ok &&
            buildingId == 'observatory' &&
            state.isBuilt('observatory')) {
          state.run.winterLengthKnown = true;
        }
        return r;
      });

  ActionResult research(String researchId) =>
      _spend(1, () => ResearchSystem.work(state, researchId));

  ActionResult forage() => _spend(1, () {
        final got = FoodWaterSystem.forage(state, config, _rng);
        return ActionResult.success(
            'Foraged. Brought back ${got.toStringAsFixed(0)} food.');
      });

  ActionResult scavenge() => _spend(1, () {
        state.resources.scrap += 12;
        return const ActionResult.success('Scavenged the wreck for scrap.');
      });

  ActionResult fetchPod({String? crewId}) {
    final cost = state.run.phase == Phase.winter
        ? config.pods.fetchActionsWinter
        : config.pods.fetchActionsSummer;
    return _spend(
        cost, () => WreckSystem.fetch(state, config, _rng, crewId: crewId));
  }

  ActionResult wake(String crewId) =>
      _spend(1, () => WreckSystem.wake(state, crewId));

  ActionResult treat(String crewId) => _spend(1, () {
        final person = state.crewById(crewId);
        if (person == null) return const ActionResult.fail('No such colonist.');
        return MedicalSystem.treat(state, config, _rng, person);
      });

  ActionResult quarantine(String crewId) => _spend(1, () {
        final person = state.crewById(crewId);
        if (person == null) return const ActionResult.fail('No such colonist.');
        return MedicalSystem.quarantine(state, person);
      });

  ActionResult synthesize() =>
      _spend(1, () => MedicalSystem.synthesize(state, config));

  ActionResult feedCreatures() => _spend(1, () {
        if (CreatureSystem.feed(state, config)) {
          return const ActionResult.success(
              'Fed the creatures. A few days of quiet, bought.');
        }
        return const ActionResult.fail('Not enough food to feed them.');
      });

  ActionResult burnBiomass() => _spend(1, () {
        if (PowerSystem.burnBiomass(state, config)) {
          return const ActionResult.success('Burned biomass into fuel.');
        }
        return const ActionResult.fail('No converter, or no biomass to burn.');
      });

  /// Take the loan. Not an action itself - it changes the economy. Gated behind
  /// biotic adaptation, and not re-takeable while running or owed.
  ActionResult takeLoan() {
    if (ActionEconomy.takeLoan(state, config)) {
      // Recompute today's pool so the borrowed action is available now.
      state.actionsToday.total = ActionEconomy.computePool(state, config);
      return const ActionResult.success(
          'Took the loan. A fourth action for three days.');
    }
    return const ActionResult.fail(
        'The loan is not available - needs biotic adaptation, and not while it is owed.');
  }

  /// Assign a standing order - free planning, so a long winter is not all clicks.
  ActionResult setStandingOrder(String crewId, StandingTask task, int days,
      {String? targetId}) {
    final person = state.crewById(crewId);
    if (person == null) return const ActionResult.fail('No such colonist.');
    person.standingOrder =
        StandingOrder(task: task, daysRemaining: days, targetId: targetId);
    return ActionResult.success(
        '${person.name} will ${task.name} for $days days.');
  }

  /// Read the manifest - free, always.
  List<ManifestEntry> readManifest() => WreckSystem.readManifest(state);

  // --- ending the day ---

  /// Resolve the day, handle succession and the ending, then open the next
  /// morning. Autosave is the last thing to happen, so the saved state matches
  /// exactly what the digest describes.
  DayDigest endDay() {
    final digest = DayResolver.resolveDayEnd(state, config, _rng);
    _handleSuccession(digest);

    if (state.run.phase == Phase.ending && !digest.runEnded) {
      _resolveSpringEnding(digest);
    } else if (digest.runEnded) {
      // A death ending: report the survivors (usually none) and who stayed frozen.
      final survivors = state.crew.where((c) => c.awake && c.alive).length;
      finalEnding = Ending.death;
      finalOutcome =
          EndingOutcome(Ending.death, survivors, state.pods.wreck.count);
      profile.runsPlayed += 1;
      profile.recordEnding(Ending.death.name);
    }

    // Keep the serialised RNG cursor in step, then this is a clean autosave point.
    state.run.rngState = _rng.state;

    if (state.run.phase == Phase.summer || state.run.phase == Phase.winter) {
      _beginDay();
    }
    return digest;
  }

  /// Skip forward while standing orders hold, stopping on anything worth a look:
  /// a telegraph, a death, a phase change, or the run ending.
  DayDigest advanceDays(int maxDays) {
    final span = DayDigest(fromDay: state.run.day, toDay: state.run.day);
    for (var i = 0; i < maxDays; i++) {
      final day = endDay();
      span.absorb(day);
      final stop = day.deaths.isNotEmpty ||
          day.newTelegraphs.isNotEmpty ||
          day.phaseChanged ||
          day.runEnded;
      if (stop) {
        span.stopReason ??= _stopReason(day);
        break;
      }
    }
    return span;
  }

  String _stopReason(DayDigest d) {
    if (d.runEnded) return 'the run ended';
    if (d.phaseChanged) return 'the season turned';
    if (d.deaths.isNotEmpty) return 'someone died';
    if (d.newTelegraphs.isNotEmpty) return 'a warning appeared';
    return 'stopped';
  }

  // If the character you control dies, you take over one other survivor. If that
  // successor later dies, the run is over even if others live.
  void _handleSuccession(DayDigest digest) {
    final controlled = state.crewById(state.control.controlledCrewId ?? '');
    final controlledDown =
        controlled == null || !controlled.alive || !controlled.awake;
    if (!controlledDown) return;

    if (!state.control.successionUsed) {
      final heir = state.livingAwake
          .where((c) => c.id != state.control.controlledCrewId)
          .cast<Crew?>()
          .firstWhere(
            (c) => c != null,
            orElse: () => null,
          );
      if (heir != null) {
        state.control
          ..controlledCrewId = heir.id
          ..successionUsed = true;
        digest.lines
            .add('You take over ${heir.name}. One life after your own.');
        return;
      }
    }
    // No heir, or the succession was already spent - the run is over.
    if (!digest.runEnded) {
      state.run.phase = Phase.ending;
      digest
        ..runEnded = true
        ..ending = Ending.death
        ..phaseChanged = true
        ..newPhase = Phase.ending;
    }
  }

  // Spring: work out which ending, write the count, apply unlocks.
  void _resolveSpringEnding(DayDigest digest) {
    final outcome = EndingSystem.resolve(state);
    digest
      ..runEnded = true
      ..ending = outcome.ending;
    finalEnding = outcome.ending;
    finalOutcome = outcome;
    final unlocked = UnlockSystem.applyUnlocks(state, profile, beaten: true);
    profile.runsPlayed += 1;
    profile.recordEnding(outcome.ending.name);
    digest.lines.add('Spring. ${outcome.woke} woken, ${outcome.saved} '
        '${outcome.ending == Ending.rescue ? 'saved' : 'left frozen'}.');
    if (unlocked.isNotEmpty) {
      digest.lines
          .add('Unlocked ${unlocked.length} colonist(s) for future runs.');
    }
  }

  void _log(String type, String text) =>
      state.log.add(LogEntry(day: state.run.day, type: type, text: text));

  /// The ending outcome, for the ending screen and the count line.
  EndingOutcome endingOutcome() => EndingSystem.resolve(state);
}
