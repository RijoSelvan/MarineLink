import 'package:flutter/material.dart';

class CategoryHelper {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String all = 'All';
  static const String fish = 'Fish';
  static const String prawns = 'Prawns';
  static const String crab = 'Crab';
  static const String others = 'Others';

  static const List<String> categories = [
    all,
    fish,
    prawns,
    crab,
    others,
  ];

  static const List<String> selectableCategories = [
    fish,
    prawns,
    crab,
    others,
  ];

  // ============================================================
  // CATEGORY ASSET IMAGES
  // ============================================================

  static const String fishImagePath = 'assets/images/categories/fish.jpg';
  static const String prawnsImagePath = 'assets/images/categories/prawns.jpg';
  static const String crabImagePath = 'assets/images/categories/crab.jpg';
  static const String othersImagePath = 'assets/images/categories/others.jpg';
  static const String allImagePath = 'assets/images/categories/all.jpg';

  /// Returns the asset path of the real photo for each seafood category.
  static String getCategoryAssetImage(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'fish':
        return fishImagePath;
      case 'prawns':
        return prawnsImagePath;
      case 'crab':
        return crabImagePath;
      case 'others':
        return othersImagePath;
      case 'all':
      default:
        return allImagePath;
    }
  }

  /// Returns a descriptive subtitle for the category.
  static String getCategorySubtitle(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'fish':
        return 'Mackerel, Tuna & Seer';
      case 'prawns':
        return 'Fresh Tiger & White Prawns';
      case 'crab':
        return 'Blue & Mud Crabs';
      case 'others':
        return 'Squid & Cuttlefish';
      case 'all':
      default:
        return 'All Fresh Seafood';
    }
  }

  /// Builds a photo-based category image widget with fallback to emoji.
  static Widget buildCategoryImageWidget({
    required String category,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final String assetPath = getCategoryAssetImage(category);
    Widget imageWidget = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => buildCategoryIconWidget(
        category: category,
        size: (width != null && width < 40) ? 20 : 28,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  /// Builds a modern photo icon/avatar for a product or category with graceful fallback.
  static Widget buildProductIcon({
    required String category,
    String? fishName,
    double size = 48,
    double borderRadius = 12,
    bool isCircle = false,
  }) {
    final String resolvedCategory = determineCategory(
      category: category,
      fishName: fishName,
    );
    final String assetPath = getCategoryAssetImage(resolvedCategory);

    final Widget imageWidget = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => Container(
        width: size,
        height: size,
        color: getCategoryLightColor(resolvedCategory),
        child: Center(
          child: Text(
            getCategoryEmoji(resolvedCategory),
            style: TextStyle(fontSize: size * 0.48),
          ),
        ),
      ),
    );

    if (isCircle) {
      return ClipOval(
        child: SizedBox(width: size, height: size, child: imageWidget),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: imageWidget),
    );
  }



  // ============================================================
  // CATEGORY EMOJI
  // ============================================================

  /// Returns the emoji character for each seafood category.
  static String getCategoryEmoji(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'all':
        return '🐠';
      case 'fish':
        return '🐟';
      case 'prawns':
        return '🦐';
      case 'crab':
        return '🦀';
      case 'others':
      default:
        return '🌊';
    }
  }

  // ============================================================
  // CATEGORY ICONS (fallback Material icons)
  // ============================================================

  static IconData getCategoryIcon(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'all':
        return Icons.apps_rounded;
      case 'fish':
        return Icons.set_meal_rounded;
      case 'prawns':
        return Icons.set_meal_rounded;
      case 'crab':
        return Icons.set_meal_rounded;
      case 'others':
      default:
        return Icons.waves_rounded;
    }
  }

  // ============================================================
  // CATEGORY ICON WIDGET (emoji-based)
  // ============================================================

  /// Builds a category-appropriate emoji widget with background color.
  static Widget buildCategoryIconWidget({
    required String category,
    double size = 32,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final Color bgColor = backgroundColor ?? getCategoryLightColor(category);
    final String emoji = getCategoryEmoji(category);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY COLORS
  // ============================================================

  static Color getCategoryColor(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'fish':
        return const Color(0xff0A4D68);
      case 'prawns':
        return const Color(0xffD85C27);
      case 'crab':
        return const Color(0xffC0392B);
      case 'others':
        return const Color(0xff6C3483);
      case 'all':
      default:
        return const Color(0xff0A4D68);
    }
  }

  static Color getCategoryLightColor(String category) {
    switch (normalizeCategoryKey(category)) {
      case 'fish':
        return const Color(0xffE8F4F8);
      case 'prawns':
        return const Color(0xffFDEFEA);
      case 'crab':
        return const Color(0xffFBEAEA);
      case 'others':
        return const Color(0xffF4ECF7);
      case 'all':
      default:
        return const Color(0xffE8F4F8);
    }
  }

  // ============================================================
  // NORMALIZATION
  // ============================================================

  /// Returns normalized lowercase key: 'all', 'fish', 'prawns', 'crab', 'others'
  static String normalizeCategoryKey(String? input) {
    if (input == null) return 'others';
    final String raw = input.trim().toLowerCase();
    if (raw.isEmpty || raw == 'all') return 'all';

    // 1. Prawns / Shrimp / Pawn
    if (_isPrawns(raw)) return 'prawns';

    // 2. Crab / Crabs
    if (_isCrab(raw)) return 'crab';

    // 3. Fish
    if (_isFish(raw)) return 'fish';

    // 4. Others (Squid, Shellfish, etc.)
    if (_isOthers(raw)) return 'others';

    return 'others';
  }

  // ============================================================
  // DETERMINE DISPLAY CATEGORY
  // ============================================================

  /// Inspects product fields (category, fishType, fishName, description)
  /// and returns a clean, capitalized category: "Fish", "Prawns", "Crab", or "Others".
  static String determineCategory({
    String? category,
    String? fishType,
    String? fishName,
    String? description,
  }) {
    // 1. Check category field
    if (category != null && category.trim().isNotEmpty) {
      final key = normalizeCategoryKey(category);
      if (key != 'others' && key != 'all') {
        return getDisplayCategory(key);
      }
    }

    // 2. Check fishType field
    if (fishType != null && fishType.trim().isNotEmpty) {
      final key = normalizeCategoryKey(fishType);
      if (key != 'others' && key != 'all') {
        return getDisplayCategory(key);
      }
    }

    // 3. Check fishName field
    if (fishName != null && fishName.trim().isNotEmpty) {
      final key = normalizeCategoryKey(fishName);
      if (key != 'others' && key != 'all') {
        return getDisplayCategory(key);
      }
    }

    // 4. Check description field
    if (description != null && description.trim().isNotEmpty) {
      final key = normalizeCategoryKey(description);
      if (key != 'others' && key != 'all') {
        return getDisplayCategory(key);
      }
    }

    // 5. If category was explicitly set to something else (e.g. 'Others' / 'Squid')
    if (category != null && category.trim().isNotEmpty) {
      return getDisplayCategory(normalizeCategoryKey(category));
    }

    if (fishType != null && fishType.trim().isNotEmpty) {
      return getDisplayCategory(normalizeCategoryKey(fishType));
    }

    return fish;
  }

  // ============================================================
  // GET DISPLAY CATEGORY NAME
  // ============================================================

  static String getDisplayCategory(String key) {
    switch (key.toLowerCase()) {
      case 'fish':
        return fish;
      case 'prawns':
      case 'prawn':
      case 'shrimp':
      case 'shrimps':
      case 'pawn':
      case 'pawns':
        return prawns;
      case 'crab':
      case 'crabs':
        return crab;
      case 'others':
      case 'other':
        return others;
      default:
        return fish;
    }
  }

  // ============================================================
  // MATCHES CATEGORY FILTER
  // ============================================================

  static bool matchesCategory({
    required String selectedCategory,
    String? category,
    String? fishType,
    String? fishName,
    String? description,
  }) {
    final String selectedKey = normalizeCategoryKey(selectedCategory);
    if (selectedKey == 'all') return true;

    // Check primary category
    final String resolvedCategory = determineCategory(
      category: category,
      fishType: fishType,
      fishName: fishName,
      description: description,
    );

    final String resolvedKey = normalizeCategoryKey(resolvedCategory);
    if (resolvedKey == selectedKey) return true;

    // Fallback: check if the search keywords match anywhere in combined text
    final String combined = '${category ?? ''} ${fishType ?? ''} ${fishName ?? ''} ${description ?? ''}'.toLowerCase();

    if (selectedKey == 'prawns' && _isPrawns(combined)) return true;
    if (selectedKey == 'crab' && _isCrab(combined)) return true;
    if (selectedKey == 'fish' && _isFish(combined)) return true;
    if (selectedKey == 'others' && _isOthers(combined)) return true;

    return false;
  }

  // ============================================================
  // HELPER CHECKERS
  // ============================================================

  static bool _isPrawns(String text) {
    final lower = text.toLowerCase();
    return lower.contains('prawn') ||
        lower.contains('shrimp') ||
        lower.contains('pawn') || // common typo support
        lower.contains('scampi') ||
        lower.contains('vannamei') ||
        lower.contains('lobster');
  }

  static bool _isCrab(String text) {
    final lower = text.toLowerCase();
    return lower.contains('crab') ||
        lower.contains('crabs') ||
        lower.contains('dungeness');
  }

  static bool _isFish(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('fish') ||
        lower.contains('marine fish') ||
        lower.contains('sea fish') ||
        lower.contains('freshwater fish')) {
      return true;
    }

    const fishKeywords = [
      'tuna',
      'sardine',
      'mackerel',
      'pomfret',
      'salmon',
      'cod',
      'tilapia',
      'rohu',
      'catla',
      'hilsa',
      'barramundi',
      'snapper',
      'seer',
      'kingfish',
      'anchovy',
      'anchovies',
      'ribbonfish',
      'trout',
      'bass',
      'grouper',
      'halibut',
      'mahi',
      'carp',
      'perch',
      'pollock',
      'swordfish',
      'sailfish',
      'marlin',
      'barracuda',
      'mullet',
      'catfish',
      'bhetki',
      'surmai',
      'vanjaram',
      'bangda',
      'ayala',
      'mathi',
      'rawas',
      'bombay duck',
    ];

    for (final word in fishKeywords) {
      if (lower.contains(word)) {
        return true;
      }
    }

    return false;
  }

  static bool _isOthers(String text) {
    final lower = text.toLowerCase();
    return lower.contains('squid') ||
        lower.contains('octopus') ||
        lower.contains('cuttlefish') ||
        lower.contains('clam') ||
        lower.contains('mussel') ||
        lower.contains('oyster') ||
        lower.contains('scallop') ||
        lower.contains('shellfish') ||
        lower.contains('seaweed') ||
        lower.contains('eel') ||
        lower.contains('other');
  }
}
