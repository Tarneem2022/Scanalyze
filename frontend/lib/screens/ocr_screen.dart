import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// 6.3 - OCR ingredient extraction screen.
class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key});

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  final _imagePicker = ImagePicker();
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isExtracting = false;
  bool _isSubmitting = false;
  bool _hasExtractedText = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      setState(() {
        _isExtracting = true;
        _error = null;
      });

      // Run on-device OCR via Google ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final extractedText = recognizedText.text;

      if (extractedText.isEmpty) {
        setState(() {
          _isExtracting = false;
          _error = 'No text detected in the image. Please try again with a clearer photo.';
        });
        return;
      }

      setState(() {
        _textController.text = extractedText;
        _isExtracting = false;
        _hasExtractedText = true;
      });
    } catch (e) {
      setState(() {
        _isExtracting = false;
        _error = 'Failed to extract text: ${e.toString()}';
      });
    }
  }

  Future<void> _submitOcrProduct() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final product = await api.createOcrProduct(
        text,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      );

      if (!mounted) return;
      final uri = GoRouterState.of(context).uri;
      final isReturn = uri.queryParameters['action'] == 'return';

      if (mounted) {
        if (isReturn) {
          context.pop(product);
        } else {
          context.pushReplacement('/analysis/${product.id}');
        }
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to submit product. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Capture'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Capture Options ───
            if (!_hasExtractedText) ...[
              Text(
                'Capture Ingredients',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo of the ingredient list on the product label',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Camera button
              _CaptureButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take Photo',
                description: 'Use camera to capture ingredient list',
                color: AppTheme.primary,
                onTap: _isExtracting ? null : () => _captureImage(ImageSource.camera),
              ),

              const SizedBox(height: 16),

              // Gallery button
              _CaptureButton(
                icon: Icons.photo_library_rounded,
                label: 'From Gallery',
                description: 'Select an existing photo',
                color: AppTheme.secondary,
                onTap: _isExtracting ? null : () => _captureImage(ImageSource.gallery),
              ),

              if (_isExtracting) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      SizedBox(height: 16),
                      Text(
                        'Extracting text from image...',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // ─── Extracted Text Editor ───
            if (_hasExtractedText) ...[
              Text(
                'Extracted Ingredients',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Review and edit the extracted text before submitting',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Product name (optional)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Product Name (optional)',
                  prefixIcon: Icon(Icons.label_outline_rounded, color: AppTheme.textMuted),
                ),
              ),

              const SizedBox(height: 16),

              // Ingredients text editor
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.bgCardLight),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: 'Ingredients...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                ),
              ),

              const SizedBox(height: 16),

              // Re-capture button
              TextButton.icon(
                onPressed: () => setState(() {
                  _hasExtractedText = false;
                  _textController.clear();
                }),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Re-capture'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
              ),

              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitOcrProduct,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark),
                        )
                      : const Icon(Icons.analytics_rounded),
                  label: Text(_isSubmitting ? 'Analyzing...' : 'Analyze Product'),
                ),
              ),
            ],

            // ─── Error ───
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.unsafe, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: AppTheme.unsafe, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.bgCardLight),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
