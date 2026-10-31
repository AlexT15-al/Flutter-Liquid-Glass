import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../platform/home_widget.dart';
import 'activity_store.dart';

/// Keeps the home screen widget in step with today.
///
/// Sends the rings and steps when they change, at most once a minute, and
/// always as the app goes to the background, which is when the widget is
/// about to be looked at.
class WidgetSync {
  WidgetSync(this._activity, {this._widget = const HomeWidget()});

  final ActivityStore _activity;
  final HomeWidget _widget;

  static const _interval = Duration(minutes: 1);

  AppLifecycleListener? _lifecycle;
  Map<String, num>? _sent;
  DateTime? _sentAt;
  Timer? _pending;

  void attach() {
    _activity.addListener(_onChange);
    _lifecycle = AppLifecycleListener(onHide: () => _send(force: true));
    _send(force: true);
  }

  void dispose() {
    _activity.removeListener(_onChange);
    _lifecycle?.dispose();
    _pending?.cancel();
  }

  Map<String, num> _snapshot() {
    final today = _activity.today;
    final goals = _activity.goals;
    return {
      'move': today.activeKcal.round(),
      'moveGoal': goals.moveKcal,
      'exercise': today.exerciseMinutes.round(),
      'exerciseGoal': goals.exerciseMinutes,
      'activeHours': today.activeHours,
      'activeHoursGoal': goals.activeHours,
      'steps': today.steps,
      'stepsGoal': goals.steps,
    };
  }

  void _onChange() {
    final sentAt = _sentAt;
    if (sentAt == null || DateTime.now().difference(sentAt) >= _interval) {
      _send();
    } else {
      _pending ??= Timer(_interval - DateTime.now().difference(sentAt), () {
        _pending = null;
        _send();
      });
    }
  }

  void _send({bool force = false}) {
    final snapshot = _snapshot();
    final sent = _sent;
    if (!force &&
        sent != null &&
        sent.length == snapshot.length &&
        sent.entries.every((e) => snapshot[e.key] == e.value)) {
      return;
    }
    _sent = snapshot;
    _sentAt = DateTime.now();
    unawaited(_widget.update(snapshot));
  }
}
