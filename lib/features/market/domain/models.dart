class Coin {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.price,
    required this.marketCap,
    required this.volume,
    required this.rank,
    required this.change24h,
    required this.circulatingSupply,
    this.maxSupply,
    this.sparkline = const [],
  });

  final String id, symbol, name, image;
  final double price, marketCap, volume, circulatingSupply;
  final double? change24h, maxSupply;
  final int? rank;
  final List<double> sparkline;

  factory Coin.fromJson(Map<String, dynamic> j) => Coin(
        id: j['id'],
        symbol: (j['symbol'] as String).toUpperCase(),
        name: j['name'],
        image: j['image'] ?? '',
        price: (j['current_price'] ?? 0).toDouble(),
        marketCap: (j['market_cap'] ?? 0).toDouble(),
        volume: (j['total_volume'] ?? 0).toDouble(),
        rank: j['market_cap_rank'],
        change24h: (j['price_change_percentage_24h'] as num?)?.toDouble(),
        circulatingSupply: (j['circulating_supply'] ?? 0).toDouble(),
        maxSupply: (j['max_supply'] as num?)?.toDouble(),
        sparkline: ((j['sparkline_in_7d']?['price'] as List?) ?? const [])
            .map<double>((e) => (e as num).toDouble())
            .toList(),
      );
}

class CoinDetail {
  const CoinDetail({
    required this.coin,
    required this.description,
    required this.high24h,
    required this.low24h,
    required this.ath,
    required this.atl,
    required this.totalSupply,
    required this.change7d,
    required this.change30d,
    required this.categories,
  });

  final Coin coin;
  final String description;
  final double high24h, low24h, ath, atl;
  final double? totalSupply, change7d, change30d;
  final List<String> categories;

  factory CoinDetail.fromJson(Map<String, dynamic> j) => CoinDetail(
        coin: Coin.fromJson(j),
        description: j['description'] ?? '',
        high24h: (j['high_24h'] ?? 0).toDouble(),
        low24h: (j['low_24h'] ?? 0).toDouble(),
        ath: (j['ath'] ?? 0).toDouble(),
        atl: (j['atl'] ?? 0).toDouble(),
        totalSupply: (j['total_supply'] as num?)?.toDouble(),
        change7d: (j['price_change_percentage_7d'] as num?)?.toDouble(),
        change30d: (j['price_change_percentage_30d'] as num?)?.toDouble(),
        categories: List<String>.from(j['categories'] ?? const []),
      );
}

class ChartPoint {
  const ChartPoint(this.time, this.price);
  final DateTime time;
  final double price;
}

class MarketStats {
  const MarketStats({
    required this.marketCap,
    required this.volume,
    required this.change24h,
    required this.btcDominance,
    required this.ethDominance,
    required this.activeCoins,
    required this.markets,
  });

  final double marketCap, volume, change24h, btcDominance, ethDominance;
  final int activeCoins, markets;

  factory MarketStats.fromJson(Map<String, dynamic> j) => MarketStats(
        marketCap: (j['total_market_cap_usd'] ?? 0).toDouble(),
        volume: (j['total_volume_usd'] ?? 0).toDouble(),
        change24h: (j['market_cap_change_percentage_24h_usd'] ?? 0).toDouble(),
        btcDominance: (j['btc_dominance'] ?? 0).toDouble(),
        ethDominance: (j['eth_dominance'] ?? 0).toDouble(),
        activeCoins: j['active_cryptocurrencies'] ?? 0,
        markets: j['markets'] ?? 0,
      );
}

enum SortField { marketCap, price, volume, change, name }

enum CoinFilter { all, gainers, losers }

enum ChartRange {
  d1('24H', '1'),
  d7('7D', '7'),
  d30('30D', '30'),
  d90('90D', '90'),
  y1('1Y', '365');

  const ChartRange(this.label, this.days);
  final String label, days;
}
