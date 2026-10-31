import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/database/app_database.dart';
import 'package:halo/data/workouts/workout_repository.dart';
import 'package:halo/data/workouts/workout_session.dart';
import 'package:halo/domain/body_profile.dart';
import 'package:halo/domain/workout.dart';
import 'package:halo/features/workout/live/workout_controller.dart';
import 'package:halo/features/workout/live/workout_live_activity.dart';
import 'package:halo/platform/haptics.dart';
import 'package:halo/platform/live_activity.dart';

class _FakeLive extends LiveActivity {
  final calls = <(String, LiveActivityState?)>[];
  void Function(String)? onEvent;

  @override
  void listen(void Function(String event) onEvent) => this.onEvent = onEvent;

  @override
  Future<void> start(LiveActivityState state) async =>
      calls.add(('start', state));

  @override
  Future<void> update(LiveActivityState state) async =>
      calls.add(('update', state));

  @override
  Future<void> end() async => calls.add(('end', null));

  List<String> get names => [for (final c in calls) c.$1];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late _FakeLive live;
  late WorkoutController controller;
  late StreamController<bool> enabled;
  late WorkoutLiveActivity binding;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    now = DateTime(2026, 10, 31, 9);
    live = _FakeLive();
    enabled = StreamController<bool>();
    controller = WorkoutController(
      repository: WorkoutRepository(
        AppDatabase.forExecutor(DatabaseConnection(NativeDatabase.memory())),
      ),
      stepCounter: ValueNotifier<int?>(null),
      clock: () => now,
    );
    binding = WorkoutLiveActivity(
      controller: controller,
      enabled: enabled.stream,
      platform: live,
      clock: () => now,
    )..attach();
  });

  tearDown(() {
    binding.dispose();
    enabled.close();
  });

  Future<WorkoutSession> run(WorkoutType type) async {
    await controller.start(
      type: type,
      goal: const WorkoutGoal(WorkoutGoalKind.time, 30),
      profile: const BodyProfile(heightCm: 180, weightKg: 80),
    );
    return controller.session!;
  }

  test('appears after the countdown, follows the workout, then goes', () async {
    final session = await run(WorkoutType.strength);
    expect(live.calls, isEmpty);

    controller.skipCountdown();
    expect(live.names, ['start']);
    expect(live.calls.single.$2!.title, 'Strength');

    // Numbers changed, but too soon after the last update.
    now = now.add(const Duration(seconds: 2));
    session.notifyListeners();
    expect(live.names, ['start']);

    now = now.add(const Duration(minutes: 1));
    session.notifyListeners();
    expect(live.names, ['start', 'update']);
    expect(live.calls.last.$2!.progress, closeTo(1 / 30, 0.01));

    // Pausing shows at once.
    session.pause();
    expect(live.names.last, 'update');
    expect(live.calls.last.$2!.paused, isTrue);

    session.end();
    expect(live.names.last, 'end');
    controller.discard();
  });

  test('pause and resume from the notification reach the workout', () async {
    final session = await run(WorkoutType.indoorRun);
    controller.skipCountdown();
    live.onEvent!('pause');
    expect(session.phase, SessionPhase.paused);
    live.onEvent!('resume');
    expect(session.phase, SessionPhase.running);
    controller.minimize();
    live.onEvent!('open');
    expect(controller.expanded, isTrue);
    controller.discard();
    expect(live.names.last, 'end');
  });

  test('turned off, an indoor workout shows nothing', () async {
    enabled.add(false);
    await Future<void>.delayed(Duration.zero);
    await run(WorkoutType.yoga);
    controller.skipCountdown();
    expect(live.calls, isEmpty);
    controller.discard();
  });

  test('turned on mid-workout, it starts over', () async {
    enabled.add(false);
    await Future<void>.delayed(Duration.zero);
    await run(WorkoutType.hiit);
    controller.skipCountdown();
    enabled.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(live.names, ['start']);
    expect(live.calls.single.$2!.quiet, isFalse);
    controller.discard();
  });

  group('haptics gate', () {
    late List<String> sent;
    late HapticsGate gate;

    setUp(() {
      sent = [];
      gate = HapticsGate(_Recorder(sent));
    });

    tearDown(() => Haptics.enabled = true);

    ByteData call(String method) => const JSONMethodCodec().encodeMethodCall(
      MethodCall(method, 'HapticFeedbackType.lightImpact'),
    );

    test('passes haptics while on', () async {
      await gate.send('flutter/platform', call('HapticFeedback.vibrate'));
      expect(sent, ['HapticFeedback.vibrate']);
    });

    test('drops haptics while off, and only haptics', () async {
      Haptics.enabled = false;
      final reply = await gate.send(
        'flutter/platform',
        call('HapticFeedback.vibrate'),
      );
      expect(const JSONMethodCodec().decodeEnvelope(reply!), isNull);
      await gate.send('flutter/platform', call('SystemSound.play'));
      expect(sent, ['SystemSound.play']);
    });
  });
}

class _Recorder implements BinaryMessenger {
  _Recorder(this.sent);

  final List<String> sent;

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    sent.add(const JSONMethodCodec().decodeMethodCall(message).method);
    return Future.value(const JSONMethodCodec().encodeSuccessEnvelope(null));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
