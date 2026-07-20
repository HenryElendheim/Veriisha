// One seeded random stream for the whole run. Every roll - event choice, forage
// return, treatment success, injury, winter length - draws from this. The state
// is a single int stored in the save, so a run replays exactly from its seed.
//
// It is never a global. The engine owns one instance and passes it explicitly to
// anything that needs a roll. That is what keeps determinism honest.

/// A small, fast, fully deterministic generator (SplitMix64). Its whole state is
/// one 64-bit int, which serialises trivially.
class SeededRng {
  int _state;

  SeededRng(int seed) : _state = seed & _mask64;

  /// Rebuild an RNG mid-stream from a serialised state (used on save load).
  SeededRng.fromState(int state) : _state = state & _mask64;

  int get state => _state;

  static const int _mask64 = 0xFFFFFFFFFFFFFFFF;

  int _next() {
    // SplitMix64. All arithmetic masked back to 64 bits so it behaves the same
    // everywhere and the sequence is reproducible.
    _state = (_state + 0x9E3779B97F4A7C15) & _mask64;
    var z = _state;
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & _mask64;
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & _mask64;
    return (z ^ (z >> 31)) & _mask64;
  }

  /// A double in [0, 1).
  double nextDouble() {
    // Take the top 53 bits so the result lands in the exact-integer range of a
    // double, then scale into [0, 1).
    final bits = _next() >> 11;
    return bits / (1 << 53);
  }

  /// An int in [0, max).
  int nextInt(int max) {
    if (max <= 0) return 0;
    return (nextDouble() * max).floor();
  }

  /// An int in [min, max] inclusive.
  int nextRange(int min, int max) {
    if (max <= min) return min;
    return min + nextInt(max - min + 1);
  }

  /// True with the given probability.
  bool chance(double probability) => nextDouble() < probability;

  /// Pick one element from a non-empty list.
  T pick<T>(List<T> items) => items[nextInt(items.length)];
}
