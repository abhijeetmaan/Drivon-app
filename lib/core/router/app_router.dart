import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/intro_system/presentation/screens/futuristic_intro_screen.dart';
import '../../features/onboarding/presentation/screens/cinematic_onboarding_screen.dart';
import '../../shared/services/onboarding_prefs.dart';
import '../../shared/widgets/app_shell.dart';

/// Notifies [GoRouter] when [authProvider] changes (login, logout, bootstrap).
class GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerRefreshProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen<AsyncValue<AuthSession?>>(authProvider, (_, __) => notifier.notify());
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final authState = ref.read(authProvider);

      if (authState.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      if (authState.hasError) {
        return loc == '/error' ? null : '/error';
      }

      final loggedIn = authState.valueOrNull != null;
      final onAuthPage = loc == '/login' || loc == '/signup';
      final inLaunchFlow = loc == '/splash' || loc == '/intro';
      final onboardingDone = readOnboardingCompletedSync();

      if (!loggedIn) {
        if (inLaunchFlow) return null;
        if (!onAuthPage) return '/login';
        return null;
      }

      if (loc == '/splash' || loc == '/error') {
        return onboardingDone ? '/' : '/onboarding';
      }

      if (onAuthPage) {
        return onboardingDone ? '/' : '/onboarding';
      }

      if (!onboardingDone && loc != '/onboarding') {
        return '/onboarding';
      }

      if (onboardingDone && loc == '/onboarding') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const FuturisticIntroScreen(),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => const AuthBootstrapErrorScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const CinematicOnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class AuthBootstrapErrorScreen extends ConsumerWidget {
  const AuthBootstrapErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final message = auth.hasError ? '${auth.error}' : 'Unknown error';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Could not start the app',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.invalidate(authProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
