import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'buyer_product_details_screen.dart';

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final ProductService productService = ProductService();

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';
  String selectedCategory = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: productService.getProducts(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xff0A4D68),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Unable to load products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        // Convert Firestore documents to Product objects
        final List<Product> products = documents.map((document) {
          final data = document.data();

          return Product(
            id: data['id']?.toString() ?? document.id,
            fishName: data['fishName']?.toString() ?? '',
            category: data['category']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
            imageUrl: data['imageUrl']?.toString() ?? '',
            exporterId: data['exporterId']?.toString() ?? '',
            exporterName:
                data['exporterName']?.toString() ?? 'Exporter',
            price: _toDouble(data['price']),
            quantity: _toInt(data['quantity']),
            rating: _toDouble(data['rating']),
            isAvailable: data['isAvailable'] == true,
          );
        }).where((product) {
          // Only show available products
          if (!product.isAvailable || product.quantity <= 0) {
            return false;
          }

          // Search filter
          if (searchText.isNotEmpty) {
            final search = searchText.toLowerCase();

            final matchesName =
                product.fishName.toLowerCase().contains(search);

            final matchesCategory =
                product.category.toLowerCase().contains(search);

            if (!matchesName && !matchesCategory) {
              return false;
            }
          }

          // Category filter
          if (selectedCategory != 'All' &&
              product.category.toLowerCase() !=
                  selectedCategory.toLowerCase()) {
            return false;
          }

          return true;
        }).toList();

        return _buildHome(products);
      },
    );
  }

  Widget _buildHome(List<Product> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeCard(),

          const SizedBox(height: 25),

          _searchBar(),

          const SizedBox(height: 25),

          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _categories(),

          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Products',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${products.length} items',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          if (products.isEmpty)
            _emptyProducts()
          else
            ...products.map(
              (product) => _productCard(product),
            ),
        ],
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff0A4D68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Buyer 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Find fresh seafood directly from trusted exporters.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchText = value.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search fish, prawns, crab...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchText = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _categories() {
    return SizedBox(
      height: 105,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _category(
            Icons.all_inclusive,
            'All',
            'All',
          ),
          _category(
            Icons.set_meal,
            'Fish',
            'Fish',
          ),
          _category(
            Icons.water,
            'Prawns',
            'Prawns',
          ),
          _category(
            Icons.cruelty_free,
            'Crab',
            'Crab',
          ),
          _category(
            Icons.anchor,
            'Others',
            'Others',
          ),
        ],
      ),
    );
  }

  Widget _category(
    IconData icon,
    String title,
    String category,
  ) {
    final bool selected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        width: 75,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: selected
                  ? const Color(0xff0A4D68)
                  : const Color(0xffE8F4F8),
              child: Icon(
                icon,
                color: selected
                    ? Colors.white
                    : const Color(0xff0A4D68),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(Product product) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BuyerProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              _productImage(product.imageUrl),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.fishName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      product.category,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '₹${product.price.toStringAsFixed(0)}/kg',
                      style: const TextStyle(
                        color: Color(0xff0A4D68),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Stock: ${product.quantity} kg',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xffE8F4F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.set_meal,
          size: 40,
          color: Color(0xff0A4D68),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 75,
        height: 75,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 75,
            height: 75,
            color: const Color(0xffE8F4F8),
            child: const Icon(
              Icons.broken_image,
              color: Color(0xff0A4D68),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 70,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Exporters have not added any available fish yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}