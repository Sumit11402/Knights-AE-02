import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:findwell_app/models/chat_message.dart';
import 'package:findwell_app/providers/settings_provider.dart';
import 'package:findwell_app/providers/project_provider.dart';
import 'package:findwell_app/services/supabase_service.dart';

const _uuid = Uuid();

/// Chat state for a specific project.
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, String>(
        (ref, projectId) {
  return ChatNotifier(ref, projectId);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final String projectId;

  ChatNotifier(this._ref, this.projectId) : super(const ChatState());

  /// Send a message and get an AI response.
  Future<void> sendMessage(
    String content, {
    String? attachedDocName,
    String? attachedDocText,
  }) async {
    if (content.trim().isEmpty) return;

    final cleanText = content.trim();

    // Auto-detect "Remember..." directives and save to memory
    if (cleanText.toLowerCase().contains('remember')) {
      try {
        String fact = cleanText;
        if (cleanText.toLowerCase().startsWith('remember')) {
          fact = cleanText.substring(8).replaceAll(RegExp(r'^(that|my|is|:)+\s*', caseSensitive: false), '').trim();
        }
        final saved = await SupabaseService.saveUserMemory(fact);
        if (!saved) {
          state = state.copyWith(
            error: "Couldn't save that to your memory — check your connection or sign-in.",
          );
        }
      } catch (_) {}
    }

    // Add user message
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: cleanText,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final llm = _ref.read(llmServiceProvider);
      final project = _ref.read(projectProvider(projectId));

      // Build history for API (last 20 messages)
      final history = state.messages
          .where((m) => m.role != MessageRole.system)
          .take(20)
          .map((m) => m.toApiMessage())
          .toList();

      final memories = await SupabaseService.fetchUserMemories();

      final response = await llm.researchChat(
        topic: project?.topic ?? 'Research',
        history: history.sublist(0, history.length - 1), // exclude current
        userMessage: content.trim(),
        outline: project?.outline,
        memories: memories,
        attachedDocName: attachedDocName,
        attachedDocText: attachedDocText,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
      );

      // Persist to project chat history
      _ref.read(projectsProvider.notifier).addChatMessage(
            projectId,
            {'role': 'user', 'content': content.trim()},
          );
      _ref.read(projectsProvider.notifier).addChatMessage(
            projectId,
            {'role': 'assistant', 'content': response},
          );

      // Persist to standalone conversations table (capped @ 10 recent)
      final supabase = SupabaseService();
      final title = project?.topic ?? cleanText;
      final userSaved = await supabase.saveConversationMessage(
        conversationId: projectId,
        title: title,
        role: 'user',
        content: cleanText,
        attachedDocumentRef: attachedDocName,
      );
      final assistantSaved = await supabase.saveConversationMessage(
        conversationId: projectId,
        title: title,
        role: 'assistant',
        content: response,
      );
      if (!userSaved || !assistantSaved) {
        state = state.copyWith(
          error: "Couldn't sync this chat to the cloud — check your connection or sign-in.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}