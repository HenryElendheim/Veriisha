import '../models/enums.dart';

// The three sites. Not easy, medium, hard - three different shapes of pressure,
// chosen once and permanent.

class SiteDef {
  final SiteId id;
  final String name;
  final ThreatType threat;
  final String riskShape;
  final List<String> mustBuy; // building ids this site really needs
  final double
      heatRetention; // multiplier on how long reactor fuel effectively lasts
  final double
      greenhouseFactor; // how well crops grow here - the cave is dim, so food is tight
  final String character;

  const SiteDef({
    required this.id,
    required this.name,
    required this.threat,
    required this.riskShape,
    required this.mustBuy,
    required this.heatRetention,
    this.greenhouseFactor = 1.0,
    required this.character,
  });
}

const Map<SiteId, SiteDef> kSites = {
  SiteId.ridge: SiteDef(
    id: SiteId.ridge,
    name: 'Ridge',
    threat: ThreatType.avalanche,
    riskShape: 'Rare, total. Long quiet, then the ceiling.',
    mustBuy: ['anchors', 'tremor_sensor'],
    heatRetention: 1.0,
    character: 'Long quiet, then the ceiling',
  ),
  SiteId.basin: SiteDef(
    id: SiteId.basin,
    name: 'Basin',
    threat: ThreatType.predator,
    riskShape: 'Constant drain. Well fed, never at peace.',
    mustBuy: ['perimeter_wall', 'arms_rack'],
    heatRetention: 1.0,
    character: 'Well fed, never at peace',
  ),
  // The cave's rock holds heat, so fuel lasts meaningfully longer here. It is the
  // site that could survive a 130-day winter, if it survives a normal one.
  SiteId.cave: SiteDef(
    id: SiteId.cave,
    name: 'Cave',
    threat: ThreatType.starvation,
    riskShape: 'Rising cost. Warmest camp, most likely to starve.',
    mustBuy: ['greenhouse', 'food_cache'],
    heatRetention: 1.4,
    greenhouseFactor:
        0.9, // dim under the rock - one greenhouse will not feed a full camp
    character: 'Warmest camp, most likely to starve',
  ),
};

SiteDef siteDef(SiteId id) => kSites[id]!;
