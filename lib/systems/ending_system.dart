import '../models/enums.dart';
import '../models/run.dart';

// The two endings, both reached by surviving to spring, neither the good one.
// Beacon built -> a ship lifts off every pod the clock has not reached. No beacon
// -> the colony stays with the few it carried. The count is the whole payload.

class EndingOutcome {
  final Ending ending;
  final int woke; // how many you carried home and woke
  final int saved; // beacon: lifted off. colony: stayed frozen.
  const EndingOutcome(this.ending, this.woke, this.saved);
}

class EndingSystem {
  /// Work out the ending at spring. `woke` counts the colonists you woke; `saved`
  /// is the beacon's rescue, or the number left frozen if there is no beacon.
  static EndingOutcome resolve(RunSave s) {
    final woke = s.crew.where((c) => c.awake && c.alive).length;
    final frozenLeft = s.pods.wreck.count;

    if (s.isBuilt('beacon')) {
      // The ship lifts off everyone the clock has not reached.
      return EndingOutcome(Ending.rescue, woke, frozenLeft);
    }
    // No beacon: the colony. Fed early is an understanding; fed only when
    // desperate is a truce.
    final r = s.creatureRelations;
    final ending = r.fedEarly > r.fedDesperate
        ? Ending.colonyUnderstanding
        : Ending.colonyTruce;
    return EndingOutcome(ending, woke, frozenLeft);
  }
}
