import 'package:flutter/material.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/models/project.dart';

/// Visual indicator showing research progress through 4 stages.
class StageIndicator extends StatelessWidget {
  final ResearchStage currentStage;

  const StageIndicator({super.key, required this.currentStage});

  static const _stages = [
    _StageInfo(Icons.lightbulb_outline, 'Outline', ResearchStage.outlineDone),
    _StageInfo(Icons.search, 'Papers', ResearchStage.literatureDone),
    _StageInfo(Icons.edit_note, 'Draft', ResearchStage.draftDone),
    _StageInfo(Icons.check_circle_outline, 'Complete', ResearchStage.complete),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _stages.length; i++) ...[
          _buildStageCircle(context, _stages[i], i),
          if (i < _stages.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: currentStage.index >= _stages[i].requiredStage.index
                      ? AppColors.accentPurple
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCardBorder.withValues(alpha: 0.3)
                          : AppColors.lightCardBorder),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStageCircle(
      BuildContext context, _StageInfo info, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = currentStage.index >= info.requiredStage.index;
    final isCurrent = currentStage == info.requiredStage ||
        (index == 0 &&
            (currentStage == ResearchStage.created ||
                currentStage == ResearchStage.outlining));

    final textColor = isActive
        ? (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.textMuted : AppColors.lightTextSecondary);

    final inactiveBg = isDark
        ? AppColors.darkCard.withValues(alpha: 0.5)
        : AppColors.lightCardBorder.withValues(alpha: 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.accentPurple : inactiveBg,
            border: Border.all(
              color: isCurrent
                  ? AppColors.accentPurple
                  : isActive
                      ? AppColors.accentPurple.withValues(alpha: 0.5)
                      : (isDark
                          ? AppColors.darkCardBorder.withValues(alpha: 0.3)
                          : AppColors.lightCardBorder),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.accentPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            info.icon,
            size: 16,
            color: isActive ? Colors.white : (isDark ? AppColors.textMuted : AppColors.lightTextSecondary),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          info.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _StageInfo {
  final IconData icon;
  final String label;
  final ResearchStage requiredStage;

  const _StageInfo(this.icon, this.label, this.requiredStage);
}
