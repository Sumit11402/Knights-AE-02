import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:findwell_app/screens/home_screen.dart';
import 'package:findwell_app/screens/settings_screen.dart';
import 'package:findwell_app/screens/new_project_screen.dart';
import 'package:findwell_app/screens/project_detail_screen.dart';
import 'package:findwell_app/screens/chat_screen.dart';
import 'package:findwell_app/screens/auth_screen.dart';
import 'package:findwell_app/services/supabase_service.dart';

bool _determineInitialAuth() {
  try {
    if (SupabaseService.isInitialized) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) return true;
    }
  } catch (_) {}
  return false;
}

final appRouter = GoRouter(
  initialLocation: _determineInitialAuth() ? '/' : '/auth',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/new-project',
      name: 'new-project',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NewProjectScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/project/:id',
      name: 'project-detail',
      pageBuilder: (context, state) {
        final projectId = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProjectDetailScreen(projectId: projectId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/project/:id/chat',
      name: 'project-chat',
      pageBuilder: (context, state) {
        final projectId = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ChatScreen(projectId: projectId),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
