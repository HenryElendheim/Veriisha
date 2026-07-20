import '../config/game_config.dart';
import '../content/research.dart';
import '../models/enums.dart';
import '../models/run.dart';

// The action economy. A day is a fixed number of actions, and people are a
// prerequisite for them, never a multiplier: the pool is min(base, able bodies).
// Extra crew are insurance and specialist skills, not a longer day.

class ActionEconomy {
  /// The base action cap for the current phase, before bodies and the loan. A
  /// tireless able body raises the cap (five instead of three).
  static int _baseCap(RunSave s, GameConfig c) {
    var base = s.run.phase == Phase.summer
        ? c.time.summerActions
        : c.time.winterActions;
    final tireless = s.ableCrew.any((p) => p.hasTrait(Trait.tireless));
    if (tireless && base < 5) base = 5;
    return base;
  }

  /// The action pool for the morning: min(base, able bodies), plus the loan.
  /// Starting alone means day one gives exactly one action.
  static int computePool(RunSave s, GameConfig c) {
    final ableBodies = s.ableCrew.length;
    final cap = _baseCap(s, c);
    final pool = cap < ableBodies ? cap : ableBodies;
    final withLoan = pool + loanModifier(s, c);
    return withLoan < 0 ? 0 : withLoan;
  }

  /// The loan's effect on the pool right now: +1 while borrowing, -1 while repaying.
  static int loanModifier(RunSave s, GameConfig c) {
    final loan = s.actionsToday.loan;
    if (loan.active && !loan.inDebt) return c.loan.upBonus;
    if (loan.inDebt) return -c.loan.downPenalty;
    return 0;
  }

  /// Can the loan be taken? Only once biotic adaptation is done, and never while
  /// it is already running or still owed.
  static bool canTakeLoan(RunSave s) {
    return s.isResearched(kBioticAdaptationId) && !s.actionsToday.loan.busy;
  }

  /// Take the loan: three days of a fourth action, then the debt comes due.
  static bool takeLoan(RunSave s, GameConfig c) {
    if (!canTakeLoan(s)) return false;
    final loan = s.actionsToday.loan;
    loan.active = true;
    loan.inDebt = false;
    loan.daysRemaining = c.loan.upDays;
    loan.debtRemaining =
        c.loan.downDays; // what will be owed once the up-phase ends
    return true;
  }

  /// Advance the loan one day. Three days up, then three days down, then clear.
  static void tickLoan(RunSave s, GameConfig c) {
    final loan = s.actionsToday.loan;
    if (!loan.active) return;
    if (!loan.inDebt) {
      loan.daysRemaining -= 1;
      if (loan.daysRemaining <= 0) {
        loan.inDebt = true;
        loan.daysRemaining = c.loan.downDays;
      }
    } else {
      loan.daysRemaining -= 1;
      loan.debtRemaining -= 1;
      if (loan.daysRemaining <= 0) {
        loan.active = false;
        loan.inDebt = false;
        loan.debtRemaining = 0;
      }
    }
  }
}
