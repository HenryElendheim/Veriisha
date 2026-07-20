import '../models/enums.dart';

// Small value types the engine hands back: the outcome of a single action, and
// the digest of a resolved day (or a skipped span).

/// The outcome of attempting one action.
class ActionResult {
  final bool ok;
  final String message;
  const ActionResult(this.ok, this.message);
  const ActionResult.fail(String message) : this(false, message);
  const ActionResult.success(String message) : this(true, message);
}

/// One death, for the digest and the memorial.
class DeathRecord {
  final String name;
  final Cause cause;
  final bool fromWreck; // true if this was the daily wreck-clock death
  const DeathRecord(this.name, this.cause, {this.fromWreck = false});
}

/// What happened overnight, or across a skipped span. This is what a UI or the
/// console harness reads to tell the player what changed.
class DayDigest {
  final int fromDay;
  int toDay;
  final List<DeathRecord> deaths;
  final List<String> newTelegraphs; // in-world signs that appeared
  final List<String> lines; // notable log lines for the span
  bool phaseChanged;
  Phase? newPhase;
  bool runEnded;
  Ending? ending;
  String? stopReason; // why an advance-days run halted

  DayDigest({
    required this.fromDay,
    required this.toDay,
    List<DeathRecord>? deaths,
    List<String>? newTelegraphs,
    List<String>? lines,
    this.phaseChanged = false,
    this.newPhase,
    this.runEnded = false,
    this.ending,
    this.stopReason,
  })  : deaths = deaths ?? [],
        newTelegraphs = newTelegraphs ?? [],
        lines = lines ?? [];

  /// Merge a later single-day digest into a spanning one (for advance-days).
  void absorb(DayDigest other) {
    toDay = other.toDay;
    deaths.addAll(other.deaths);
    newTelegraphs.addAll(other.newTelegraphs);
    lines.addAll(other.lines);
    if (other.phaseChanged) {
      phaseChanged = true;
      newPhase = other.newPhase;
    }
    if (other.runEnded) {
      runEnded = true;
      ending = other.ending;
    }
    stopReason ??= other.stopReason;
  }
}
