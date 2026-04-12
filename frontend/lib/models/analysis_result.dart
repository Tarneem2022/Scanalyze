/// Represents a safety analysis result.
class AnalysisResult {
  final int id;
  final int productId;
  final int userId;
  final double overallScore;
  final String safetyClass; // 'SAFE', 'MODERATE', 'UNSAFE'
  final List<Alert> alerts;
  final List<IngredientAnalysis> ingredientDetails;
  final String? createdAt;

  AnalysisResult({
    required this.id,
    required this.productId,
    required this.userId,
    required this.overallScore,
    required this.safetyClass,
    this.alerts = const [],
    this.ingredientDetails = const [],
    this.createdAt,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      userId: json['user_id'] as int,
      overallScore: (json['overall_score'] as num).toDouble(),
      safetyClass: json['safety_class'] as String,
      alerts: (json['alerts'] as List<dynamic>?)
              ?.map((e) => Alert.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ingredientDetails: (json['ingredient_details'] as List<dynamic>?)
              ?.map((e) => IngredientAnalysis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
    );
  }
}

/// A safety alert generated during analysis.
class Alert {
  final String severity; // 'DANGER', 'WARNING', 'INFO'
  final String type; // 'ALLERGY', 'AVOIDED', 'HIGH_RISK', 'UNCLASSIFIED'
  final String? ingredient;
  final String message;

  Alert({
    required this.severity,
    required this.type,
    this.ingredient,
    required this.message,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      severity: json['severity'] as String,
      type: json['type'] as String,
      ingredient: json['ingredient'] as String?,
      message: json['message'] as String,
    );
  }
}

/// Per-ingredient analysis detail.
class IngredientAnalysis {
  final String rawName;
  final bool isClassified;
  final double riskScore;
  final String riskLevel;
  final String type;
  final String? description;
  final String? matchedName;

  IngredientAnalysis({
    required this.rawName,
    required this.isClassified,
    required this.riskScore,
    required this.riskLevel,
    required this.type,
    this.description,
    this.matchedName,
  });

  factory IngredientAnalysis.fromJson(Map<String, dynamic> json) {
    return IngredientAnalysis(
      rawName: json['raw_name'] as String,
      isClassified: json['is_classified'] as bool? ?? false,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 5.0,
      riskLevel: json['risk_level'] as String? ?? 'UNKNOWN',
      type: json['type'] as String? ?? 'OTHER',
      description: json['description'] as String?,
      matchedName: json['matched_name'] as String?,
    );
  }
}
