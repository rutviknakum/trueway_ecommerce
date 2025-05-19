// debug_auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A debug utility to diagnose API connection issues
class DebugAuthService {

  /// Test all aspects of API connectivity and authorization
  static Future<void> runDiagnostics(BuildContext context) async {
    String diagnosticResult = await _fullApiDiagnostic();
    
    // Show a dialog with the diagnostic results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report, color: Colors.blue),
            SizedBox(width: 10),
            Text('Server Diagnostics'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(diagnosticResult),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Send a direct test request to test server connection
  static Future<bool> testDirectRegistration(
    String email,
    String password,
    String firstName,
    String lastName,
    String mobile,
  ) async {
    try {
      // Try a completely different approach using a direct URL
      final directUrl = 'https://map.uminber.in/wp-json/wp/v2/users';
      
      // Basic auth string
      final credentials = base64Encode(utf8.encode('${ApiConfig.consumerKey}:${ApiConfig.consumerSecret}'));
      
      // Try with minimal data
      final payload = {
        'username': email,
        'email': email,
        'password': password,
        'name': '$firstName $lastName',
      };
      
      print('Attempting direct registration with: $directUrl');
      print('Payload: ${json.encode(payload)}');
      
      final response = await http.post(
        Uri.parse(directUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $credentials',
        },
        body: json.encode(payload),
      );
      
      print('Direct registration response code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      
      // Try the WooCommerce endpoint as a fallback
      final wooUrl = 'https://map.uminber.in/wp-json/wc/v3/customers';
      
      final wooResponse = await http.post(
        Uri.parse('$wooUrl?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'username': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );
      
      print('WooCommerce registration response: ${wooResponse.statusCode}');
      print('Response body: ${wooResponse.body}');
      
      return wooResponse.statusCode >= 200 && wooResponse.statusCode < 300;
    } catch (e) {
      print('Error in direct registration test: $e');
      return false;
    }
  }
  
  /// Run a full diagnostic on all API aspects
  static Future<String> _fullApiDiagnostic() async {
    StringBuffer results = StringBuffer();
    results.writeln('=== API CONNECTION DIAGNOSTICS ===\n');
    results.writeln('Time: ${DateTime.now()}\n');
    
    // 1. Test basic connectivity
    results.writeln('1. Testing basic connectivity...');
    try {
      final response = await http.get(Uri.parse('https://google.com'));
      results.writeln('   Internet access: ${response.statusCode == 200 ? 'SUCCESS ✓' : 'FAILED ✗'} (${response.statusCode})');
    } catch (e) {
      results.writeln('   Internet access: FAILED ✗ ($e)');
    }
    
    // 2. Test API base URL
    results.writeln('\n2. Testing API base URL...');
    try {
      final response = await http.get(Uri.parse(ApiConfig.baseUrl));
      results.writeln('   API base URL: ${response.statusCode < 400 ? 'SUCCESS ✓' : 'FAILED ✗'} (${response.statusCode})');
    } catch (e) {
      results.writeln('   API base URL: FAILED ✗ ($e)');
    }
    
    // 3. Test WooCommerce API access
    results.writeln('\n3. Testing WooCommerce API access...');
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}&per_page=1';
      final response = await http.get(Uri.parse(url));
      results.writeln('   WooCommerce products: ${response.statusCode < 400 ? 'SUCCESS ✓' : 'FAILED ✗'} (${response.statusCode})');
    } catch (e) {
      results.writeln('   WooCommerce products: FAILED ✗ ($e)');
    }
    
    // 4. Test WordPress REST API
    results.writeln('\n4. Testing WordPress REST API...');
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/wp/v2/posts?per_page=1'));
      results.writeln('   WordPress posts: ${response.statusCode < 400 ? 'SUCCESS ✓' : 'FAILED ✗'} (${response.statusCode})');
    } catch (e) {
      results.writeln('   WordPress posts: FAILED ✗ ($e)');
    }
    
    // 5. Test API credentials for customer endpoint
    results.writeln('\n5. Testing API credentials for user management...');
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.customersEndpoint}?consumer_key=${ApiConfig.consumerKey}&consumer_secret=${ApiConfig.consumerSecret}';
      final response = await http.get(Uri.parse(url));
      results.writeln('   Customer list access: ${response.statusCode < 400 ? 'SUCCESS ✓' : 'FAILED ✗'} (${response.statusCode})');
      
      if (response.statusCode >= 400) {
        results.writeln('   Error: ${response.body}');
      }
    } catch (e) {
      results.writeln('   Customer list access: FAILED ✗ ($e)');
    }
    
    // 6. Configuration summary
    results.writeln('\n6. Configuration Summary:');
    results.writeln('   Base URL: ${ApiConfig.baseUrl}');
    results.writeln('   Consumer Key: ${ApiConfig.consumerKey.substring(0, 5)}...${ApiConfig.consumerKey.substring(ApiConfig.consumerKey.length - 5)}');
    results.writeln('   Endpoints: ');
    results.writeln('     - Customers: ${ApiConfig.customersEndpoint}');
    results.writeln('     - Products: ${ApiConfig.productsEndpoint}');
    
    results.writeln('\n=== END OF DIAGNOSTICS ===');
    return results.toString();
  }
}
