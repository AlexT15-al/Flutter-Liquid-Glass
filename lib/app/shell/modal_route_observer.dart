import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// Knows whether a modal presentation (a sheet, a dialog, an action sheet) is
/// on top of the Navigator.
///
/// The tab bar is drawn above the Navigator so pushed pages slide under it.
/// The same placement would also put it over every sheet, where iOS has the
/// sheet cover the tab bar. The chrome reads [modalOnTop] and gets out of the
/// way while one is up.
///
/// A route counts as modal when it does not fill the screen opaquely (a page
/// pushed in the stack is opaque, everything presented over a page is not),
/// or when it is a full-screen dialog, which stands in for the whole app.
class ModalRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> modalOnTop = ValueNotifier(false);

  final List<Route<dynamic>> _stack = [];

  void _update() {
    final top = _stack.isEmpty ? null : _stack.last;
    // A full-screen dialog (the bedside clock) covers the tab bar as well.
    modalOnTop.value =
        top is ModalRoute &&
        (!top.opaque || (top is PageRoute && top.fullscreenDialog));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) {
      _stack[index] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _update();
  }
}

/// Hands [ModalRouteObserver.modalOnTop] to the pages under the Navigator,
/// which dim themselves while a sheet is up.
class ModalPresentationScope extends InheritedWidget {
  const ModalPresentationScope({
    super.key,
    required this.modalOnTop,
    required super.child,
  });

  final ValueListenable<bool> modalOnTop;

  static ValueListenable<bool>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ModalPresentationScope>()
      ?.modalOnTop;

  @override
  bool updateShouldNotify(ModalPresentationScope oldWidget) =>
      modalOnTop != oldWidget.modalOnTop;
}
