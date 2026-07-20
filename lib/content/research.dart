import '../models/enums.dart';

// Research runs over several days and needs a qualified body. Its effects persist
// into winter. Biotic adaptation is the important one: it unlocks the cheap
// Veriishan crops and, with them, the loan.

class ResearchDef {
  final String id;
  final String name;
  final int daysOfWork; // qualified-body days to finish
  final Role requiredRole; // who can do the work
  final String effect;

  const ResearchDef({
    required this.id,
    required this.name,
    required this.daysOfWork,
    required this.requiredRole,
    required this.effect,
  });
}

const List<ResearchDef> kResearch = [
  ResearchDef(
    id: 'biotic_adaptation',
    name: 'Biotic adaptation',
    daysOfWork: 3,
    requiredRole: Role.botanist,
    effect:
        'Lets the colony eat what Veriisha grows. Unlocks cheap crops and the loan.',
  ),
  ResearchDef(
    id: 'cold_tolerance',
    name: 'Cold tolerance',
    daysOfWork: 2,
    requiredRole: Role.engineer,
    effect: 'Crew hold their warmth a little longer in cold rooms.',
  ),
  ResearchDef(
    id: 'field_medicine',
    name: 'Field medicine',
    daysOfWork: 2,
    requiredRole: Role.medic,
    effect: 'Improves treatment odds when no medic is on hand.',
  ),
];

final Map<String, ResearchDef> _byId = {for (final r in kResearch) r.id: r};
ResearchDef researchDef(String id) => _byId[id]!;

/// The research id the loan is gated behind.
const String kBioticAdaptationId = 'biotic_adaptation';
