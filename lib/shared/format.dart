/// Number and date formatting, in English, without pulling in `intl` for the
/// handful of shapes the app needs.
abstract final class Format {
  /// `12345` → `12,345`.
  static String integer(num value) {
    final digits = value.round().abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// One decimal under 100, none above: `3.4`, `112`.
  static String decimal(double value) =>
      value < 100 ? value.toStringAsFixed(1) : integer(value);

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// `Friday, 31 October`.
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

  /// `Fri`.
  static String shortWeekday(DateTime date) =>
      _weekdays[date.weekday - 1].substring(0, 3);

  /// `M`, `T`, `W`…: the single letter over a day in a week strip.
  static String weekdayLetter(DateTime date) =>
      _weekdays[date.weekday - 1].substring(0, 1);

  /// `Today`, `Yesterday`, or `Thursday, 29 October`.
  static String relativeDay(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    // Calendar days counted in UTC, so a day that changes the clocks (23 or
    // 25 hours long) still counts as one.
    final day = DateTime.utc(date.year, date.month, date.day);
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    final difference = todayStart.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return longDate(date);
  }
}

/// Whether two moments fall on the same local calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
