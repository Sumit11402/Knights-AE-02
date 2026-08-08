import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/providers/settings_provider.dart';
import 'package:findwell_app/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _endpointCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _supabaseUrlCtrl;
  late TextEditingController _supabaseKeyCtrl;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _endpointCtrl = TextEditingController(text: settings.apiEndpoint);
    _apiKeyCtrl = TextEditingController(text: settings.apiKey);
    _modelCtrl = TextEditingController(text: settings.model);
    _supabaseUrlCtrl = TextEditingController(text: settings.supabaseUrl);
    _supabaseKeyCtrl = TextEditingController(text: settings.supabaseAnonKey);
  }

  @override
  void dispose() {
    _endpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _supabaseUrlCtrl.dispose();
    _supabaseKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── LLM Configuration Section ──
          _SectionHeader(title: 'AI Model & Configuration', icon: Icons.api),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model Selection', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      '4-LLM Ensemble',
                      'llama-3.1-8b-instant',
                      'openrouter/auto',
                    ].map((m) {
                      final isSelected = settings.model == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) {
                            _modelCtrl.text = m;
                            ref.read(settingsProvider.notifier).setModel(m);
                            if (m == 'openrouter/auto' || m == '4-LLM Ensemble') {
                              _endpointCtrl.text = 'https://openrouter.ai/api/v1';
                              ref.read(settingsProvider.notifier).setApiEndpoint('https://openrouter.ai/api/v1');
                              _apiKeyCtrl.text = 'YOUR_OPENROUTER_API_KEY';
                              ref.read(settingsProvider.notifier).setApiKey('YOUR_OPENROUTER_API_KEY');
                            } else if (m == 'llama-3.1-8b-instant') {
                              _endpointCtrl.text = 'https://api.groq.com/openai/v1';
                              ref.read(settingsProvider.notifier).setApiEndpoint('https://api.groq.com/openai/v1');
                              _apiKeyCtrl.text = 'YOUR_GROQ_API_KEY';
                              ref.read(settingsProvider.notifier).setApiKey('YOUR_GROQ_API_KEY');
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.shield, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'API credentials secured on device',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Temperature slider
                Row(
                  children: [
                    Text('Temperature', style: theme.textTheme.labelLarge),
                    const Spacer(),
                    Text(
                      settings.temperature.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.temperature,
                  min: 0,
                  max: 2,
                  divisions: 20,
                  activeColor: AppColors.accentPurple,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).setTemperature(v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Precise',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontSize: 10)),
                    Text('Creative',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // ── Test Connection ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: settings.isConfigured && !_testing
                    ? _testConnection
                    : null,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.wifi_tethering),
                label:
                    Text(_testing ? 'Testing...' : 'Test Connection'),
              ),
            ),
          ),

          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('✓')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult!.startsWith('✓')
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('✓')
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _testResult!.startsWith('✓')
                          ? AppColors.success
                          : AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Appearance Section ──
          _SectionHeader(title: 'Appearance', icon: Icons.palette),

          GlassCard(
            child: Row(
              children: [
                Icon(Icons.dark_mode,
                    color: AppColors.accentPurple, size: 20),
                const SizedBox(width: 12),
                Text('Dark Mode', style: theme.textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: settings.isDarkMode,
                  activeThumbColor: AppColors.accentPurple,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleDarkMode(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── About Section ──
          _SectionHeader(title: 'About', icon: Icons.info_outline),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.science,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FindWell',
                            style: theme.textTheme.titleMedium),
                        Text('v1.0.0 • Self-Evolving Autonomous Agent',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'FindWell — A secure, self-evolving autonomous research and computer-use agent featuring governed self-improvement, hybrid live RAG, and sandboxed code execution.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final llm = ref.read(llmServiceProvider);
      final result = await llm.testConnection();
      setState(() {
        _testResult = '✓ Connected! Response: "$result"';
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accentPurple),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.accentPurple,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
