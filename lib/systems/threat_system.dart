import '../config/game_config.dart';
import '../content/events.dart';
import '../content/sites.dart';
import '../models/enums.dart';
import '../models/world.dart';
import '../models/run.dart';
import '../engine/rng.dart';

// The warning queue. Every crisis becomes visible one to two days before it lands,
// through an in-world sign. The minimum warning being at least one full day is
// what makes an untelegraphed hit impossible rather than merely unlikely.

/// A threat that just landed, and whether it was telegraphed. `wasVisible` must
/// always be true - if it is ever false, the telegraph guarantee has broken.
class LandedThreat {
  final Threat threat;
  final bool wasVisible;
  final String line;
  const LandedThreat(this.threat, this.wasVisible, this.line);
}

class ThreatSystem {
  /// How deep into winter we are, 0..1. Summer is 0.
  static double winterProgress(RunSave s) {
    if (s.run.phase != Phase.winter || s.run.winterLength <= 0) return 0;
    return (s.run.day / s.run.winterLength).clamp(0.0, 1.0);
  }

  /// Step 7 of day-end: every active threat draws one day closer.
  static void advance(RunSave s) {
    for (final t in s.threats) {
      t.daysUntil -= 1;
    }
  }

  /// Land every threat that has reached its day. Applies the damage, honours
  /// mitigations, and returns what landed so the caller can prove each was
  /// telegraphed.
  static List<LandedThreat> land(RunSave s, GameConfig c) {
    final landed = <LandedThreat>[];
    final remaining = <Threat>[];
    for (final t in s.threats) {
      if (t.daysUntil > 0) {
        remaining.add(t);
        continue;
      }
      final line = _apply(s, c, t);
      landed.add(LandedThreat(t, t.visible, line));
    }
    s.threats
      ..clear()
      ..addAll(remaining);
    return landed;
  }

  /// Step 8: maybe raise new threats. Anything created here is given a warning of
  /// at least warningMinDays, so nothing can ever land on the day it is born.
  static void spawnEvents(RunSave s, GameConfig c, SeededRng rng) {
    final progress = winterProgress(s);
    // Site avalanche chain (Ridge): rare, but total when it comes.
    if (siteDef(s.run.siteId).threat == ThreatType.avalanche &&
        s.run.phase == Phase.winter &&
        rng.chance(0.04 + progress * 0.04)) {
      _raise(s, c, rng, ThreatType.avalanche, 'ridge-slope',
          'Tremors on the slope. The ceiling is loosening.');
      return;
    }
    // Generic weather and equipment troubles.
    if (rng.chance(0.28)) {
      final pool =
          kEvents.where((e) => progress >= e.minWinterProgress).toList();
      if (pool.isEmpty) return;
      final ev = _weightedPick(pool, rng);
      _raise(s, c, rng, ev.type, ev.id, ev.sign);
    }
  }

  /// Step 9: flip on the telegraph for any threat now inside the warning window,
  /// and return the freshly appeared signs.
  static List<String> updateTelegraphs(RunSave s, GameConfig c) {
    final signs = <String>[];
    for (final t in s.threats) {
      if (!t.visible && t.daysUntil <= c.threat.warningMaxDays) {
        t.visible = true;
        signs.add(_signFor(t));
      }
    }
    return signs;
  }

  /// Raise a threat from another system (the creatures do this for predator
  /// attacks) so it goes through the same telegraph guarantee as everything else.
  static void raise(RunSave s, GameConfig c, SeededRng rng, ThreatType type,
          String source,
          {double? severity}) =>
      _raise(s, c, rng, type, source, '', severityOverride: severity);

  // --- helpers ---

  static void _raise(RunSave s, GameConfig c, SeededRng rng, ThreatType type,
      String source, String sign,
      {double? severityOverride}) {
    // Longer warning if the site has a sensor for it.
    var maxLead = c.threat.warningMaxDays;
    if (type == ThreatType.avalanche && s.isBuilt('tremor_sensor')) {
      maxLead += 1;
    }
    if (s.isBuilt('sensor_post')) maxLead += 1;
    final lead = rng.nextRange(c.threat.warningMinDays, maxLead);
    final base = kBaseSeverity[type] ?? 8;
    final severity = severityOverride ?? base * (1 + winterProgress(s));
    s.threats.add(Threat(
        type: type, source: source, daysUntil: lead, severity: severity));
  }

  static String _signFor(Threat t) {
    for (final e in kEvents) {
      if (e.id == t.source) return e.sign;
    }
    if (t.type == ThreatType.avalanche) {
      return 'Tremors on the slope. The ceiling is loosening.';
    }
    return 'Something is coming: ${t.type.name}.';
  }

  // Apply a landed threat. Mitigations soften it; nothing removes it entirely.
  static String _apply(RunSave s, GameConfig c, Threat t) {
    switch (t.type) {
      case ThreatType.storm:
        final soften = s.isBuilt('shutters') ? 0.4 : 1.0;
        for (final p in s.livingAwake) {
          p.stats.warmth = (p.stats.warmth - (t.severity * soften))
              .round()
              .clamp(0, 100)
              .toInt();
        }
        return 'A storm hit the camp.';
      case ThreatType.equipmentFailure:
        s.resources.power.fuel = (s.resources.power.fuel - t.severity * 0.1)
            .clamp(0, double.infinity);
        return 'Equipment failed. Fuel was lost keeping things running.';
      case ThreatType.fuelLeak:
        s.resources.power.fuel = (s.resources.power.fuel - t.severity * 0.15)
            .clamp(0, double.infinity);
        return 'A fuel line leaked overnight.';
      case ThreatType.cropBlight:
        s.resources.food =
            (s.resources.food - t.severity * 2).clamp(0, double.infinity);
        return 'Blight took part of the crop.';
      case ThreatType.avalanche:
        final soften = s.isBuilt('anchors') ? 0.35 : 1.0;
        for (final p in s.livingAwake) {
          p.stats.health = (p.stats.health - (t.severity * soften))
              .round()
              .clamp(0, 100)
              .toInt();
        }
        return 'The slope came down on the camp.';
      case ThreatType.predator:
        // The wall blunts them; the arms rack lets crew drive them off.
        var soften = 1.0;
        if (s.isBuilt('perimeter_wall')) soften *= 0.5;
        if (s.isBuilt('arms_rack')) soften *= 0.6;
        final targets = s.livingAwake.toList();
        if (targets.isEmpty) return 'Predators tested an empty perimeter.';
        // Pick the first able body; deterministic given the ordered crew list.
        final victim = targets.first;
        final hit = (t.severity * soften).round();
        victim.stats.health = (victim.stats.health - hit).clamp(0, 100).toInt();
        if (soften > 0.4 && !victim.hasCondition(Condition.injured)) {
          victim.conditions.add(Condition.injured);
        }
        return 'Predators reached the wall. ${victim.name} was hurt driving them back.';
      case ThreatType.starvation:
        return 'The larder is running dangerously low.';
    }
  }

  static EventDef _weightedPick(List<EventDef> pool, SeededRng rng) {
    final total = pool.fold<double>(0, (a, e) => a + e.weight);
    var r = rng.nextDouble() * total;
    for (final e in pool) {
      r -= e.weight;
      if (r <= 0) return e;
    }
    return pool.last;
  }
}
