import '../models/enums.dart';

// The event catalogue the threat system draws from. Every one of these enters the
// world as a queued threat with a telegraph, never as an instant hit.

class EventDef {
  final String id;
  final ThreatType type;
  final String sign; // the in-world telegraph line
  final double weight; // relative likelihood when an event is rolled
  final double
      minWinterProgress; // 0..1 - how deep into winter before it can occur

  const EventDef({
    required this.id,
    required this.type,
    required this.sign,
    this.weight = 1.0,
    this.minWinterProgress = 0.0,
  });
}

// A spread of twenty-plus events. Site chains (avalanche, predator, starvation)
// are handled directly by the threat system; these are the shared weather and
// equipment troubles that can land at any camp.
const List<EventDef> kEvents = [
  EventDef(
      id: 'storm',
      type: ThreatType.storm,
      sign: 'The pressure drops. A storm is building.',
      weight: 3),
  EventDef(
      id: 'hard_storm',
      type: ThreatType.storm,
      sign: 'The glass is falling fast - this one will be bad.',
      weight: 1.5,
      minWinterProgress: 0.3),
  EventDef(
      id: 'equipment_failure',
      type: ThreatType.equipmentFailure,
      sign: 'A panel is flickering. Something is about to fail.',
      weight: 2),
  EventDef(
      id: 'fuel_leak',
      type: ThreatType.fuelLeak,
      sign: 'You smell fuel. A line is weeping somewhere.',
      weight: 1.5),
  EventDef(
      id: 'crop_blight',
      type: ThreatType.cropBlight,
      sign: 'Leaves are curling in the greenhouse.',
      weight: 1.2,
      minWinterProgress: 0.2),
  EventDef(
      id: 'deep_freeze',
      type: ThreatType.storm,
      sign: 'The outside gauge is plunging. A deep freeze is coming.',
      weight: 1.5,
      minWinterProgress: 0.5),
  EventDef(
      id: 'equipment_strain',
      type: ThreatType.equipmentFailure,
      sign: 'The reactor note has changed. It is straining.',
      weight: 1.5,
      minWinterProgress: 0.4),
];

/// The severity a landed event applies, before winter-depth and difficulty
/// scaling. Kept here so tuning stays out of the systems.
const Map<ThreatType, double> kBaseSeverity = {
  ThreatType.storm: 8,
  ThreatType.equipmentFailure: 10,
  ThreatType.fuelLeak: 12,
  ThreatType.cropBlight: 9,
  ThreatType.avalanche: 30,
  ThreatType.predator: 7,
  ThreatType.starvation: 6,
};
