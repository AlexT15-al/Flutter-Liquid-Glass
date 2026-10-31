import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../data/preferences/halo_preferences.dart';
import '../../../shared/widgets/halo_sheet.dart';
import '../domain/today_card.dart';

/// Opens Edit Summary: choose which cards Today shows, and in what order.
///
/// The list is the page's cards: a delete badge and a grabber on each shown
/// card, an insert badge on each hidden one. Every change is written at once,
/// so there is nothing to lose and no Cancel; the tick only closes.
Future<void> showEditTodaySheet(BuildContext context) async {
  final preferences = HaloScope.preferencesOf(context);
  final current = await preferences.watchTodayCards().first;
  if (!context.mounted) return;

  await showHaloSheet<void>(
    context,
    builder: (context, controller) => _EditTodaySheet(
      controller: controller,
      preferences: preferences,
      initial: current,
    ),
  );
}

class _EditTodaySheet extends StatefulWidget {
  const _EditTodaySheet({
    required this.controller,
    required this.preferences,
    required this.initial,
  });

  final ScrollController controller;
  final HaloPreferences preferences;
  final List<TodayCard> initial;

  @override
  State<_EditTodaySheet> createState() => _EditTodaySheetState();
}

class _EditTodaySheetState extends State<_EditTodaySheet> {
  late List<TodayCard> _shown = List.of(widget.initial);

  List<TodayCard> get _hidden => [
        for (final card in TodayCard.values)
          if (!_shown.contains(card)) card,
      ];

  void _update(List<TodayCard> next) {
    setState(() => _shown = next);
    widget.preferences.setTodayCards(next);
  }

  @override
  Widget build(BuildContext context) {
    // `GlassListTile` replaces the ambient text style rather than merging into
    // it, so the row title is given the app's own style explicitly. Otherwise
    // it would drop the app font the moment one is set.
    final rowTitle = DefaultTextStyle.of(context).style.copyWith(
          color: HaloColors.labelOf(context),
          fontSize: 17,
        );

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Edit Summary',
        trailing: SheetConfirmButton(
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      children: [
        const SectionCaption('Shown on Today'),
        // Solid sections pick the elevated card colour inside a sheet on their
        // own: the sheet route raises the interface level.
        GlassReorderableList.grouped(
          surfaceStyle: GlassSurfaceStyle.solid,
          itemCount: _shown.length,
          // Hands over the index the item settled at, already adjusted for
          // its own removal.
          onReorderItem: (from, to) {
            final next = List.of(_shown);
            next.insert(to, next.removeAt(from));
            _update(next);
          },
          itemBuilder: (context, index) {
            final card = _shown[index];
            return GlassListTile(
              key: ValueKey(card),
              isEditing: true,
              canDelete: true,
              onDelete: () => _update(List.of(_shown)..remove(card)),
              canReorder: true,
              reorderIndex: index,
              leading: _CardGlyph(card: card),
              titleStyle: rowTitle,
              title: Text(card.title),
            );
          },
        ),
        if (_hidden.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionCaption('More Cards'),
          GlassGroupedSection(
            // The list above already sits inside the sheet's padding; the
            // section's default margin would inset it a second time.
            margin: EdgeInsets.zero,
            surfaceStyle: GlassSurfaceStyle.solid,
            children: [
              for (final card in _hidden)
                GlassListTile(
                  key: ValueKey(card),
                  isEditing: true,
                  canInsert: true,
                  onInsert: () => _update([..._shown, card]),
                  leading: _CardGlyph(card: card),
                  titleStyle: rowTitle,
                  title: Text(card.title),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A card's glyph on a rounded tile of its colour, as Settings draws its row
/// icons.
class _CardGlyph extends StatelessWidget {
  const _CardGlyph({required this.card});

  final TodayCard card;

  @override
  Widget build(BuildContext context) {
    final color = card.color.resolveFrom(context);
    return Container(
      width: 28,
      height: 28,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        color: color,
      ),
      alignment: Alignment.center,
      child: Icon(
        card.icon,
        size: 17,
        color: card == TodayCard.readiness
            ? HaloColors.onAccent.resolveFrom(context)
            : const Color(0xFFFFFFFF),
      ),
    );
  }
}
