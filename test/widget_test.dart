import 'package:flutter_test/flutter_test.dart';
import 'package:halo/app/shell/halo_tab.dart';

import 'support/harness.dart';

void main() {
  testWidgets('shell shows Today and switches tabs', (tester) async {
    final harness = await Harness.create(tester);
    await tester.pumpWidget(harness.app);
    await tester.pump(const Duration(seconds: 1));

    for (final tab in HaloTab.values) {
      expect(find.text(tab.title), findsWidgets);
    }
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);

    await tester.tap(find.text('Sleep').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text('Last night, your schedule and smart alarm.'),
      findsOneWidget,
    );

    await harness.tearDown(tester);
  });
}
