import 'package:intl/intl.dart';

class Fmt {
  static String price(num? v) {
    if (v == null) return '—';
    if (v >= 1) return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(v);
    return NumberFormat.currency(symbol: '\$', decimalDigits: 6).format(v);
  }

  static String compact(num? v, {bool currency = true}) {
    if (v == null) return '—';
    final s = NumberFormat.compact().format(v);
    return currency ? '\$$s' : s;
  }

  static String percent(num? v) {
    if (v == null) return '—';
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  }
}
