import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/market_repository.dart';
import '../domain/models.dart';
import 'package:flutter_riverpod/legacy.dart';

final marketRepositoryProvider =
    Provider((ref) => MarketRepository(ref.watch(apiClientProvider), ref.watch(sharedPrefsProvider)));

class MarketQuery {
  const MarketQuery({
    this.search = '',
    this.sort = SortField.marketCap,
    this.ascending = false,
    this.filter = CoinFilter.all,
  });
  final String search;
  final SortField sort;
  final bool ascending;
  final CoinFilter filter;

  MarketQuery copyWith({String? search, SortField? sort, bool? ascending, CoinFilter? filter}) => MarketQuery(
        search: search ?? this.search,
        sort: sort ?? this.sort,
        ascending: ascending ?? this.ascending,
        filter: filter ?? this.filter,
      );
}

class MarketQueryNotifier extends Notifier<MarketQuery> {
  @override
  MarketQuery build() => const MarketQuery();

  void setSearch(String v) => state = state.copyWith(search: v.trim());
  void setFilter(CoinFilter f) => state = state.copyWith(filter: f);
  void setSort(SortField f) => state = state.sort == f
      ? state.copyWith(ascending: !state.ascending)
      : state.copyWith(sort: f, ascending: f == SortField.name);
}

final marketQueryProvider = NotifierProvider<MarketQueryNotifier, MarketQuery>(MarketQueryNotifier.new);

final coinsProvider = FutureProvider.autoDispose<List<Coin>>((ref) async {
  final q = ref.watch(marketQueryProvider);
  // Debounce search typing: if the query changes within 350 ms this provider is disposed.
  var disposed = false;
  ref.onDispose(() => disposed = true);
  if (q.search.isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (disposed) throw StateError('cancelled');
  }
  return ref.watch(marketRepositoryProvider).coins(
        query: q.search,
        sort: q.sort,
        ascending: q.ascending,
        filter: q.filter,
      );
});

final coinDetailProvider = FutureProvider.autoDispose.family<CoinDetail, String>(
  (ref, id) => ref.watch(marketRepositoryProvider).detail(id),
);

final chartRangeProvider = StateProvider.autoDispose.family<ChartRange, String>((_, __) => ChartRange.d7);

final chartProvider = FutureProvider.autoDispose.family<List<ChartPoint>, String>((ref, id) {
  final range = ref.watch(chartRangeProvider(id));
  return ref.watch(marketRepositoryProvider).chart(id, range);
});

final statsProvider = FutureProvider.autoDispose<MarketStats>(
  (ref) => ref.watch(marketRepositoryProvider).stats(),
);

class WatchlistNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(marketRepositoryProvider).watchlist();

  void toggle(String id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    ref.read(marketRepositoryProvider).saveWatchlist(state);
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, Set<String>>(WatchlistNotifier.new);

final watchedCoinsProvider = FutureProvider.autoDispose<List<Coin>>((ref) {
  final ids = ref.watch(watchlistProvider);
  return ref.watch(marketRepositoryProvider).coinsByIds(ids);
});
