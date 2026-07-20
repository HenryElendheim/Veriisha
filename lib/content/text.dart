import '../models/enums.dart';

// The little text the game does carry: the endings, and a helper for the one
// line that holds the whole emotional payload - the count.

/// The plain number line the ending screen must show, unburied.
/// woke - how many you personally carried home and woke.
/// saved - how many the beacon lifted off, or how many stayed frozen.
String endingCountLine(Ending ending, {required int woke, required int saved}) {
  final wokeWord = _spellSmall(woke);
  final savedWord = _spellSmall(saved);
  switch (ending) {
    case Ending.rescue:
      return 'You woke $wokeWord. The beacon saved $savedWord.';
    case Ending.colonyUnderstanding:
    case Ending.colonyTruce:
      return 'You woke $wokeWord. $savedWord stayed frozen.';
    case Ending.death:
      return 'You woke $wokeWord. The rest stayed frozen.';
  }
}

/// A short epilogue per ending. No subtitles, no ceremony - just the shade.
String endingText(Ending ending) {
  switch (ending) {
    case Ending.rescue:
      return 'A ship came. Every pod the clock had not reached was lifted off '
          'the planet. You saved more than any amount of hauling ever could.';
    case Ending.colonyUnderstanding:
      return 'Nobody was coming. You fed them early, while they still had '
          'strength, and spring arrived on an understanding already built.';
    case Ending.colonyTruce:
      return 'Nobody was coming. You fed them only when they were desperate at '
          'your wall. Harmony came anyway, but as a truce, not a friendship.';
    case Ending.death:
      return 'The cold took the last of you. The wreck went on emptying without '
          'anyone left to read the names.';
  }
}

// Spell small numbers as words, the way the design writes the count line. Larger
// numbers fall back to digits.
const List<String> _smallWords = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
];

String _spellSmall(int n) {
  if (n >= 0 && n < _smallWords.length) return _smallWords[n];
  return '$n';
}
