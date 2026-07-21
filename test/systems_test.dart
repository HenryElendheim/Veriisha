import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';
import 'package:veriisha/systems/condition_system.dart';
import 'package:veriisha/systems/power_system.dart';
import 'package:veriisha/systems/threat_system.dart';
import 'package:veriisha/systems/food_water_system.dart';

// The refinements that keep a run honest: bodies recover, the biofuel loop keeps
// the reactor alive, and a threat death is named for the threat that caused it.

void main() {
  const c = GameConfig.normal();

  Crew ablePerson(String id) => Crew(
        id: id,
        name: id,
        roles: const [Role.engineer],
        awake: true,
        alive: true,
        able: true,
      );

  test(
      'bodies recover - frostbite thaws when warm, injuries mend as health returns',
      () {
    final p = ablePerson('p')
      ..conditions.addAll([Condition.frostbitten, Condition.injured])
      ..stats.warmth = 80
      ..stats.health = 90;
    final s = RunSave(run: RunMeta(seed: 1, phase: Phase.winter), crew: [p]);

    ConditionSystem.recover(s);
    expect(p.hasCondition(Condition.frostbitten), isFalse);
    expect(p.hasCondition(Condition.injured), isFalse);
    expect(p.hasCondition(Condition.healthy), isTrue);
  });

  test('a still-cold, still-hurt body does not recover yet', () {
    final p = ablePerson('p')
      ..conditions.add(Condition.frostbitten)
      ..stats.warmth = 20;
    final s = RunSave(run: RunMeta(seed: 1, phase: Phase.winter), crew: [p]);
    ConditionSystem.recover(s);
    expect(p.hasCondition(Condition.frostbitten), isTrue);
  });

  test('the biofuel converter keeps fuel alive by burning biomass', () {
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter, siteId: SiteId.basin),
      buildings: [Building(id: 'biofuel_converter', built: true, level: 1)],
      resources: Resources(biomass: 100, power: Power(output: 100, fuel: 1)),
    );
    final before = s.resources.power.fuel;
    PowerSystem.burnDailyFuel(s, c);
    // A day's burn is more than covered by the converter, so fuel holds or climbs.
    expect(s.resources.power.fuel, greaterThan(before));
    expect(s.resources.biomass, lessThan(100));
  });

  test('without a converter, fuel just drains', () {
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter, siteId: SiteId.basin),
      resources: Resources(biomass: 100, power: Power(output: 100, fuel: 10)),
    );
    PowerSystem.burnDailyFuel(s, c);
    expect(s.resources.power.fuel, lessThan(10));
    expect(s.resources.biomass, 100); // no converter, biomass untouched
  });

  test(
      'difficulty bites end to end - an idle crew lasts longer on easy than hard',
      () {
    // Play a run doing nothing at all, and see how many days pass before it ends.
    // Harder difficulty means faster decay, so an idle crew should fall sooner.
    int idleRunLength(Difficulty difficulty) {
      final e = GameEngine.newRun(seed: 555, difficulty: difficulty);
      e.chooseCharacter('rusher');
      e.chooseSite(SiteId.ridge);
      var days = 0;
      while (e.phase != Phase.ending && days < 400) {
        days++;
        e.endDay();
      }
      return days;
    }

    final easy = idleRunLength(Difficulty.easy);
    final hard = idleRunLength(Difficulty.hard);
    expect(hard, lessThan(easy),
        reason: 'hard should end an idle run sooner than easy');
  });

  test('standing orders have live effect - tending the crop lifts the yield',
      () {
    RunSave camp({bool tend = false}) {
      final tender = ablePerson('p');
      if (tend) {
        tender.standingOrder =
            StandingOrder(task: StandingTask.tendCrop, daysRemaining: 5);
      }
      return RunSave(
        run: RunMeta(seed: 1, phase: Phase.winter, siteId: SiteId.ridge),
        crew: [tender],
        buildings: [Building(id: 'greenhouse', built: true, level: 1)],
        resources: Resources(),
      );
    }

    final plain = camp();
    FoodWaterSystem.produce(plain, c);
    final tended = camp(tend: true);
    FoodWaterSystem.produce(tended, c);
    expect(tended.resources.food, greaterThan(plain.resources.food));
  });

  test('teaching passes a role on, so knowledge survives the person', () {
    final e = GameEngine.newRun(seed: 1);
    e.chooseCharacter('rusher'); // an engineer
    e.chooseSite(SiteId.ridge);
    // A medic joins the camp, awake and able.
    final medic = ablePerson('med')..roles.add(Role.medic);
    medic.roles.remove(Role.engineer);
    e.state.crew.add(medic);
    e.state.actionsToday.total = 5; // room to act

    final student = e.state.crewById('rusher')!;
    expect(student.hasRole(Role.medic), isFalse);

    final r = e.teach('med', 'rusher', Role.medic);
    expect(r.ok, isTrue);
    expect(student.hasRole(Role.medic), isTrue);

    // You cannot teach a role you do not hold.
    final bad = e.teach('rusher', 'med', Role.botanist);
    expect(bad.ok, isFalse);
  });

  test('an avalanche death is named an avalanche, not a vague illness', () {
    final victim = ablePerson('v')..stats.health = 5;
    final s = RunSave(
      run: RunMeta(seed: 1, phase: Phase.winter, day: 40, siteId: SiteId.ridge),
      crew: [victim],
      // A visible avalanche due to land this step.
      threats: [
        Threat(
            type: ThreatType.avalanche,
            source: 'slope',
            daysUntil: 0,
            visible: true,
            severity: 40)
      ],
    );
    final deaths = <DeathRecord>[];
    ThreatSystem.land(s, c, 40, deaths);
    expect(victim.alive, isFalse);
    expect(deaths.single.cause, Cause.avalanche);
    expect(s.memorial.single.cause, Cause.avalanche);
  });
}
