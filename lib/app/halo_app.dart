import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'shell/halo_chrome.dart';
import 'shell/halo_tab_controller.dart';
import 'shell/halo_tabs_root.dart';
import 'shell/modal_route_observer.dart';
import 'theme/halo_colors.dart';

/// The root of the app.
///
/// `CupertinoApp` rather than `MaterialApp`: the glass package is Material-free,
/// and under `MaterialApp` every `Text` would need a `Material` ancestor.
///
/// Stateful only to own what has to outlive every route: the tab controller,
/// because the chrome it drives sits above them all, and the navigator key.
class HaloApp extends StatefulWidget {
  const HaloApp({super.key});

  @override
  State<HaloApp> createState() => _HaloAppState();
}

class _HaloAppState extends State<HaloApp> {
  final HaloTabController _tabs = HaloTabController();

  /// The chrome is built in `builder:`, above the Navigator, so this key is its
  /// only handle on the Navigator: tapping a tab pops back to the root.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Tells the chrome when a sheet or dialog is up, so the tab bar can step
  /// aside for it.
  final ModalRouteObserver _routes = ModalRouteObserver();

  @override
  void dispose() {
    _routes.modalOnTop.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Above the CupertinoApp so both sides of the Navigator reach it.
    return HaloTabScope(
      controller: _tabs,
      child: CupertinoApp(
        title: 'Halo',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        navigatorObservers: [_routes],
        // Null brightness follows the system. A stored Light / Dark / System
        // preference arrives with Settings.
        theme: const CupertinoThemeData(
          primaryColor: HaloColors.accent,
          scaffoldBackgroundColor: HaloColors.background,
        ),
        // The nesting order matters. `GlassNavigationShell` must wrap the
        // Navigator, and there must be exactly one. The chrome goes outside it
        // so the full-screen layers it will host later (the live workout, the
        // sleep session) paint above the shell's hoisted bar buttons too.
        builder: (context, child) => HaloChrome(
          navigatorKey: _navigatorKey,
          modalOnTop: _routes.modalOnTop,
          child: GlassNavigationShell(child: child!),
        ),
        home: const HaloTabsRoot(),
      ),
    );
  }
}
