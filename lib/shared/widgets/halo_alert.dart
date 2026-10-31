import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme/halo_colors.dart';
import '../../app/theme/halo_motion.dart';

/// How an alert button reads.
enum HaloAlertStyle {
  /// The one action the alert is for: filled with the accent.
  primary,
  normal,

  /// Deletes or discards: red text.
  destructive,

  /// Backs out: always last.
  cancel,
}

/// One button of an alert, and what the alert returns when it is pressed.
class HaloAlertAction<T> {
  const HaloAlertAction(
    this.label, {
    this.value,
    this.style = HaloAlertStyle.normal,
  });

  final String label;
  final T? value;
  final HaloAlertStyle style;
}

/// An alert the way iOS 27 draws one: a large rounded card, the title and
/// message aligned to the leading edge, an optional text field, and the
/// buttons stacked as full-width capsules, the main action filled.
///
/// Not dismissed by tapping outside it, as on iOS: an alert asks for an
/// answer.
Future<T?> showHaloAlert<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<HaloAlertAction<T>> actions,
  TextEditingController? field,
  String? fieldPlaceholder,
}) {
  // Cancel goes to the bottom whatever order it was given in.
  final ordered = [
    ...actions.where((a) => a.style != HaloAlertStyle.cancel),
    ...actions.where((a) => a.style == HaloAlertStyle.cancel),
  ];
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: const Color(0x33000000),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => _HaloAlert<T>(
      title: title,
      message: message,
      actions: ordered,
      field: field,
      fieldPlaceholder: fieldPlaceholder,
    ),
    transitionBuilder: (context, animation, _, child) {
      final disable = MediaQuery.disableAnimationsOf(context);
      final reverse = animation.status == AnimationStatus.reverse;
      // In: grows from a little larger than its size, settling with a slight
      // spring; out: simply fades.
      final scale = disable || reverse
          ? 1.0
          : Tween(
              begin: 1.12,
              end: 1.0,
            ).transform(HaloMotion.alertCurve.transform(animation.value));
      return Opacity(
        opacity: Curves.easeOut.transform(animation.value),
        child: Transform.scale(scale: scale, child: child),
      );
    },
  );
}

/// Yes or no to something destructive: the common case, in one call.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  String? message,
  required String action,
}) async =>
    await showHaloAlert<bool>(
      context,
      title: title,
      message: message,
      actions: [
        HaloAlertAction(action, value: true, style: HaloAlertStyle.destructive),
        const HaloAlertAction(
          'Cancel',
          value: false,
          style: HaloAlertStyle.cancel,
        ),
      ],
    ) ??
    false;

class _HaloAlert<T> extends StatelessWidget {
  const _HaloAlert({
    required this.title,
    required this.message,
    required this.actions,
    required this.field,
    required this.fieldPlaceholder,
  });

  final String title;
  final String? message;
  final List<HaloAlertAction<T>> actions;
  final TextEditingController? field;
  final String? fieldPlaceholder;

  static const _width = 300.0;
  static const _radius = 34.0;

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final label = HaloColors.labelOf(context);
    final surface = dark ? const Color(0xFF262628) : const Color(0xFFF9F9F9);
    final fill = dark ? const Color(0xFF3A3A3C) : const Color(0xFFE3E3E3);
    final width = MediaQuery.sizeOf(context).width;
    final style = DefaultTextStyle.of(context).style;

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          width: width - 72 < _width ? width - 72 : _width,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: surface,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(_radius),
                side: BorderSide(
                  color: dark
                      ? const Color(0x1AFFFFFF)
                      : const Color(0x1F000000),
                  width: 0.5,
                ),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 40,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        title,
                        style: style.copyWith(
                          color: label,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          message!,
                          style: style.copyWith(
                            color: label,
                            fontSize: 17,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    if (field != null) ...[
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          color: fill,
                          shape: const StadiumBorder(),
                        ),
                        child: CupertinoTextField(
                          controller: field,
                          autofocus: true,
                          placeholder: fieldPlaceholder,
                          decoration: null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          style: style.copyWith(color: label, fontSize: 17),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _AlertButton<T>(action: actions[i], fill: fill),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertButton<T> extends StatefulWidget {
  const _AlertButton({required this.action, required this.fill});

  final HaloAlertAction<T> action;
  final Color fill;

  @override
  State<_AlertButton<T>> createState() => _AlertButtonState<T>();
}

class _AlertButtonState<T> extends State<_AlertButton<T>> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final primary = action.style == HaloAlertStyle.primary;
    final background = primary
        ? HaloColors.accent.resolveFrom(context)
        : widget.fill;
    final ink = switch (action.style) {
      HaloAlertStyle.primary => HaloColors.onAccent.resolveFrom(context),
      HaloAlertStyle.destructive => CupertinoColors.systemRed.resolveFrom(
        context,
      ),
      _ => HaloColors.labelOf(context),
    };
    final duration = HaloMotion.of(
      context,
      _pressed ? HaloMotion.pressInDuration : HaloMotion.pressOutDuration,
    );

    return Semantics(
      button: true,
      label: action.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop(action.value);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: duration,
          curve: HaloMotion.pressCurve,
          child: AnimatedContainer(
            duration: duration,
            height: 48,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: _pressed
                  ? Color.lerp(background, const Color(0xFF000000), 0.08)
                  : background,
              shape: const StadiumBorder(),
            ),
            child: Text(
              action.label,
              style: DefaultTextStyle.of(context).style.copyWith(
                color: ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
