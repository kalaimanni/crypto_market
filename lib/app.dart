import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class CryptoApp extends ConsumerWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'CoinScope',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: ref.watch(routerProvider),
      );
}
