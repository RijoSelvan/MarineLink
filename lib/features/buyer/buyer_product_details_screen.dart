import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/category_helper.dart';
import '../../utils/stock_helper.dart';
import 'buyer_cart_screen.dart';


class BuyerProductDetailsScreen extends StatefulWidget {
  final Product product;

  const BuyerProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<BuyerProductDetailsScreen> createState() =>
      _BuyerProductDetailsScreenState();
}

class _BuyerProductDetailsScreenState
    extends State<BuyerProductDetailsScreen> {
  final ProductService productService = ProductService();

  int quantity = 1;
  late final TextEditingController _quantityController;

  bool isAddingToCart = false;
  bool isWishlistLoading = false;
  bool isInWishlist = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '$quantity');
    _checkWishlist();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQty, int maxStock) {
    int clamped = newQty;
    if (clamped < 1) clamped = 1;
    if (clamped > maxStock && maxStock > 0) clamped = maxStock;
    setState(() {
      quantity = clamped;
    });
    _quantityController.text = '$clamped';
    _quantityController.selection = TextSelection.fromPosition(
      TextPosition(offset: _quantityController.text.length),
    );
  }

  // ================================================================
  // CHECK WISHLIST
  // ================================================================

  Future<void> _checkWishlist() async {
    try {
      final result = await productService.isInWishlist(
        widget.product.id,
      );

      if (!mounted) return;

      setState(() {
        isInWishlist = result;
      });
    } catch (e) {
      // Ignore wishlist check errors.
    }
  }

  // ================================================================
  // TOGGLE WISHLIST
  // ================================================================

  Future<void> _toggleWishlist() async {
    if (isWishlistLoading) return;

    setState(() {
      isWishlistLoading = true;
    });

    String? result;

    if (isInWishlist) {
      result = await productService.removeFromWishlist(
        widget.product.id,
      );
    } else {
      result = await productService.addToWishlist(
        product: widget.product,
      );
    }

    if (!mounted) return;

    setState(() {
      isWishlistLoading = false;
    });

    if (result == null) {
      setState(() {
        isInWishlist = !isInWishlist;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isInWishlist
                ? '${widget.product.fishName} added to wishlist'
                : '${widget.product.fishName} removed from wishlist',
          ),
          backgroundColor: isInWishlist
              ? Colors.green
              : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;

    final double totalPrice = product.price * quantity;

    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,

        title: const Text(
          'Product Details',
        ),

        actions: [
          isWishlistLoading
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _toggleWishlist,
                  tooltip: isInWishlist
                      ? 'Remove from Wishlist'
                      : 'Add to Wishlist',
                  icon: Icon(
                    isInWishlist
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isInWishlist
                        ? Colors.red
                        : Colors.white,
                    size: 28,
                  ),
                ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded, size: 26),
            tooltip: 'View Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuyerCartScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================================
            // PRODUCT IMAGE
            // ========================================================

            _buildProductImage(product.imageUrl),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // PRODUCT NAME
                  // ==================================================

                  Text(
                    product.fishName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1F1F1F),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // CATEGORY
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F4F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        color: Color(0xff0A4D68),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // PRICE
                  // ==================================================

                  Text(
                    '₹${product.price.toStringAsFixed(2)} / kg',
                    style: const TextStyle(
                      fontSize: 25,
                      color: Color(0xff0A4D68),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // RATING
                  // ==================================================

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Product Rating',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // STOCK
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: product.isOutOfStock
                          ? Colors.red.withValues(alpha: 0.08)
                          : Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: product.isOutOfStock
                            ? Colors.red.withValues(alpha: 0.25)
                            : Colors.green.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              product.isOutOfStock
                                  ? Icons.warning_amber_rounded
                                  : Icons.inventory_2_rounded,
                              color: product.isOutOfStock
                                  ? Colors.red
                                  : Colors.green.shade800,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                product.isOutOfStock
                                    ? 'Out of Stock'
                                    : 'Stock Available: ${StockHelper.formatStockDetailed(product.quantity)}',
                                style: TextStyle(
                                  color: product.isOutOfStock
                                      ? Colors.red
                                      : Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!product.isOutOfStock) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  '📦 ${(product.quantity ~/ 50)} Boxes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      Border.all(color: Colors.teal.shade200),
                                ),
                                child: Text(
                                  '⚖️ ${(product.quantity / 1000).toStringAsFixed(product.quantity % 1000 == 0 ? 0 : 2)} Tons',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ℹ️ 1 Box = 50 kg • 1 Ton = 20 Boxes (1,000 kg)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Divider(),

                  const SizedBox(height: 20),

                  // ==================================================
                  // EXPORTER INFORMATION
                  // ==================================================

                  const Text(
                    'Exporter Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Color(0xffE8F4F8),
                          child: Icon(
                            Icons.store_rounded,
                            color: Color(0xff0A4D68),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exporter',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                product.exporterName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    product.description.isEmpty
                        ? 'No description available.'
                        : product.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // QUANTITY
                  // ==================================================

                  const Text(
                    'Select Quantity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _quantityButton(
                        icon: Icons.remove_rounded,
                        onPressed: quantity > 1 && !product.isOutOfStock
                            ? () {
                                _updateQuantity(quantity - 1, product.quantity);
                              }
                            : null,
                      ),
                      const SizedBox(width: 8),

                      Container(
                        width: 95,
                        height: 44,
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          enabled: !product.isOutOfStock,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0A4D68),
                          ),
                          decoration: InputDecoration(
                            suffixText: 'kg',
                            suffixStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xff0A4D68),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val);
                            if (parsed != null && parsed > 0) {
                              final clamped = parsed > product.quantity
                                  ? product.quantity
                                  : parsed;
                              setState(() {
                                quantity = clamped;
                              });
                              if (clamped != parsed) {
                                _quantityController.text = '$clamped';
                                _quantityController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _quantityController.text.length),
                                );
                              }
                            }
                          },
                          onEditingComplete: () {
                            final parsed = int.tryParse(_quantityController.text);
                            if (parsed == null || parsed < 1) {
                              _updateQuantity(1, product.quantity);
                            } else if (parsed > product.quantity) {
                              _updateQuantity(product.quantity, product.quantity);
                            }
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      _quantityButton(
                        icon: Icons.add_rounded,
                        onPressed:
                            quantity < product.quantity && !product.isOutOfStock
                                ? () {
                                    _updateQuantity(quantity + 1, product.quantity);
                                  }
                                : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '≈ ${quantity ~/ 50} Box${(quantity ~/ 50) == 1 ? '' : 'es'} (${(quantity / 1000).toStringAsFixed(2)} Ton)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!product.isOutOfStock) ...[
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            label: const Text('+1 Box (50 kg)'),
                            avatar:
                                const Icon(Icons.add_box_outlined, size: 16),
                            onPressed: () {
                              _updateQuantity(quantity + 50, product.quantity);
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: const Text('+5 Boxes (250 kg)'),
                            avatar: const Icon(Icons.inventory_2_outlined,
                                size: 16),
                            onPressed: () {
                              _updateQuantity(quantity + 250, product.quantity);
                            },
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            label: const Text('+1 Ton (20 Boxes)'),
                            avatar: const Icon(Icons.scale, size: 16),
                            onPressed: () {
                              _updateQuantity(quantity + 1000, product.quantity);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],


                  const SizedBox(height: 25),

                  // ==================================================
                  // TOTAL PRICE
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F4F8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          '₹${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 21,
                            color: Color(0xff0A4D68),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ADD TO CART BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xff0A4D68),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),

                      onPressed: product.isOutOfStock ||
                              isAddingToCart
                          ? null
                          : _addToCart,

                      child: isAddingToCart
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  product.isOutOfStock
                                      ? Icons.remove_shopping_cart_outlined
                                      : Icons.shopping_bag_rounded,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  product.isOutOfStock
                                      ? 'OUT OF STOCK'
                                      : 'ADD TO CART',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // VIEW CART BUTTON
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xff0A4D68), width: 1.5),
                        foregroundColor: const Color(0xff0A4D68),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyerCartScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_rounded),
                      label: const Text(
                        'VIEW CART',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // AVAILABILITY MESSAGE
                  // ==================================================

                  if (product.isOutOfStock)
                    const Center(
                      child: Text(
                        'This product is currently out of stock.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ADD TO CART
  // ================================================================

  Future<void> _addToCart() async {
    if (widget.product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This product is out of stock.',
          ),
          backgroundColor: Colors.red,
        ),
      );


      return;
    }

    setState(() {
      isAddingToCart = true;
    });

    final String? result =
        await productService.addToCart(
      product: widget.product,
      quantity: quantity,
    );

    if (!mounted) return;

    setState(() {
      isAddingToCart = false;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.fishName} added to cart',
          ),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.amberAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BuyerCartScreen(),
                ),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // PRODUCT IMAGE
  // ================================================================

  Widget _buildProductImage(String imageUrl) {
    final String fallbackAsset = CategoryHelper.getCategoryAssetImage(widget.product.category);

    if (imageUrl.trim().isEmpty) {
      return Image.asset(
        fallbackAsset,
        width: double.infinity,
        height: 270,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          width: double.infinity,
          height: 270,
          color: const Color(0xffE8F4F8),
          child: const Center(
            child: Text(
              '🐟',
              style: TextStyle(fontSize: 90),
            ),
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 270,
      fit: BoxFit.cover,
      loadingBuilder:
          (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          width: double.infinity,
          height: 270,
          color: const Color(0xffE8F4F8),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xff0A4D68),
            ),
          ),
        );
      },
      errorBuilder:
          (context, error, stackTrace) {
        return Image.asset(
          fallbackAsset,
          width: double.infinity,
          height: 270,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Container(
            width: double.infinity,
            height: 270,
            color: const Color(0xffE8F4F8),
            child: const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '🐟',
                  style: TextStyle(fontSize: 55),
                ),
                SizedBox(height: 8),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ================================================================
  // QUANTITY BUTTON
  // ================================================================

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final bool disabled = onPressed == null;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: disabled
            ? Colors.grey.shade300
            : const Color(0xff0A4D68),
        borderRadius: BorderRadius.circular(9),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 20,
          color: disabled
              ? Colors.grey
              : Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}