import 'nutrition.dart';

/// What a food contains, for fasting days and preferences.
enum FoodTag {
  /// Allowed on a strict Orthodox fast: no meat, fish, dairy or eggs.
  /// Shellfish and octopus are allowed.
  lenten,
  meat,
  fish,
  dairy,
  egg,
}

/// One food at a usual portion, with what it brings.
///
/// The figures are typical values for the portion described, rounded: an
/// estimate, which is what logging a meal without weighing it can be.
class FoodItem {
  const FoodItem(
    this.name,
    this.portion,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat, {
    this.tags = const {},
    this.meals = const {},
  });

  final String name;
  final String portion;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final Set<FoodTag> tags;

  /// The meals a planned week may put it in; empty for foods only logged.
  final Set<Meal> meals;

  bool get lenten => tags.contains(FoodTag.lenten);

  FoodEntry toEntry({
    required DateTime time,
    required Meal meal,
    double portions = 1,
  }) => FoodEntry(
    time: time,
    meal: meal,
    name: name,
    kcal: kcal * portions,
    protein: protein * portions,
    carbs: carbs * portions,
    fat: fat * portions,
    portions: portions,
  );
}

const _b = {Meal.breakfast};
const _l = {Meal.lunch};
const _ld = {Meal.lunch, Meal.dinner};
const _d = {Meal.dinner};
const _s = {Meal.snack};
const _bs = {Meal.breakfast, Meal.snack};

const _lenten = {FoodTag.lenten};
const _dairy = {FoodTag.dairy};
const _meat = {FoodTag.meat};
const _fish = {FoodTag.fish};
const _egg = {FoodTag.egg};

/// Foods to log by name and to plan weeks from, Greek kitchen first.
abstract final class FoodCatalog {
  static const all = <FoodItem>[
    // ── Breakfast ──────────────────────────────────────────────────────────
    FoodItem(
      'Greek yogurt with honey and walnuts',
      '200 g yogurt',
      330,
      20,
      26,
      16,
      tags: _dairy,
      meals: _bs,
    ),
    FoodItem(
      'Greek yogurt 2%',
      '200 g',
      150,
      20,
      8,
      4,
      tags: _dairy,
      meals: _bs,
    ),
    FoodItem(
      'Oatmeal with banana',
      '1 bowl',
      320,
      9,
      58,
      6,
      tags: _lenten,
      meals: _b,
    ),
    FoodItem(
      'Oatmeal with milk and berries',
      '1 bowl',
      330,
      13,
      52,
      8,
      tags: _dairy,
      meals: _b,
    ),
    FoodItem('Scrambled eggs', '2 eggs', 200, 13, 2, 15, tags: _egg, meals: _b),
    FoodItem(
      'Omelette with feta and tomato',
      '2 eggs',
      290,
      18,
      4,
      22,
      tags: {FoodTag.egg, FoodTag.dairy},
      meals: _b,
    ),
    FoodItem('Boiled egg', '1 egg', 75, 6, 0.5, 5, tags: _egg, meals: _bs),
    FoodItem(
      'Wholegrain toast with tahini and honey',
      '2 slices',
      330,
      10,
      42,
      14,
      tags: _lenten,
      meals: _b,
    ),
    FoodItem(
      'Wholegrain toast with peanut butter',
      '2 slices',
      350,
      13,
      36,
      17,
      tags: _lenten,
      meals: _b,
    ),
    FoodItem(
      'Toast with turkey and cheese',
      '1 sandwich',
      330,
      22,
      30,
      13,
      tags: {FoodTag.meat, FoodTag.dairy},
      meals: _b,
    ),
    FoodItem('Koulouri', '1 ring', 280, 9, 52, 4, tags: _lenten, meals: _bs),
    FoodItem(
      'Spanakopita',
      '1 piece',
      320,
      9,
      26,
      20,
      tags: _dairy,
      meals: _bs,
    ),
    FoodItem('Tiropita', '1 piece', 360, 11, 28, 23, tags: _dairy, meals: _bs),
    FoodItem(
      'Lenten spinach pie',
      '1 piece',
      260,
      6,
      28,
      14,
      tags: _lenten,
      meals: _bs,
    ),
    FoodItem(
      'Fruit salad',
      '1 bowl',
      120,
      1.5,
      29,
      0.5,
      tags: _lenten,
      meals: _bs,
    ),
    FoodItem(
      'Smoothie, banana and oat milk',
      '400 ml',
      260,
      5,
      50,
      5,
      tags: _lenten,
      meals: _bs,
    ),

    // ── Mains ──────────────────────────────────────────────────────────────
    FoodItem('Fasolada', '1 plate', 380, 16, 50, 12, tags: _lenten, meals: _ld),
    FoodItem(
      'Fakes (lentil soup)',
      '1 plate',
      360,
      18,
      48,
      10,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Revithada (chickpea soup)',
      '1 plate',
      400,
      16,
      52,
      14,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Gigantes plaki',
      '1 plate',
      420,
      17,
      50,
      16,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem('Briam', '1 plate', 320, 6, 30, 20, tags: _lenten, meals: _ld),
    FoodItem(
      'Fasolakia ladera',
      '1 plate',
      310,
      6,
      28,
      19,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Gemista, lenten',
      '2 pieces',
      420,
      8,
      62,
      15,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Spanakorizo',
      '1 plate',
      360,
      8,
      55,
      12,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Imam bayildi',
      '1 plate',
      330,
      5,
      26,
      23,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Lenten pasta with tomato sauce',
      '1 plate',
      450,
      14,
      80,
      8,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Shrimp saganaki, no feta',
      '1 plate',
      300,
      28,
      12,
      15,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Grilled octopus',
      '1 plate',
      260,
      40,
      6,
      8,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Squid with rice',
      '1 plate',
      450,
      28,
      55,
      12,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Lentil and rice bowl with vegetables',
      '1 bowl',
      430,
      17,
      70,
      9,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Tofu stir-fry with rice',
      '1 plate',
      480,
      22,
      60,
      16,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Chickpea salad',
      '1 bowl',
      380,
      14,
      40,
      18,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Grilled chicken breast with rice',
      '1 plate',
      520,
      45,
      55,
      11,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Grilled chicken with salad',
      '1 plate',
      380,
      42,
      10,
      18,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Chicken souvlaki pita',
      '1 pita',
      480,
      30,
      45,
      19,
      tags: _meat,
      meals: _l,
    ),
    FoodItem(
      'Pork gyros pita',
      '1 pita',
      600,
      25,
      50,
      32,
      tags: _meat,
      meals: _l,
    ),
    FoodItem(
      'Chicken souvlaki skewers',
      '2 skewers',
      320,
      40,
      2,
      16,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Biftekia with potatoes',
      '1 plate',
      650,
      35,
      45,
      35,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Moussaka',
      '1 portion',
      600,
      25,
      30,
      42,
      tags: {FoodTag.meat, FoodTag.dairy, FoodTag.egg},
      meals: _ld,
    ),
    FoodItem(
      'Pastitsio',
      '1 portion',
      620,
      28,
      45,
      35,
      tags: {FoodTag.meat, FoodTag.dairy, FoodTag.egg},
      meals: _ld,
    ),
    FoodItem(
      'Kotopoulo lemonato with potatoes',
      '1 plate',
      560,
      38,
      40,
      26,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Beef stifado',
      '1 plate',
      520,
      40,
      20,
      30,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Spaghetti bolognese',
      '1 plate',
      650,
      30,
      80,
      22,
      tags: _meat,
      meals: _ld,
    ),
    FoodItem(
      'Turkey and vegetable wrap',
      '1 wrap',
      420,
      30,
      42,
      14,
      tags: _meat,
      meals: _l,
    ),
    FoodItem(
      'Grilled salmon with vegetables',
      '1 plate',
      480,
      38,
      15,
      29,
      tags: _fish,
      meals: _ld,
    ),
    FoodItem(
      'Baked cod with potatoes',
      '1 plate',
      420,
      35,
      40,
      12,
      tags: _fish,
      meals: _ld,
    ),
    FoodItem(
      'Grilled sea bream',
      '1 fish',
      350,
      45,
      0,
      18,
      tags: _fish,
      meals: _ld,
    ),
    FoodItem('Tuna salad', '1 bowl', 350, 30, 12, 20, tags: _fish, meals: _ld),
    FoodItem(
      'Horiatiki salad',
      '1 bowl',
      350,
      10,
      12,
      30,
      tags: _dairy,
      meals: _ld,
    ),
    FoodItem(
      'Green salad with olive oil',
      '1 bowl',
      150,
      2,
      8,
      13,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem('Dakos', '1 rusk', 300, 8, 32, 16, tags: _dairy, meals: _ld),
    FoodItem(
      'Omelette with vegetables',
      '3 eggs',
      300,
      20,
      6,
      22,
      tags: _egg,
      meals: _d,
    ),
    FoodItem(
      'Lentil salad with vegetables',
      '1 bowl',
      330,
      16,
      40,
      11,
      tags: _lenten,
      meals: _d,
    ),
    FoodItem(
      'Vegetable soup',
      '1 bowl',
      180,
      5,
      28,
      5,
      tags: _lenten,
      meals: _d,
    ),
    FoodItem(
      'Chicken soup avgolemono',
      '1 bowl',
      320,
      25,
      25,
      12,
      tags: {FoodTag.meat, FoodTag.egg},
      meals: _d,
    ),
    FoodItem(
      'Hummus with pita and vegetables',
      '1 plate',
      420,
      13,
      50,
      19,
      tags: _lenten,
      meals: _ld,
    ),
    FoodItem(
      'Wholegrain pasta with vegetables',
      '1 plate',
      450,
      16,
      75,
      10,
      tags: _lenten,
      meals: _ld,
    ),

    // ── Sides and snacks ───────────────────────────────────────────────────
    FoodItem('Feta cheese', '50 g', 130, 7, 2, 11, tags: _dairy, meals: _s),
    FoodItem('Olives', '10 olives', 60, 0.5, 1, 6, tags: _lenten, meals: _s),
    FoodItem('Bread, slice', '1 slice', 80, 3, 15, 1, tags: _lenten),
    FoodItem('Rusk (paximadi)', '1 piece', 100, 3, 19, 1.5, tags: _lenten),
    FoodItem('Tzatziki', '2 tbsp', 70, 3, 3, 5, tags: _dairy),
    FoodItem('Fava', '1 bowl', 280, 15, 38, 8, tags: _lenten, meals: _ld),
    FoodItem('Apple', '1 medium', 95, 0.5, 25, 0.3, tags: _lenten, meals: _s),
    FoodItem('Banana', '1 medium', 105, 1.3, 27, 0.4, tags: _lenten, meals: _s),
    FoodItem('Orange', '1 medium', 65, 1.3, 16, 0.2, tags: _lenten, meals: _s),
    FoodItem('Grapes', '1 cup', 105, 1, 27, 0.2, tags: _lenten, meals: _s),
    FoodItem('Almonds', '30 g', 175, 6, 6, 15, tags: _lenten, meals: _s),
    FoodItem('Walnuts', '30 g', 195, 4.5, 4, 19, tags: _lenten, meals: _s),
    FoodItem('Halva', '50 g', 260, 6, 26, 15, tags: _lenten, meals: _s),
    FoodItem('Protein bar', '1 bar', 210, 20, 22, 7, tags: _dairy, meals: _s),
    FoodItem(
      'Carrot and cucumber sticks with hummus',
      '1 bowl',
      160,
      5,
      16,
      9,
      tags: _lenten,
      meals: _s,
    ),
    FoodItem(
      'Cottage cheese with fruit',
      '1 bowl',
      190,
      18,
      18,
      4,
      tags: _dairy,
      meals: _s,
    ),
    FoodItem(
      'Dark chocolate',
      '20 g',
      120,
      1.5,
      9,
      9,
      tags: _lenten,
      meals: _s,
    ),
    FoodItem('Loukoumades', '1 portion', 450, 6, 60, 21, tags: _lenten),
    FoodItem('Baklava', '1 piece', 330, 5, 37, 19, tags: _dairy),
    FoodItem('Ice cream', '2 scoops', 270, 5, 32, 14, tags: _dairy),
    FoodItem('Potato chips', '1 small bag', 250, 3, 25, 16, tags: _lenten),
    FoodItem(
      'Pizza',
      '2 slices',
      560,
      24,
      66,
      22,
      tags: {FoodTag.dairy, FoodTag.meat},
    ),
    FoodItem('Burger with fries', '1 meal', 950, 35, 95, 48, tags: _meat),
    FoodItem(
      'Club sandwich',
      '1 sandwich',
      650,
      30,
      55,
      34,
      tags: {FoodTag.meat, FoodTag.egg},
    ),

    // ── Drinks ─────────────────────────────────────────────────────────────
    FoodItem(
      'Freddo espresso, no sugar',
      '1 cup',
      5,
      0.3,
      0.5,
      0,
      tags: _lenten,
    ),
    FoodItem(
      'Freddo cappuccino, medium sugar',
      '1 cup',
      110,
      4,
      13,
      5,
      tags: _dairy,
    ),
    FoodItem(
      'Frappé with milk and sugar',
      '1 glass',
      120,
      3,
      18,
      4,
      tags: _dairy,
    ),
    FoodItem(
      'Greek coffee, medium sweet',
      '1 cup',
      25,
      0.2,
      5,
      0.2,
      tags: _lenten,
    ),
    FoodItem('Orange juice', '250 ml', 110, 2, 26, 0.5, tags: _lenten),
    FoodItem('Milk 1.5%', '250 ml', 115, 8.5, 12, 4, tags: _dairy),
    FoodItem('Beer', '330 ml', 145, 1.5, 12, 0, tags: _lenten),
    FoodItem('Wine', '1 glass', 125, 0, 4, 0, tags: _lenten),
    FoodItem('Soft drink', '330 ml', 140, 0, 35, 0, tags: _lenten),
  ];

  /// Foods whose name contains every word typed, best match first.
  static List<FoodItem> search(String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    final hits = [
      for (final item in all)
        if (words.every((w) => item.name.toLowerCase().contains(w))) item,
    ];
    final first = words.first;
    hits.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(first) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(first) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.name.length - b.name.length;
    });
    return hits;
  }

  /// For a meal without a known food: roughly how big it was.
  static const estimates = [
    ('Light', 300.0),
    ('Regular', 550.0),
    ('Large', 850.0),
  ];
}
