import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper class to handle iOS local network permission requests
/// This is specifically needed for Flutter debug mode to allow
/// the Dart VM Service to work properly on iOS devices
class NetworkPermissionHelper {
  /// Flag to track if we've already attempted to trigger the dialog
  static bool _hasTriggeredDialog = false;

  /// Attempts multiple approaches to trigger the iOS local network permission dialog
  static Future<void> triggerLocalNetworkPermissionDialog() async {
    // Only run on iOS and only once per app session
    if (!Platform.isIOS || _hasTriggeredDialog) return;
    _hasTriggeredDialog = true;
    
    // First approach: Bind to localhost with different ports
    await _tryBindToLocalhost();
    
    // Second approach: Try to establish connection to our own socket
    await _tryConnectToLocalhost();
  }

  /// Try to bind to localhost on multiple ports to trigger the permission dialog
  static Future<void> _tryBindToLocalhost() async {
    // Try multiple ports in case some are already in use
    final ports = [12345, 54321, 8123, 8124, 0];
    
    for (final port in ports) {
      try {
        debugPrint('Attempting to bind to localhost:$port to trigger network permission dialog');
        final socket = await ServerSocket.bind('localhost', port, shared: true);
        
        // Wait a moment for the dialog to appear
        await Future.delayed(const Duration(milliseconds: 500));
        
        await socket.close();
        debugPrint('Successfully bound to localhost:${socket.port}');
        return; // Success, no need to try other ports
      } catch (e) {
        debugPrint('Failed to bind to localhost:$port - $e');
        // Continue to the next port
      }
    }
  }

  /// Try to connect to localhost to trigger the permission dialog
  static Future<void> _tryConnectToLocalhost() async {
    try {
      // Create a temporary server socket
      final server = await ServerSocket.bind('localhost', 0);
      final port = server.port;
      
      debugPrint('Created server on port $port, now trying to connect to it');
      
      // Try to connect to our own server
      final socket = await Socket.connect('localhost', port);
      
      // Wait a moment for the dialog to appear
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clean up
      await socket.close();
      await server.close();
      
      debugPrint('Successfully connected to localhost:$port');
    } catch (e) {
      debugPrint('Failed to connect to localhost - $e');
    }
  }
  
  /// Call this if you need to manually reset the trigger status
  static void reset() {
    _hasTriggeredDialog = false;
  }
}
