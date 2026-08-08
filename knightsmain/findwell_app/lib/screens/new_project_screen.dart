import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/providers/project_provider.dart';
import 'package:findwell_app/providers/settings_provider.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final _topicCtrl = TextEditingController();
  String? _selectedDomain;
  bool _creating = false;

  static const _domains = [
    'Machine Learning',
    'NLP',
    'Computer Vision',
    'Reinforcement Learning',
    'Physics',
    'Biology',
    'Chemistry',
    'Mathematics',
    'Statistics',
    'Economics',
    'Medicine',
    'Other',
  ];

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Research'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.15),
                    AppColors.accentBlue.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.lightbulb,
                      size: 36, color: AppColors.accentPurple),
                  const SizedBox(height: 8),
                  Text(
                    'What do you want to research?',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter a research topic and the AI will generate\nan outline, find papers, and draft your paper.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Topic input
            Text('Research Topic', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _topicCtrl,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                    'e.g., "Attention mechanisms in transformer architectures for low-resource NLP tasks"',
                hintMaxLines: 3,
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 20),

            // Domain selection
            Text('Domain (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _domains.map((domain) {
                final isSelected = _selectedDomain == domain;
                return ChoiceChip(
                  label: Text(domain),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDomain = selected ? domain : null;
                    });
                  },
                  selectedColor:
                      AppColors.accentPurple.withValues(alpha: 0.3),
                  checkmarkColor: AppColors.accentPurple,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.accentPurple
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    _topicCtrl.text.trim().isNotEmpty && !_creating
                        ? _createProject
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  disabledBackgroundColor:
                      AppColors.accentPurple.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _creating
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Creating...'),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rocket_launch, size: 20),
                          SizedBox(width: 8),
                          Text('Start Research',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
            ),

            if (!settings.isConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add your API key in Settings to use AI features.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    setState(() => _creating = true);

    try {
      final project = await ref
          .read(projectsProvider.notifier)
          .createProject(
            _topicCtrl.text.trim(),
            domain: _selectedDomain,
          );

      if (mounted) {
        context.go('/project/${project.id}');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}
