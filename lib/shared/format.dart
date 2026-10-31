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
}
