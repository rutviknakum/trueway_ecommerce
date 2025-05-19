// network_utils.dart
import 'dart:io';
import 'package:http/http.dart' as http;

/// A utility class for network operations and diagnostics
class NetworkUtils {
  /// Check if the device has an active internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      // Try to connect to multiple reliable hosts to check internet connectivity
      final List<String> reliableHosts = [
        'google.com',
        'apple.com',
        'microsoft.com',
        'amazon.com'
      ];
      
      // Try each host until we get a successful connection
      for (final host in reliableHosts) {
        try {
          final result = await InternetAddress.lookup(host);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          // Try the next host
          continue;
        }
      }
      
      // If DNS lookup fails, try an HTTP request
      try {
        final response = await http.get(Uri.parse('https://google.com'))
            .timeout(Duration(seconds: 5));
        return response.statusCode >= 200 && response.statusCode < 300;
      } catch (_) {
        return false;
      }
    } catch (e) {
      print("Error checking internet connection: $e");
      return false;
    }
  }
  
  /// Diagnose server connectivity issues
  static Future<Map<String, dynamic>> diagnoseServerConnection(String serverUrl) async {
    try {
      // First check internet connectivity
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        return {
          'success': false,
          'error': 'No internet connection',
          'detail': 'Please check your device\'s internet connection and try again.'
        };
      }
      
      // Try to connect to the server
      try {
        final response = await http.get(Uri.parse(serverUrl))
            .timeout(Duration(seconds: 5));
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': true,
            'message': 'Server is reachable',
          };
        } else {
          return {
            'success': false,
            'error': 'Server returned an error',
            'detail': 'Server responded with status code ${response.statusCode}',
            'status_code': response.statusCode
          };
        }
      } catch (e) {
        return {
          'success': false,
          'error': 'Cannot connect to server',
          'detail': 'The server appears to be unreachable: $e',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Diagnostic error',
        'detail': 'An error occurred while diagnosing the connection: $e',
      };
    }
  }
}
