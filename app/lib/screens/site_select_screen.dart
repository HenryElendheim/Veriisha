import 'package:flutter/material.dart';
import 'package:veriisha/veriisha.dart';
import '../game/game_controller.dart';
import 'run_screen.dart';

// The site: three shapes of pressure, chosen once and permanent. Picking one
// starts the run and drops into it.

class SiteSelectScreen extends StatelessWidget {
  final GameController controller;
  final String characterId;
  final Difficulty difficulty;

  const SiteSelectScreen({
    super.key,
    required this.controller,
    required this.characterId,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a site')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final id in SiteId.values) _SiteCard(def: siteDef(id), onTap: () => _start(context, id)),
          ],
        ),
      ),
    );
  }

  void _start(BuildContext context, SiteId site) {
    controller.newRun(
      characterId: characterId,
      difficulty: difficulty,
      site: site,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RunScreen(controller: controller)),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteDef def;
  final VoidCallback onTap;
  const _SiteCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.onSurface.withOpacity(0.15))),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(def.name, style: TextStyle(fontSize: 20, letterSpacing: 2, color: scheme.onSurface)),
              const SizedBox(height: 4),
              Text('Threat: ${def.threat.name}',
                  style: TextStyle(color: scheme.secondary, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(def.riskShape, style: TextStyle(color: scheme.onSurface.withOpacity(0.8))),
              const SizedBox(height: 8),
              Text('Must-buy: ${def.mustBuy.join(', ')}',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
