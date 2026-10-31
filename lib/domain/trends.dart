/// Which way a measure is going.
enum TrendDirection { up, down, steady }

/// One measure's recent average against its longer one, the way Fitness
/// compares the last 90 days with the last 365.
class Trend {
  const Trend({
    required this.title,
    required this.unit,
    required this.recent,
    required this.year,
    this.higherIsBetter = true,
  });

  final String title;
  final String unit;

  /// Averages per day: the last 90 days, and the last 365.
  final double recent;
  final double year;

  /// For weight while losing, lower is the good direction.
  final bool higherIsBetter;

  /// Within 3% either way is steady.
  TrendDirection get direction {
    if (year <= 0) {
      return recent > 0 ? TrendDirection.up : TrendDirection.steady;
    }
    final change = (recent - year) / year;
    if (change.abs() < 0.03) return TrendDirection.steady;
    return change > 0 ? TrendDirection.up : TrendDirection.down;
  }

  bool get good => switch (direction) {
    TrendDirection.steady => true,
    TrendDirection.up => higherIsBetter,
    TrendDirection.down => !higherIsBetter,
  };

  /// The average of [values] over the days that have any data, or 0.
  static double average(Iterable<double> values) {
    final present = values.where((v) => v > 0).toList();
    if (present.isEmpty) return 0;
    return present.reduce((a, b) => a + b) / present.length;
  }
}
