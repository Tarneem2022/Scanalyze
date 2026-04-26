import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../models/product.dart';

/// 6.2 - Barcode scanning screen.
class BarcodeScreen extends ConsumerStatefulWidget {
  const BarcodeScreen({super.key});

  @override
  ConsumerState<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends ConsumerState<BarcodeScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  String? _error;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    // Check for manual barcode entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final manualBarcode = uri.queryParameters['manual'];
      if (manualBarcode != null && manualBarcode.isNotEmpty) {
        _lookupBarcode(manualBarcode);
      }
    });
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode(String barcode) async {
    if (_isProcessing) return;
    
    // Check if we should return the barcode instead of navigating
    final uri = GoRouterState.of(context).uri;
    final isReturn = uri.queryParameters['action'] == 'return';

    if (isReturn) {
      context.pop(barcode);
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _statusMessage = 'Looking up barcode $barcode...';
    });

    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getProductByBarcode(barcode);
      final product = Product.fromJson(data['product'] as Map<String, dynamic>);

      if (mounted) {
        context.pushReplacement('/analysis/${product.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          // Extract more specific error message if possible
          String errorMessage = 'Product not found for barcode: $barcode';
          if (e.toString().contains('DioException')) {
             if (e.toString().contains('401')) {
                errorMessage = 'Authentication Error: You are not connected to the backend correctly. Please restart the app with the Python backend running.';
             } else if (e.toString().contains('404')) {
                errorMessage = 'Product not found in Local Database, OpenFoodFacts, or OpenBeautyFacts.';
             } else {
                errorMessage = 'Connection Error: Failed to reach the Python Backend. Is it running on the correct IP?';
             }
          }
          _error = errorMessage;
          _statusMessage = null;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    _lookupBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final isManual = uri.queryParameters['manual'] != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: isManual || _isProcessing
          ? _buildLoadingView()
          : _buildScannerView(),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera
        MobileScanner(
          controller: _scannerController!,
          onDetect: _onDetect,
        ),

        // Overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(120),
          ),
        ),

        // Scan window
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

        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.unsafe, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Point camera at barcode',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            const Icon(Icons.error_outline, color: AppTheme.unsafe, size: 64),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.unsafe),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ] else ...[
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(
              _statusMessage ?? 'Processing...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
