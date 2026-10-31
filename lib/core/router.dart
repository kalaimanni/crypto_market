import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/market/presentation/coin_detail_screen.dart';
import '../features/market/presentation/market_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/watchlist/presentation/watchlist_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever login state changes (login / logout).
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // splash decides where to go next
      if (!loggedIn && loc != '/login') return '/login';
      if (loggedIn && loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const MarketScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/stats', builder: (_, __) => const StatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistScreen())]),
        ],
      ),
      GoRoute(
        path: '/coin/:id',
        builder: (_, state) => CoinDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
});
