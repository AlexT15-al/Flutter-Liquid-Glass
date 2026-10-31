import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../domain/app_theme_mode.dart';
import '../features/workout/live/workout_controller.dart';
import 'halo_scope.dart';
import 'shell/halo_chrome.dart';
import 'shell/halo_tab_controller.dart';
import 'shell/halo_tabs_root.dart';
import 'shell/modal_route_observer.dart';
import 'theme/halo_colors.dart';
import 'theme/halo_metrics.dart';

/// The root of the app.
///
/// `CupertinoApp` rather than `MaterialApp`: the glass package is Material-free,
/// and under `MaterialApp` every `Text` would need a `Material` ancestor.
///
/// Stateful only to own what has to outlive every route: the tab controller,
/// because the chrome it drives sits above them all, and the navigator key.
class HaloApp extends StatefulWidget {
  const HaloApp({super.key, this.initialThemeMode = AppThemeMode.system});

  /// The stored appearance, read before the first frame so the app never
  /// opens in the other one and then flips.
  final AppThemeMode initialThemeMode;

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

  /// Created once; a stream made in `build` would resubscribe on every
  /// rebuild.
  Stream<AppThemeMode>? _themeMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeMode ??= HaloScope.preferencesOf(context).watchThemeMode();
  }

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
      child: ModalPresentationScope(
        modalOnTop: _routes.modalOnTop,
        // Tells every page to leave room for the workout pill above the bar.
        child: ChromeAccessoryScope(
          showing: WorkoutScope.of(context).session != null,
          child: StreamBuilder<AppThemeMode>(
            stream: _themeMode,
            initialData: widget.initialThemeMode,
            builder: (context, snapshot) =>
                _buildApp(snapshot.data ?? widget.initialThemeMode),
          ),
        ),
      ),
    );
  }

  Widget _buildApp(AppThemeMode themeMode) {
    return CupertinoApp(
      title: 'Halo',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      navigatorObservers: [_routes],
      // Null brightness follows the system, which is what System means.
      // Everything downstream resolves against this: the colour tokens are
      // dynamic, and the glass picks its variant from the Cupertino pin.
      theme: CupertinoThemeData(
        brightness: themeMode.brightness,
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
    );
  }
}
