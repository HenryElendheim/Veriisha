import 'package:flutter/foundation.dart';
import 'package:veriisha/veriisha.dart';

// The bridge between the engine and the interface. It owns the live run, forwards
// player decisions to the engine, and notifies listeners so the screens redraw.
// The engine stays pure - all the Flutter-facing glue lives here.

class GameController extends ChangeNotifier {
  GameEngine? _engine;

  bool get hasRun => _engine != null;
  GameEngine get engine => _engine!;
  RunSave get state => engine.state;

  /// Start a run from the three chosen decisions. The seed defaults to the clock,
  /// but can be fixed for a reproducible run.
  void newRun({
    required String characterId,
    required Difficulty difficulty,
    required SiteId site,
    int? seed,
  }) {
    final e = GameEngine.newRun(
      seed: seed ?? DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      difficulty: difficulty,
    );
    e.chooseCharacter(characterId);
    e.chooseSite(site);
    _engine = e;
    notifyListeners();
  }

  /// Spend an action, then redraw. Returns the engine's result so a screen can
  /// surface a message.
  ActionResult act(ActionResult Function(GameEngine e) action) {
    final r = action(engine);
    if (r.ok) notifyListeners();
    return r;
  }

  /// End the day and redraw with the digest.
  DayDigest endDay() {
    final digest = engine.endDay();
    notifyListeners();
    return digest;
  }

  /// Take back the last action, then redraw.
  void undo() {
    engine.undo();
    notifyListeners();
  }

  void clear() {
    _engine = null;
    notifyListeners();
  }
}
