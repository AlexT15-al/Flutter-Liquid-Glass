import 'package:flutter/cupertino.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../domain/sleep.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_page.dart';
import '../sleep_controller.dart';
import 'night_page.dart';

/// Every night, newest first, a month to a card.
class NightsPage extends StatefulWidget {
  const NightsPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const NightsPage());

  @override
  State<NightsPage> createState() => _NightsPageState();
}

class _NightsPageState extends State<NightsPage> {
  Stream<List<SleepNight>>? _nights;
  Stream<SleepSchedule>? _schedule;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nights ??= SleepScope.read(context).repository.watchNights(365);
    _schedule ??= HaloScope.preferencesOf(context).watchSleepSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'All Nights'),
      body: StreamBuilder<SleepSchedule>(
        stream: _schedule,
        initialData: const SleepSchedule(),
        builder: (context, schedule) => StreamBuilder<List<SleepNight>>(
          stream: _nights,
          initialData: const [],
          builder: (context, snapshot) {
            final nights = snapshot.data ?? const [];
            final months = <(int, int), List<SleepNight>>{};
            for (final night in nights) {
              final key = (night.morning.year, night.morning.month);
              (months[key] ??= []).add(night);
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                HaloMetrics.cardPadding,
                HaloMetrics.topInset(context),
                HaloMetrics.cardPadding,
                HaloMetrics.bottomInset(context),
              ),
              children: [
                if (nights.isEmpty)
                  const GroupCaption('No nights yet.', footer: true),
                for (final MapEntry(key: (year, _), value: list)
                    in months.entries) ...[
                  GroupCaption('${Format.monthName(list.first.morning)} $year'),
                  GroupedCard(
                    children: [
                      for (final night in list)
                        GroupedRow(
                          title: Format.relativeDay(night.morning),
                          value: night.hasStages && night.asleep.inMinutes == 0
                              ? 'No sleep'
                              : '${Format.durationWords(night.asleep)} · '
                                    '${SleepScore.of(night, schedule.data!).value}',
                          onTap: () => Navigator.of(
                            context,
                          ).push(NightPage.route(night)),
                        ),
                    ],
                  ),
                  const SizedBox(height: HaloMetrics.sectionTopGap),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
