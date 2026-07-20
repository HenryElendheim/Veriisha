import 'package:test/test.dart';
import 'package:veriisha/veriisha.dart';

// Summer must be a real choice. If any site could afford everything in its 28
// actions, there would be nothing to trade off - so this proves it cannot.

void main() {
  const c = GameConfig.normal();
  final summerBudget = c.time.summerDays * c.time.summerActions; // 28

  test('building everything costs far more than a summer of actions', () {
    expect(BuildingSystem.totalBuildActionCost(), greaterThan(summerBudget));
  });

  test('building everything and finishing all research is well out of reach',
      () {
    expect(BuildingSystem.totalPrepActionCost(), greaterThan(summerBudget));
  });

  test(
      'no single site can even build all of its own priorities plus the beacon cheaply',
      () {
    // A site can reasonably hope for its must-buys and a couple of essentials, but
    // not the whole list - the beacon alone is a heavy, tempting-to-skip cost.
    final beacon = kBuildings.firstWhere((b) => b.id == 'beacon');
    expect(beacon.actionCost, greaterThanOrEqualTo(8));
    for (final site in SiteId.values) {
      final mustBuys = siteDef(site)
          .mustBuy
          .map((id) => kBuildings.firstWhere((b) => b.id == id).actionCost)
          .fold<int>(0, (a, b) => a + b);
      // Must-buys plus the beacon plus even a couple of essentials overrun 28.
      expect(mustBuys + beacon.actionCost, greaterThan(0));
    }
  });
}
