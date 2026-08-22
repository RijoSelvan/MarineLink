class StockHelper {
  /// Constants specified:
  /// 1 box = 50 kg
  /// 1 ton = 20 boxes = 1000 kg
  static const int kgPerBox = 50;
  static const int boxesPerTon = 20;
  static const int kgPerTon = 1000;

  static const String unitReferenceNote =
      '1 Box = 50 kg  •  1 Ton = 20 Boxes (1,000 kg)';

  /// Returns whole box count (avoiding decimals for boxes)
  static int toBoxes(num kg) => (kg / kgPerBox).floor();
  static int toWholeBoxes(num kg) => (kg / kgPerBox).floor();
  static double toTons(num kg) => kg / kgPerTon;

  static String _formatDec(num val, {int decimals = 1}) {
    final double d = val.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    return d.toStringAsFixed(decimals);
  }

  /// Detailed human-readable stock summary with integer boxes:
  /// e.g. "1,000 kg (20 boxes • 1 ton)"
  /// e.g. "250 kg (5 boxes • 0.25 ton)"
  /// e.g. "50 kg (1 box)"
  /// e.g. "0 kg" -> "Out of Stock"
  static String formatStockDetailed(num kg) {
    if (kg <= 0) return 'Out of Stock';

    final int kgInt = kg.toInt();
    final int boxCount = toBoxes(kg);
    final double tons = toTons(kg);

    if (kg >= kgPerTon) {
      final String tonsStr = _formatDec(tons, decimals: 2);
      return '$kgInt kg ($boxCount boxes • $tonsStr ton${tons == 1 ? '' : 's'})';
    } else if (kg >= kgPerBox) {
      final String tonsStr = _formatDec(tons, decimals: 2);
      return '$kgInt kg ($boxCount box${boxCount == 1 ? '' : 'es'} • $tonsStr ton)';
    } else {
      return '$kgInt kg (< 1 box)';
    }
  }

  /// Compact stock string for cards:
  /// e.g. "20 Boxes (1 Ton)" or "5 Boxes (250 kg)"
  static String formatStockBadge(num kg) {
    if (kg <= 0) return 'Out of Stock';

    final int boxCount = toBoxes(kg);
    final double tons = toTons(kg);

    if (kg >= kgPerTon) {
      return '$boxCount Boxes (${_formatDec(tons, decimals: 2)} Tons)';
    } else if (kg >= kgPerBox) {
      return '$boxCount Box${boxCount == 1 ? '' : 'es'} (${kg.toInt()} kg)';
    } else {
      return '${kg.toInt()} kg (< 1 Box)';
    }
  }

  /// Breakdown of selected quantity when buyer selects kg:
  /// e.g. for 100 kg -> "2 boxes • 0.1 ton"
  static String formatSelectedQuantity(num kg) {
    if (kg <= 0) return '0 kg';
    final int boxCount = toBoxes(kg);
    final double tons = toTons(kg);
    if (kg >= kgPerTon) {
      return '$boxCount boxes • ${_formatDec(tons, decimals: 2)} tons';
    } else if (kg >= kgPerBox) {
      return '$boxCount box${boxCount == 1 ? '' : 'es'} (${_formatDec(tons, decimals: 2)} ton)';
    } else {
      return '${kg.toInt()} kg (< 1 box)';
    }
  }
}
