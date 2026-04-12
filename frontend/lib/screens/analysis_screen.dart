import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

/// 6.4 - Product Analysis Result Screen.
class AnalysisScreen extends ConsumerStatefulWidget {
  final int productId;
  const AnalysisScreen({super.key, required this.productId});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isLoading = true;
  Product? _product;
  AnalysisResult? _analysis;
  String? _error;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.analyzeProduct(widget.productId);

      setState(() {
        _product = Product.fromJson(data['product'] as Map<String, dynamic>);
        _analysis = AnalysisResult.fromJson(data['analysis'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze product';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;
    final api = ref.read(apiServiceProvider);
    try {
      if (_isFavorited) {
        await api.removeFavorite(_product!.id);
      } else {
        await api.addFavorite(_product!.id);
      }
      setState(() => _isFavorited = !_isFavorited);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorited ? AppTheme.unsafe : AppTheme.textSecondary,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _buildResults(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.unsafe, size: 64),
          const SizedBox(height: 16),
          Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final product = _product!;
    final analysis = _analysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Product Header ───
          _ProductHeader(product: product)
              .animate()
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ─── Safety Score Gauge ───
          Center(
            child: _SafetyGauge(
              score: analysis.overallScore,
              safetyClass: analysis.safetyClass,
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 24),

          // ─── Alerts ───
          if (analysis.alerts.isNotEmpty) ...[
            Text('Alerts', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...analysis.alerts.map((alert) =>
                _AlertCard(alert: alert)
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideX(begin: -0.1)),
            const SizedBox(height: 24),
          ],

          // ─── Ingredients List ───
          Text(
            'Ingredients (${analysis.ingredientDetails.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          
          if (analysis.ingredientDetails.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.bgCardLight),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'No Ingredients Found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The scanner successfully found this product, but the open-source database (Open Beauty Facts / Open Food Facts) does not have any ingredients transcribed for it yet. Try another product!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...analysis.ingredientDetails.asMap().entries.map((entry) {
              final i = entry.key;
              final detail = entry.value;
              return _IngredientTile(detail: detail)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 500 + i * 50));
            }),
        ],
      ),
    );
  }
}

/// ─── Product Header ───
class _ProductHeader extends StatelessWidget {
  final Product product;
  const _ProductHeader({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Row(
        children: [
          // Product image
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 72,
                  height: 72,
                  color: AppTheme.bgCardLight,
                  child: const Icon(Icons.image_rounded, color: AppTheme.textMuted),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: AppTheme.bgCardLight,
                  child: const Icon(Icons.broken_image_rounded, color: AppTheme.textMuted),
                ),
              ),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: AppTheme.textMuted, size: 32),
            ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brand != null && product.brand!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.brand!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (product.barcode != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        product.barcode!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: product.source == 'API' ? AppTheme.infoBg : AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.source == 'API' ? 'API Product' : 'OCR Scanned',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: product.source == 'API' ? AppTheme.accent : AppTheme.moderate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Animated Safety Gauge ───
class _SafetyGauge extends StatelessWidget {
  final double score;
  final String safetyClass;

  const _SafetyGauge({required this.score, required this.safetyClass});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(score);
    final gradient = AppTheme.scoreGradient(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Column(
        children: [
          // Circular gauge
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _GaugePainter(score: score, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Safety badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppTheme.safetyIcon(safetyClass), color: AppTheme.bgDark, size: 18),
                const SizedBox(width: 6),
                Text(
                  AppTheme.safetyLabel(safetyClass),
                  style: const TextStyle(
                    color: AppTheme.bgDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular safety gauge
class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background arc
    final bgPaint = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.score != score;
}

/// ─── Alert Card ───
class _AlertCard extends StatelessWidget {
  final Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (alert.severity) {
      case 'DANGER':
        bgColor = AppTheme.dangerBg;
        textColor = AppTheme.unsafe;
        icon = Icons.dangerous_rounded;
        break;
      case 'WARNING':
        bgColor = AppTheme.warningBg;
        textColor = AppTheme.moderate;
        icon = Icons.warning_rounded;
        break;
      default:
        bgColor = AppTheme.infoBg;
        textColor = AppTheme.accent;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: textColor.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Ingredient Tile ───
class _IngredientTile extends StatelessWidget {
  final IngredientAnalysis detail;
  const _IngredientTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(detail.riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Row(
        children: [
          // Risk indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: riskColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Center(
              child: Text(
                detail.riskScore.toStringAsFixed(0),
                style: TextStyle(
                  color: riskColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.rawName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: riskColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        detail.riskLevel,
                        style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (detail.matchedName != null && detail.matchedName != detail.rawName) ...[
                      const SizedBox(width: 8),
                      Text(
                        '→ ${detail.matchedName}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                    if (!detail.isClassified) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Unclassified',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                if (detail.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail.description!,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _riskColor(double score) {
    if (score <= 2) return AppTheme.safe;
    if (score <= 4) return const Color(0xFF8BC34A); // light green
    if (score <= 6) return AppTheme.moderate;
    if (score <= 8) return const Color(0xFFFF7043); // orange-red
    return AppTheme.unsafe;
  }
}
