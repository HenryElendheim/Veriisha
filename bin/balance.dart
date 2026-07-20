// The balance tool. Plays many runs across seeds, sites and difficulties with the
// shared strategy, and reports how they ended. The design's targets: a first run
// should lose in the first third of winter, a good run should reach spring with a
// few alive, and no site should be the obvious best. This is how you check that
// without editing a line of logic - you read the numbers, then tune the config.
//
// ignore_for_file: avoid_print

import 'package:veriisha/veriisha.dart';
import 'auto_player.dart';

void main(List<String> args) {
  final runsPerCell = args.isNotEmpty ? int.tryParse(args.first) ?? 40 : 40;

  print(
      '== VERIISHA balance sweep - $runsPerCell runs per site, normal difficulty ==');
  print('');

  var grandSpring = 0;
  var grandTotal = 0;
  for (final site in SiteId.values) {
    final outcomes = <RunOutcome>[];
    for (var i = 0; i < runsPerCell; i++) {
      // The SAME seed set for every site, so any difference is the site itself
      // and not a lucky or unlucky run of draws.
      final seed = 10000 + i;
      final e = GameEngine.newRun(seed: seed, difficulty: Difficulty.normal);
      e.chooseCharacter('rusher');
      e.chooseSite(site);
      outcomes.add(playRun(e));
    }
    _report(site, outcomes);
    grandSpring += outcomes.where((o) => o.reachedSpring).length;
    grandTotal += outcomes.length;
  }

  print('');
  print('Overall reached spring: $grandSpring / $grandTotal '
      '(${_pct(grandSpring, grandTotal)}).');
}

void _report(SiteId site, List<RunOutcome> outcomes) {
  final n = outcomes.length;
  final spring = outcomes.where((o) => o.reachedSpring).length;
  final rescue = outcomes.where((o) => o.ending == Ending.rescue).length;
  final understanding =
      outcomes.where((o) => o.ending == Ending.colonyUnderstanding).length;
  final truce = outcomes.where((o) => o.ending == Ending.colonyTruce).length;
  final death = outcomes.where((o) => o.ending == Ending.death).length;

  final springWoke =
      outcomes.where((o) => o.reachedSpring).map((o) => o.woke).toList();
  final avgWoke = springWoke.isEmpty
      ? 0.0
      : springWoke.reduce((a, b) => a + b) / springWoke.length;
  final avgSaved = spring == 0
      ? 0.0
      : outcomes
              .where((o) => o.reachedSpring)
              .map((o) => o.saved)
              .reduce((a, b) => a + b) /
          spring;

  print('${siteDef(site).name.padRight(6)}  '
      'spring ${_pct(spring, n)}  '
      'rescue $rescue / colony ${understanding + truce} / died $death  '
      'avg woke ${avgWoke.toStringAsFixed(1)}  avg saved/left ${avgSaved.toStringAsFixed(0)}');
}

String _pct(int a, int b) => b == 0 ? '0%' : '${(100 * a / b).round()}%';
