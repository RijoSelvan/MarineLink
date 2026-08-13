import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';

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

  bool isAddingToCart = false;
  bool isWishlistLoading = false;
  bool isInWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
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
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: isInWishlist
                        ? Colors.red
                        : Colors.white,
                    size: 28,
                  ),
                ),
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
                        Icons.star,
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${product.quantity} kg available',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                            Icons.person,
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
                        icon: Icons.remove,
                        onPressed: quantity > 1
                            ? () {
                                setState(() {
                                  quantity--;
                                });
                              }
                            : null,
                      ),

                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity kg',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _quantityButton(
                        icon: Icons.add,
                        onPressed:
                            quantity < product.quantity
                                ? () {
                                    setState(() {
                                      quantity++;
                                    });
                                  }
                                : null,
                      ),
                    ],
                  ),

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

                      onPressed: product.quantity <= 0 ||
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
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'ADD TO CART',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // AVAILABILITY MESSAGE
                  // ==================================================

                  if (product.quantity <= 0)
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
    if (widget.product.quantity <= 0) {
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
            textColor: Colors.white,
            onPressed: () {
              // Cart navigation can be connected
              // through the Buyer Dashboard.
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
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: 270,
        color: const Color(0xffE8F4F8),
        child: const Icon(
          Icons.set_meal,
          size: 110,
          color: Color(0xff0A4D68),
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
        return Container(
          width: double.infinity,
          height: 270,
          color: const Color(0xffE8F4F8),
          child: const Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 70,
                color: Color(0xff0A4D68),
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