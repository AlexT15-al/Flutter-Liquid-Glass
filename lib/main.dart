import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app/halo_app.dart';
import 'app/theme/halo_glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only: every screen is laid out for a phone held upright, and a
  // live workout must not rotate when the phone moves in a pocket or armband.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Draw behind the system bars; `TransparentSystemBars` keeps them clear.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Async disk-to-RAM shader preload. No GPU work, so the first frame is not
  // held back, and the first glass surface does not stall compiling.
  await LiquidGlassWidgets.initialize();

  runApp(
    LiquidGlassWidgets.wrap(
      // The iOS 27 material, premium in both appearances. Brightness is
      // resolved at each glass widget's own context, so the variants follow
      // the app's theme rather than the device's.
      theme: HaloGlass.theme,
      // No adaptive quality: it benchmarks the device on launch and can drop a
      // tier mid-session, which on chrome that is always visible reads as the
      // app degrading. Premium is the requirement.
      adaptiveQuality: false,
      child: const HaloApp(),
    ),
  );
}
