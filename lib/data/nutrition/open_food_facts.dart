import 'dart:convert';
import 'dart:io';

import '../../domain/food_catalog.dart';
import '../database/app_database.dart';

/// Packaged foods by barcode, from Open Food Facts, the free, open product
/// database. A product once found is kept on the phone, so scanning it again
/// needs no connection.
class OpenFoodFacts {
  OpenFoodFacts(this._db);

  final AppDatabase _db;

  static String _key(String code) => 'barcode:$code';

  /// The product, or null if it is not known; throws without a connection.
  Future<FoodItem?> lookup(String code) async {
    final cached = await _db.readValue(_key(code));
    if (cached != null) {
      return parse(jsonDecode(cached) as Map<String, Object?>);
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..userAgent = 'Halo/1.0 (health app; contact via app store listing)';
    try {
      final uri =
          Uri.https('world.openfoodfacts.org', '/api/v2/product/$code.json', {
            'fields':
                'product_name,product_name_en,brands,nutriments,serving_size,'
                'serving_quantity',
          });
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw HttpException('Open Food Facts answered ${response.statusCode}');
      }
      final body =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, Object?>;
      final item = parse(body);
      if (item != null) await _db.writeValue(_key(code), jsonEncode(body));
      return item;
    } finally {
      client.close();
    }
  }

  /// A product response as a food at one serving, or per 100 g when the
  /// product gives no serving.
  static FoodItem? parse(Map<String, Object?> body) {
    if (body['status'] != 1) return null;
    final product = body['product'];
    if (product is! Map) return null;
    String? text(String key) {
      final v = product[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final name = text('product_name_en') ?? text('product_name');
    if (name == null) return null;
    final brand = text('brands')?.split(',').first.trim();
    final n = product['nutriments'];
    double? per100(String key) {
      if (n is! Map) return null;
      final v = n['${key}_100g'];
      return v is num ? v.toDouble() : double.tryParse('$v');
    }

    final kcal =
        per100('energy-kcal') ??
        (per100('energy') == null ? null : per100('energy')! / 4.184);
    if (kcal == null) return null;

    final serving = product['serving_quantity'];
    final grams = serving is num
        ? serving.toDouble()
        : double.tryParse('${serving ?? ''}');
    final hasServing = grams != null && grams > 0;
    final scale = hasServing ? grams / 100 : 1.0;
    return FoodItem(
      brand == null || name.toLowerCase().contains(brand.toLowerCase())
          ? name
          : '$name, $brand',
      hasServing ? (text('serving_size') ?? '${grams.round()} g') : '100 g',
      kcal * scale,
      (per100('proteins') ?? 0) * scale,
      (per100('carbohydrates') ?? 0) * scale,
      (per100('fat') ?? 0) * scale,
    );
  }
}
