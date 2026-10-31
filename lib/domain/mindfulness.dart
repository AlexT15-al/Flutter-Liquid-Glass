/// What a mindful session was.
enum MindfulKind {
  breathe('Breathe'),
  meditate('Meditate');

  const MindfulKind(this.title);

  final String title;

  static MindfulKind byName(String name) =>
      MindfulKind.values.asNameMap()[name] ?? meditate;
}

/// Minutes spent breathing or meditating.
class MindfulSession {
  const MindfulSession({
    this.id,
    required this.start,
    required this.length,
    required this.kind,
  });

  final int? id;
  final DateTime start;
  final Duration length;
  final MindfulKind kind;
}

/// How someone felt, State of Mind style: a place on a scale from very
/// unpleasant to very pleasant, the feelings that describe it, and what it
/// was about.
class MoodEntry {
  const MoodEntry({
    this.id,
    required this.time,
    required this.valence,
    this.feelings = const {},
    this.contexts = const {},
  });

  final int? id;
  final DateTime time;

  /// 0 very unpleasant … 6 very pleasant.
  final int valence;
  final Set<String> feelings;
  final Set<String> contexts;

  String get label => Mood.labels[valence.clamp(0, 6)];
}

abstract final class Mood {
  static const labels = [
    'Very Unpleasant',
    'Unpleasant',
    'Slightly Unpleasant',
    'Neutral',
    'Slightly Pleasant',
    'Pleasant',
    'Very Pleasant',
  ];

  static const unpleasant = [
    'Stressed',
    'Anxious',
    'Tired',
    'Sad',
    'Frustrated',
    'Overwhelmed',
    'Lonely',
    'Irritated',
    'Worried',
    'Bored',
  ];

  static const neutral = [
    'Calm',
    'Content',
    'Indifferent',
    'Peaceful',
    'Tired',
  ];

  static const pleasant = [
    'Happy',
    'Grateful',
    'Calm',
    'Confident',
    'Excited',
    'Hopeful',
    'Proud',
    'Relieved',
    'Joyful',
    'Energised',
  ];

  /// Feelings that fit where on the scale someone is.
  static List<String> feelingsFor(int valence) => switch (valence) {
    < 3 => unpleasant,
    3 => neutral,
    _ => pleasant,
  };

  static const contexts = [
    'Work',
    'Family',
    'Friends',
    'Partner',
    'Health',
    'Fitness',
    'Sleep',
    'Food',
    'Money',
    'Weather',
    'Studies',
    'Hobbies',
  ];
}

/// Breathing at a calm pace: in for [inhale], out for [exhale].
///
/// Slow breathing, around six breaths a minute with a longer out-breath, is
/// what most breathing exercises settle on: it is the pace that most
/// steadies heart rate and calms the body.
class BreathPattern {
  const BreathPattern({
    this.inhale = const Duration(seconds: 4),
    this.exhale = const Duration(seconds: 6),
  });

  final Duration inhale;
  final Duration exhale;

  Duration get breath => inhale + exhale;

  /// Breaths in [length], rounded down.
  int breathsIn(Duration length) =>
      length.inMilliseconds ~/ breath.inMilliseconds;

  /// Where in a breath [elapsed] falls: whether breathing in, and how full
  /// the lungs are, from 0 to 1.
  (bool, double) at(Duration elapsed) {
    final t = elapsed.inMilliseconds % breath.inMilliseconds;
    if (t < inhale.inMilliseconds) {
      return (true, t / inhale.inMilliseconds);
    }
    return (false, 1 - (t - inhale.inMilliseconds) / exhale.inMilliseconds);
  }
}
