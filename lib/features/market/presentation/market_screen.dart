import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets/coin_tile.dart';
import 'widgets/state_views.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final query = ref.watch(marketQueryProvider);

    return SafeArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(children: [
            Expanded(
              child: Text('Markets', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: ref.read(marketQueryProvider.notifier).setSearch,
            decoration: InputDecoration(
              hintText: 'Search coins…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in CoinFilter.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                    selected: query.filter == f,
                    onSelected: (_) => ref.read(marketQueryProvider.notifier).setFilter(f),
                  ),
                ),
              const VerticalDivider(width: 16, indent: 10, endIndent: 10),
              for (final s in SortField.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    avatar: query.sort == s ? Icon(query.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 14) : null,
                    label: Text(switch (s) {
                      SortField.marketCap => 'Market cap',
                      SortField.price => 'Price',
                      SortField.volume => 'Volume',
                      SortField.change => '24h %',
                      SortField.name => 'Name',
                    }),
                    selected: query.sort == s,
                    showCheckmark: false,
                    onSelected: (_) => ref.read(marketQueryProvider.notifier).setSort(s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: coins.when(
            loading: () => const LoadingList(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(coinsProvider)),
            data: (list) => list.isEmpty
                ? const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No coins found',
                    subtitle: 'Try a different search or filter.',
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(coinsProvider.future),
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => CoinTile(coin: list[i]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}
