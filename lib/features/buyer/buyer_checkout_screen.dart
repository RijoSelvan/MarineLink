import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../services/product_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/notification_service.dart';
import '../../utils/category_helper.dart';
import '../../utils/delivery_calculator.dart';
import 'buyer_orders_screen.dart';

class BuyerCheckoutScreen extends StatefulWidget {
  const BuyerCheckoutScreen({super.key});

  @override
  State<BuyerCheckoutScreen> createState() => _BuyerCheckoutScreenState();
}

class _BuyerCheckoutScreenState extends State<BuyerCheckoutScreen> {
  final ProductService productService = ProductService();
  late final RazorpayService _razorpayService;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _cartStream;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController addressTitleController = TextEditingController(text: 'Home');

  String _selectedPaymentMethod = 'Razorpay'; // 'Razorpay' or 'Cash on Delivery'
  bool isLoading = false;

  // Saved Addresses State
  List<Map<String, dynamic>> _savedAddresses = [];
  int _selectedAddressIndex = -1;
  bool _useSavedAddress = true;
  bool _saveNewAddress = true;

  // Stored for Razorpay callback & order placement
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedCartItems = [];
  double _cachedSubtotal = 0.0;
  double _cachedDeliveryCharge = 0.0;
  double _cachedGrandTotal = 0.0;
  double _cachedDistanceKm = 0.0;
  String _cachedGodownAddress = '';

  @override
  void initState() {
    super.initState();
    _cartStream = productService.getCart();
    _initRazorpay();
    _loadBuyerDetails();
  }

  void _initRazorpay() {
    _razorpayService = RazorpayService();
    _razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Successful! Payment ID: ${response.paymentId}');
    if (!mounted) return;
    _placeOrder(
      _cachedCartItems,
      subtotal: _cachedSubtotal,
      deliveryCharge: _cachedDeliveryCharge,
      grandTotal: _cachedGrandTotal,
      distanceKm: _cachedDistanceKm,
      godownAddress: _cachedGodownAddress,
      isRazorpay: true,
      paymentId: response.paymentId ?? 'PAY_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    debugPrint('Payment Failed! Code: ${response.code}, Message: ${response.message}');
    if (!mounted) return;
    setState(() => isLoading = false);

    // If user cancelled the payment sheet, don't show an error dialog
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment cancelled.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if network error
    if (response.code == Razorpay.NETWORK_ERROR) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rawMessage = response.message ?? '';
    final isAuthError = rawMessage.toLowerCase().contains('authentication failed') ||
        rawMessage.toLowerCase().contains('bad_request_error') ||
        rawMessage.toLowerCase().contains('invalid key') ||
        response.code == Razorpay.INVALID_OPTIONS;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isAuthError ? Icons.vpn_key_off_outlined : Icons.error_outline,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isAuthError ? 'Razorpay Key Error' : 'Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAuthError) ...[
              const Text(
                'Razorpay rejected the payment because the API Key ID is not registered or has expired.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade200),
                ),
                child: const Text(
                  'To use real Razorpay test checkout:\n1. Log in to dashboard.razorpay.com\n2. Go to Settings > API Keys\n3. Generate a Test Key and paste it into lib/services/razorpay_service.dart',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Would you like to simulate a successful payment to test order placement?',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              Text(
                rawMessage.isNotEmpty
                    ? rawMessage
                    : 'The transaction could not be completed. Please try again or choose Cash on Delivery.',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          if (isAuthError && _cachedCartItems.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A4D68),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Simulate Test Payment'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _simulateSuccessfulPayment();
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _simulateSuccessfulPayment() {
    final mockPaymentId = 'pay_test_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('Simulating successful Razorpay payment: $mockPaymentId');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulating successful test payment...'),
        backgroundColor: Colors.teal,
        duration: Duration(seconds: 2),
      ),
    );
    _placeOrder(
      _cachedCartItems,
      subtotal: _cachedSubtotal,
      deliveryCharge: _cachedDeliveryCharge,
      grandTotal: _cachedGrandTotal,
      distanceKm: _cachedDistanceKm,
      godownAddress: _cachedGodownAddress,
      isRazorpay: true,
      paymentId: mockPaymentId,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    pincodeController.dispose();
    addressTitleController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOAD BUYER DETAILS & SAVED ADDRESSES
  // ================================================================
  Future<void> _loadBuyerDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!document.exists) return;
      final data = document.data();
      if (data == null) return;

      final dynamic rawSaved = data['savedAddresses'];
      final List<Map<String, dynamic>> addressesList = [];

      if (rawSaved is List) {
        for (final item in rawSaved) {
          if (item is Map) {
            addressesList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      // If user has a default address in profile and no saved addresses list, treat it as saved address
      final profileAddress = data['address']?.toString() ?? '';
      if (addressesList.isEmpty && profileAddress.trim().isNotEmpty) {
        addressesList.add({
          'title': 'Default / Home',
          'name': data['name']?.toString() ?? user.displayName ?? '',
          'phone': data['phone']?.toString() ?? '',
          'address': profileAddress,
          'city': data['city']?.toString() ?? '',
          'pincode': data['pincode']?.toString() ?? '',
        });
      }

      if (!mounted) return;
      setState(() {
        _savedAddresses = addressesList;
        nameController.text = data['name']?.toString() ?? user.displayName ?? '';
        phoneController.text = data['phone']?.toString() ?? '';

        if (_savedAddresses.isNotEmpty) {
          _useSavedAddress = true;
          _selectedAddressIndex = 0;
          _applySavedAddress(_savedAddresses[0]);
        } else {
          _useSavedAddress = false;
          _selectedAddressIndex = -1;
          if (profileAddress.isNotEmpty) {
            addressController.text = profileAddress;
          }
          if (data['city'] != null) {
            cityController.text = data['city'].toString();
          }
          if (data['pincode'] != null) {
            pincodeController.text = data['pincode'].toString();
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading buyer details: $e');
    }
  }

  void _applySavedAddress(Map<String, dynamic> addr) {
    if (addr['name']?.toString().isNotEmpty == true) {
      nameController.text = addr['name'].toString();
    }
    if (addr['phone']?.toString().isNotEmpty == true) {
      phoneController.text = addr['phone'].toString();
    }
    addressController.text = addr['address']?.toString() ?? '';
    cityController.text = addr['city']?.toString() ?? '';
    pincodeController.text = addr['pincode']?.toString() ?? '';
  }

  // ================================================================
  // BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xff0A4D68),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load cart.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff0A4D68)),
            );
          }

          final items = snapshot.data?.docs ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          double subtotal = 0;
          for (final item in items) {
            final data = item.data();
            final double price = _toDouble(data['price']);
            final int quantity = _toInt(data['quantity']);
            subtotal += price * quantity;
          }

          // Determine origin godown address from cart items or fallback
          String originGodown = '';
          for (final item in items) {
            final itemData = item.data();
            final itemGodown = itemData['godownAddress']?.toString() ?? '';
            if (itemGodown.trim().isNotEmpty) {
              originGodown = itemGodown.trim();
              break;
            }
          }
          if (originGodown.isEmpty) {
            originGodown = 'Kochi Fishing Harbour Godown, Kerala';
          }
          _cachedGodownAddress = originGodown;

          // Compute transit distance & cold-chain delivery charge
          final double distanceKm = DeliveryCalculator.calculateDistanceKm(
            godownAddress: originGodown,
            buyerAddress: addressController.text.trim(),
            buyerCity: cityController.text.trim(),
            buyerPincode: pincodeController.text.trim(),
          );
          final double deliveryCharge = DeliveryCalculator.calculateDeliveryCharge(distanceKm);
          final double grandTotal = subtotal + deliveryCharge;

          // Cache for payment trigger
          _cachedCartItems = items;
          _cachedSubtotal = subtotal;
          _cachedDeliveryCharge = deliveryCharge;
          _cachedGrandTotal = grandTotal;
          _cachedDistanceKm = distanceKm;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ...items.map((document) {
                  final data = document.data();
                  final String fishName = data['fishName']?.toString() ?? 'Product';
                  final double price = _toDouble(data['price']);
                  final int quantity = _toInt(data['quantity']);

                  return Card(
                    elevation: 1.5,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xffE8F4F8),
                        backgroundImage: AssetImage(
                          CategoryHelper.getCategoryAssetImage(
                            CategoryHelper.determineCategory(
                              category: data['category']?.toString(),
                              fishName: fishName,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        fishName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        '$quantity kg × ₹${price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Text(
                        '₹${(price * quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xff0A4D68),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // ====================================================
                // DELIVERY ADDRESS (SAVED ADDRESSES OR MANUAL)
                // ====================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_savedAddresses.isNotEmpty)
                      Text(
                        _useSavedAddress ? 'Saved Address' : 'Manual Entry',
                        style: TextStyle(
                          color: _useSavedAddress ? Colors.teal : Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Toggle tabs if user has saved addresses
                if (_savedAddresses.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.bookmark_added_rounded,
                            size: 16,
                            color: _useSavedAddress ? Colors.white : const Color(0xff0A4D68),
                          ),
                          label: Text('Saved Addresses (${_savedAddresses.length})'),
                          selected: _useSavedAddress,
                          selectedColor: const Color(0xff0A4D68),
                          labelStyle: TextStyle(
                            color: _useSavedAddress ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _useSavedAddress = true;
                                if (_selectedAddressIndex >= 0 &&
                                    _selectedAddressIndex < _savedAddresses.length) {
                                  _applySavedAddress(_savedAddresses[_selectedAddressIndex]);
                                } else if (_savedAddresses.isNotEmpty) {
                                  _selectedAddressIndex = 0;
                                  _applySavedAddress(_savedAddresses[0]);
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.edit_location_alt_rounded,
                            size: 16,
                            color: !_useSavedAddress ? Colors.white : Colors.grey.shade700,
                          ),
                          label: const Text('Enter Manually'),
                          selected: !_useSavedAddress,
                          selectedColor: const Color(0xff0A4D68),
                          labelStyle: TextStyle(
                            color: !_useSavedAddress ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _useSavedAddress = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // 1. Saved Address Selector Cards
                if (_useSavedAddress && _savedAddresses.isNotEmpty) ...[
                  ...List.generate(_savedAddresses.length, (index) {
                    final item = _savedAddresses[index];
                    final bool isSelected = _selectedAddressIndex == index;
                    final String title = item['title']?.toString() ?? 'Address ${index + 1}';
                    final String addr = item['address']?.toString() ?? '';
                    final String city = item['city']?.toString() ?? '';
                    final String pin = item['pincode']?.toString() ?? '';
                    final String ph = item['phone']?.toString() ?? '';

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAddressIndex = index;
                          _applySavedAddress(item);
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xff0A4D68) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xff0A4D68).withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xff0A4D68) : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff0A4D68).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          title.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff0A4D68),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item['name']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    addr,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  Text(
                                    '$city - $pin',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  if (ph.isNotEmpty)
                                    Text(
                                      'Phone: $ph',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _useSavedAddress = false;
                          addressController.clear();
                          cityController.clear();
                          pincodeController.clear();
                        });
                      },
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: const Text('+ Enter a New Address'),
                    ),
                  ),
                ] else ...[
                  // 2. Manual Address Form
                  _textField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),

                  _textField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  _textField(
                    controller: addressController,
                    label: 'Delivery Address / Street / Building',
                    icon: Icons.home_rounded,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _textField(
                          controller: cityController,
                          label: 'City / Port District',
                          icon: Icons.location_city_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _textField(
                          controller: pincodeController,
                          label: 'PIN Code',
                          icon: Icons.pin_drop_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _textField(
                          controller: addressTitleController,
                          label: 'Address Label (e.g. Home, Office, Hub)',
                          icon: Icons.label_outline,
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Save this address for future orders',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    value: _saveNewAddress,
                    activeColor: const Color(0xff0A4D68),
                    onChanged: (val) => setState(() => _saveNewAddress = val ?? true),
                  ),
                ],

                const SizedBox(height: 20),

                // ====================================================
                // BILLING & COLD-CHAIN DELIVERY BREAKDOWN
                // ====================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff088395).withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, color: Color(0xff0A4D68), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Price & Delivery Breakdown',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items Subtotal', style: TextStyle(color: Colors.black87, fontSize: 14)),
                          Text('₹${subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Cold-chain Delivery Charge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Refrigerated Delivery',
                                        style: TextStyle(color: Colors.black87, fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'COLD CHAIN',
                                        style: TextStyle(
                                            color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '~${distanceKm.toStringAsFixed(0)} km transit from Godown (${originGodown.length > 25 ? '${originGodown.substring(0, 25)}...' : originGodown})',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${deliveryCharge.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0A4D68),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Razorpay Option
                _paymentMethodCard(
                  id: 'Razorpay',
                  title: 'Razorpay Online Payment',
                  subtitle: 'Cards, UPI, NetBanking',
                  badge: 'SECURE',
                  icon: Icons.credit_card,
                  iconColor: const Color(0xff0A4D68),
                ),

                const SizedBox(height: 10),

                // Cash on Delivery Option
                _paymentMethodCard(
                  id: 'Cash on Delivery',
                  title: 'Cash on Delivery',
                  subtitle: 'Pay directly on delivery',
                  badge: null,
                  icon: Icons.payments_outlined,
                  iconColor: Colors.teal,
                ),

                const SizedBox(height: 30),

                // Place / Pay Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0A4D68),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () => _handlePaymentSubmission(
                              items,
                              subtotal: subtotal,
                              deliveryCharge: deliveryCharge,
                              grandTotal: grandTotal,
                              distanceKm: distanceKm,
                              godownAddress: originGodown,
                            ),
                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            _selectedPaymentMethod == 'Razorpay'
                                ? 'PROCEED TO PAY ₹${grandTotal.toStringAsFixed(2)}'
                                : 'PLACE ORDER (COD) - ₹${grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // PAYMENT METHOD CARD
  // ================================================================
  Widget _paymentMethodCard({
    required String id,
    required String title,
    required String subtitle,
    required String? badge,
    required IconData icon,
    required Color iconColor,
  }) {
    final bool isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xff0A4D68) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff0A4D68).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xff0A4D68) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff0A4D68),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: iconColor.withValues(alpha: 0.12),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
  // PAYMENT SUBMISSION HANDLER
  // ================================================================
  Future<void> _handlePaymentSubmission(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items, {
    required double subtotal,
    required double deliveryCharge,
    required double grandTotal,
    required double distanceKm,
    required String godownAddress,
  }) async {
    if (!_validateFields()) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before placing an order.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cache items and totals for Razorpay callback
    _cachedCartItems = items;
    _cachedSubtotal = subtotal;
    _cachedDeliveryCharge = deliveryCharge;
    _cachedGrandTotal = grandTotal;
    _cachedDistanceKm = distanceKm;
    _cachedGodownAddress = godownAddress;

    if (_selectedPaymentMethod == 'Razorpay') {
      setState(() => isLoading = true);
      try {
        await _razorpayService.openCheckout(
          amountInRupees: grandTotal,
          customerName: nameController.text.trim().isNotEmpty
              ? nameController.text.trim()
              : 'Buyer',
          customerEmail: user.email ?? 'buyer@marinelink.com',
          customerPhone: RazorpayService.sanitizePhone(phoneController.text.trim()),
          orderDescription: 'MarineLink Cold-Chain Seafood Order',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment gateway: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Cash on Delivery
      _placeOrder(
        items,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
        grandTotal: grandTotal,
        distanceKm: distanceKm,
        godownAddress: godownAddress,
        isRazorpay: false,
      );
    }
  }

  bool _validateFields() {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        pincodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all delivery details.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // ================================================================
  // PLACE ORDER
  // ================================================================
  Future<void> _placeOrder(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items, {
    required double subtotal,
    required double deliveryCharge,
    required double grandTotal,
    required double distanceKm,
    required String godownAddress,
    required bool isRazorpay,
    String paymentId = '',
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final List<Map<String, dynamic>> products = [];
      for (final document in items) {
        final data = document.data();
        products.add({
          'productId': data['productId'] ?? document.id,
          'fishName': data['fishName'] ?? '',
          'category': data['category'] ?? '',
          'price': _toDouble(data['price']),
          'quantity': _toInt(data['quantity']),
          'imageUrl': data['imageUrl'] ?? '',
          'exporterId': data['exporterId'] ?? '',
          'exporterName': data['exporterName'] ?? '',
          'godownAddress': data['godownAddress'] ?? godownAddress,
        });
      }

      final String primaryExporterId =
          products.isNotEmpty ? (products.first['exporterId'] ?? '') : '';
      final List<String> exporterIds = products
          .map((p) => p['exporterId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final String primaryFishName = products.isNotEmpty
          ? (products.first['fishName'] ?? 'Fish Product')
          : 'Fish Product';
      final dynamic primaryPrice =
          products.isNotEmpty ? products.first['price'] : subtotal;
      final dynamic primaryQuantity =
          products.isNotEmpty ? products.first['quantity'] : 1;

      final DocumentReference orderDoc =
          FirebaseFirestore.instance.collection('orders').doc();

      final String paymentMethod = isRazorpay ? 'Razorpay' : 'Cash on Delivery';
      final String paymentStatus = isRazorpay ? 'Paid' : 'Pending';
      final String initialStatus = 'Pending';

      final Map<String, dynamic> orderPayload = {
        'orderId': orderDoc.id,
        'buyerId': user.uid,
        'buyerName': nameController.text.trim(),
        'buyerEmail': user.email ?? '',
        'buyerPhone': phoneController.text.trim(),
        'exporterId': primaryExporterId,
        'exporterIds': exporterIds,
        'fishName': primaryFishName,
        'price': primaryPrice,
        'quantity': primaryQuantity,
        'deliveryAddress': addressController.text.trim(),
        'city': cityController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'items': products,
        'products': products,
        'subtotal': subtotal,
        'deliveryCharge': deliveryCharge,
        'distanceKm': distanceKm,
        'godownAddress': godownAddress,
        'totalAmount': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentId': paymentId,
        'status': initialStatus,
        'orderStatus': initialStatus,
        'shipmentStatus': 'Not Shipped',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await orderDoc.set(orderPayload);

      // Save address if user entered manually and opted to save
      if (!_useSavedAddress && _saveNewAddress) {
        try {
          final newAddressEntry = {
            'title': addressTitleController.text.trim().isNotEmpty
                ? addressTitleController.text.trim()
                : 'Address ${_savedAddresses.length + 1}',
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'address': addressController.text.trim(),
            'city': cityController.text.trim(),
            'pincode': pincodeController.text.trim(),
            'addedAt': Timestamp.now(),
          };
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'savedAddresses': FieldValue.arrayUnion([newAddressEntry]),
            'address': addressController.text.trim(),
            'city': cityController.text.trim(),
            'pincode': pincodeController.text.trim(),
          }, SetOptions(merge: true));
        } catch (addrErr) {
          debugPrint('Error saving new address: $addrErr');
        }
      }

      // Clear buyer cart in batch
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final document in items) {
        batch.delete(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(document.id),
        );
      }
      await batch.commit();

      // Decrement stock for each ordered product and update availability
      for (final document in items) {
        try {
          final data = document.data();
          final String prodId =
              (data['productId']?.toString() ?? document.id).trim();
          final int orderedQty = _toInt(data['quantity']);

          if (prodId.isNotEmpty && orderedQty > 0) {
            final DocumentReference prodRef =
                FirebaseFirestore.instance.collection('products').doc(prodId);

            await FirebaseFirestore.instance.runTransaction((transaction) async {
              final DocumentSnapshot prodSnap = await transaction.get(prodRef);
              if (prodSnap.exists && prodSnap.data() != null) {
                final Map<String, dynamic> pData =
                    prodSnap.data() as Map<String, dynamic>;
                final int currentStock = _toInt(pData['quantity']);
                final int newStock =
                    (currentStock - orderedQty).clamp(0, 999999999);
                final bool stillAvailable = newStock > 0;

                transaction.update(prodRef, {
                  'quantity': newStock,
                  'isAvailable': stillAvailable,
                  'status': stillAvailable ? 'Available' : 'Out of Stock',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
              }
            });
          }
        } catch (stockErr) {
          debugPrint('Error decrementing product stock: $stockErr');
        }
      }


      // Trigger notifications for Buyer & Exporter(s)
      try {
        final notifService = NotificationService();
        final buyerDisplayName = nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : 'Buyer';

        // 1. Notify Buyer
        await notifService.notifyUser(
          userId: user.uid,
          title: 'Order Placed Successfully! 🛍️',
          message:
              'Your order for $primaryFishName has been placed ($paymentMethod - ₹${grandTotal.toStringAsFixed(2)}).',
          type: 'order_placed',
          orderId: orderDoc.id,
        );

        // 2. Notify Exporter(s)
        final Set<String> targetExporters = Set<String>.from(exporterIds);
        if (primaryExporterId.isNotEmpty) {
          targetExporters.add(primaryExporterId);
        }

        for (final expId in targetExporters) {
          await notifService.notifyUser(
            userId: expId,
            title: 'New Order Received! 🎣',
            message:
                '$buyerDisplayName placed an order for $primaryFishName ($paymentMethod - ₹${grandTotal.toStringAsFixed(2)}).',
            type: 'new_order',
            orderId: orderDoc.id,
          );
        }
      } catch (notifErr) {
        debugPrint('Error dispatching notifications on order place: $notifErr');
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      _showSuccessDialog(orderDoc.id, isRazorpay, paymentId, grandTotal);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(
    String orderId,
    bool isRazorpay,
    String paymentId,
    double total,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isRazorpay
                    ? 'Payment of ₹${total.toStringAsFixed(2)} was received via Razorpay.'
                    : 'Order confirmed with Cash on Delivery.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _dialogInfoRow('Order ID', '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}'),
                    if (paymentId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _dialogInfoRow('Payment ID', paymentId),
                    ],
                    const SizedBox(height: 6),
                    _dialogInfoRow('Amount', '₹${total.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _dialogInfoRow('Payment', isRazorpay ? 'Paid (Razorpay)' : 'Cash on Delivery'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close checkout screen
              },
              child: const Text('Back to Home'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A4D68),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BuyerOrdersScreen()),
                );
              },
              child: const Text('View Orders'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================
  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff0A4D68)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff0A4D68), width: 1.5),
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}