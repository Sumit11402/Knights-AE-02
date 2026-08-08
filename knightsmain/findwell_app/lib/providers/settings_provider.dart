import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findwell_app/models/settings.dart';
import 'package:findwell_app/services/storage_service.dart';
import 'package:findwell_app/services/llm_service.dart';

/// Global storage service provider.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Global LLM service provider.
final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService();
});

/// Settings state provider — manages app configuration.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.read(storageServiceProvider),
    ref.read(llmServiceProvider),
  );
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;
  final LlmService _llm;

  SettingsNotifier(this._storage, this._llm) : super(const AppSettings());

  /// Load settings from storage.
  Future<void> load() async {
    final settings = await _storage.getSettings();
    state = settings;
    _syncLlm(settings);
  }

  /// Update settings and persist.
  Future<void> update(AppSettings settings) async {
    state = settings;
    await _storage.saveSettings(settings);
    _syncLlm(settings);
  }

  /// Update a single field.
  Future<void> setApiEndpoint(String endpoint) async {
    await update(state.copyWith(apiEndpoint: endpoint));
  }

  Future<void> setApiKey(String key) async {
    await update(state.copyWith(apiKey: key));
  }

  Future<void> setModel(String model) async {
    await update(state.copyWith(model: model));
  }

  Future<void> setTemperature(double temp) async {
    await update(state.copyWith(temperature: temp));
  }

  Future<void> setMaxTokens(int tokens) async {
    await update(state.copyWith(maxTokens: tokens));
  }

  Future<void> setSupabaseUrl(String url) async {
    await update(state.copyWith(supabaseUrl: url));
  }

  Future<void> setSupabaseAnonKey(String key) async {
    await update(state.copyWith(supabaseAnonKey: key));
  }

  Future<void> toggleDarkMode() async {
    await update(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void _syncLlm(AppSettings settings) {
    _llm.configure(
      baseUrl: settings.apiEndpoint,
      apiKey: settings.apiKey,
      model: settings.model,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
    );
  }
}

/// Connection test provider.
final connectionTestProvider = FutureProvider.autoDispose<String?>((ref) async {
  return null; // Not auto-tested; triggered manually
});
