import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:findwell_app/models/project.dart';

/// Supabase Cloud Storage & Auth Service for FindWell.
class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  static bool get isInitialized => _initialized && _client != null;

  /// Initialize Supabase with the provided URL and Anon Key.
  static Future<bool> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (url.isEmpty || anonKey.isEmpty) return false;
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase is not initialized. Please configure credentials in Settings.');
    }
    return _client!;
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  // ── Projects Sync ─────────────────────────────────────────

  Future<List<ResearchProject>> fetchProjects() async {
    final response = await client
        .from('projects')
        .select()
        .order('updated_at', ascending: false);
    
    return (response as List).map((map) {
      final rawHistory = map['chat_history'] as List? ?? [];
      return ResearchProject(
        id: map['id'] as String,
        topic: map['topic'] as String,
        domain: map['domain'] as String?,
        currentStage: ResearchStage.values[map['current_stage'] as int? ?? 0],
        outline: map['outline'] as String?,
        chatHistory: rawHistory
            .map((m) => Map<String, String>.from(m as Map))
            .toList(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }

  Future<void> saveProject(ResearchProject project) async {
    final userId = currentUser?.id;
    await client.from('projects').upsert({
      'id': project.id,
      if (userId != null) 'user_id': userId,
      'topic': project.topic,
      'domain': project.domain,
      'current_stage': project.currentStage.index,
      'outline': project.outline,
      'chat_history': project.chatHistory, // was missing — history never synced
      'updated_at': project.updatedAt.toIso8601String(),
    });
  }

  Future<void> deleteProject(String projectId) async {
    await client.from('projects').delete().eq('id', projectId);
  }

  // ── Vector Similarity Search (pgvector) ────────────────────

  Future<List<Map<String, dynamic>>> searchEvidenceVector({
    required String projectId,
    required List<double> queryEmbedding,
    double threshold = 0.7,
    int count = 5,
  }) async {
    final response = await client.rpc(
      'match_evidence',
      params: {
        'query_embedding': queryEmbedding,
        'match_threshold': threshold,
        'match_count': count,
        'filter_project_id': projectId,
      },
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  // ── Long-Term AI Memory via Supabase Cloud ─────────────────────
  // NOTE: no hardcoded seed fact here anymore — that was overriding every
  // real memory with "User name is Shivam" for every user, on every device.
  static final List<String> _localMemories = [];

  /// Saves a fact to Supabase. Returns true only if the cloud write actually
  /// succeeded — callers should check this instead of assuming it worked,
  /// since a silent failure here is exactly why memory looked "flaky".
  static Future<bool> saveUserMemory(String memoryText) async {
    if (memoryText.trim().isEmpty) return false;
    if (!_localMemories.contains(memoryText)) {
      _localMemories.add(memoryText);
    }

    if (!isInitialized) return false;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final res = await client
          .from('extension_sessions')
          .select('messages')
          .eq('user_id', userId)
          .eq('session_key', 'user_memories')
          .maybeSingle();

      List<dynamic> msgs = [];
      if (res != null && res['messages'] != null) {
        msgs = List.from(res['messages']);
      }
      msgs.add({'role': 'user', 'content': memoryText});

      // If this throws, it is very likely because extension_sessions is
      // missing a UNIQUE constraint on (user_id, session_key) — the
      // onConflict target below requires one to exist in the DB schema.
      await client.from('extension_sessions').upsert({
        'user_id': userId,
        'session_key': 'user_memories',
        'page_title': 'User Persistent Memories',
        'page_domain': 'findwell.ai',
        'page_url': 'https://findwell.ai/memories',
        'messages': msgs,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,session_key');
      return true;
    } catch (e) {
      // TODO: pipe this to your logger/crash reporter instead of print
      // ignore: avoid_print
      print('MEMORY SAVE FAILED: $e');
      return false;
    }
  }

  static Future<List<String>> fetchUserMemories() async {
    if (!isInitialized) return _localMemories;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return _localMemories;

    try {
      final res = await client
          .from('extension_sessions')
          .select('messages')
          .eq('user_id', userId)
          .eq('session_key', 'user_memories')
          .maybeSingle();

      if (res != null && res['messages'] != null) {
        final msgs = res['messages'] as List;
        final fetched = msgs
            .map((m) => m['content'] as String? ?? '')
            .where((txt) => txt.isNotEmpty)
            .toList();
        for (final f in fetched) {
          if (!_localMemories.contains(f)) _localMemories.add(f);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('MEMORY FETCH FAILED: $e');
    }
    // Always return whatever we have locally, even if the network call
    // above failed — better to answer from cache than say "I don't know".
    return _localMemories;
  }

  // NOTE: no fake placeholder UUID here anymore. RLS on conversations/
  // messages requires auth.uid() = user_id, and auth.uid() is NULL for an
  // unauthenticated request — a made-up user_id can never satisfy that, so
  // every write was being silently rejected by Postgres for anyone not
  // actually signed in. Callers must check for null and skip the cloud
  // call (or prompt sign-in) instead of writing under a fake id.
  static String? get effectiveUserId => _client?.auth.currentUser?.id;

  // ── Standalone Conversations & Messages (Cap @ 10) ─────────────

  Future<List<Map<String, dynamic>>> fetchRecentConversations() async {
    if (!isInitialized) return [];
    final userId = effectiveUserId;
    if (userId == null) return [];

    try {
      final response = await client
          .from('conversations')
          .select('*, messages(*)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // ignore: avoid_print
      print('FETCH CONVERSATIONS FAILED: $e');
      return [];
    }
  }

  /// Returns true only if the message actually made it to Supabase.
  /// Callers should check this instead of assuming it worked — a swallowed
  /// exception here was exactly why history looked "flaky" before.
  Future<bool> saveConversationMessage({
    required String conversationId,
    required String title,
    required String role,
    required String content,
    String? attachedDocumentRef,
  }) async {
    if (!isInitialized) return false;
    final userId = effectiveUserId;
    if (userId == null) return false; // not signed in — would fail RLS anyway

    try {
      // 1. Ensure conversation exists & update timestamp (triggers 10-cap retention pruning in DB)
      await client.from('conversations').upsert({
        'id': conversationId,
        'user_id': userId,
        'title': title,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insert message
      await client.from('messages').insert({
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        if (attachedDocumentRef != null) 'attached_document_ref': attachedDocumentRef,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('SAVE CONVERSATION MESSAGE FAILED: $e');
      return false;
    }
  }
}