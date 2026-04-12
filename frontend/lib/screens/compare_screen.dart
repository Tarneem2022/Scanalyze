import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/analysis_result.dart';

/// 6.5 - Compare two products side-by-side.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final _barcode1Controller = TextEditingController();
  final _barcode2Controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  // Results
  Product? _product1;
  Product? _product2;
  AnalysisResult? _analysis1;
  AnalysisResult? _analysis2;

  @override
  void dispose() {
    _barcode1Controller.dispose();
    _barcode2Controller.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final b1 = _barcode1Controller.text.trim();
    final b2 = _barcode2Controller.text.trim();

    if (b1.isEmpty || b2.isEmpty) {
      setState(() => _error = 'Please enter both barcodes');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);

      // Fetch both products
      final data1 = await api.getProductByBarcode(b1);
      final data2 = await api.getProductByBarcode(b2);
      final p1 = Product.fromJson(data1['product'] as Map<String, dynamic>);
      final p2 = Product.fromJson(data2['product'] as Map<String, dynamic>);

      // Compare
      final compareData = await api.compareProducts(p1.id, p2.id);
      final comparison = compareData['comparison'] as Map<String, dynamic>;

      setState(() {
        _product1 = Product.fromJson(comparison['product_1']['product'] as Map<String, dynamic>);
        _product2 = Product.fromJson(comparison['product_2']['product'] as Map<String, dynamic>);
        _analysis1 = AnalysisResult.fromJson(comparison['product_1']['analysis'] as Map<String, dynamic>);
        _analysis2 = AnalysisResult.fromJson(comparison['product_2']['analysis'] as Map<String, dynamic>);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not find or compare products. Check barcodes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Input Section ───
            Text('Enter barcodes to compare', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),

            TextField(
              controller: _barcode1Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Product 1 barcode',
                prefixIcon: Icon(Icons.looks_one_rounded, color: AppTheme.primary),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _barcode2Controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Product 2 barcode',
                prefixIcon: Icon(Icons.looks_two_rounded, color: AppTheme.secondary),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _compare,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                      )
                    : const Icon(Icons.compare_arrows_rounded),
                label: Text(_isLoading ? 'Comparing...' : 'Compare'),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.unsafe, fontSize: 13)),
            ],

            // ─── Results ───
            if (_product1 != null && _product2 != null) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _CompareCard(product: _product1!, analysis: _analysis1!)),
                  const SizedBox(width: 12),
                  Expanded(child: _CompareCard(product: _product2!, analysis: _analysis2!)),
                ],
              ),
              const SizedBox(height: 16),
              _ComparisonSummary(analysis1: _analysis1!, analysis2: _analysis2!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final Product product;
  final AnalysisResult analysis;

  const _CompareCard({required this.product, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.scoreColor(analysis.overallScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Column(
        children: [
          Text(
            product.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (product.brand != null && product.brand!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(product.brand!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),

          // Score circle
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(25),
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                analysis.overallScore.toStringAsFixed(0),
                style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.scoreGradient(analysis.overallScore),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppTheme.safetyLabel(analysis.safetyClass),
              style: const TextStyle(color: AppTheme.bgDark, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${analysis.ingredientDetails.length} ingredients',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${analysis.alerts.length} alerts',
            style: TextStyle(
              color: analysis.alerts.isEmpty ? AppTheme.textMuted : AppTheme.moderate,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  final AnalysisResult analysis1;
  final AnalysisResult analysis2;

  const _ComparisonSummary({required this.analysis1, required this.analysis2});

  @override
  Widget build(BuildContext context) {
    final diff = analysis1.overallScore - analysis2.overallScore;
    final winner = diff > 0 ? 'Product 1' : diff < 0 ? 'Product 2' : 'Tie';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Column(
        children: [
          Text('Comparison Summary', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                diff.abs() < 1 ? 'Both products are similar' : '$winner is safer',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (diff.abs() >= 1) ...[
            const SizedBox(height: 8),
            Text(
              'Difference: ${diff.abs().toStringAsFixed(1)} points',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
