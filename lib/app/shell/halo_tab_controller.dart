import 'package:flutter/widgets.dart';

import 'halo_tab.dart';

/// The state of the app's permanent chrome.
///
/// It lives above the `Navigator` because the chrome does: the tab bar is drawn
/// once, in `CupertinoApp.builder`, and every route slides underneath it. No
/// page can own it, so the root page and the chrome both read it from here.
class HaloTabController extends ChangeNotifier {
  HaloTab _tab = HaloTab.today;
  bool _isSearching = false;
  bool _searchFieldFocused = false;
  String _query = '';

  HaloTab get tab => _tab;

  /// The search capsule is open.
  bool get isSearching => _isSearching;

  /// The search field has focus: distinct from [isSearching], which is true as
  /// soon as the capsule opens, before anything is typed.
  bool get searchFieldFocused => _searchFieldFocused;

  /// What is in the search field. Search runs over local data, so every
  /// keystroke can answer; there is nothing to throttle.
  String get query => _query;

  set tab(HaloTab value) {
    if (_tab == value) return;
    _tab = value;
    _isSearching = false;
    _searchFieldFocused = false;
    notifyListeners();
  }

  set isSearching(bool value) {
    if (_isSearching == value) return;
    _isSearching = value;
    if (!value) {
      _searchFieldFocused = false;
      // Closing search discards the query, the way dismissing a search screen
      // does on iOS.
      _query = '';
    }
    notifyListeners();
  }

  set searchFieldFocused(bool value) {
    if (_searchFieldFocused == value) return;
    _searchFieldFocused = value;
    notifyListeners();
  }

  set query(String value) {
    if (_query == value) return;
    _query = value;
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
