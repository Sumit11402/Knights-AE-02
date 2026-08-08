import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/models/chat_message.dart';
import 'package:findwell_app/providers/project_provider.dart';
import 'package:findwell_app/providers/chat_provider.dart';
import 'package:findwell_app/widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ChatScreen({super.key, required this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  String? _attachedDocName;
  String? _attachedDocText;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _parseExtractedFileText(String fileName, Uint8List? bytes, String? filePath) {
    if (bytes == null || bytes.isEmpty) return 'Attached Document: $fileName';

    final lower = fileName.toLowerCase();

    // Plain text formats (.txt, .md, .csv, .json)
    if (lower.endsWith('.txt') || lower.endsWith('.md') || lower.endsWith('.csv') || lower.endsWith('.json')) {
      try {
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }

    // PDF or Binary Formats
    try {
      final raw = String.fromCharCodes(bytes);
      final textMatches = RegExp(r'\(([^)]+)\)\s*(?:Tj|TJ)')
          .allMatches(raw)
          .map((m) => m.group(1) ?? '')
          .where((t) => t.trim().length > 1 && !t.startsWith('/'))
          .join(' ');

      if (textMatches.trim().length > 20) {
        final cleanText = textMatches
            .replaceAll(RegExp(r'\\(\d{3}|[nrtbf\(\)\\])'), ' ')
            .replaceAll(RegExp(r'[^\x20-\x7E\x0A\x0D]'), '')
            .trim();
        if (cleanText.isNotEmpty) return cleanText;
      }

      final cleanPrintable = RegExp(r'[\x20-\x7E\x0A\x0D]{4,}')
          .allMatches(raw)
          .map((m) => m.group(0) ?? '')
          .where((s) =>
              !s.contains('%PDF') &&
              !s.contains('obj') &&
              !s.contains('endobj') &&
              !s.contains('stream') &&
              !s.contains('xref') &&
              !s.contains('Font') &&
              !s.contains('Catalog'))
          .join('\n')
          .trim();

      if (cleanPrintable.isNotEmpty) {
        return cleanPrintable;
      }
    } catch (_) {}

    return 'Document Attachment: "$fileName" (Binary document attached for research analysis)';
  }

  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        Uint8List? bytes = file.bytes;

        if (bytes == null && file.path != null) {
          final f = File(file.path!);
          bytes = await f.readAsBytes();
        }

        final content = _parseExtractedFileText(fileName, bytes, file.path);

        if (content.trim().isNotEmpty) {
          setState(() {
            _attachedDocName = fileName;
            _attachedDocText = content.trim();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attached "$fileName"'),
                backgroundColor: AppColors.accentPurple,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      _showAttachDocumentDialog();
    }
  }

  void _showAttachDocumentDialog() {
    final docTitleCtrl = TextEditingController();
    final docTextCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: AppColors.accentPurple),
            SizedBox(width: 8),
            Text('Attach Research Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _pickDocumentFile();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentPurple,
                  side: const BorderSide(color: AppColors.accentPurple),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick File from Device Storage'),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('OR PASTE TEXT', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: docTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Document / Paper Title',
                  hintText: 'e.g. Attention Is All You Need.pdf',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: docTextCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Document Text / Content / Abstract',
                  hintText: 'Paste the extracted text or key findings from your document here...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = docTitleCtrl.text.trim().isEmpty ? 'Research_Document.pdf' : docTitleCtrl.text.trim();
              final text = docTextCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _attachedDocName = name;
                  _attachedDocText = text;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPurple, foregroundColor: Colors.white),
            child: const Text('Attach Document'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectProvider(widget.projectId));
    final chat = ref.watch(chatProvider(widget.projectId));
    final theme = Theme.of(context);

    // Auto-scroll when messages change
    ref.listen(chatProvider(widget.projectId), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Research Chat'),
            if (project != null)
              Text(
                project.topic,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.history_rounded, color: AppColors.accentPurple),
            onPressed: () => _showChatHistorySheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyChatState(
                    onSuggestionTap: (text) {
                      _inputCtrl.text = text;
                      _send();
                    },
                    topic: project?.topic ?? '',
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chat.messages.length +
                        (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= chat.messages.length) {
                        return const ChatBubble(
                          content: '',
                          isUser: false,
                          isStreaming: true,
                        );
                      }
                      final msg = chat.messages[index];
                      return ChatBubble(
                        content: msg.content,
                        isUser: msg.role ==
                            MessageRole.user,
                        timestamp: msg.timestamp,
                      );
                    },
                  ),
          ),

          // Error banner
          if (chat.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chat.error!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref
                        .read(chatProvider(widget.projectId).notifier)
                        .clearError(),
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: AppColors.darkCardBorder.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attached Document Chip Tag
                  if (_attachedDocName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 16, color: AppColors.accentPurple),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _attachedDocName!,
                              style: const TextStyle(fontSize: 12, color: AppColors.accentPurple, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => setState(() {
                              _attachedDocName = null;
                              _attachedDocText = null;
                            }),
                            child: const Icon(Icons.close, size: 16, color: AppColors.accentPurple),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _pickDocumentFile,
                        tooltip: 'Attach PDF / Research Document',
                        icon: const Icon(Icons.attach_file_rounded, color: AppColors.accentPurple),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _inputCtrl,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Ask about your research...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: chat.isLoading ? null : _send,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            chat.isLoading
                                ? Icons.hourglass_top
                                : Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    ref
        .read(chatProvider(widget.projectId).notifier)
        .sendMessage(
          text,
          attachedDocName: _attachedDocName,
          attachedDocText: _attachedDocText,
        );
    _focusNode.requestFocus();
  }

  void _showChatHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final projects = ref.watch(projectsProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.science, color: AppColors.accentPurple, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Chat History',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/new-project');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Past Chats List
              Expanded(
                child: projects.isEmpty
                    ? Center(
                        child: Text(
                          'No previous chats found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: projects.length,
                        itemBuilder: (c, idx) {
                          final p = projects[idx];
                          final isCurrent = p.id == widget.projectId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.accentPurple.withValues(alpha: 0.12)
                                  : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.accentPurple
                                    : (isDark ? AppColors.darkCardBorder : Colors.grey.shade200),
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.accentPurple : Colors.grey.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: isCurrent ? Colors.white : AppColors.accentPurple,
                                ),
                              ),
                              title: Text(
                                p.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                p.chatHistory.isNotEmpty
                                    ? (p.chatHistory.last['content'] ?? 'Chat session')
                                    : 'Tap to view conversation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: isCurrent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentPurple,
                                        borderRadius: BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  : const Icon(Icons.chevron_right, size: 18),
                              onTap: () {
                                Navigator.pop(ctx);
                                if (!isCurrent) {
                                  context.pushReplacement('/project/${p.id}/chat');
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty Chat State with Suggestions ──

class _EmptyChatState extends StatelessWidget {
  final Function(String) onSuggestionTap;
  final String topic;

  const _EmptyChatState({
    required this.onSuggestionTap,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final suggestions = [
      'What are the key research gaps in this area?',
      'Suggest a novel methodology for this topic.',
      'What datasets should I use for experiments?',
      'Help me formulate research hypotheses.',
      'What are potential limitations to address?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.psychology,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Research Assistant',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Ask me anything about your research.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Try asking:',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.accentPurple)),
            const SizedBox(height: 12),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSuggestionTap(s),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.darkCardBorder
                                .withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                size: 16,
                                color: AppColors.accentPurple
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s,
                                style:
                                    theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}


