/// Represents a product (from API or OCR).
class Product {
  final int id;
  final String? barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? category;
  final String source; // 'API' or 'OCR'
  final String? rawIngredientsText;
  final String? createdAt;
  final List<ProductIngredient> ingredients;

  Product({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.category,
    required this.source,
    this.rawIngredientsText,
    this.createdAt,
    this.ingredients = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      barcode: json['barcode'] as String?,
      name: json['name'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      source: json['source'] as String? ?? 'API',
      rawIngredientsText: json['raw_ingredients_text'] as String?,
      createdAt: json['created_at'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => ProductIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// A product's ingredient link (junction model).
class ProductIngredient {
  final int id;
  final String rawName;
  final bool isClassified;
  final IngredientDetail? ingredient;

  ProductIngredient({
    required this.id,
    required this.rawName,
    required this.isClassified,
    this.ingredient,
  });

  factory ProductIngredient.fromJson(Map<String, dynamic> json) {
    return ProductIngredient(
      id: json['id'] as int,
      rawName: json['raw_name'] as String,
      isClassified: json['is_classified'] as bool? ?? false,
      ingredient: json['ingredient'] != null
          ? IngredientDetail.fromJson(json['ingredient'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Detailed ingredient info from the database.
class IngredientDetail {
  final int id;
  final String name;
  final String? description;
  final String type;
  final double riskScore;
  final String riskLevel;

  IngredientDetail({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.riskScore,
    required this.riskLevel,
  });

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    return IngredientDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'OTHER',
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 5.0,
      riskLevel: json['risk_level'] as String? ?? 'UNKNOWN',
    );
  }
}
