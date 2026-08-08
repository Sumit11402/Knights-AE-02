import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:findwell_app/app/router.dart';
import 'package:findwell_app/app/theme.dart';
import 'package:findwell_app/providers/settings_provider.dart';
import 'package:findwell_app/services/storage_service.dart';
import 'package:findwell_app/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.darkBg,
  ));

  // Initialize storage
  final storage = StorageService();
  await storage.init();

  // Initialize Supabase synchronously before app launch
  final settings = await storage.getSettings();
  await SupabaseService.initialize(
    url: settings.supabaseUrl,
    anonKey: settings.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const FindWellApp(),
    ),
  );
}

class FindWellApp extends ConsumerStatefulWidget {
  const FindWellApp({super.key});

  @override
  ConsumerState<FindWellApp> createState() => _FindWellAppState();
}

class _FindWellAppState extends ConsumerState<FindWellApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(settingsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.isDarkMode;

    // Dynamically update System UI overlay style to match active theme cleanly
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp.router(
      title: 'FindWell',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      routerConfig: appRouter,
    );
  }
}
