import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';
import 'screens/home_screen.dart';
import 'screens/barcode_screen.dart';
import 'screens/ocr_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/history_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';

class ScanalyzeApp extends ConsumerStatefulWidget {
  const ScanalyzeApp({super.key});

  @override
  ConsumerState<ScanalyzeApp> createState() => _ScanalyzeAppState();
}

class _ScanalyzeAppState extends ConsumerState<ScanalyzeApp> {
  @override
  void initState() {
    super.initState();
    // Check existing auth on startup
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/auth';
        final isAuth = authState.isAuthenticated;

        // Protected routes
        final protectedRoutes = ['/history', '/favorites', '/profile', '/compare'];
        final isProtected = protectedRoutes.any((route) => state.matchedLocation.startsWith(route));

        if (!isAuth && isProtected) {
          return '/auth';
        }

        if (isAuth && loggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
        ShellRoute(
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
            GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
        GoRoute(path: '/barcode', builder: (_, __) => const BarcodeScreen()),
        GoRoute(path: '/ocr', builder: (_, __) => const OcrScreen()),
        GoRoute(
          path: '/analysis/:productId',
          builder: (_, state) {
            final productId = int.parse(state.pathParameters['productId']!);
            return AnalysisScreen(productId: productId);
          },
        ),
        GoRoute(path: '/compare', builder: (_, __) => const CompareScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'Scanalyze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
