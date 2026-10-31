import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_sheet.dart';
import '../sleep_controller.dart';

/// Bedtime and wake-up time, each on a wheel that opens under its row.
Future<void> showScheduleSheet(
  BuildContext context,
  SleepSchedule current,
) async {
  final preferences = HaloScope.preferencesOf(context);
  final next = await showHaloSheet<SleepSchedule>(
    context,
    builder: (context, scroll) =>
        _ScheduleSheet(controller: scroll, initial: current),
  );
  if (next != null) await preferences.setSleepSchedule(next);
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.controller, required this.initial});

  final ScrollController controller;
  final SleepSchedule initial;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late SleepSchedule _schedule = widget.initial;

  static DateTime _at(int minutes) =>
      DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);

  Widget _wheel(int minutes, ValueChanged<int> onChanged) => RowWheel(
    child: CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      minuteInterval: 5,
      initialDateTime: _at(minutes - minutes % 5),
      onDateTimeChanged: (t) => onChanged(t.hour * 60 + t.minute),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Sleep Schedule',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(_schedule);
          },
        ),
      ),
      children: [
        GroupedCard(
          children: [
            GroupedRow(
              title: 'Bedtime',
              value: Format.minutesOfDay(_schedule.bedtimeMinutes),
              editor: _wheel(
                _schedule.bedtimeMinutes,
                (m) => setState(
                  () => _schedule = _schedule.copyWith(bedtimeMinutes: m),
                ),
              ),
            ),
            GroupedRow(
              title: 'Wake Up',
              value: Format.minutesOfDay(_schedule.wakeMinutes),
              editor: _wheel(
                _schedule.wakeMinutes,
                (m) => setState(
                  () => _schedule = _schedule.copyWith(wakeMinutes: m),
                ),
              ),
            ),
          ],
        ),
        GroupCaption(
          'A sleep goal of ${Format.durationWords(_schedule.goal)}. Nights are '
          'scored against it, and against going to bed on time.',
          footer: true,
        ),
      ],
    );
  }
}

/// Add Sleep: starts from the times the phone measured last night, if it
/// did, so a night measured 03:00–06:00 that really ran to 09:00 is one
/// change away; otherwise from eleven to seven.
Future<void> showAddSleepSheet(BuildContext context) async {
  final controller = SleepScope.read(context);
  final detected = controller.detected;
  final range = await showSleepTimesSheet(
    context,
    title: 'Add Sleep',
    start: detected?.start,
    end: detected?.end,
  );
  if (range == null) return;
  if (detected != null) {
    await controller.record(from: range.$1, to: range.$2);
  } else {
    await controller.repository.addManual(range.$1, range.$2);
  }
}

/// When a night began and ended, on two wheels.
Future<(DateTime, DateTime)?> showSleepTimesSheet(
  BuildContext context, {
  required String title,
  DateTime? start,
  DateTime? end,
}) => showHaloSheet<(DateTime, DateTime)>(
  context,
  builder: (context, scroll) => _AddSleepSheet(
    controller: scroll,
    title: title,
    initialStart: start,
    initialEnd: end,
  ),
);

class _AddSleepSheet extends StatefulWidget {
  const _AddSleepSheet({
    required this.controller,
    required this.title,
    this.initialStart,
    this.initialEnd,
  });

  final ScrollController controller;
  final String title;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  // Last night, by default: eleven to seven.
  /// To the nearest five minutes: the wheels step in fives.
  static DateTime _round(DateTime t) {
    final minutes = (t.minute + t.second / 60) / 5;
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
    ).add(Duration(minutes: minutes.round() * 5));
  }

  /// The latest a night can end: now, on the wheels' five-minute steps.
  late final DateTime _latest = () {
    final now = DateTime.now();
    final r = _round(now);
    return r.isBefore(now) ? r.add(const Duration(minutes: 5)) : r;
  }();

  late DateTime _end = _round(
    widget.initialEnd ??
        () {
          final now = DateTime.now();
          final seven = DateTime(now.year, now.month, now.day, 7);
          return seven.isAfter(now)
              ? seven.subtract(const Duration(days: 1))
              : seven;
        }(),
  );
  late DateTime _start = _round(
    widget.initialStart ?? _end.subtract(const Duration(hours: 8)),
  );

  Duration get _length => _end.difference(_start);

  bool get _valid =>
      _length >= const Duration(minutes: 15) &&
      _length <= const Duration(hours: 16) &&
      !_end.isAfter(_latest);

  String _describe(DateTime t) =>
      '${Format.relativeDay(t)}, ${Format.timeOfDay(t)}';

  @override
  Widget build(BuildContext context) {
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: widget.title,
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: _valid
              ? () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop((_start, _end));
                }
              : null,
        ),
      ),
      children: [
        GroupedCard(
          children: [
            GroupedRow(
              title: 'In Bed',
              value: _describe(_start),
              editor: RowWheel(
                child: CupertinoDatePicker(
                  use24hFormat: true,
                  minuteInterval: 5,
                  initialDateTime: _start,
                  maximumDate: _latest,
                  onDateTimeChanged: (t) => setState(() => _start = t),
                ),
              ),
            ),
            GroupedRow(
              title: 'Out of Bed',
              value: _describe(_end),
              editor: RowWheel(
                child: CupertinoDatePicker(
                  use24hFormat: true,
                  minuteInterval: 5,
                  initialDateTime: _end,
                  maximumDate: _latest,
                  onDateTimeChanged: (t) => setState(() => _end = t),
                ),
              ),
            ),
          ],
        ),
        GroupCaption(
          _valid
              ? '${Format.durationWords(_length)} in bed.'
              : 'A night is between 15 minutes and 16 hours, and already over.',
          footer: true,
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}
