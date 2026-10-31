import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../domain/models.dart';
import '../providers.dart';

Color changeColor(num? v) => (v ?? 0) >= 0 ? AppColors.up : AppColors.down;

class CoinAvatar extends StatelessWidget {
  const CoinAvatar(this.coin, {super.key, this.size = 40});
  final Coin coin;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
        child: CachedNetworkImage(
          imageUrl: coin.image,
          width: size,
          height: size,
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.surfaceHigh,
            child: Text(coin.symbol.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          placeholder: (_, __) => Container(width: size, height: size, color: AppColors.surfaceHigh),
        ),
      );
}

class CoinTile extends ConsumerWidget {
  const CoinTile({super.key, required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref.watch(watchlistProvider).contains(coin.id);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/coin/${coin.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          SizedBox(width: 22, child: Text('${coin.rank ?? '-'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
          Hero(tag: 'coin-${coin.id}', child: CoinAvatar(coin)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(coin.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${coin.symbol} · MCap ${Fmt.compact(coin.marketCap)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
          ),
          if (coin.sparkline.length > 2) SizedBox(width: 64, height: 28, child: Sparkline(coin.sparkline, color: changeColor(coin.change24h))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Fmt.price(coin.price), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(Fmt.percent(coin.change24h), style: TextStyle(color: changeColor(coin.change24h), fontSize: 12)),
          ]),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
            icon: Icon(watched ? Icons.star_rounded : Icons.star_border_rounded, color: watched ? Colors.amber : AppColors.textMuted),
            onPressed: () => ref.read(watchlistProvider.notifier).toggle(coin.id),
          ),
        ]),
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, required this.color});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minY: values.reduce((a, b) => a < b ? a : b),
          maxY: values.reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              barWidth: 1.6,
              color: color,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      );
}
