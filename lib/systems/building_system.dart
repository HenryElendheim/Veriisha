import '../content/buildings.dart';
import '../content/research.dart';
import '../models/world.dart';
import '../models/run.dart';
import '../engine/result.dart';

// Building things. The costs are in actions, because actions are the real budget.
// The whole point of summer is that these do not all fit inside 28 actions.

class BuildingSystem {
  /// Put one build action into a building. Scrap is reserved on the first action;
  /// the building finishes once enough actions have gone in. The greenhouse can be
  /// worked again to raise its level and its yield.
  static ActionResult build(RunSave s, String buildingId) {
    final def = buildingDef(buildingId);
    var b = s.buildingById(buildingId);
    if (b != null && b.built && buildingId != 'greenhouse') {
      return ActionResult.fail('${def.name} is already built.');
    }
    // A building record is created the first time work starts on it.
    if (b == null) {
      b = Building(id: buildingId);
      s.buildings.add(b);
    }
    // Starting a fresh build (or a fresh greenhouse level) reserves the scrap.
    if (b.progress == 0) {
      if (s.resources.scrap < def.scrapCost) {
        return ActionResult.fail('Not enough scrap for the ${def.name}.');
      }
      s.resources.scrap -= def.scrapCost;
    }
    b.progress += 1;
    if (b.progress >= def.actionCost) {
      b.progress = 0;
      b.built = true;
      b.level += 1;
      return ActionResult.success('Built the ${def.name}.');
    }
    return ActionResult.success(
        'Working on the ${def.name} (${b.progress}/${def.actionCost}).');
  }

  /// The total action cost to build every building. Used by the budget test that
  /// proves no site can afford everything in its 28 summer actions.
  static int totalBuildActionCost() =>
      kBuildings.fold(0, (sum, b) => sum + b.actionCost);

  /// Total actions to build everything and finish all research.
  static int totalPrepActionCost() =>
      totalBuildActionCost() +
      kResearch.fold(0, (sum, r) => sum + r.daysOfWork);
}
