import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:findwell_app/app/theme.dart';

/// Chat message bubble with Markdown rendering.
class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;
  final DateTime? timestamp;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.accentPurple.withValues(alpha: 0.2)
                    : (isDark
                        ? AppColors.darkCard.withValues(alpha: 0.7)
                        : AppColors.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.accentPurple.withValues(alpha: 0.3)
                      : (isDark
                          ? AppColors.darkCardBorder.withValues(alpha: 0.3)
                          : AppColors.lightCardBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  else
                    MarkdownBody(
                      data: content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge,
                        h1: Theme.of(context).textTheme.headlineLarge,
                        h2: Theme.of(context).textTheme.headlineMedium,
                        h3: Theme.of(context).textTheme.titleLarge,
                        code: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: AppColors.accentCyan,
                          backgroundColor:
                              AppColors.darkBg.withValues(alpha: 0.5),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.darkBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.darkCardBorder.withValues(alpha: 0.3),
                          ),
                        ),
                        codeblockPadding: const EdgeInsets.all(12),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.accentPurple,
                              width: 3,
                            ),
                          ),
                        ),
                        blockquotePadding:
                            const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                        listBullet: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  if (isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 20,
                        height: 14,
                        child: _TypingIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: AppColors.accentBlue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 20,
          height: 14,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TypingDot(index: 0, progress: _controller.value),
                const SizedBox(width: 3),
                _TypingDot(index: 1, progress: _controller.value),
                const SizedBox(width: 3),
                _TypingDot(index: 2, progress: _controller.value),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TypingDot extends StatelessWidget {
  final int index;
  final double progress;
  const _TypingDot({required this.index, required this.progress});

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.2;
    final value = (progress - delay).clamp(0.0, 1.0);
    final opacity = (0.3 + 0.7 * (1 - (2 * value - 1).abs()));
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
