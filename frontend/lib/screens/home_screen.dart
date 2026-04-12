import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

/// 6.1 - Main Home Page with navigation hub.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?['display_name'] as String? ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Greeting ───
              Text(
                'Hello, $userName 👋',
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 4),

              Text(
                'Analyze product safety in seconds',
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // ─── Hero Action Buttons ───
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan\nBarcode',
                      gradient: AppTheme.primaryGradient,
                      onTap: () => context.push('/barcode'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.document_scanner_rounded,
                      label: 'OCR\nCapture',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                      ),
                      onTap: () => context.push('/ocr'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.15),

              const SizedBox(height: 24),

              // ─── Quick Access Grid ───
              Text(
                'Quick Access',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Compare',
                      color: AppTheme.accent,
                      onTap: () => context.push('/compare'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.history_rounded,
                      label: 'History',
                      color: AppTheme.moderate,
                      onTap: () => context.go('/history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.favorite_rounded,
                      label: 'Favorites',
                      color: AppTheme.unsafe,
                      onTap: () => context.go('/favorites'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 32),

              // ─── Manual Barcode Entry ───
              Text(
                'Manual Search',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 12),

              _ManualBarcodeSearch(),

              const SizedBox(height: 32),

              // ─── Info Section ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.bgCardLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBg,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('How it works', style: Theme.of(context).textTheme.labelLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoStep(number: '1', text: 'Scan a barcode or capture ingredients via OCR'),
                    const SizedBox(height: 8),
                    _InfoStep(number: '2', text: 'Ingredients are identified and risk-scored'),
                    const SizedBox(height: 8),
                    _InfoStep(number: '3', text: 'Get a safety score with personalized alerts'),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large action card (Barcode / OCR)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: AppTheme.bgDark),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.bgDark,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small quick-access tile
class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.bgCardLight),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manual barcode entry field
class _ManualBarcodeSearch extends StatelessWidget {
  final _controller = TextEditingController();

  _ManualBarcodeSearch();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter barcode number...',
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final barcode = _controller.text.trim();
              if (barcode.isNotEmpty) {
                // Navigate to barcode scan result with manual entry
                context.push('/barcode?manual=$barcode');
              }
            },
            child: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ],
    );
  }
}

/// Info step row
class _InfoStep extends StatelessWidget {
  final String number;
  final String text;

  const _InfoStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
