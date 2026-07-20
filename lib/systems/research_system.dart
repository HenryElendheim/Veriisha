import '../content/research.dart';
import '../models/world.dart';
import '../models/run.dart';
import '../engine/result.dart';

// Research runs over several days and needs a qualified body on the work. Each
// action spends one day of that work; the effect lands when the work is done and
// persists into winter.

class ResearchSystem {
  /// Put one day of work into a research project. Needs a qualified, able body.
  static ActionResult work(RunSave s, String researchId) {
    final def = researchDef(researchId);
    final r = s.researchById(researchId);
    if (r != null && r.complete) {
      return ActionResult.fail('${def.name} is already done.');
    }
    final qualified = s.ableCrew.any((c) => c.hasRole(def.requiredRole));
    if (!qualified) {
      return ActionResult.fail(
          'No able ${def.requiredRole.name} to work on ${def.name}.');
    }
    final project = r ?? Research(id: researchId, progress: 0);
    if (r == null) s.research.add(project);
    project.progress += 1;
    if (project.progress >= def.daysOfWork) {
      project.complete = true;
      return ActionResult.success('${def.name} complete.');
    }
    return ActionResult.success(
        'Worked on ${def.name} (${project.progress}/${def.daysOfWork}).');
  }

  /// Is biotic adaptation done - the gate the loan sits behind.
  static bool bioticAdaptationDone(RunSave s) =>
      s.isResearched(kBioticAdaptationId);
}
