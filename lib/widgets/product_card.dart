import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/category_helper.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = product.isAvailable && product.quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4D68).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Overlays
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      height: 135,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE8F4F8), Color(0xFFD4E9F2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                CategoryHelper.getCategoryAssetImage(product.category),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Text('🐟', style: TextStyle(fontSize: 44)),
                                ),
                              ),
                            )
                          : Image.asset(
                              CategoryHelper.getCategoryAssetImage(product.category),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Text('🐟', style: TextStyle(fontSize: 44)),
                              ),
                            ),
                    ),
                  ),

                  // Category Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A4D68).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category.isNotEmpty ? product.category : 'Fresh Catch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Favorite Button (Top Right)
                  if (onFavoriteTap != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavoriteTap,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? const Color(0xFFFF6B6B) : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Stock Status Badge (Bottom Left of Image)
                  if (!isAvailable)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Product Info Body
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.fishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Exporter name
                    if (product.exporterName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF088395)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              product.exporterName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Price & Rating Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '₹${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFF0A4D68),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const TextSpan(
                                text: '/kg',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (product.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
