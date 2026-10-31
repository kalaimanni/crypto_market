import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../market/domain/models.dart';
import '../../market/presentation/providers.dart';
import '../../market/presentation/widgets/coin_tile.dart';
import '../../market/presentation/widgets/state_views.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final coins = ref.watch(coinsProvider);

    return SafeArea(
      child: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(statsProvider)),
        data: (s) {
          final other = (100 - s.btcDominance - s.ethDominance).clamp(0, 100).toDouble();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(statsProvider.future),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('Market statistics', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _Metric('Total market cap', Fmt.compact(s.marketCap), sub: Fmt.percent(s.change24h), subColor: changeColor(s.change24h))),
                const SizedBox(width: 12),
                Expanded(child: _Metric('24h volume', Fmt.compact(s.volume))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Metric('Active coins', Fmt.compact(s.activeCoins, currency: false))),
                const SizedBox(width: 12),
                Expanded(child: _Metric('Markets', Fmt.compact(s.markets, currency: false))),
              ]),
              const SizedBox(height: 20),
              Text('Dominance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: PieChart(PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 34,
                        sections: [
                          PieChartSectionData(value: s.btcDominance, color: const Color(0xFFF7931A), radius: 18, showTitle: false),
                          PieChartSectionData(value: s.ethDominance, color: AppColors.accent, radius: 18, showTitle: false),
                          PieChartSectionData(value: other, color: AppColors.border, radius: 18, showTitle: false),
                        ],
                      )),
                    ),
                    const SizedBox(width: 24),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Legend(const Color(0xFFF7931A), 'BTC', s.btcDominance),
                      _Legend(AppColors.accent, 'ETH', s.ethDominance),
                      _Legend(AppColors.border, 'Others', other),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              ...coins.maybeWhen(
                data: (list) {
                  final sorted = [...list]..sort((a, b) => (b.change24h ?? 0).compareTo(a.change24h ?? 0));
                  return [
                    _Movers('Top gainers', sorted.take(3).toList()),
                    const SizedBox(height: 16),
                    _Movers('Top losers', sorted.reversed.take(3).toList()),
                  ];
                },
                orElse: () => const [],
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.sub, this.subColor});
  final String label, value;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            if (sub != null) Text(sub!, style: TextStyle(color: subColor, fontSize: 12)),
          ]),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label, this.value);
  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label  ${value.toStringAsFixed(1)}%'),
        ]),
      );
}

class _Movers extends StatelessWidget {
  const _Movers(this.title, this.coins);
  final String title;
  final List<Coin> coins;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(child: Column(children: [for (final c in coins) CoinTile(coin: c)])),
      ]);
}
