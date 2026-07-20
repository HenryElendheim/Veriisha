import '../models/enums.dart';

// The buildable list. Costs are in actions, because actions are the real budget.
// The whole point of summer is that no site can afford everything in its 28
// actions - a test asserts it (see test/budget_test.dart).

class BuildingDef {
  final String id;
  final String name;
  final int actionCost; // actions to build
  final int scrapCost;
  final int powerDraw; // ongoing power the building wants each winter day
  final List<SiteId> requiredForSites; // sites where this is close to mandatory
  final String effect; // plain description of what it does

  const BuildingDef({
    required this.id,
    required this.name,
    required this.actionCost,
    this.scrapCost = 0,
    this.powerDraw = 0,
    this.requiredForSites = const [],
    required this.effect,
  });
}

// Eleven-plus buildings, including the beacon. The beacon is deliberately
// expensive - several actions and a heavy power draw - so skipping it is a real
// temptation, not an obvious mistake.
const List<BuildingDef> kBuildings = [
  BuildingDef(
    id: 'perimeter_wall',
    name: 'Perimeter wall',
    actionCost: 4,
    scrapCost: 20,
    requiredForSites: [SiteId.basin],
    effect: 'Blunts predator attacks at the wall.',
  ),
  BuildingDef(
    id: 'arms_rack',
    name: 'Arms rack',
    actionCost: 2,
    scrapCost: 10,
    requiredForSites: [SiteId.basin],
    effect: 'Lets crew fight off predators instead of only enduring them.',
  ),
  BuildingDef(
    id: 'anchors',
    name: 'Slope anchors',
    actionCost: 3,
    scrapCost: 15,
    requiredForSites: [SiteId.ridge],
    effect: 'Holds the slope, cutting avalanche severity.',
  ),
  BuildingDef(
    id: 'tremor_sensor',
    name: 'Tremor sensor',
    actionCost: 2,
    scrapCost: 8,
    requiredForSites: [SiteId.ridge],
    effect: 'Lengthens the warning before an avalanche lands.',
  ),
  BuildingDef(
    id: 'greenhouse',
    name: 'Greenhouse',
    actionCost: 5,
    scrapCost: 25,
    powerDraw: 20,
    requiredForSites: [SiteId.cave],
    effect: 'The only reliable winter food. Yield rises with its level.',
  ),
  BuildingDef(
    id: 'food_cache',
    name: 'Food cache',
    actionCost: 2,
    scrapCost: 5,
    requiredForSites: [SiteId.cave],
    effect: 'Stores extra food against the leanest weeks.',
  ),
  BuildingDef(
    id: 'water_filter',
    name: 'Water filter',
    actionCost: 3,
    scrapCost: 12,
    powerDraw: 8,
    effect: 'Removes the microbes from snowmelt. Skipping it is a slow bleed.',
  ),
  BuildingDef(
    id: 'biofuel_converter',
    name: 'Biofuel converter',
    actionCost: 3,
    scrapCost: 15,
    effect:
        'Burns biomass into reactor fuel. Reactor fuel alone will not last.',
  ),
  BuildingDef(
    id: 'observatory',
    name: 'Observatory',
    actionCost: 2,
    scrapCost: 8,
    effect: 'Reads how long this winter runs, so you stop rationing blind.',
  ),
  BuildingDef(
    id: 'shutters',
    name: 'Storm shutters',
    actionCost: 2,
    scrapCost: 6,
    effect: 'Sealed against storms, holding heat in the worst weather.',
  ),
  BuildingDef(
    id: 'smelter',
    name: 'Smelter',
    actionCost: 3,
    scrapCost: 10,
    effect: 'Turns wreck salvage into usable scrap.',
  ),
  BuildingDef(
    id: 'sensor_post',
    name: 'Sensor post',
    actionCost: 2,
    scrapCost: 8,
    effect: 'Longer warning on everything the weather throws at you.',
  ),
  BuildingDef(
    id: 'beacon',
    name: 'Rescue beacon',
    actionCost: 8,
    scrapCost: 40,
    powerDraw: 25,
    effect:
        'Calls a ship. At spring it lifts off every pod the clock has not reached.',
  ),
];

final Map<String, BuildingDef> _byId = {for (final b in kBuildings) b.id: b};
BuildingDef buildingDef(String id) => _byId[id]!;
