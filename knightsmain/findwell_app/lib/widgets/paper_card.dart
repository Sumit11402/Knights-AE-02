import 'package:flutter/material.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/widgets/glass_card.dart';

/// Card widget for displaying a literature paper with actions.
class PaperCard extends StatelessWidget {
  final String title;
  final String authors;
  final String abstract_;
  final String? summary;
  final int? year;
  final List<String> categories;
  final bool isSaved;
  final bool isSummarizing;
  final VoidCallback? onSave;
  final VoidCallback? onRemove;
  final VoidCallback? onSummarize;
  final VoidCallback? onCopyCitation;
  final VoidCallback? onOpenUrl;

  const PaperCard({
    super.key,
    required this.title,
    required this.authors,
    required this.abstract_,
    this.summary,
    this.year,
    this.categories = const [],
    this.isSaved = false,
    this.isSummarizing = false,
    this.onSave,
    this.onRemove,
    this.onSummarize,
    this.onCopyCitation,
    this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      borderColor: isSaved
          ? AppColors.accentPurple.withValues(alpha: 0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Authors + Year
          Row(
            children: [
              Expanded(
                child: Text(
                  authors,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.accentBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (year != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$year',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Categories
          if (categories.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: categories.take(3).map((cat) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightCardBorder.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder.withValues(alpha: 0.3)
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          if (categories.isNotEmpty) const SizedBox(height: 8),

          // Abstract
          Text(
            abstract_,
            style: theme.textTheme.bodyMedium,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          // AI Summary
          if (summary != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: AppColors.accentPurple),
                      const SizedBox(width: 4),
                      Text(
                        'AI Summary',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              if (!isSaved && onSave != null)
                _ActionChip(
                  icon: Icons.bookmark_add_outlined,
                  label: 'Save',
                  onTap: onSave!,
                ),
              if (isSaved && onRemove != null)
                _ActionChip(
                  icon: Icons.bookmark_remove,
                  label: 'Saved',
                  color: AppColors.accentPurple,
                  onTap: onRemove!,
                ),
              const SizedBox(width: 8),
              if (onSummarize != null && summary == null)
                _ActionChip(
                  icon: isSummarizing
                      ? Icons.hourglass_top
                      : Icons.auto_awesome,
                  label: isSummarizing ? 'Summarizing...' : 'AI Summary',
                  onTap: isSummarizing ? () {} : onSummarize!,
                ),
              const Spacer(),
              if (onCopyCitation != null)
                IconButton(
                  onPressed: onCopyCitation,
                  icon: const Icon(Icons.format_quote, size: 18),
                  tooltip: 'Copy BibTeX',
                  visualDensity: VisualDensity.compact,
                ),
              if (onOpenUrl != null)
                IconButton(
                  onPressed: onOpenUrl,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  tooltip: 'Open on arXiv',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
