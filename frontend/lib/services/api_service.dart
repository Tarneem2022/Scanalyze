import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/product.dart';

/// Central API service for all backend communication.
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.timeout,
      receiveTimeout: ApiConstants.timeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ─── Auth ───

  Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return response.data as Map<String, dynamic>;
  }

  // ─── Products ───

  Future<Map<String, dynamic>> getProductByBarcode(String barcode) async {
    final response = await _dio.get('/products/barcode/$barcode');
    return response.data as Map<String, dynamic>;
  }

  Future<Product> createOcrProduct(String ingredientsText, {String? name}) async {
    final response = await _dio.post('/products/ocr', data: {
      'ingredients_text': ingredientsText,
      if (name != null) 'name': name,
    });
    return Product.fromJson(response.data['product'] as Map<String, dynamic>);
  }

  Future<Product> getProduct(int productId) async {
    final response = await _dio.get('/products/$productId');
    return Product.fromJson(response.data['product'] as Map<String, dynamic>);
  }

  // ─── Analysis ───

  Future<Map<String, dynamic>> analyzeProduct(int productId) async {
    final response = await _dio.post('/analysis/analyze', data: {
      'product_id': productId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> compareProducts(int productId1, int productId2) async {
    final response = await _dio.post('/analysis/compare', data: {
      'product_id_1': productId1,
      'product_id_2': productId2,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─── History ───

  Future<List<dynamic>> getHistory() async {
    final response = await _dio.get('/history');
    return response.data['history'] as List<dynamic>;
  }

  Future<void> deleteHistoryEntry(int historyId) async {
    await _dio.delete('/history/$historyId');
  }

  Future<void> clearHistory() async {
    await _dio.delete('/history/clear');
  }

  // ─── Favorites ───

  Future<List<dynamic>> getFavorites() async {
    final response = await _dio.get('/favorites');
    return response.data['favorites'] as List<dynamic>;
  }

  Future<void> addFavorite(int productId) async {
    await _dio.post('/favorites/$productId');
  }

  Future<void> removeFavorite(int productId) async {
    await _dio.delete('/favorites/$productId');
  }

  // ─── Preferences ───

  Future<Map<String, dynamic>> getPreferences() async {
    final response = await _dio.get('/preferences');
    return response.data['preferences'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePreferences({
    List<String>? allergies,
    List<String>? avoidedIngredients,
    List<Map<String, dynamic>>? customIngredients,
  }) async {
    final response = await _dio.put('/preferences', data: {
      if (allergies != null) 'allergies': allergies,
      if (avoidedIngredients != null) 'avoided_ingredients': avoidedIngredients,
      if (customIngredients != null) 'custom_ingredients': customIngredients,
    });
    return response.data['preferences'] as Map<String, dynamic>;
  }

  // ─── Ingredients ───

  Future<List<dynamic>> searchIngredients({String? search, int limit = 50}) async {
    final response = await _dio.get('/ingredients', queryParameters: {
      if (search != null) 'search': search,
      'limit': limit,
    });
    return response.data['ingredients'] as List<dynamic>;
  }
}

/// Global API service provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
