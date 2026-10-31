import 'package:flutter/widgets.dart';

import 'halo_tab.dart';

/// The state of the app's permanent chrome.
///
/// It lives above the `Navigator` because the chrome does: the tab bar is drawn
/// once, in `CupertinoApp.builder`, and every route slides underneath it. No
/// page can own it, so the root page and the chrome both read it from here.
class HaloTabController extends ChangeNotifier {
  HaloTab _tab = HaloTab.today;

  HaloTab get tab => _tab;

  set tab(HaloTab value) {
    if (_tab == value) return;
    _tab = value;
    notifyListeners();
  }
}

/// Hands [HaloTabController] to both sides of the Navigator: the chrome in
/// `builder:` and the tab bodies in `home:`.
class HaloTabScope extends InheritedNotifier<HaloTabController> {
  const HaloTabScope({
    super.key,
    required HaloTabController controller,
    required super.child,
  }) : super(notifier: controller);

  static HaloTabController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HaloTabScope>();
    assert(scope != null, 'No HaloTabScope found above this widget.');
    return scope!.notifier!;
  }

  /// Reads the controller without registering a dependency, for callbacks
  /// that run outside a build.
  static HaloTabController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<HaloTabScope>();
    assert(scope != null, 'No HaloTabScope found above this widget.');
    return scope!.notifier!;
  }
}
