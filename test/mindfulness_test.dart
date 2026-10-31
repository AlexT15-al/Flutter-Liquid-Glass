import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/mindfulness/mindfulness_repository.dart';
import 'package:halo/data/transfer/data_transfer.dart';
import 'package:halo/domain/mindfulness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('a breath is four seconds in and six out', () {
    const p = BreathPattern();
    expect(p.breathsIn(const Duration(minutes: 1)), 6);
    final (inMid, fullness) = p.at(const Duration(seconds: 2));
    expect(inMid, isTrue);
    expect(fullness, closeTo(0.5, 0.001));
    final (outMid, emptying) = p.at(const Duration(seconds: 7));
    expect(outMid, isFalse);
    expect(emptying, closeTo(0.5, 0.001));
  });

  test('feelings follow the place on the scale', () {
    expect(Mood.feelingsFor(0), contains('Stressed'));
    expect(Mood.feelingsFor(3), contains('Calm'));
    expect(Mood.feelingsFor(6), contains('Grateful'));
    expect(MoodEntry(time: DateTime(2026), valence: 5).label, 'Pleasant');
  });

  test('sessions and moods are stored, and travel in the CSV export', () async {
    final a = AppDatabase.forExecutor(
      DatabaseConnection(NativeDatabase.memory()),
    );
    final repo = MindfulnessRepository(a);
    final t = DateTime(2026, 10, 31, 8);
    await repo.addSession(
      MindfulSession(
        start: t,
        length: const Duration(minutes: 3),
        kind: MindfulKind.breathe,
      ),
    );
    await repo.addMood(
      MoodEntry(
        time: t,
        valence: 5,
        feelings: const {'Calm', 'Grateful'},
        contexts: const {'Family'},
      ),
    );
    final moods = await repo.watchMoodsSince(DateTime(2026)).first;
    expect(moods.single.feelings, {'Calm', 'Grateful'});

    final b = AppDatabase.forExecutor(
      DatabaseConnection(NativeDatabase.memory()),
    );
    expect(await DataTransfer(b).import(await DataTransfer(a).export()), 2);
    final copied = await MindfulnessRepository(
      b,
    ).watchSessionsSince(DateTime(2026)).first;
    expect(copied.single.length, const Duration(minutes: 3));
    expect(copied.single.kind, MindfulKind.breathe);
  });
}
