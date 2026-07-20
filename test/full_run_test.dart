import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';

// The phase machine and a full run through it - the "the game works" milestone.

void main() {
  test('the phase machine walks character -> site -> summer', () {
    final e = GameEngine.newRun(seed: 1);
    expect(e.phase, Phase.characterSelect);
    e.chooseCharacter('rusher');
    expect(e.phase, Phase.siteSelect);
    e.chooseSite(SiteId.ridge);
    expect(e.phase, Phase.summer);
    expect(e.state.run.day, 1);
    expect(e.state.run.winterLength, inInclusiveRange(100, 130));
  });

  test('a run always reaches a legal ending, never a stuck state', () {
    final e = GameEngine.newRun(seed: 20260720);
    e.chooseCharacter('rusher');
    e.chooseSite(SiteId.cave);
    var guard = 0;
    while (e.phase != Phase.ending && guard < 400) {
      guard++;
      e.endDay();
    }
    expect(e.phase, Phase.ending);
    expect(guard, lessThan(400), reason: 'the run terminates');
    expect(e.finalEnding, isNotNull);
  });

  test(
      'with no pods fetched, the wreck count falls by exactly the days elapsed',
      () {
    final e = GameEngine.newRun(seed: 11);
    e.chooseCharacter('chasefield');
    e.chooseSite(SiteId.basin);
    final start = e.state.pods.wreck.count;
    for (var i = 0; i < 6; i++) {
      e.endDay();
    }
    // Six day-ends, six wreck deaths, no fetches.
    expect(start - e.state.pods.wreck.count, 6);
    expect(e.state.run.day, 7);
  });

  test(
      'the beacon ending saves the pods the clock has not reached, and says the number',
      () {
    // Construct a spring with a beacon built and a couple of survivors awake.
    final e = GameEngine.newRun(seed: 3);
    e.chooseCharacter('athena');
    e.chooseSite(SiteId.cave);
    e.state.buildings.add(Building(id: 'beacon', built: true, level: 1));
    // Two extra survivors woken.
    e.state.crew.add(Crew(
        id: 'c001',
        name: 'Bee',
        roles: const [Role.medic],
        awake: true,
        alive: true,
        able: true));
    e.state.pods.wreck.count = 81;

    final outcome = e.endingOutcome();
    expect(outcome.ending, Ending.rescue);
    expect(outcome.saved, 81);
    final line = endingCountLine(outcome.ending,
        woke: outcome.woke, saved: outcome.saved);
    expect(line, contains('beacon saved'));
  });

  test('the colony ending shade follows how the creatures were fed', () {
    final understanding = GameEngine.newRun(seed: 8)
      ..chooseCharacter('rusher')
      ..chooseSite(SiteId.basin);
    understanding.state.creatureRelations.fedEarly = 2;
    expect(understanding.endingOutcome().ending, Ending.colonyUnderstanding);

    final truce = GameEngine.newRun(seed: 9)
      ..chooseCharacter('rusher')
      ..chooseSite(SiteId.basin);
    truce.state.creatureRelations.fedDesperate = 2;
    expect(truce.endingOutcome().ending, Ending.colonyTruce);
  });
}
