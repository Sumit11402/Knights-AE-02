import 'dart:convert';
import 'package:dio/dio.dart';

/// OpenAI-compatible LLM API client.
///
/// Works with OpenAI, Azure OpenAI, Ollama, LM Studio, Together AI,
/// Groq, or any other provider exposing the `/chat/completions` endpoint.
class LlmService {
  bool _isGibberish(String text) {
    if (text.length < 10) return false;
    
    // Check 1: Multi-script contamination (Cyrillic, Devanagari, Hebrew, Thai, CJK, etc. in same text)
    int scriptCount = 0;
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) scriptCount++; // Cyrillic
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) scriptCount++; // Devanagari (Hindi/Gujarati)
    if (RegExp(r'[\u0590-\u05FF]').hasMatch(text)) scriptCount++; // Hebrew
    if (RegExp(r'[\u0E00-\u0E7F]').hasMatch(text)) scriptCount++; // Thai
    if (RegExp(r'[\u4E00-\u9FFF]').hasMatch(text)) scriptCount++; // Chinese/CJK
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) scriptCount++; // Malayalam
    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(text)) scriptCount++; // Hangul (Korean)

    if (scriptCount >= 2) return true; // Mixed unrelated foreign scripts = token collapse!

    // Check 2: Token corruption code signatures ($url, _metadata, _FEATURE, etc. concatenated with text)
    if (RegExp(r'(\$\w+|\w+_\w{4,}|\b\w+<[A-Z]\w+)').allMatches(text).length >= 2 && scriptCount >= 1) {
      return true;
    }

    // Check 3: Ratio of non-standard characters
    int nonAsciiCount = 0;
    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i);
      if (code > 127 && (code < 0x0600 || code > 0x06FF)) { // exclude standard Arabic/Latin
        nonAsciiCount++;
      }
    }
    return (nonAsciiCount / text.length) > 0.15;
  }

  final Dio _dio;
  String _baseUrl;
  String _apiKey;
  String _model;
  double _temperature;
  int _maxTokens;

  LlmService({
    String baseUrl = 'https://api.openai.com/v1',
    String apiKey = '',
    String model = 'gpt-4o',
    double temperature = 0.7,
    int maxTokens = 4096,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model,
        _temperature = temperature,
        _maxTokens = maxTokens,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  // ── Configuration ─────────────────────────────────────────

  void configure({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (apiKey != null) _apiKey = apiKey;
    if (model != null) _model = model;
    if (temperature != null) _temperature = temperature;
    if (maxTokens != null) _maxTokens = maxTokens;
  }

  bool get isConfigured => _apiKey.isNotEmpty;

  // ── Core Chat Completion ──────────────────────────────────

  /// Send a chat completion request. Returns the assistant's response text.
  Future<String> chatCompletion({
    required List<Map<String, String>> messages,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    if (!isConfigured) {
      throw LlmException('API key not configured. Go to Settings to add your key.');
    }

    final url = '${_baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
    final rawModel = model ?? _model;
    // Map '4-LLM Ensemble' to effective provider model if using direct provider endpoint
    String usedModel = rawModel;
    if (rawModel.toLowerCase().contains('ensemble')) {
      if (_baseUrl.contains('openrouter')) {
        usedModel = 'openai/gpt-4o-mini';
      } else if (_baseUrl.contains('groq')) {
        usedModel = 'llama-3.1-8b-instant';
      } else if (_baseUrl.contains('anthropic')) {
        usedModel = 'claude-3-5-sonnet-20241022';
      } else if (_baseUrl.contains('googleapis')) {
        usedModel = 'gemini-2.0-flash';
      } else {
        usedModel = 'gpt-4o-mini';
      }
    }

    // Models that use max_completion_tokens instead of max_tokens
    final newParamModels = {'o3', 'o3-mini', 'o4-mini', 'gpt-5', 'gpt-5.1', 'gpt-5.2'};
    final noTempModels = {'o3', 'o3-mini', 'o4-mini'};

    final body = <String, dynamic>{
      'model': usedModel,
      'messages': messages,
    };

    if (!noTempModels.contains(usedModel)) {
      body['temperature'] = temperature ?? _temperature;
    }

    final tokens = maxTokens ?? _maxTokens;
    if (newParamModels.contains(usedModel)) {
      body['max_completion_tokens'] = tokens;
    } else {
      body['max_tokens'] = tokens;
    }

    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List;
      if (choices.isEmpty) {
        throw LlmException('No response from LLM');
      }
      final message = choices[0]['message'] as Map<String, dynamic>;
      final content = message['content'] as String? ?? '';
      if (content.trim().isEmpty || _isGibberish(content)) {
        return "I don't have that specific detail saved yet! You can tell me 'Remember [detail]' and I'll keep it stored for you.";
      }
      return content;
    } on DioException catch (e) {
      if (e.response != null) {
        final status = e.response!.statusCode;
        final body = e.response!.data;
        if (status == 401) {
          throw LlmException('Invalid API key. Check your key in Settings.');
        }
        if (status == 429) {
          throw LlmException('Rate limited. Please wait a moment and try again.');
        }
        throw LlmException('API error ($status): $body');
      }
      throw LlmException('Network error: ${e.message}');
    }
  }

  // ── Test Connection ───────────────────────────────────────

  /// Test the connection by sending a simple completion.
  Future<String> testConnection() async {
    final result = await chatCompletion(
      messages: [
        {'role': 'user', 'content': 'Say "connected" in one word.'},
      ],
      maxTokens: 10,
    );
    return result;
  }

  // ── Research Prompts ──────────────────────────────────────

  /// Generate a research outline for the given topic.
  Future<String> generateOutline(String topic, {String? domain}) async {
    return chatCompletion(
      messages: [
        {
          'role': 'system',
          'content': '''You are a senior research advisor and expert academic writer. 
Your task is to decompose a research topic into a structured outline for an academic paper.

Output a well-organized research outline in Markdown format with:
1. **Problem Statement** — clear articulation of the research problem
2. **Research Questions** — 3-5 specific, testable research questions
3. **Background & Motivation** — why this matters, what gap exists
4. **Proposed Methodology** — high-level approach and methods
5. **Expected Contributions** — what this research will contribute
6. **Potential Challenges** — known risks and mitigation strategies

Use bullet points and sub-items. Be specific and actionable. Academic tone.'''
        },
        {
          'role': 'user',
          'content':
              'Generate a comprehensive research outline for: "$topic"${domain != null ? ' (Domain: $domain)' : ''}',
        },
      ],
      maxTokens: 3000,
    );
  }

  /// Summarize a paper abstract using AI.
  Future<String> summarizePaper(String title, String abstract_) async {
    return chatCompletion(
      messages: [
        {
          'role': 'system',
          'content':
              'You are a research paper summarizer. Provide a concise 3-4 sentence summary of the paper\'s key contributions, methodology, and findings. Be specific about what makes this paper notable.',
        },
        {
          'role': 'user',
          'content': 'Title: $title\n\nAbstract: $abstract_',
        },
      ],
      maxTokens: 500,
    );
  }

  /// Generate a specific section of a paper draft.
  Future<String> generateDraftSection({
    required String topic,
    required String section,
    String? outline,
    String? previousSections,
    List<String>? paperSummaries,
  }) async {
    final context = StringBuffer();
    if (outline != null) context.writeln('OUTLINE:\n$outline\n');
    if (previousSections != null) {
      context.writeln('PREVIOUS SECTIONS:\n$previousSections\n');
    }
    if (paperSummaries != null && paperSummaries.isNotEmpty) {
      context.writeln(
          'RELATED PAPERS:\n${paperSummaries.join('\n---\n')}\n');
    }

    return chatCompletion(
      messages: [
        {
          'role': 'system',
          'content': '''You are an expert academic writer specializing in scientific papers.
Write the "$section" section of an academic paper. 

Rules:
- Use formal academic tone appropriate for top-tier venues (NeurIPS/ICML/ICLR)
- Be technically precise and rigorous
- Include relevant citations using [Author, Year] format
- For Introduction: clearly state the problem, motivation, and contributions
- For Related Work: organize by theme, not chronologically
- For Method: be detailed enough to reproduce
- For Experiments: describe setup, datasets, baselines, and metrics
- For Results: present findings with analysis and comparisons
- For Conclusion: summarize contributions and future work
- Write 400-800 words for this section
- Use Markdown formatting with headers, bold, and bullet points where appropriate'''
        },
        {
          'role': 'user',
          'content':
              'Topic: "$topic"\n\n${context.toString()}\n\nWrite the "$section" section now.',
        },
      ],
      maxTokens: 2000,
    );
  }

  /// Research chat Q&A with project context & attached document.
  Future<String> researchChat({
    required String topic,
    required List<Map<String, String>> history,
    required String userMessage,
    String? outline,
    List<String>? memories,
    String? attachedDocName,
    String? attachedDocText,
  }) async {
    final memList = memories ?? [];
    final memoryContext = memList.map((m) => '- $m').join('\n');

    String cleanDocText = (attachedDocText ?? '').trim();
    if (cleanDocText.length > 16000) {
      cleanDocText = cleanDocText.substring(0, 16000) +
          '\n\n[... Document content safely truncated to first 16,000 characters to fit model context window ...]';
    }

    final docBlock = cleanDocText.isNotEmpty
        ? '''

ATTACHED DOCUMENT CONTENT:
Document Name: "${attachedDocName ?? 'Attached Document'}"
==================================================
$cleanDocText
==================================================

CRITICAL DOCUMENT INSTRUCTIONS:
1. The user has attached the document above to this conversation.
2. You MUST use the attached document as your primary authoritative source to answer the user's questions.
3. If the user asks a question that is answered in the document, quote/reference key details directly from it.
4. If the attached document does NOT contain information about a specific question, state clearly and politely: "The attached document does not cover this specific question, but here is what it does discuss: [brief summary]." Never claim that you don't have access to documents.'''
        : '';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            '''You are FindWell, an advanced AI research assistant with persistent long-term memory.
The user is working on a research project about: "$topic".
${outline != null ? '\nTheir research outline:\n$outline\n' : ''}
$docBlock

PERSISTENT USER MEMORY & STORED FACTS:
${memoryContext.isNotEmpty ? memoryContext : 'None saved yet.'}

CRITICAL MEMORY DIRECTIVES:
1. You HAVE long-term memory enabled. Use the stored facts above when relevant to answer user questions.
2. When the user asks you to remember something, acknowledge warmly that you have stored it for future conversations.
3. If asked about a personal fact (such as a name or preference) that is NOT in the stored memories list above, state politely that you don't have that saved yet and invite them to share it. Do NOT lecture or give meta disclaimers.
4. Respond ONLY in clear, natural English.
5. Never output corrupted tokens or foreign non-English scripts.'''
      },
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    return chatCompletion(messages: messages);
  }
}

class LlmException implements Exception {
  final String message;
  LlmException(this.message);

  @override
  String toString() => message;
}