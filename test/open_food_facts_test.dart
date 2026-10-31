import 'package:flutter_test/flutter_test.dart';
import 'package:halo/data/nutrition/open_food_facts.dart';

void main() {
  test('a product with a serving is sized to the serving', () {
    final item = OpenFoodFacts.parse({
      'status': 1,
      'product': {
        'product_name': 'Greek Yoghurt 2%',
        'brands': 'Fage, Total',
        'serving_size': '1 pot (170 g)',
        'serving_quantity': 170,
        'nutriments': {
          'energy-kcal_100g': 73,
          'proteins_100g': 10,
          'carbohydrates_100g': 3,
          'fat_100g': 2,
        },
      },
    })!;
    expect(item.name, 'Greek Yoghurt 2%, Fage');
    expect(item.portion, '1 pot (170 g)');
    expect(item.kcal, closeTo(124.1, 0.01));
    expect(item.protein, closeTo(17, 0.01));
  });

  test('without a serving it is per 100 g, from kJ if need be', () {
    final item = OpenFoodFacts.parse({
      'status': 1,
      'product': {
        'product_name': 'Rusks',
        'nutriments': {'energy_100g': 1674},
      },
    })!;
    expect(item.portion, '100 g');
    expect(item.kcal, closeTo(400, 0.5));
  });

  test('unknown products and products without energy give nothing', () {
    expect(OpenFoodFacts.parse({'status': 0}), isNull);
    expect(
      OpenFoodFacts.parse({
        'status': 1,
        'product': {'product_name': 'Water', 'nutriments': {}},
      }),
      isNull,
    );
  });
}
