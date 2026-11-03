import 'package:flutter_test/flutter_test.dart';
import 'package:halo/domain/food_catalog.dart';
import 'package:halo/domain/food_search.dart';

void main() {
  bool finds(String name, String query) =>
      FoodSearch.score(name, FoodSearch.words(query)) != null;

  test('any word of the name, in any order', () {
    expect(finds('Sandwich Zorbas', 'zorbas'), isTrue);
    expect(finds('Sandwich Zorbas', 'zorbas sandwich'), isTrue);
    expect(finds('Sandwich Zorbas', 'zorb'), isTrue);
    expect(finds('Sandwich Zorbas', 'pizza'), isFalse);
  });

  test('Greek and Greeklish, with or without accents', () {
    expect(finds('Sandwich Zorbas', 'ζορμπάς'), isTrue);
    expect(finds('Sandwich Zorbas', 'zormpas'), isTrue);
    expect(finds('Chicken souvlaki pita', 'σουβλάκι'), isTrue);
    expect(finds('Χωριάτικη σαλάτα', 'horiatiki'), isTrue);
    expect(finds('Fakes (lentil soup)', 'φακές'), isTrue);
    expect(finds('Mushrooms, sautéed', 'sauteed'), isTrue);
  });

  test('one letter wrong in a longer word', () {
    expect(finds('Sandwich Zorbas', 'zorbaz'), isTrue);
    expect(finds('Chicken souvlaki pita', 'souvlaky'), isTrue);
    expect(finds('Moussaka', 'musaka'), isTrue);
    // Short words have to be right.
    expect(finds('Egg', 'ehg'), isFalse);
  });

  test('a whole word comes before a part of one, short names first', () {
    final results = FoodCatalog.search('egg');
    expect(results.first.name, 'Egg');
    final pita = FoodCatalog.search('pita');
    expect(pita.first.name.toLowerCase(), startsWith('pita'));
  });

  test('the catalogue answers to Greek too', () {
    expect(FoodCatalog.search('μουσακάς').first.name, 'Moussaka');
    expect(
      FoodCatalog.search('γιουβέτσι').map((f) => f.name),
      contains('Giouvetsi with beef'),
    );
  });
}
