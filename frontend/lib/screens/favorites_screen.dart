import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// 6.7 - Favorites screen.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getFavorites();
      setState(() {
        _favorites = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int productId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.removeFavorite(productId);
      setState(() => _favorites.removeWhere((f) => f['product_id'] == productId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textMuted.withAlpha(80)),
                      const SizedBox(height: 16),
                      const Text('No favorites yet', style: TextStyle(color: AppTheme.textMuted)),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap ❤ on a product analysis to save it here',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final fav = _favorites[index];
                    final product = fav['product'] as Map<String, dynamic>?;
                    final name = product?['name'] as String? ?? 'Unknown';
                    final brand = product?['brand'] as String? ?? '';
                    final productId = product?['id'] as int?;
                    final source = product?['source'] as String? ?? 'API';

                    return Material(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: InkWell(
                        onTap: productId != null ? () => context.push('/analysis/$productId') : null,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Icon(
                                      source == 'OCR' ? Icons.document_scanner_rounded : Icons.qr_code_2_rounded,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: productId != null ? () => _removeFavorite(productId) : null,
                                    child: const Icon(Icons.favorite_rounded, color: AppTheme.unsafe, size: 20),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (brand.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  brand,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
                  },
                ),
    );
  }
}
