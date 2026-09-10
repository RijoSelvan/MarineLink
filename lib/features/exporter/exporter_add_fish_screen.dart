import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/category_helper.dart';

class AddFishScreen extends StatefulWidget {
  const AddFishScreen({super.key});

  @override
  State<AddFishScreen> createState() => _AddFishScreenState();
}

class _AddFishScreenState extends State<AddFishScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fishNameController = TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? fishType;
  String? quality;
  String? unit;

  bool isLoading = false;

  final List<String> fishTypes = [
    'Tuna',
    'Sardine',
    'Mackerel',
    'Pomfret',
    'Prawns',
    'Crab',
    'Squid',
    'Other',
  ];

  final List<String> qualityTypes = [
    'Premium',
    'Grade A',
    'Grade B',
    'Standard',
  ];

  final List<String> units = [
    'Kg',
    'Ton',
    'Box',
  ];

  @override
  void dispose() {
    fishNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> addFish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (fishType == null || quality == null || unit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select fish type, quality and unit'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String exporterName = 'Exporter';
      String godownAddress = 'Kochi Fishing Harbour Cold Storage Hub, Kerala - 682005';
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final udata = userDoc.data()!;
          if (udata['name'] != null && udata['name'].toString().isNotEmpty) {
            exporterName = udata['name'].toString();
          }
          if (udata['godownAddress'] != null && udata['godownAddress'].toString().isNotEmpty) {
            godownAddress = udata['godownAddress'].toString();
          } else if (udata['location'] != null && udata['location'].toString().isNotEmpty) {
            godownAddress = '${udata['location']} Harbour Godown';
          }
        }
      } catch (_) {}

      final resolvedCategory = CategoryHelper.determineCategory(
        fishType: fishType,
        fishName: fishNameController.text.trim(),
        description: descriptionController.text.trim(),
      );

      final docRef = FirebaseFirestore.instance.collection('products').doc();
      final double qty = double.tryParse(quantityController.text.trim()) ?? 0;
      final double price = double.tryParse(priceController.text.trim()) ?? 0;

      int totalStockKg = qty.toInt();
      double effectivePricePerKg = price;

      if (unit == 'Box') {
        // 1 box = 50 kg
        totalStockKg = (qty * 50).round();
        effectivePricePerKg = price / 50.0;
      } else if (unit == 'Ton') {
        // 1 ton = 20 boxes = 1000 kg
        totalStockKg = (qty * 1000).round();
        effectivePricePerKg = price / 1000.0;
      }

      await docRef.set({
        'id': docRef.id,
        'exporterId': user.uid,
        'exporterName': exporterName,
        'fishName': fishNameController.text.trim(),
        'fishType': fishType,
        'category': resolvedCategory,
        'description': descriptionController.text.trim(),
        'price': effectivePricePerKg,
        'originalPrice': price,
        'quantity': totalStockKg,
        'unit': 'Kg',
        'selectedUnit': unit,
        'quality': quality,
        'location': locationController.text.trim(),
        'godownAddress': godownAddress,
        'imageUrl': '',
        'status': totalStockKg > 0 ? 'Available' : 'Out of Stock',
        'isAvailable': totalStockKg > 0,
        'rating': 0.0,
        'createdAt': Timestamp.now(),
      });



      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fish product added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xff0A4D68),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),
      appBar: AppBar(
        title: const Text('Add Fish'),
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff0A4D68),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.set_meal,
                          color: Color(0xff0A4D68),
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Fish Product',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Add your seafood product for buyers',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Category Photo Preview Card
                Builder(
                  builder: (context) {
                    final currentCategory = CategoryHelper.determineCategory(
                      fishType: fishType,
                      fishName: fishNameController.text.trim(),
                    );
                    return Container(
                      width: double.infinity,
                      height: 130,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              CategoryHelper.getCategoryAssetImage(currentCategory),
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 14,
                              right: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Category Photo: $currentCategory',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        CategoryHelper.getCategorySubtitle(currentCategory),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff0A4D68).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white30),
                                    ),
                                    child: const Text(
                                      'Auto Matched',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  'Fish Information',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0A4D68),
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: fishNameController,
                  decoration: inputDecoration(
                    label: 'Fish Name',
                    icon: Icons.set_meal,
                    hint: 'Enter fish name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter fish name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: fishType,
                  decoration: inputDecoration(
                    label: 'Fish Type',
                    icon: Icons.category,
                  ),
                  items: fishTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      fishType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select fish type';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: quality,
                  decoration: inputDecoration(
                    label: 'Quality',
                    icon: Icons.star,
                  ),
                  items: qualityTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      quality = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select quality';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Quantity & Pricing',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0A4D68),
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: inputDecoration(
                    label: 'Price',
                    icon: Icons.currency_rupee,
                    hint: 'Enter price',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price';
                    }

                    final price = double.tryParse(value.trim());

                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: quantityController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: inputDecoration(
                          label: 'Quantity',
                          icon: Icons.scale,
                          hint: 'Enter quantity',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter quantity';
                          }

                          final quantity =
                              double.tryParse(value.trim());

                          if (quantity == null || quantity <= 0) {
                            return 'Invalid quantity';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        decoration: inputDecoration(
                          label: 'Unit',
                          icon: Icons.straighten,
                        ),
                        items: units.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            unit = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select unit';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Color(0xff0A4D68)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unit == 'Box'
                              ? '📦 1 Box = 50 kg (Price will be calculated per kg: ₹${priceController.text.trim().isNotEmpty && double.tryParse(priceController.text.trim()) != null ? (double.parse(priceController.text.trim()) / 50).toStringAsFixed(1) : "..."} / kg)'
                              : unit == 'Ton'
                                  ? '⚖️ 1 Ton = 20 Boxes = 1,000 kg (Price will be calculated per kg)'
                                  : '💡 Standard Units: 1 Box = 50 kg • 1 Ton = 20 Boxes (1,000 kg)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff0A4D68),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),


                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0A4D68),
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: locationController,
                  decoration: inputDecoration(
                    label: 'Location',
                    icon: Icons.location_on,
                    hint: 'Enter fish location',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: inputDecoration(
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Enter product description',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : addFish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A4D68),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_box),
                              SizedBox(width: 10),
                              Text(
                                'ADD FISH PRODUCT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}