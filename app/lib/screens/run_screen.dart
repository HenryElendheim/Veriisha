import 'package:flutter/material.dart';
import 'package:veriisha/veriisha.dart';
import '../game/game_controller.dart';

// The run, on screen. Deliberately plain - the whole point of the design is that
// the game is tense as blocks and numbers before any art. Bars carry their value
// as text, never colour alone, so the screen reads for everyone.

class RunScreen extends StatelessWidget {
  final GameController controller;
  const RunScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasRun) return const SizedBox.shrink();
        final e = controller.engine;
        if (e.phase == Phase.ending) return _EndingView(controller: controller);
        return _RunView(controller: controller);
      },
    );
  }
}

class _RunView extends StatelessWidget {
  final GameController controller;
  const _RunView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    final s = e.state;
    final scheme = Theme.of(context).colorScheme;
    final telegraphs = s.threats.where((t) => t.visible).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${siteDef(s.run.siteId).name} - ${s.run.phase.name} day ${s.run.day}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${e.actionsLeft} action(s)',
                  style: TextStyle(color: scheme.primary, letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (telegraphs.isNotEmpty)
              _Banner(
                lines: telegraphs.map((t) => _signOf(t)).toList(),
                color: scheme.secondary,
              ),
            _ResourceRow(s: s),
            const SizedBox(height: 8),
            _SectionLabel('Crew (${s.livingAwake.length} awake)'),
            for (final c in s.crew.where((c) => c.awake && c.alive)) _CrewLane(crew: c),
            const SizedBox(height: 8),
            const _SectionLabel('The wreck'),
            Text('${s.pods.wreck.count} still frozen. One is lost every day.',
                style: TextStyle(color: scheme.onSurface.withOpacity(0.75))),
            const SizedBox(height: 16),
            _ActionBar(controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(controller: controller),
    );
  }

  String _signOf(Threat t) => 'Warning: ${t.type.name} in ${t.daysUntil} day(s).';
}

class _Banner extends StatelessWidget {
  final List<String> lines;
  final Color color;
  const _Banner({required this.lines, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines) Text(l, style: TextStyle(color: color)),
          ],
        ),
      );
}

class _ResourceRow extends StatelessWidget {
  final RunSave s;
  const _ResourceRow({required this.s});
  @override
  Widget build(BuildContext context) {
    final r = s.resources;
    final items = {
      'Food': r.food.toStringAsFixed(0),
      'Water': r.water.clean.toStringAsFixed(0),
      'Fuel': r.power.fuel.toStringAsFixed(0),
      'Scrap': '${r.scrap}',
      'Supplies': '${r.medSupplies}',
      'Biomass': r.biomass.toStringAsFixed(0),
    };
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final e in items.entries)
          Text('${e.key} ${e.value}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, letterSpacing: 1)),
      ],
    );
  }
}

class _CrewLane extends StatelessWidget {
  final Crew crew;
  const _CrewLane({required this.crew});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = crew.conditions.where((c) => c != Condition.healthy).map((c) => c.name).join(', ');
    return Card(
      color: scheme.surfaceContainer,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(crew.name,
                      style: TextStyle(color: scheme.onSurface, fontSize: 16, letterSpacing: 1)),
                ),
                Text(crew.roles.map((r) => r.name).join('/'),
                    style: TextStyle(color: scheme.primary, fontSize: 12)),
              ],
            ),
            if (status.isNotEmpty)
              Text(status, style: TextStyle(color: scheme.error, fontSize: 12)),
            const SizedBox(height: 6),
            _StatBar(label: 'Hunger', value: crew.stats.hunger),
            _StatBar(label: 'Thirst', value: crew.stats.thirst),
            _StatBar(label: 'Warmth', value: crew.stats.warmth),
            _StatBar(label: 'Health', value: crew.stats.health),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  const _StatBar({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Colour AND a word/number - never colour alone.
    final critical = value <= 20;
    final barColor = critical ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: TextStyle(color: scheme.onSurface, fontSize: 12))),
          Expanded(
            child: ClipRect(
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 10,
                backgroundColor: scheme.onSurface.withOpacity(0.12),
                color: barColor,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text('  $value/100${critical ? ' !' : ''}',
                style: TextStyle(color: barColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final GameController controller;
  const _ActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    final s = e.state;
    void run(ActionResult Function(GameEngine e) fn) {
      final r = controller.act(fn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message), duration: const Duration(milliseconds: 1200)),
      );
    }

    // A sleeping pod at camp, if any, and a sick crewmate, if any.
    final sleeping = s.pods.bay.where((sl) {
      final c = s.crewById(sl.crewId ?? '');
      return sl.occupied && c != null && !c.awake;
    }).toList();
    final sick = s.livingAwake.where((c) => c.hasCondition(Condition.sick)).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionButton('Forage', () => run((e) => e.forage())),
        _ActionButton('Scavenge', () => run((e) => e.scavenge())),
        _ActionButton('Fetch pod', () => run((e) => e.fetchPod())),
        if (sleeping.isNotEmpty)
          _ActionButton('Wake', () => run((e) => e.wake(sleeping.first.crewId!))),
        _ActionButton('Build greenhouse', () => run((e) => e.build('greenhouse'))),
        _ActionButton('Build converter', () => run((e) => e.build('biofuel_converter'))),
        _ActionButton('Build beacon', () => run((e) => e.build('beacon'))),
        if (sick.isNotEmpty)
          _ActionButton('Treat', () => run((e) => e.treat(sick.first.id))),
        _ActionButton('Synthesize', () => run((e) => e.synthesize())),
        // Pacing: skip forward while orders hold, stopping on anything notable.
        _ActionButton('Advance 5 days', () {
          final digest = controller.advanceDays(5);
          final msg = digest.stopReason != null
              ? 'Stopped after day ${digest.toDay}: ${digest.stopReason}.'
              : 'Advanced to day ${digest.toDay}.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1600)),
          );
        }),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ActionButton(this.label, this.onPressed);
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(shape: const RoundedRectangleBorder()),
        child: Text(label),
      );
}

class _BottomBar extends StatelessWidget {
  final GameController controller;
  const _BottomBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: e.canUndo ? controller.undo : null,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder()),
                child: const Text('Undo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  final digest = controller.endDay();
                  final msg = digest.lines.isEmpty
                      ? 'A quiet day.'
                      : digest.lines.take(3).join('  |  ');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1800)),
                  );
                },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder()),
                child: const Text('End day', style: TextStyle(letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndingView extends StatelessWidget {
  final GameController controller;
  const _EndingView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final e = controller.engine;
    final outcome = e.finalOutcome ?? e.endingOutcome();
    final ending = e.finalEnding ?? outcome.ending;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('The end')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(endingText(ending), style: TextStyle(color: scheme.onSurface, height: 1.5)),
              const SizedBox(height: 20),
              // The count - the whole emotional payload, shown plainly.
              Text(
                endingCountLine(ending, woke: outcome.woke, saved: outcome.saved),
                style: TextStyle(color: scheme.primary, fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 20),
              Text('The memorial holds ${e.state.memorial.length} names.',
                  style: TextStyle(color: scheme.onSurface.withOpacity(0.7))),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: const RoundedRectangleBorder()),
                child: const Text('Back to title'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary, letterSpacing: 3, fontSize: 12)),
      );
}
