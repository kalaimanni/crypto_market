import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../market/presentation/providers.dart';
import '../../market/presentation/widgets/coin_tile.dart';
import '../../market/presentation/widgets/state_views.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(watchedCoinsProvider);
    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Watchlist', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: coins.when(
            loading: () => const LoadingList(count: 5),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(watchedCoinsProvider)),
            data: (list) => list.isEmpty
                ? const EmptyView(
                    icon: Icons.star_border_rounded,
                    title: 'Your watchlist is empty',
                    subtitle: 'Tap the star on any coin to track it here.',
                  )
                : ListView.builder(itemCount: list.length, itemBuilder: (_, i) => CoinTile(coin: list[i])),
          ),
        ),
      ]),
    );
  }
}
