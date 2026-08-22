import 'dart:math';

/// Helper to calculate distance between Exporter Godown and Buyer Address,
/// and compute temperature-controlled cold-chain seafood delivery charges.
class DeliveryCalculator {
  // Base cold-chain dispatch and handling fee in INR
  static const double baseColdChainFee = 50.0;
  // Per km delivery rate for refrigerated cold-chain cargo in INR
  static const double ratePerKm = 3.50;
  // Minimum delivery charge in INR
  static const double minDeliveryCharge = 75.0;

  /// Major Indian seafood ports, harbours and hub coordinates
  static final Map<String, GeoHubPoint> knownHubs = {
    'kochi': const GeoHubPoint(9.9312, 76.2673, 'Kochi Fishing Harbour Godown, Kerala'),
    'cochin': const GeoHubPoint(9.9312, 76.2673, 'Cochin Export Terminal, Kerala'),
    'mumbai': const GeoHubPoint(18.9220, 72.8347, 'Sassoon Dock Godown, Mumbai, Maharashtra'),
    'chennai': const GeoHubPoint(13.0827, 80.2707, 'Kasimedu Fishery Harbour Godown, Chennai, TN'),
    'visakhapatnam': const GeoHubPoint(17.6868, 83.2185, 'Vizag Port Seafood Complex, AP'),
    'vizag': const GeoHubPoint(17.6868, 83.2185, 'Vizag Port Seafood Complex, AP'),
    'mangalore': const GeoHubPoint(12.9141, 74.8560, 'Old Port Bunder Godown, Mangalore, Karnataka'),
    'tuticorin': const GeoHubPoint(8.7642, 78.1348, 'Thoothukudi Harbour Hub, Tamil Nadu'),
    'thoothukudi': const GeoHubPoint(8.7642, 78.1348, 'Thoothukudi Harbour Hub, Tamil Nadu'),
    'goa': const GeoHubPoint(15.2993, 74.1240, 'Mormugao Port Godown, Goa'),
    'panaji': const GeoHubPoint(15.4909, 73.8278, 'Panaji Fish Hub, Goa'),
    'kolkata': const GeoHubPoint(22.5726, 88.3639, 'Haldia / Diamond Harbour Hub, West Bengal'),
    'surat': const GeoHubPoint(21.1702, 72.8311, 'Magdalla Port Cold Storage, Gujarat'),
    'veraval': const GeoHubPoint(20.9075, 70.3677, 'Veraval Fisheries Hub, Gujarat'),
    'kanyakumari': const GeoHubPoint(8.0883, 77.5385, 'Chinnamuttom Harbour, Tamil Nadu'),
    'calicut': const GeoHubPoint(11.2588, 75.7804, 'Beypore Harbour Godown, Kozhikode, Kerala'),
    'kozhikode': const GeoHubPoint(11.2588, 75.7804, 'Beypore Harbour Godown, Kozhikode, Kerala'),
    'kollam': const GeoHubPoint(8.8932, 76.6141, 'Neendakara Harbour Hub, Kerala'),
    'alappuzha': const GeoHubPoint(9.4981, 76.3388, 'Thottappally Harbour Hub, Kerala'),
    'bangalore': const GeoHubPoint(12.9716, 77.5946, 'Bangalore Central Hub, Karnataka'),
    'hyderabad': const GeoHubPoint(17.3850, 78.4867, 'Hyderabad Cold Logistics, Telangana'),
    'delhi': const GeoHubPoint(28.6139, 77.2090, 'NCR Seafood Cargo Terminal, Delhi'),
    'ernakulam': const GeoHubPoint(9.9816, 76.2999, 'Ernakulam Cold Store Hub, Kerala'),
  };

  /// Calculates estimated distance (km) between an exporter's godown and buyer address.
  static double calculateDistanceKm({
    required String godownAddress,
    required String buyerAddress,
    String? buyerCity,
    String? buyerPincode,
  }) {
    final godownLower = godownAddress.toLowerCase();
    final buyerLower = '${buyerAddress.toLowerCase()} ${(buyerCity ?? '').toLowerCase()}';

    // 1. Check if both match known cities/hubs
    GeoHubPoint? originPoint;
    for (final entry in knownHubs.entries) {
      if (godownLower.contains(entry.key)) {
        originPoint = entry.value;
        break;
      }
    }
    originPoint ??= const GeoHubPoint(9.9312, 76.2673, 'Kochi Fishing Harbour'); // Default to Kochi primary export port

    GeoHubPoint? destPoint;
    for (final entry in knownHubs.entries) {
      if (buyerLower.contains(entry.key)) {
        destPoint = entry.value;
        break;
      }
    }

    if (destPoint != null) {
      final double straightDistance = _haversineDistance(
        originPoint.lat,
        originPoint.lng,
        destPoint.lat,
        destPoint.lng,
      );
      // Road transit factor is typically ~1.28x of straight-line haversine distance
      final double roadDistance = straightDistance * 1.28;
      // If same city, minimum 12 km local cold dispatch
      return max(12.0, roadDistance.roundToDouble());
    }

    // 2. Heuristic fallback based on pincode comparison if available
    if (buyerPincode != null && buyerPincode.trim().length >= 6) {
      final String pin = buyerPincode.trim();
      final String godownPin = _extractPincode(godownAddress);
      if (godownPin.isNotEmpty && pin == godownPin) {
        return 14.0; // Same postal zone
      } else if (godownPin.isNotEmpty && pin.substring(0, 2) == godownPin.substring(0, 2)) {
        return 48.0; // Same state/nearby district
      }
    }

    // 3. Fallback: check if same state or city keywords
    if (godownLower.contains('kerala') && buyerLower.contains('kerala')) {
      return 65.0; // Average intrastate transit
    } else if (godownLower.contains('tamil nadu') && buyerLower.contains('tamil nadu')) {
      return 85.0;
    } else if (godownLower.contains('maharashtra') && buyerLower.contains('maharashtra')) {
      return 95.0;
    }

    // Default interstate/regional transit distance
    return 130.0;
  }

  /// Calculates the delivery charge in INR based on distance and cold-chain pricing.
  static double calculateDeliveryCharge(double distanceKm) {
    final double rawCharge = baseColdChainFee + (distanceKm * ratePerKm);
    return max(minDeliveryCharge, (rawCharge / 5).round() * 5.0); // Rounded to nearest ₹5
  }

  /// Extracts 6-digit Indian pincode from an address string
  static String _extractPincode(String address) {
    final regex = RegExp(r'\b[1-9][0-9]{5}\b');
    final match = regex.firstMatch(address);
    return match?.group(0) ?? '';
  }

  /// Haversine formula for distance between two lat/lng coordinates in kilometers
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * pi / 180.0;
}

class GeoHubPoint {
  final double lat;
  final double lng;
  final String name;

  const GeoHubPoint(this.lat, this.lng, this.name);
}
