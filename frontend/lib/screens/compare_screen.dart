import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

  // Manual IDs (for OCR products)
  int? _manualId1;
  int? _manualId2;

  @override
  void dispose() {
    _barcode1Controller.dispose();
    _barcode2Controller.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final b1 = _barcode1Controller.text.trim();
    final b2 = _barcode2Controller.text.trim();

    if ((b1.isEmpty && _manualId1 == null) || (b2.isEmpty && _manualId2 == null)) {
      setState(() => _error = 'Please enter or scan both products');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);

      // Fetch or use products
      int? id1 = _manualId1;
      int? id2 = _manualId2;

      if (id1 == null) {
        final data1 = await api.getProductByBarcode(b1);
        id1 = Product.fromJson(data1['product'] as Map<String, dynamic>).id;
      }

      if (id2 == null) {
        final data2 = await api.getProductByBarcode(b2);
        id2 = Product.fromJson(data2['product'] as Map<String, dynamic>).id;
      }

      // Compare
      final compareData = await api.compareProducts(id1, id2);
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
        _error = 'Could not find or compare products. Check barcodes or try again.';
      });
    }
  }

  Future<void> _scanBarcode(int slot) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _BarcodeScannerForCompare(),
      ),
    );
    if (result != null) {
      setState(() {
        if (slot == 1) {
          _barcode1Controller.text = result;
          _manualId1 = null;
        } else {
          _barcode2Controller.text = result;
          _manualId2 = null;
        }
      });
    }
  }

  Future<void> _scanOcr(int slot) async {
    final result = await context.push<Product>('/ocr?action=return');
    if (result != null) {
      setState(() {
        if (slot == 1) {
          _barcode1Controller.text = 'OCR: ${result.name}';
          _manualId1 = result.id;
        } else {
          _barcode2Controller.text = 'OCR: ${result.name}';
          _manualId2 = result.id;
        }
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
              onChanged: (val) => setState(() => _manualId1 = null),
              decoration: InputDecoration(
                hintText: 'Product 1 barcode',
                prefixIcon: const Icon(Icons.looks_one_rounded, color: AppTheme.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
                      onPressed: () => _scanBarcode(1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded, color: AppTheme.primary),
                      onPressed: () => _scanOcr(1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _barcode2Controller,
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _manualId2 = null),
              decoration: InputDecoration(
                hintText: 'Product 2 barcode',
                prefixIcon: const Icon(Icons.looks_two_rounded, color: AppTheme.secondary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.secondary),
                      onPressed: () => _scanBarcode(2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded, color: AppTheme.secondary),
                      onPressed: () => _scanOcr(2),
                    ),
                  ],
                ),
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

/// Lightweight barcode scanner used only by Compare screen.
/// Uses Navigator.push/pop instead of GoRouter to avoid redirect issues.
class _BarcodeScannerForCompare extends StatefulWidget {
  const _BarcodeScannerForCompare();

  @override
  State<_BarcodeScannerForCompare> createState() => _BarcodeScannerForCompareState();
}

class _BarcodeScannerForCompareState extends State<_BarcodeScannerForCompare> {
  MobileScannerController? _controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    _scanned = true;
    Navigator.of(context).pop(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
          Container(color: Colors.black.withAlpha(120)),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 2),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
