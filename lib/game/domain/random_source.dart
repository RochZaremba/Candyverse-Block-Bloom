/// Stateful random boundary. A snapshot must be persisted with the run.
abstract interface class RandomSource {
  int get state;
  int nextInt(int upperBound);
}

/// Park–Miller minimal standard RNG, version 1. Integer operations are exact
/// on Dart VM and JS (the largest product is below 2^53).
class SeededRandom implements RandomSource {
  SeededRandom(int seed) : _state = seed % (modulus - 1) + 1;

  SeededRandom.fromState(int state) : _state = state {
    if (state < 1 || state >= modulus) {
      throw ArgumentError.value(state, 'state', 'Invalid RNG snapshot.');
    }
  }

  static const modulus = 2147483647;
  int _state;
  @override
  int get state => _state;

  @override
  int nextInt(int upperBound) {
    if (upperBound < 1 || upperBound > modulus - 1) {
      throw RangeError.range(upperBound, 1, modulus - 1, 'upperBound');
    }
    // Rejection sampling avoids modulo bias.
    final limit = (modulus - 1) ~/ upperBound * upperBound;
    int value;
    do {
      _state = _state * 16807 % modulus;
      value = _state - 1;
    } while (value >= limit);
    return value % upperBound;
  }
}
