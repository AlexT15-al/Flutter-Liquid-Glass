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

  /// A running clock: `4:07`, `12:34`, `1:02:09`.
  static String clock(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$ss';
    }
    return '$minutes:$ss';
  }

  /// Millilitres as litres, to the glass: `1.25`, `2`, `0.5`.
  static String litres(int ml) {
    final l = ml / 1000;
    if (ml % 1000 == 0) return '${l.round()}';
    if (ml % 100 == 0) return l.toStringAsFixed(1);
    return l.toStringAsFixed(2);
  }

  /// A time of day on the 24-hour clock: `07:05`, `23:41`.
  static String timeOfDay(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  /// Minutes after midnight as a time of day: `23:30`.
  static String minutesOfDay(int minutes) {
    final m = minutes % (24 * 60);
    return '${(m ~/ 60).toString().padLeft(2, '0')}:'
        '${(m % 60).toString().padLeft(2, '0')}';
  }

  /// A pace per kilometre: `5'42"`.
  static String pace(Duration perKm) {
    final minutes = perKm.inMinutes;
    final seconds = perKm.inSeconds % 60;
    return '$minutes\'${seconds.toString().padLeft(2, '0')}"';
  }

  /// A length of time in words: `45 min`, `1 hr 12 min`.
  static String durationWords(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  /// `October`.
  static String monthName(DateTime date) => _months[date.month - 1];

  /// `Thursday`.
  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

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
