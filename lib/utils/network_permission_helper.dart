import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Helper class to handle iOS local network permission requests
/// This is specifically needed for Flutter debug mode to allow
/// the Dart VM Service to work properly on iOS devices
class NetworkPermissionHelper {
  /// Maximum number of attempts to trigger the permission dialog per session
  static const int _maxAttempts = 5;
  
  /// Counter to track number of attempts made in this session
  static int _attemptsMade = 0;
  
  /// Preference key to store permission granted status
  static const String _permissionGrantedKey = 'network_permission_granted';

  /// Checks if the user has previously indicated they've granted the permission
  /// and attempts to verify actual permission status
  static Future<bool> hasGrantedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.getBool(_permissionGrantedKey) ?? false;
    
    // If we've previously marked it as granted, actually test if it works
    if (savedState) {
      return await _canAccessNetwork();
    }
    
    return false;
  }
  
  /// Marks that the user has granted network permission
  static Future<void> markPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionGrantedKey, true);
    _attemptsMade = _maxAttempts; // Stop further attempts
  }

  /// Attempts multiple approaches to trigger the iOS local network permission dialog
  static Future<void> triggerLocalNetworkPermissionDialog() async {
    // Only run on iOS
    if (!Platform.isIOS) return;
    
    // Check if permission is already granted by actually testing network access
    if (await _canAccessNetwork()) {
      debugPrint('Network permission confirmed to be working, marking as granted');
      await markPermissionGranted();
      return;
    }
    
    // Reset permission state since we've confirmed it's not working
    await reset();
    
    debugPrint('Attempting to trigger iOS local network permission dialog...');
    
    // Make multiple more aggressive attempts with a small delay between them
    // Respect the maximum number of attempts across app restarts
    for (int i = 0; i < _maxAttempts && _attemptsMade < _maxAttempts; i++) {
      _attemptsMade++;
      debugPrint('Attempt ${i+1} to trigger permission dialog');
      
      // Force app to foreground to make sure permission dialog can appear
      if (i == 0) {
        await _ensureAppInForeground();
        
        // Clear any existing permission dialogs by triggering a different one
        debugPrint('Requesting location permission to prime system dialogs');
        await Permission.locationWhenInUse.request();
        // Give iOS time to process the permission request
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Try both approaches together for more reliable triggering
      bool success = false;
      
      // First approach: Bind to localhost with different ports
      final bindSuccess = await _tryBindToLocalhost();
      success = bindSuccess;
      
      // Second approach: Try to establish connection to our own socket
      final connectSuccess = await _tryConnectToLocalhost();
      success = success || connectSuccess;
      
      // Third approach: Try to use platform channel call to trigger dialog
      await _tryPlatformChannelNetworkCall();
      
      // If we successfully performed at least one network action, check if permission works
      if (success && await _canAccessNetwork()) {
        debugPrint('Network permission now working, marking as granted');
        await markPermissionGranted();
        return;
      }
      
      // Wait between attempts
      await Future.delayed(const Duration(milliseconds: 800));
    }
    
    // Give time for the dialog to appear
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Try to bind to localhost on multiple ports to trigger the permission dialog
  static Future<bool> _tryBindToLocalhost() async {
    // Try multiple ports in case some are already in use
    final ports = [12345, 54321, 8123, 8124, 8080, 9090, 0];
    
    for (final port in ports) {
      try {
        debugPrint('Attempting to bind to localhost:$port to trigger network permission dialog');
        
        // Use a shorter timeout for binding operations
        final socket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4, // Use explicit loopback address
          port, 
          shared: true
        ).timeout(const Duration(seconds: 2), onTimeout: () {
          debugPrint('Binding timed out for port $port');
          throw TimeoutException('Binding timed out');
        });
        
        // Immediately try to connect to our own socket to force more network activity
        try {
          final client = await Socket.connect(InternetAddress.loopbackIPv4, socket.port)
              .timeout(const Duration(seconds: 1));
          client.add('Hello'.codeUnits);
          await Future.delayed(const Duration(milliseconds: 100));
          await client.close();
        } catch (e) {
          debugPrint('Failed to connect to our own socket: $e');
        }
        
        // Keep the socket open a bit longer to ensure dialog appears
        await Future.delayed(const Duration(milliseconds: 300));
        
        await socket.close();
        debugPrint('Successfully bound to localhost:${socket.port}');
        return true; // Success
      } catch (e) {
        debugPrint('Failed to bind to localhost:$port - $e');
        // Continue to the next port
      }
    }
    
    return false; // No successful binding
  }

  /// Try to connect to localhost to trigger the permission dialog
  static Future<bool> _tryConnectToLocalhost() async {
    ServerSocket? server;
    Socket? socket;
    
    try {
      // Create a temporary server socket
      server = await ServerSocket.bind('localhost', 0, shared: true)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Server socket binding timed out');
      });
      final port = server.port;
      
      debugPrint('Created server on port $port, now trying to connect to it');
      
      // Setup the server to accept connections
      final completer = Completer<void>();
      server.listen((client) {
        debugPrint('Accepted connection from client');
        client.listen(
          (data) => debugPrint('Received data: ${String.fromCharCodes(data)}'),
          onDone: () => debugPrint('Client disconnected')
        );
        if (!completer.isCompleted) completer.complete();
      });
      
      // Try to connect to our own server
      socket = await Socket.connect('localhost', port)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Connection attempt timed out');
      });
      
      // Send some data to make the connection more active
      socket.add('Hello from client'.codeUnits);
      
      // Wait for the server to process the connection
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => debugPrint('Waiting for server connection timed out')
      );
      
      // Wait longer for the dialog to appear
      await Future.delayed(const Duration(seconds: 2));
      
      debugPrint('Successfully connected to localhost:$port');
      return true;
    } catch (e) {
      debugPrint('Failed to connect to localhost - $e');
      return false;
    } finally {
      // Clean up
      socket?.destroy();
      server?.close();
    }
  }
  
  /// Tries to use platform channels for network access to trigger dialog
  static Future<void> _tryPlatformChannelNetworkCall() async {
    try {
      // Create a platform channel with a unique name
      const platform = MethodChannel('com.trueway.ecommerce/network_test');
      // Try to invoke a method that doesn't exist - this will fail but may trigger network
      await platform.invokeMethod('testNetworkPermission').catchError((e) {
        // Expected to fail, but the attempt itself might trigger the permission dialog
        debugPrint('Platform channel method call failed as expected: $e');
      });
    } catch (e) {
      debugPrint('Platform channel setup failed: $e');
    }
  }

  /// Test if we can actually access the network by binding a socket
  static Future<bool> _canAccessNetwork() async {
    try {
      // Try to quickly bind to a socket on localhost as a test
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0, shared: true)
          .timeout(const Duration(seconds: 1));
      await socket.close();
      return true;
    } catch (e) {
      debugPrint('Network access test failed: $e');
      return false;
    }
  }

  /// Ensure app is in foreground for permission dialogs to appear
  static Future<void> _ensureAppInForeground() async {
    // Currently there's no direct way in Flutter to force foreground,
    // but we can try to interact with the UI thread
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Call this if you need to manually reset the permission status
  static Future<void> reset() async {
    _attemptsMade = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionGrantedKey);
  }
}
