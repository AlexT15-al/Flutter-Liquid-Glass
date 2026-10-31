import 'package:flutter_test/flutter_test.dart';
import 'package:halo/app/halo_app.dart';
import 'package:halo/app/shell/halo_tab.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('shell shows the four tabs and switches between them',
      (tester) async {
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        theme: const GlassThemeData.ios27(),
        child: const HaloApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (final tab in HaloTab.values) {
      expect(find.text(tab.title), findsWidgets);
    }

    await tester.tap(find.text('Sleep').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Last night, your schedule and smart alarm.'),
        findsOneWidget);
  });
}
