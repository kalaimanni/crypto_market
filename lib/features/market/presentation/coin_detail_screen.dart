import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets/coin_tile.dart';
import 'widgets/price_chart.dart';
import 'widgets/state_views.dart';

class CoinDetailScreen extends ConsumerWidget {
  const CoinDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(coinDetailProvider(id));
    final watched = ref.watch(watchlistProvider).contains(id);

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.coin.name ?? ''),
        actions: [
          IconButton(
            icon: Icon(watched ? Icons.star_rounded : Icons.star_border_rounded, color: watched ? Colors.amber : null),
            onPressed: () => ref.read(watchlistProvider.notifier).toggle(id),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(coinDetailProvider(id))),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Hero(tag: 'coin-$id', child: CoinAvatar(d.coin, size: 48)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(Fmt.price(d.coin.price), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${d.coin.symbol}  ·  Rank #${d.coin.rank ?? '-'}', style: const TextStyle(color: AppColors.textMuted)),
                ]),
              ),
              _ChangePill(d.coin.change24h),
            ]),
            const SizedBox(height: 20),
            _ChartSection(id: id),
            const SizedBox(height: 20),
            _StatsGrid(d),
            if (d.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('About ${d.coin.name}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(d.description, style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill(this.v);
  final double? v;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: changeColor(v).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(Fmt.percent(v), style: TextStyle(color: changeColor(v), fontWeight: FontWeight.w600)),
      );
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(chartRangeProvider(id));
    final chart = ref.watch(chartProvider(id));
    return Column(children: [
      Card(
        child: SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: chart.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(chartProvider(id))),
              data: (pts) => pts.length < 2
                  ? const EmptyView(icon: Icons.show_chart, title: 'No chart data', subtitle: 'Nothing to plot for this range.')
                  : PriceChart(points: pts, range: range),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final r in ChartRange.values)
          ChoiceChip(
            label: Text(r.label),
            selected: r == range,
            showCheckmark: false,
            onSelected: (_) => ref.read(chartRangeProvider(id).notifier).state = r,
          ),
      ]),
    ]);
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(this.d);
  final CoinDetail d;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Market cap', Fmt.compact(d.coin.marketCap)),
      ('24h volume', Fmt.compact(d.coin.volume)),
      ('Circulating supply', Fmt.compact(d.coin.circulatingSupply, currency: false)),
      ('Max supply', d.coin.maxSupply == null ? '∞' : Fmt.compact(d.coin.maxSupply, currency: false)),
      ('24h high', Fmt.price(d.high24h)),
      ('24h low', Fmt.price(d.low24h)),
      ('All-time high', Fmt.price(d.ath)),
      ('7d / 30d', '${Fmt.percent(d.change7d)} / ${Fmt.percent(d.change30d)}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: [
        for (final (label, value) in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              ]),
            ),
          ),
      ],
    );
  }
}
