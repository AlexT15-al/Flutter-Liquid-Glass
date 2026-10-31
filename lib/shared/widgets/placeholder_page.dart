import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_metrics.dart';
import 'halo_page.dart';
import 'large_title.dart';

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

/// The body of a tab whose page has not been built yet.
///
/// A real scroll view with the real insets, so the bar's edge fade and the
/// clearance above the tab bar are already what the finished page will get.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    super.key,
    required this.titleController,
    required this.icon,
    required this.title,
    required this.message,
  });

  final GlassLargeTitleController titleController;
  final Widget icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: titleController.scrollController,
      slivers: [
        ...largeTitleSlivers(
          context,
          title: title,
          controller: titleController,
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              40,
              0,
              40,
              HaloMetrics.bottomInset(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 56,
                    color: HaloColors.tertiaryLabelOf(context),
                  ),
                  child: icon,
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Next',
                  style: TextStyle(
                    color: HaloColors.labelOf(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: HaloColors.secondaryLabelOf(context),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
