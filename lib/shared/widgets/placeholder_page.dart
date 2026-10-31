import 'package:flutter/cupertino.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import 'halo_page.dart';

/// A pushed screen that has not been built yet.
///
/// Real routes from the first day, so the navigation morph, the back gesture
/// and the tab bar staying put can all be checked before any page exists.
/// Each one is replaced as its page lands.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  static Route<void> route(String title) =>
      CupertinoPageRoute<void>(builder: (_) => PlaceholderPage(title: title));

  @override
  Widget build(BuildContext context) {
    return HaloPage(
      appBar: haloBar(context, title: title),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: HaloMetrics.bottomInset(context)),
          child: Text(
            'Coming soon',
            style: TextStyle(
              color: HaloColors.tertiaryLabelOf(context),
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}
