import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_client.dart';
import '../domain/models.dart';


class MarketRepository {
  MarketRepository(this._api, this._prefs);
  final ApiClient _api;
  final SharedPreferences _prefs;

  final _cache = <String, ({DateTime at, Object data})>{};

  Future<T> _cached<T extends Object>(String key, Duration ttl, Future<T> Function() load) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) return hit.data as T;
    try {
      final data = await load();
      _cache[key] = (at: DateTime.now(), data: data);
      return data;
    } catch (_) {
      if (hit != null) return hit.data as T; // serve stale data instead of failing
      rethrow;
    }
  }

  Future<List<Coin>> _markets() => _cached('markets', const Duration(seconds: 60), () async {
        final res = await _api.get<List<dynamic>>('/coins/markets', query: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 100,
          'page': 1,
          'sparkline': true,
          'price_change_percentage': '24h',
        });
        return res.map((e) => Coin.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<List<Coin>> coins({
    String query = '',
    SortField sort = SortField.marketCap,
    bool ascending = false,
    CoinFilter filter = CoinFilter.all,
  }) async {
    var list = await _markets();
    final q = query.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => c.name.toLowerCase().contains(q) || c.symbol.toLowerCase().contains(q)).toList();
    }
    list = switch (filter) {
      CoinFilter.all => list,
      CoinFilter.gainers => list.where((c) => (c.change24h ?? 0) > 0).toList(),
      CoinFilter.losers => list.where((c) => (c.change24h ?? 0) < 0).toList(),
    };
    int cmp(Coin a, Coin b) => switch (sort) {
          SortField.marketCap => a.marketCap.compareTo(b.marketCap),
          SortField.price => a.price.compareTo(b.price),
          SortField.volume => a.volume.compareTo(b.volume),
          SortField.change => (a.change24h ?? 0).compareTo(b.change24h ?? 0),
          SortField.name => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        };
    final sorted = [...list]..sort(cmp);
    return ascending ? sorted : sorted.reversed.toList();
  }

  Future<List<Coin>> coinsByIds(Set<String> ids) async {
    if (ids.isEmpty) return [];
    final key = 'ids:${(ids.toList()..sort()).join(',')}';
    return _cached(key, const Duration(seconds: 60), () async {
      final res = await _api.get<List<dynamic>>('/coins/markets', query: {
        'vs_currency': 'usd',
        'ids': ids.join(','),
        'order': 'market_cap_desc',
        'sparkline': true,
        'price_change_percentage': '24h',
      });
      return res.map((e) => Coin.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<CoinDetail> detail(String id) => _cached('detail:$id', const Duration(minutes: 2), () async {
        final d = await _api.get<Map<String, dynamic>>('/coins/${Uri.encodeComponent(id)}', query: {
          'localization': false,
          'tickers': false,
          'community_data': false,
          'developer_data': false,
        });
        final m = d['market_data'] as Map<String, dynamic>;
        double? usd(String k) => ((m[k] as Map?)?['usd'] as num?)?.toDouble();
        final description = ((d['description']?['en'] as String?) ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
        return CoinDetail(
          coin: Coin(
            id: d['id'],
            symbol: (d['symbol'] as String).toUpperCase(),
            name: d['name'],
            image: d['image']?['large'] ?? '',
            price: usd('current_price') ?? 0,
            marketCap: usd('market_cap') ?? 0,
            volume: usd('total_volume') ?? 0,
            rank: d['market_cap_rank'],
            change24h: (m['price_change_percentage_24h'] as num?)?.toDouble(),
            circulatingSupply: (m['circulating_supply'] as num?)?.toDouble() ?? 0,
            maxSupply: (m['max_supply'] as num?)?.toDouble(),
          ),
          description: description.length > 600 ? '${description.substring(0, 600)}…' : description,
          high24h: usd('high_24h') ?? 0,
          low24h: usd('low_24h') ?? 0,
          ath: usd('ath') ?? 0,
          atl: usd('atl') ?? 0,
          totalSupply: (m['total_supply'] as num?)?.toDouble(),
          change7d: (m['price_change_percentage_7d'] as num?)?.toDouble(),
          change30d: (m['price_change_percentage_30d'] as num?)?.toDouble(),
          categories: List<String>.from((d['categories'] as List?)?.whereType<String>() ?? const []),
        );
      });

  Future<List<ChartPoint>> chart(String id, ChartRange range) =>
      _cached('chart:$id:${range.days}', range == ChartRange.d1 ? const Duration(minutes: 1) : const Duration(minutes: 5),
          () async {
        final res = await _api.get<Map<String, dynamic>>('/coins/${Uri.encodeComponent(id)}/market_chart',
            query: {'vs_currency': 'usd', 'days': range.days});
        return (res['prices'] as List)
            .map((p) => ChartPoint(DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt()), (p[1] as num).toDouble()))
            .toList();
      });

  Future<MarketStats> stats() => _cached('global', const Duration(minutes: 2), () async {
        final res = await _api.get<Map<String, dynamic>>('/global');
        final d = res['data'] as Map<String, dynamic>;
        final pct = d['market_cap_percentage'] as Map<String, dynamic>;
        return MarketStats(
          marketCap: (d['total_market_cap']['usd'] as num).toDouble(),
          volume: (d['total_volume']['usd'] as num).toDouble(),
          change24h: (d['market_cap_change_percentage_24h_usd'] as num?)?.toDouble() ?? 0,
          btcDominance: (pct['btc'] as num).toDouble(),
          ethDominance: (pct['eth'] as num).toDouble(),
          activeCoins: d['active_cryptocurrencies'] ?? 0,
          markets: d['markets'] ?? 0,
        );
      });

  Set<String> watchlist() => (_prefs.getStringList('watchlist') ?? const []).toSet();
  Future<void> saveWatchlist(Set<String> ids) => _prefs.setStringList('watchlist', ids.toList());
}
