import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:findwell_app/models/project.dart';
import 'package:findwell_app/models/paper.dart';
import 'package:findwell_app/models/settings.dart';

/// Local storage service using Hive (NoSQL) + flutter_secure_storage (API keys).
class StorageService {
  static const _projectsBox = 'projects';
  static const _papersBox = 'papers';
  static const _settingsBox = 'settings';
  static const _apiKeyKey = 'llm_api_key';
  static const _supabaseAnonKeyKey = 'supabase_anon_key';

  final FlutterSecureStorage _secureStorage;
  late Box<String> _projects;
  late Box<String> _papers;
  late Box<String> _settings;

  StorageService() : _secureStorage = const FlutterSecureStorage();

  /// Initialize Hive and open boxes.
  Future<void> init() async {
    await Hive.initFlutter();
    _projects = await Hive.openBox<String>(_projectsBox);
    _papers = await Hive.openBox<String>(_papersBox);
    _settings = await Hive.openBox<String>(_settingsBox);
  }

  // ── Projects ──────────────────────────────────────────────

  Future<List<ResearchProject>> getProjects() async {
    final projects = <ResearchProject>[];
    for (final key in _projects.keys) {
      final json = _projects.get(key);
      if (json != null) {
        try {
          projects.add(ResearchProject.fromJson(jsonDecode(json)));
        } catch (_) {}
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<ResearchProject?> getProject(String id) async {
    final json = _projects.get(id);
    if (json == null) return null;
    return ResearchProject.fromJson(jsonDecode(json));
  }

  Future<void> saveProject(ResearchProject project) async {
    await _projects.put(project.id, jsonEncode(project.toJson()));
  }

  Future<void> deleteProject(String id) async {
    await _projects.delete(id);
    // Also delete associated papers
    final keysToDelete = <String>[];
    for (final key in _papers.keys) {
      if ((key as String).startsWith('$id:')) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      await _papers.delete(key);
    }
  }

  // ── Papers ────────────────────────────────────────────────

  Future<List<Paper>> getPapersForProject(String projectId) async {
    final papers = <Paper>[];
    for (final key in _papers.keys) {
      if ((key as String).startsWith('$projectId:')) {
        final json = _papers.get(key);
        if (json != null) {
          try {
            papers.add(Paper.fromJson(jsonDecode(json)));
          } catch (_) {}
        }
      }
    }
    return papers;
  }

  Future<void> savePaper(String projectId, Paper paper) async {
    await _papers.put('$projectId:${paper.id}', jsonEncode(paper.toJson()));
  }

  Future<void> removePaper(String projectId, String paperId) async {
    await _papers.delete('$projectId:$paperId');
  }

  // ── Settings ──────────────────────────────────────────────

  Future<AppSettings> getSettings() async {
    final settingsJson = _settings.get('app_settings');
    final storedKey = await _secureStorage.read(key: _apiKeyKey);
    final apiKey = (storedKey != null && storedKey.isNotEmpty)
        ? storedKey
        : 'YOUR_OPENROUTER_API_KEY';
    final supabaseAnonKey = await _secureStorage.read(key: _supabaseAnonKeyKey) ??
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (settingsJson == null) {
      return AppSettings(apiKey: apiKey, supabaseAnonKey: supabaseAnonKey);
    }
    return AppSettings.fromJson(jsonDecode(settingsJson)).copyWith(
      apiKey: apiKey,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    // Save API key and Supabase key securely
    await _secureStorage.write(key: _apiKeyKey, value: settings.apiKey);
    await _secureStorage.write(
        key: _supabaseAnonKeyKey, value: settings.supabaseAnonKey);
    // Save the rest in Hive
    await _settings.put('app_settings', jsonEncode(settings.toJson()));
  }

  // ── Auth Persistence ──────────────────────────────────────
  static const _isLoggedInKey = 'is_logged_in';

  bool get isLoggedIn => _settings.get(_isLoggedInKey) == 'true';

  Future<void> setLoggedIn(bool loggedIn) async {
    await _settings.put(_isLoggedInKey, loggedIn ? 'true' : 'false');
  }
}