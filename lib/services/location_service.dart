import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request location permission and get the user's postal code
  static Future<String> getPostalCode() async {
    print("LocationService: Starting postal code retrieval");
    try {
      // Check location permissions
      print("LocationService: Checking permissions");
      LocationPermission permission = await Geolocator.checkPermission();
      print("LocationService: Current permission status: $permission");

      if (permission == LocationPermission.denied) {
        print("LocationService: Permission denied, requesting permission");
        permission = await Geolocator.requestPermission();
        print("LocationService: After request, permission status: $permission");
        if (permission == LocationPermission.denied) {
          print("LocationService: Permission denied after request");
          return '000000'; // Return default if permission denied
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // User has permanently denied location - return default
        print("LocationService: Permission permanently denied");
        return '000000';
      }

      // Get current position with a timeout
      print("LocationService: Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Lower accuracy is faster
        timeLimit: Duration(
          seconds: 10,
        ), // Increased timeout for better chance of success
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          print("LocationService: Position request timed out");
          throw TimeoutException("Position request timed out");
        },
      );

      print(
        "LocationService: Got position: ${position.latitude}, ${position.longitude}",
      );

      // Get placemark from coordinates
      print("LocationService: Getting placemark from coordinates");
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print("LocationService: Placemark request timed out");
          throw TimeoutException("Placemark request timed out");
        },
      );

      print("LocationService: Got ${placemarks.length} placemarks");

      if (placemarks.isNotEmpty) {
        String? postalCode = placemarks.first.postalCode;
        print("LocationService: First placemark postal code: $postalCode");

        if (postalCode != null && postalCode.isNotEmpty) {
          print("LocationService: Successfully got postal code: $postalCode");
          return postalCode;
        } else {
          print("LocationService: Postal code is null or empty");
        }
      } else {
        print("LocationService: No placemarks returned");
      }

      print(
        "LocationService: Could not get postal code from location, using default",
      );
    } catch (e) {
      print("LocationService: Error getting location for postal code: $e");

      // Try to get last known position as fallback
      try {
        print("LocationService: Trying to get last known position as fallback");
        Position? lastPosition = await Geolocator.getLastKnownPosition();

        if (lastPosition != null) {
          print(
            "LocationService: Got last position: ${lastPosition.latitude}, ${lastPosition.longitude}",
          );

          List<Placemark> placemarks = await placemarkFromCoordinates(
            lastPosition.latitude,
            lastPosition.longitude,
          );

          if (placemarks.isNotEmpty &&
              placemarks.first.postalCode != null &&
              placemarks.first.postalCode!.isNotEmpty) {
            String postalCode = placemarks.first.postalCode!;
            print(
              "LocationService: Got postal code from last position: $postalCode",
            );
            return postalCode;
          }
        } else {
          print("LocationService: No last known position available");
        }
      } catch (fallbackError) {
        print("LocationService: Error in fallback method: $fallbackError");
      }
    }

    print("LocationService: Returning default postal code '000000'");
    return '000000'; // Final fallback
  }

  /// A simple test method that can be called from anywhere to verify the location service
  static Future<void> testLocationService() async {
    print("LocationService: Test started");
    String postalCode = await getPostalCode();
    print("LocationService: Test completed. Postal code: $postalCode");
  }
}
