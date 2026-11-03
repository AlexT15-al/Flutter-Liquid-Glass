import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/halo_metrics.dart';
import '../../../platform/live_activity.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_page.dart';

/// A temporary check of what keeps the live workout out of Samsung's Now
/// Bar: test notifications, each one change from the next.
class NowBarTestPage extends StatefulWidget {
  const NowBarTestPage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const NowBarTestPage());

  @override
  State<NowBarTestPage> createState() => _NowBarTestPageState();
}

class _NowBarTestPageState extends State<NowBarTestPage> {
  String? _promoted;
  int _shown = 0;

  static const _tests = [
    (1, 'Like the navigation app', 'Category navigation, no buttons'),
    (2, 'As a workout', 'Category workout, no buttons'),
    (3, 'As a stopwatch', 'Category stopwatch, no buttons'),
    (4, 'Halo’s way', 'Workout, Pause button, running time'),
    (
      5,
      'Navigation app’s code',
      'Its own code, NotificationCompat, from a running service',
    ),
    (6, 'Test 1 from a service', 'Test 1, posted from a running service'),
  ];

  Future<void> _show(int variant) async {
    HapticFeedback.selectionClick();
    final promoted = await const LiveActivity().test(variant);
    if (!mounted) return;
    setState(() {
      _promoted = promoted;
      _shown = variant;
    });
  }

  @override
  void dispose() {
    const LiveActivity().test(0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: 'Now Bar Test'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          HaloMetrics.cardPadding,
          HaloMetrics.topInset(context),
          HaloMetrics.cardPadding,
          HaloMetrics.bottomInset(context),
        ),
        children: [
          const GroupCaption(
            'Tap one, lock the phone, and see whether it is in the Now Bar. '
            'Each replaces the one before. Tell Claude which ones show.',
            footer: true,
          ),
          const SizedBox(height: 8),
          GroupedCard(
            children: [
              for (final (variant, title, _) in _tests)
                GroupedRow(
                  title: '$variant. $title',
                  value: _shown == variant ? 'Shown' : null,
                  onTap: () => _show(variant),
                ),
            ],
          ),
          GroupCaption(
            [for (final (v, _, d) in _tests) '$v: $d'].join('\n'),
            footer: true,
          ),
          const SizedBox(height: HaloMetrics.sectionTopGap),
          GroupedCard(
            children: [
              GroupedRow(
                title: 'Promoted Notifications',
                value: _promoted ?? '—',
              ),
              GroupedRow(
                title: 'Remove Test',
                destructive: true,
                onTap: () => _show(0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
