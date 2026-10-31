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

/// A night entered by hand: when you went to bed and when you got up.
Future<void> showAddSleepSheet(BuildContext context) async {
  final repository = SleepScope.read(context).repository;
  final range = await showHaloSheet<(DateTime, DateTime)>(
    context,
    builder: (context, scroll) => _AddSleepSheet(controller: scroll),
  );
  if (range != null) await repository.addManual(range.$1, range.$2);
}

class _AddSleepSheet extends StatefulWidget {
  const _AddSleepSheet({required this.controller});

  final ScrollController controller;

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  // Last night, by default: eleven to seven.
  late DateTime _end = () {
    final now = DateTime.now();
    final seven = DateTime(now.year, now.month, now.day, 7);
    return seven.isAfter(now) ? seven.subtract(const Duration(days: 1)) : seven;
  }();
  late DateTime _start = _end.subtract(const Duration(hours: 8));

  Duration get _length => _end.difference(_start);

  bool get _valid =>
      _length >= const Duration(minutes: 15) &&
      _length <= const Duration(hours: 16) &&
      !_end.isAfter(DateTime.now());

  String _describe(DateTime t) =>
      '${Format.relativeDay(t)}, ${Format.timeOfDay(t)}';

  @override
  Widget build(BuildContext context) {
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Add Sleep',
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
                  maximumDate: DateTime.now(),
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
                  maximumDate: DateTime.now(),
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
