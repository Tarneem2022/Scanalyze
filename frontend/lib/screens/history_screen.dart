import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

/// 6.6 - History of analyzed products.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getHistory();
      setState(() {
        _history = data.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(int historyId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteHistoryEntry(historyId);
      setState(() => _history.removeWhere((h) => h['id'] == historyId));
    } catch (_) {}
  }

  Future<void> _clearAll() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.clearHistory();
      setState(() => _history.clear());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.textMuted),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  title: const Text('Clear History?'),
                  content: const Text('This will remove all history entries.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearAll();
                      },
                      child: const Text('Clear', style: TextStyle(color: AppTheme.unsafe)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: AppTheme.textMuted.withAlpha(80)),
                      const SizedBox(height: 16),
                      const Text('No analysis history yet', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    final product = entry['product'] as Map<String, dynamic>?;
                    final analysis = entry['analysis'] as Map<String, dynamic>?;

                    final name = product?['name'] as String? ?? 'Unknown';
                    final brand = product?['brand'] as String? ?? '';
                    final score = (analysis?['overall_score'] as num?)?.toDouble();
                    final safetyClass = analysis?['safety_class'] as String? ?? 'UNKNOWN';
                    final viewedAt = entry['viewed_at'] as String? ?? '';
                    final productId = product?['id'] as int?;

                    final scoreColor = score != null ? AppTheme.scoreColor(score) : AppTheme.textMuted;

                    return Dismissible(
                      key: Key('history_${entry['id']}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerBg,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: const Icon(Icons.delete_rounded, color: AppTheme.unsafe),
                      ),
                      onDismissed: (_) => _deleteEntry(entry['id'] as int),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: InkWell(
                            onTap: productId != null ? () => context.push('/analysis/$productId') : null,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Score circle
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: scoreColor.withAlpha(25),
                                      border: Border.all(color: scoreColor, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        score?.toStringAsFixed(0) ?? '?',
                                        style: TextStyle(
                                          color: scoreColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: scoreColor.withAlpha(20),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                AppTheme.safetyLabel(safetyClass),
                                                style: TextStyle(
                                                  color: scoreColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            if (brand.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Text(brand, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatDate(viewedAt),
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 50)),
                    );
                  },
                ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
