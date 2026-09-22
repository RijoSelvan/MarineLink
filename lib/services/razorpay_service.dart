import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  late Razorpay _razorpay;

  /// Razorpay Test Key ID & Secret
  static String keyId = 'rzp_test_Tj8DMQFRn0OsiM';
  static String keySecret = 'T1xfiSJEKrKzZY6HSO7qZt4O';

  // Backwards compatibility alias
  static String get defaultTestKey => keyId;
  static set defaultTestKey(String val) => keyId = val;

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay Payment Success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Razorpay Payment Error: ${response.code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay External Wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  /// Sanitizes phone number to standard 10-digit format for Razorpay
  static String sanitizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits.isNotEmpty ? digits : '9876543210';
  }

  /// Creates an order on Razorpay using the Orders API
  static Future<String?> createOrder({
    required int amountInPaise,
    String currency = 'INR',
    String? receipt,
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://api.razorpay.com/v1/orders');
      final request = await client.postUrl(uri);

      final authBytes = utf8.encode('$keyId:$keySecret');
      final base64Auth = base64Encode(authBytes);
      request.headers.set(HttpHeaders.authorizationHeader, 'Basic $base64Auth');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final body = jsonEncode({
        'amount': amountInPaise,
        'currency': currency,
        'receipt': receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      });

      request.write(body);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final orderId = data['id'] as String?;
        debugPrint('Razorpay Order created successfully: $orderId');
        return orderId;
      } else {
        debugPrint('Razorpay Order creation returned: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      debugPrint('Error creating Razorpay order: $e');
    }
    return null;
  }

  Future<void> openCheckout({
    required double amountInRupees,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String? orderDescription,
    String? key,
  }) async {
    // Razorpay requires amount in currency subunits (paise for INR)
    final int amountInPaise = (amountInRupees * 100).round();

    // Create official order on Razorpay for seamless compliance
    String? orderId;
    try {
      orderId = await createOrder(amountInPaise: amountInPaise);
    } catch (e) {
      debugPrint('Could not pre-create order, proceeding with direct checkout: $e');
    }

    final options = {
      'key': (key != null && key.isNotEmpty) ? key : keyId,
      'amount': amountInPaise,
      'name': 'MarineLink Exports',
      'description': orderDescription ?? 'Seafood Export Order Payment',
      'currency': 'INR',
      'timeout': 180, // in seconds
      if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      'prefill': {
        'contact': sanitizePhone(customerPhone),
        'email': customerEmail.isNotEmpty ? customerEmail : 'buyer@marinelink.com',
        'name': customerName.isNotEmpty ? customerName : 'Valued Customer',
      },
      'image': 'https://cdn-icons-png.flaticon.com/128/3050/3050525.png', // Lightweight optimized 128px logo
      'theme': {
        'color': '#0A4D68',
      },
      'method': {
        'netbanking': true,
        'card': true,
        'upi': true,
        'wallet': false, // Explicitly avoid wallet as requested
        'emi': false,
        'paylater': false,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      rethrow;
    }
  }

  void dispose() {
    try {
      _razorpay.clear();
    } catch (_) {}
  }
}


