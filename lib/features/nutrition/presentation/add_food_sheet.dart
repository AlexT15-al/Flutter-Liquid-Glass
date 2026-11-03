import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/nutrition/open_food_facts.dart';
import '../../../domain/food_catalog.dart';
import '../../../domain/food_search.dart';
import '../../../domain/nutrition.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_alert.dart';
import '../../../shared/widgets/halo_card.dart';
import '../../../shared/widgets/halo_sheet.dart';
import 'scanner_page.dart';

/// A food at one portion: from the catalogue, or something logged before.
class _Choice {
  const _Choice({
    required this.name,
    required this.portion,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
  });

  factory _Choice.item(FoodItem item) => _Choice(
    name: item.name,
    portion: item.portion,
    kcal: item.kcal,
    protein: item.protein,
    carbs: item.carbs,
    fat: item.fat,
  );

  /// A past entry, brought back to a single portion.
  factory _Choice.entry(FoodEntry e) {
    double? one(double? v) => v == null ? null : v / e.portions;
    return _Choice(
      name: e.name,
      portion: '1 portion',
      kcal: one(e.kcal),
      protein: one(e.protein),
      carbs: one(e.carbs),
      fat: one(e.fat),
    );
  }

  final String name;
  final String portion;
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  FoodEntry toEntry(Meal meal, double portions, {int? id, DateTime? time}) {
    double? times(double? v) => v == null ? null : v * portions;
    return FoodEntry(
      id: id,
      time: time ?? DateTime.now(),
      meal: meal,
      name: name,
      kcal: times(kcal),
      protein: times(protein),
      carbs: times(carbs),
      fat: times(fat),
      portions: portions,
    );
  }
}

/// Adds a food to [meal]: searched from the catalogue or recent foods, or
/// typed in, with calories if known, a rough size if not, or none at all.
///
/// On another [day], the food is logged on it, at the meal's usual time.
Future<void> showAddFoodSheet(
  BuildContext context, {
  required Meal meal,
  DateTime? day,
}) async {
  final nutrition = HaloScope.nutritionOf(context);
  final recent = await nutrition.recent();
  final known = await nutrition.known();
  if (!context.mounted) return;
  final entry = await showHaloSheet<FoodEntry>(
    context,
    builder: (context, scroll) => _AddFoodSheet(
      controller: scroll,
      meal: meal,
      recent: recent,
      known: known,
    ),
  );
  if (entry == null) return;
  final now = DateTime.now();
  if (day == null || isSameDay(day, now)) {
    await nutrition.addFood(entry);
    return;
  }
  final (hour, minute) = switch (entry.meal) {
    Meal.breakfast => (8, 30),
    Meal.lunch => (13, 30),
    Meal.dinner => (20, 30),
    Meal.snack => (17, 0),
  };
  await nutrition.addFood(
    FoodEntry(
      time: DateTime(day.year, day.month, day.day, hour, minute),
      meal: entry.meal,
      name: entry.name,
      kcal: entry.kcal,
      protein: entry.protein,
      carbs: entry.carbs,
      fat: entry.fat,
      portions: entry.portions,
    ),
  );
}

class _AddFoodSheet extends StatefulWidget {
  const _AddFoodSheet({
    required this.controller,
    required this.meal,
    required this.recent,
    this.known = const [],
  });

  final ScrollController controller;
  final Meal meal;
  final List<FoodEntry> recent;

  /// Every food logged before, typed in or scanned: searched alongside the
  /// catalogue.
  final List<FoodEntry> known;

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late Meal _meal = widget.meal;
  final _query = TextEditingController();
  final _kcal = TextEditingController();
  _Choice? _choice;
  bool _custom = false;
  double _portions = 1;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    _kcal.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    _kcal.dispose();
    super.dispose();
  }

  FoodEntry? get _entry {
    final choice = _choice;
    if (choice != null) return choice.toEntry(_meal, _portions);
    final name = _query.text.trim();
    if (!_custom || name.isEmpty) return null;
    final kcal = double.tryParse(_kcal.text.replaceAll(',', '.'));
    return FoodEntry(time: DateTime.now(), meal: _meal, name: name, kcal: kcal);
  }

  bool _scanning = false;

  /// The camera, then Open Food Facts; the product found becomes the choice.
  Future<void> _scan() async {
    final facts = OpenFoodFacts(HaloScope.databaseOf(context));
    final code = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(ScannerPage.route());
    if (code == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final item = await facts.lookup(code);
      if (!mounted) return;
      if (item == null) {
        await showHaloAlert<void>(
          context,
          title: 'Not Found',
          message:
              'Barcode $code isn’t in Open Food Facts yet. Type the food’s '
              'name to add it by hand.',
          actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
        );
      } else {
        _pick(_Choice.item(item));
      }
    } on Object {
      if (!mounted) return;
      await showHaloAlert<void>(
        context,
        title: 'No Connection',
        message:
            'Looking a barcode up the first time needs the internet. Try '
            'again when you are online.',
        actions: const [HaloAlertAction('OK', style: HaloAlertStyle.primary)],
      );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// The user's own foods and the catalogue's, best match first; at the
  /// same match, the user's own.
  List<_Choice> _search(String query) {
    final words = FoodSearch.words(query);
    if (words.isEmpty) return const [];
    final catalog = {for (final f in FoodCatalog.all) f.name.toLowerCase()};
    final scored = <(int, _Choice)>[
      for (final e in widget.known)
        if (!catalog.contains(e.name.toLowerCase()))
          if (FoodSearch.score(e.name, words) case final s?)
            (s - 500, _Choice.entry(e)),
      for (final item in FoodCatalog.all)
        if (FoodSearch.score(item.name, words) case final s?)
          (s, _Choice.item(item)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, c) in scored.take(15)) c];
  }

  void _pick(_Choice choice) {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _choice = choice;
      _custom = false;
      _portions = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final query = _query.text.trim();
    final results = _search(query);
    final suggestions = query.isEmpty
        ? [
            for (final e in widget.recent.take(4)) _Choice.entry(e),
            for (final item
                in FoodCatalog.all
                    .where((i) => i.meals.contains(_meal))
                    .take(8))
              _Choice.item(item),
          ]
        : results;

    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Add Food',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: entry == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(entry);
                },
        ),
      ),
      children: [
        _MealPicker(
          meal: _meal,
          onChanged: (meal) => setState(() => _meal = meal),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        if (_choice case final choice?) ...[
          _PortionCard(
            choice: choice,
            portions: _portions,
            onChanged: (p) => setState(() => _portions = p),
          ),
          CupertinoButton(
            onPressed: () => setState(() => _choice = null),
            child: Text(
              'Choose Something Else',
              style: TextStyle(
                color: HaloColors.accent.resolveFrom(context),
                fontSize: 17,
              ),
            ),
          ),
        ] else ...[
          CupertinoSearchTextField(
            controller: _query,
            placeholder: 'Search foods, or type what you ate',
            style: DefaultTextStyle.of(
              context,
            ).style.copyWith(color: HaloColors.labelOf(context), fontSize: 17),
            onChanged: (_) => setState(() => _custom = false),
          ),
          const SizedBox(height: HaloMetrics.cardGap),
          GroupedCard(
            children: [
              GroupedRow(
                title: _scanning ? 'Looking It Up…' : 'Scan Barcode',
                leading: Icon(
                  CupertinoIcons.barcode_viewfinder,
                  size: 22,
                  color: HaloColors.accent.resolveFrom(context),
                ),
                onTap: _scanning ? null : _scan,
              ),
            ],
          ),
          const SizedBox(height: HaloMetrics.cardGap),
          if (_custom)
            _CustomCard(name: query, kcal: _kcal)
          else ...[
            GroupCaption(query.isEmpty ? 'Suggestions' : 'Foods'),
            GroupedCard(
              children: [
                for (final choice in suggestions)
                  GroupedRow(
                    title: choice.name,
                    value: choice.kcal == null
                        ? '—'
                        : '${Format.integer(choice.kcal!)} kcal',
                    onTap: () => _pick(choice),
                  ),
                if (query.isNotEmpty)
                  GroupedRow(
                    title: 'Add “$query”',
                    leading: Icon(
                      CupertinoIcons.pencil,
                      size: 20,
                      color: HaloColors.accent.resolveFrom(context),
                    ),
                    onTap: () => setState(() => _custom = true),
                  ),
              ],
            ),
            if (query.isNotEmpty && results.isEmpty)
              const GroupCaption(
                'Not in the list: add it by name, with calories if you know '
                'them.',
                footer: true,
              ),
          ],
        ],
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}

class _MealPicker extends StatelessWidget {
  const _MealPicker({required this.meal, required this.onChanged});

  final Meal meal;
  final ValueChanged<Meal> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSegmentedControl(
      segments: [for (final m in Meal.values) GlassSegment(label: m.title)],
      selectedIndex: meal.index,
      onSegmentSelected: (i) => onChanged(Meal.values[i]),
      height: 40,
      borderRadius: 20,
      settings: HaloGlass.of(context),
      quality: HaloGlass.quality,
      useOwnLayer: true,
      selectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
        color: HaloColors.labelOf(context),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      unselectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
        color: HaloColors.secondaryLabelOf(context),
        fontSize: 15,
      ),
    );
  }
}

/// The chosen food, how many portions, and what that comes to.
class _PortionCard extends StatelessWidget {
  const _PortionCard({
    required this.choice,
    required this.portions,
    required this.onChanged,
  });

  final _Choice choice;
  final double portions;
  final ValueChanged<double> onChanged;

  static String describe(double p) =>
      p == p.roundToDouble() ? '${p.round()}' : p.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final entry = choice.toEntry(Meal.snack, portions);
    final secondary = HaloColors.secondaryLabelOf(context);
    final accent = HaloColors.accent.resolveFrom(context);
    String grams(double? v) => v == null ? '—' : '${v.round()} g';

    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice.name,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${choice.portion} a portion',
            style: TextStyle(color: secondary, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Step(
                icon: CupertinoIcons.minus,
                color: accent,
                onTap: portions > 0.5 ? () => onChanged(portions - 0.5) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      describe(portions),
                      style: TextStyle(
                        color: HaloColors.labelOf(context),
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      portions == 1 ? 'PORTION' : 'PORTIONS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Step(
                icon: CupertinoIcons.plus,
                color: accent,
                onTap: portions < 5 ? () => onChanged(portions + 0.5) : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (title, value) in [
                (
                  'Energy',
                  entry.kcal == null
                      ? '—'
                      : '${Format.integer(entry.kcal!)} kcal',
                ),
                ('Protein', grams(entry.protein)),
                ('Carbs', grams(entry.carbs)),
                ('Fat', grams(entry.fat)),
              ])
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: HaloColors.labelOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// Something not in the list: its calories if known, a rough size if not.
class _CustomCard extends StatelessWidget {
  const _CustomCard({required this.name, required this.kcal});

  final String name;
  final TextEditingController kcal;

  @override
  Widget build(BuildContext context) {
    final secondary = HaloColors.secondaryLabelOf(context);
    return HaloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: TextStyle(
              color: HaloColors.labelOf(context),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: HaloColors.fill.resolveFrom(context),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: CupertinoTextField(
              controller: kcal,
              placeholder: 'Calories (optional)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              suffix: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('kcal', style: TextStyle(color: secondary)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              style: DefaultTextStyle.of(context).style.copyWith(
                color: HaloColors.labelOf(context),
                fontSize: 17,
              ),
              // The squircle is drawn around it: a text field takes only a
              // box decoration.
              decoration: null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Not sure? Pick the size of the meal:',
            style: TextStyle(color: secondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (label, value) in FoodCatalog.estimates) ...[
                Expanded(
                  child: HaloCard(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: HaloColors.fill.resolveFrom(context),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      kcal.text = value.round().toString();
                    },
                    child: Column(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: HaloColors.labelOf(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '~${value.round()} kcal',
                          style: TextStyle(color: secondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                if (label != FoodCatalog.estimates.last.$1)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A logged food: change the portions or the meal, or delete it.
Future<void> showEditFoodSheet(BuildContext context, FoodEntry entry) async {
  final nutrition = HaloScope.nutritionOf(context);
  final result = await showHaloSheet<FoodEntry?>(
    context,
    builder: (context, scroll) =>
        _EditFoodSheet(controller: scroll, entry: entry),
  );
  if (result == null) return;
  if (result.portions <= 0) {
    await nutrition.deleteFood(entry.id!);
  } else {
    await nutrition.updateFood(result);
  }
}

class _EditFoodSheet extends StatefulWidget {
  const _EditFoodSheet({required this.controller, required this.entry});

  final ScrollController controller;
  final FoodEntry entry;

  @override
  State<_EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends State<_EditFoodSheet> {
  late Meal _meal = widget.entry.meal;
  late double _portions = widget.entry.portions;
  late final _Choice _choice = _Choice.entry(widget.entry);

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return HaloSheet(
      controller: widget.controller,
      header: HaloSheetHeader(
        title: 'Edit Food',
        leading: SheetButton.close(context),
        trailing: SheetConfirmButton(
          onTap: () => Navigator.of(context).pop(
            _choice.toEntry(_meal, _portions, id: entry.id, time: entry.time),
          ),
        ),
      ),
      children: [
        _MealPicker(
          meal: _meal,
          onChanged: (meal) => setState(() => _meal = meal),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        _PortionCard(
          choice: _choice,
          portions: _portions,
          onChanged: (p) => setState(() => _portions = p),
        ),
        const SizedBox(height: HaloMetrics.cardGap),
        CupertinoButton(
          onPressed: () => Navigator.of(context).pop(
            // Zero portions: the caller deletes it.
            _choice.toEntry(_meal, 0, id: entry.id, time: entry.time),
          ),
          child: Text(
            'Delete',
            style: TextStyle(
              color: CupertinoColors.destructiveRed.resolveFrom(context),
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(height: HaloMetrics.sheetBottomPadding),
      ],
    );
  }
}
