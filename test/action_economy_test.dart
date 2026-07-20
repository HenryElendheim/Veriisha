import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';

// The action economy: people are a prerequisite for actions, never a multiplier,
// and the loan borrows effort now against effort soon.

RunSave _stateWith({required Phase phase, required int awakeAble}) {
  final crew = <Crew>[];
  for (var i = 0; i < awakeAble; i++) {
    crew.add(Crew(
      id: 'c$i',
      name: 'C$i',
      roles: const [Role.engineer],
      awake: true,
      alive: true,
      able: true,
    ));
  }
  return RunSave(run: RunMeta(seed: 1, phase: phase), crew: crew);
}

void main() {
  const c = GameConfig.normal();

  group('action pool', () {
    test('summer is seven days of four actions - 28 in total', () {
      expect(c.time.summerDays, 7);
      expect(c.time.summerActions, 4);
      expect(c.time.summerDays * c.time.summerActions, 28);
    });

    test('starting alone gives exactly one action on day one', () {
      final engine = GameEngine.newRun(seed: 42);
      engine.chooseCharacter('rusher');
      engine.chooseSite(SiteId.ridge);
      expect(engine.state.run.phase, Phase.summer);
      expect(engine.state.run.day, 1);
      expect(engine.state.actionsToday.total, 1);
    });

    test(
        'pool is min(base, able bodies) - bodies are a prerequisite, not a multiplier',
        () {
      // Two able bodies in summer: capped by bodies, not the base of four.
      expect(
          ActionEconomy.computePool(
              _stateWith(phase: Phase.summer, awakeAble: 2), c),
          2);
      // Six able bodies in summer: capped by the base of four.
      expect(
          ActionEconomy.computePool(
              _stateWith(phase: Phase.summer, awakeAble: 6), c),
          4);
      // Six able bodies in winter: capped by the base of three.
      expect(
          ActionEconomy.computePool(
              _stateWith(phase: Phase.winter, awakeAble: 6), c),
          3);
    });
  });

  group('the loan', () {
    RunSave bioticReady() {
      final s = _stateWith(phase: Phase.winter, awakeAble: 4);
      s.research.add(Research(id: 'biotic_adaptation', complete: true));
      return s;
    }

    test('is gated behind biotic adaptation', () {
      final without = _stateWith(phase: Phase.winter, awakeAble: 4);
      expect(ActionEconomy.canTakeLoan(without), isFalse);
      expect(ActionEconomy.canTakeLoan(bioticReady()), isTrue);
    });

    test('runs +1 for three days, then -1 for three days, then clears', () {
      final s = bioticReady();
      expect(ActionEconomy.takeLoan(s, c), isTrue);

      final modifiers = <int>[];
      for (var day = 0; day < 6; day++) {
        modifiers.add(ActionEconomy.loanModifier(s, c));
        ActionEconomy.tickLoan(s, c);
      }
      expect(modifiers, [1, 1, 1, -1, -1, -1]);
      // Fully repaid and re-takeable again.
      expect(s.actionsToday.loan.busy, isFalse);
    });

    test('cannot be re-taken while active or in debt', () {
      final s = bioticReady();
      ActionEconomy.takeLoan(s, c);
      expect(ActionEconomy.canTakeLoan(s), isFalse); // active
      for (var i = 0; i < 3; i++) {
        ActionEconomy.tickLoan(s, c);
      }
      expect(ActionEconomy.canTakeLoan(s), isFalse); // now in debt
      for (var i = 0; i < 3; i++) {
        ActionEconomy.tickLoan(s, c);
      }
      expect(ActionEconomy.canTakeLoan(s), isTrue); // cleared
    });
  });
}
