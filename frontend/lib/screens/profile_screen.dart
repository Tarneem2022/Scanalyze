import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// 6.8 - Profile & Preferences screen.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  List<String> _allergies = [];
  List<String> _avoidedIngredients = [];
  final _newAllergyController = TextEditingController();
  final _newAvoidedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _newAllergyController.dispose();
    _newAvoidedController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final api = ref.read(apiServiceProvider);
      final prefs = await api.getPreferences();
      setState(() {
        _allergies = List<String>.from(prefs['allergies'] ?? []);
        _avoidedIngredients = List<String>.from(prefs['avoided_ingredients'] ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.updatePreferences(
        allergies: _allergies,
        avoidedIngredients: _avoidedIngredients,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
        );
      }
    }
  }

  void _addAllergy() {
    final val = _newAllergyController.text.trim();
    if (val.isNotEmpty && !_allergies.contains(val.toLowerCase())) {
      setState(() => _allergies.add(val.toLowerCase()));
      _newAllergyController.clear();
      _savePreferences();
    }
  }

  void _addAvoided() {
    final val = _newAvoidedController.text.trim();
    if (val.isNotEmpty && !_avoidedIngredients.contains(val.toLowerCase())) {
      setState(() => _avoidedIngredients.add(val.toLowerCase()));
      _newAvoidedController.clear();
      _savePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textMuted),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/auth');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── User Info ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.bgCardLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              (user?['display_name'] as String? ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.bgDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?['display_name'] as String? ?? 'User',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?['email'] as String? ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ─── Allergies ───
                  _PreferenceSection(
                    title: 'Allergies',
                    subtitle: 'Ingredients that trigger allergy alerts',
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppTheme.unsafe,
                    items: _allergies,
                    controller: _newAllergyController,
                    onAdd: _addAllergy,
                    onRemove: (item) {
                      setState(() => _allergies.remove(item));
                      _savePreferences();
                    },
                    hintText: 'Add allergy (e.g., peanut, gluten)',
                  ),

                  const SizedBox(height: 24),

                  // ─── Avoided Ingredients ───
                  _PreferenceSection(
                    title: 'Avoided Ingredients',
                    subtitle: 'Ingredients you want to avoid (milder alerts)',
                    icon: Icons.block_rounded,
                    iconColor: AppTheme.moderate,
                    items: _avoidedIngredients,
                    controller: _newAvoidedController,
                    onAdd: _addAvoided,
                    onRemove: (item) {
                      setState(() => _avoidedIngredients.remove(item));
                      _savePreferences();
                    },
                    hintText: 'Add ingredient (e.g., palm oil)',
                  ),
                ],
              ),
            ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<String> items;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  final String hintText;

  const _PreferenceSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        // Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: hintText),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
              iconSize: 32,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Chip(
              label: Text(item, style: const TextStyle(fontSize: 13)),
              backgroundColor: AppTheme.bgCardLight,
              deleteIcon: const Icon(Icons.close_rounded, size: 16),
              deleteIconColor: AppTheme.textMuted,
              onDeleted: () => onRemove(item),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.bgCardLight),
              ),
            );
          }).toList(),
        ),

        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'None added yet',
              style: TextStyle(color: AppTheme.textMuted.withAlpha(120), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}
