import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A utility class to diagnose and attempt to fix server connection issues
class ServerDiagnostics {
  
  /// Run comprehensive diagnostics on the server connection
  static Future<Map<String, dynamic>> diagnoseServerConnection() async {
    final results = <String, dynamic>{
      'tests': [],
      'success': false,
      'recommendations': [],
    };
    
    // Test 1: Basic internet connectivity
    try {
      final connectivityTest = await _testInternetConnectivity();
      results['tests'].add(connectivityTest);
      
      if (!connectivityTest['success']) {
        results['recommendations'].add('Check your device\'s internet connection.');
        results['error'] = 'No internet connection detected';
        return results;
      }
    } catch (e) {
      results['tests'].add({
        'name': 'Internet Connectivity',
        'success': false,
        'error': e.toString(),
      });
      results['error'] = 'Error checking internet: $e';
      return results;
    }
    
    // Test 2: Basic server connectivity
    try {
      final serverTest = await _testServerConnectivity();
      results['tests'].add(serverTest);
      
      if (!serverTest['success']) {
        results['recommendations'].add('The server appears to be unreachable. Please try again later.');
        results['error'] = 'Server unreachable: ${serverTest['error']}';
        return results;
      }
    } catch (e) {
      results['tests'].add({
        'name': 'Server Connectivity',
        'success': false,
        'error': e.toString(),
      });
      results['error'] = 'Error checking server: $e';
      return results;
    }
    
    // Test 3: API credentials
    try {
      final credentialsTest = await _testApiCredentials();
      results['tests'].add(credentialsTest);
      
      if (!credentialsTest['success']) {
        results['recommendations'].add('API credentials may be invalid. Please check your configuration.');
        results['error'] = 'API credentials issue: ${credentialsTest['error']}';
        return results;
      }
    } catch (e) {
      results['tests'].add({
        'name': 'API Credentials',
        'success': false,
        'error': e.toString(),
      });
      results['error'] = 'Error checking API credentials: $e';
      return results;
    }
    
    // If we got this far, all basic tests passed
    results['success'] = true;
    results['message'] = 'Server diagnostics passed. The server appears to be working correctly.';
    return results;
  }
  
  /// Test basic internet connectivity
  static Future<Map<String, dynamic>> _testInternetConnectivity() async {
    final result = {
      'name': 'Internet Connectivity',
      'success': false,
    };
    
    try {
      // Try multiple reliable hosts
      for (final host in ['google.com', 'apple.com', 'cloudflare.com']) {
        try {
          final response = await http.get(Uri.parse('https://$host'))
              .timeout(Duration(seconds: 5));
          
          if (response.statusCode >= 200 && response.statusCode < 400) {
            result['success'] = true;
            result['details'] = 'Successfully connected to $host';
            return result;
          }
        } catch (_) {
          // Try the next host
          continue;
        }
      }
      
      // If we get here, all hosts failed
      result['error'] = 'Failed to connect to any test hosts';
      return result;
    } catch (e) {
      result['error'] = e.toString();
      return result;
    }
  }
  
  /// Test connectivity to the API server
  static Future<Map<String, dynamic>> _testServerConnectivity() async {
    final result = {
      'name': 'Server Connectivity',
      'success': false,
    };
    
    try {
      final serverUrl = ApiConfig.baseUrl;
      
      // Try a HEAD request first to minimize data transfer
      try {
        final response = await http.head(Uri.parse(serverUrl))
            .timeout(Duration(seconds: 10));
        
        if (response.statusCode < 500) {
          // Anything that's not a server error is considered "reachable"
          result['success'] = true;
          result['details'] = 'Server responded with status ${response.statusCode}';
          return result;
        } else {
          result['error'] = 'Server returned error status: ${response.statusCode}';
          return result;
        }
      } catch (e) {
        // HEAD request failed, try a GET request as fallback
        try {
          final response = await http.get(Uri.parse(serverUrl))
              .timeout(Duration(seconds: 10));
          
          if (response.statusCode < 500) {
            result['success'] = true;
            result['details'] = 'Server responded with status ${response.statusCode}';
            return result;
          } else {
            result['error'] = 'Server returned error status: ${response.statusCode}';
            return result;
          }
        } catch (e) {
          result['error'] = 'Failed to connect to server: $e';
          return result;
        }
      }
    } catch (e) {
      result['error'] = e.toString();
      return result;
    }
  }
  
  /// Test if API credentials are valid
  static Future<Map<String, dynamic>> _testApiCredentials() async {
    final result = {
      'name': 'API Credentials',
      'success': false,
    };
    
    try {
      // Check if we have consumer key and secret
      final consumerKey = ApiConfig.consumerKey;
      final consumerSecret = ApiConfig.consumerSecret;
      
      if (consumerKey.isEmpty || consumerSecret.isEmpty) {
        result['error'] = 'API credentials are missing';
        return result;
      }
      
      // Create auth string
      final authString = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
      
      // Test WooCommerce endpoint
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/wp-json/wc/v3/products?per_page=1');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Basic $authString',
            'Content-Type': 'application/json',
          },
        ).timeout(Duration(seconds: 15));
        
        if (response.statusCode == 200 || response.statusCode == 401) {
          // 401 means credentials are invalid but API is working
          result['success'] = true;
          result['valid_credentials'] = response.statusCode == 200;
          result['details'] = 'API credentials ${response.statusCode == 200 ? 'valid' : 'invalid'}';
          return result;
        } else {
          result['error'] = 'API endpoint returned status: ${response.statusCode}';
          return result;
        }
      } catch (e) {
        result['error'] = 'Failed to test API credentials: $e';
        return result;
      }
    } catch (e) {
      result['error'] = e.toString();
      return result;
    }
  }
  
  /// Show a diagnostic dialog with detailed information
  static Future<void> showDiagnosticDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Diagnosing Server Connection'),
            ],
          ),
          content: Text('Please wait while we diagnose the server connection...'),
        );
      },
    );
    
    try {
      // Run diagnostics
      final results = await diagnoseServerConnection();
      
      // Close progress dialog
      Navigator.of(context).pop();
      
      // Show results dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  results['success'] ? Icons.check_circle : Icons.error,
                  color: results['success'] ? Colors.green : Colors.red,
                ),
                SizedBox(width: 10),
                Text(results['success'] ? 'Diagnostics Passed' : 'Connection Issues'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    results['success']
                        ? 'All diagnostic tests passed.'
                        : 'Some diagnostic tests failed.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  if (!results['success'] && results['recommendations'] != null)
                    ...List<Widget>.from(
                      (results['recommendations'] as List).map((rec) => 
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $rec',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    'Detailed Results:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List<Widget>.from(
                    (results['tests'] as List).map((test) => 
                      Padding(
                        padding: EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Icon(
                              test['success'] ? Icons.check : Icons.close,
                              color: test['success'] ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${test['name']}: ${test['success'] ? 'Pass' : 'Fail'}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close progress dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Diagnostic Error'),
            content: Text('An error occurred while running diagnostics: $e'),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }
}
