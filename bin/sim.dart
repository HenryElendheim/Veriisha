// A headless full run, narrated. Plays a complete game with a fixed seed using
// the shared strategy and prints a daily digest, ending on one of the two endings
// with the plain count line. This is the proof that the simulation works - the
// whole game is decisions and numbers, and here they are, with no interface.
//
// ignore_for_file: avoid_print

import 'package:veriisha/veriisha.dart';
import 'auto_player.dart';

void main() {
  final engine =
      GameEngine.newRun(seed: 20260720, difficulty: Difficulty.normal);

  print('== VERIISHA - headless full run ==');
  print(engine.chooseCharacter('rusher').message);
  print(engine.chooseSite(SiteId.cave).message);
  print('Winter length this run: ${engine.state.run.winterLength} days '
      '(hidden in game until the observatory).');
  print('');

  final outcome = playRun(engine, out: print);

  print('');
  print('== END ==');
  print(endingText(outcome.ending));
  print(endingCountLine(outcome.ending,
      woke: outcome.woke, saved: outcome.saved));
  print('');
  print('Reached ${outcome.reachedSpring ? 'spring' : 'a death ending'}. '
      'Memorial holds ${outcome.memorialNames} names, '
      '${outcome.wreckDeaths} of them from the wreck.');
}
