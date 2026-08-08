/// App settings model for LLM configuration, Supabase cloud sync, and preferences.
class AppSettings {
  final String apiEndpoint;
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;
  final bool isDarkMode;
  final String supabaseUrl;
  final String supabaseAnonKey;

  const AppSettings({
    this.apiEndpoint = 'https://openrouter.ai/api/v1',
    this.apiKey = 'YOUR_OPENROUTER_API_KEY',
    this.model = '4-LLM Ensemble',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.isDarkMode = true,
    this.supabaseUrl = 'https://gjxycmdicnilsuwljxzy.supabase.co',
    this.supabaseAnonKey = const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
    ),
  });

  bool get isConfigured => apiKey.isNotEmpty;
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  AppSettings copyWith({
    String? apiEndpoint,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? isDarkMode,
    String? supabaseUrl,
    String? supabaseAnonKey,
  }) {
    return AppSettings(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiEndpoint': apiEndpoint,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'isDarkMode': isDarkMode,
        'supabaseUrl': supabaseUrl,
        // API key and Supabase key stored securely in flutter_secure_storage
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      apiEndpoint: json['apiEndpoint'] as String? ?? 'https://api.openai.com/v1',
      model: json['model'] as String? ?? 'gpt-4o',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      isDarkMode: json['isDarkMode'] as bool? ?? true,
      supabaseUrl: json['supabaseUrl'] as String? ??
          'https://gjxycmdicnilsuwljxzy.supabase.co',
    );
  }
}
