import 'package:flutter/material.dart';
import 'package:findwell_app/app/theme.dart';

/// Shimmer loading placeholder for cards and content.
class LoadingShimmer extends StatefulWidget {
  final double height;
  final double width;
  final double borderRadius;
  final int lines;

  const LoadingShimmer({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = 8,
    this.lines = 1,
  });

  /// Creates a card-shaped shimmer placeholder.
  const LoadingShimmer.card({super.key})
      : height = 120,
        width = double.infinity,
        borderRadius = 16,
        lines = 0;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lines > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.lines, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildShimmerBar(
              width: i == widget.lines - 1
                  ? widget.width * 0.6
                  : widget.width,
            ),
          );
        }),
      );
    }

    return _buildShimmerBar(width: widget.width, height: widget.height);
  }

  Widget _buildShimmerBar({
    required double width,
    double? height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkCard : AppColors.lightCard;
    final highlightColor =
        isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height ?? widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                baseColor,
                highlightColor.withValues(alpha: 0.5),
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
