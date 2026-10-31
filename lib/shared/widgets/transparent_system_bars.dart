import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme/halo_glass.dart';

/// Makes Android's status bar and navigation bar fully transparent, with icons
/// that follow the app's brightness.
///
/// Android 15+ otherwise draws a contrast scrim behind both bars, and the
/// package's own status-bar styles hardcode an opaque black navigation bar. So
/// every page sets `GlassScaffold.statusBarStyle: GlassStatusBarStyle.none`
/// and wraps itself in this instead.
class TransparentSystemBars extends StatelessWidget {
  const TransparentSystemBars({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = HaloGlass.brightnessOf(context) == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        systemNavigationBarColor: const Color(0x00000000),
        systemNavigationBarDividerColor: const Color(0x00000000),
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: icons,
        systemNavigationBarIconBrightness: icons,
        // iOS reads the inverse convention on this one.
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: child,
    );
  }
}
