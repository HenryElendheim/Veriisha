import 'package:flutter/material.dart';
import 'package:veriisha/veriisha.dart';
import '../game/game_controller.dart';
import 'site_select_screen.dart';

// Character and difficulty. The three engineers are identity, not advantage;
// difficulty is a plain choice, with hard stating plainly that it locks you to
// the three. Site comes next.

class NewRunScreen extends StatefulWidget {
  const NewRunScreen({super.key});

  @override
  State<NewRunScreen> createState() => _NewRunScreenState();
}

class _NewRunScreenState extends State<NewRunScreen> {
  final GameController _controller = GameController();
  String _characterId = kPresets.first.id;
  Difficulty _difficulty = Difficulty.normal;

  static const _difficultyBlurb = {
    Difficulty.easy: 'Luck tilted your way - kinder rolls and gentler events.',
    Difficulty.normal: 'The game exactly as intended.',
    Difficulty.hard: 'Everything tighter, luck against you. Only the three engineers.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Run')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _Header('Who do you wake as'),
            for (final p in kPresets)
              _ChoiceTile(
                label: p.name,
                note: 'Engineer',
                selected: _characterId == p.id,
                onTap: () => setState(() => _characterId = p.id),
              ),
            const SizedBox(height: 20),
            const _Header('Difficulty'),
            for (final d in Difficulty.values)
              _ChoiceTile(
                label: d.name[0].toUpperCase() + d.name.substring(1),
                note: _difficultyBlurb[d]!,
                selected: _difficulty == d,
                onTap: () => setState(() => _difficulty = d),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      // The primary action stays put at the bottom, always reachable.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SiteSelectScreen(
                  controller: _controller,
                  characterId: _characterId,
                  difficulty: _difficulty,
                ),
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text('Choose a site', style: TextStyle(letterSpacing: 2)),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 3,
            fontSize: 12,
          ),
        ),
      );
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final String note;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.label,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.primary.withOpacity(0.12) : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? scheme.primary : scheme.onSurface.withOpacity(0.15),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(label, style: const TextStyle(letterSpacing: 1)),
        subtitle: Text(note),
        trailing: selected ? Icon(Icons.check, color: scheme.primary) : null,
      ),
    );
  }
}
