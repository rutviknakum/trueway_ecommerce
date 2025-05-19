import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to handle iOS local network permission requests
/// This is specifically needed for Flutter debug mode to allow
/// the Dart VM Service to work properly on iOS devices
class NetworkPermissionHelper {
  /// Flag to track if we've already attempted to trigger the dialog
  static bool _hasTriggeredDialog = false;
  
  /// Preference key to store permission granted status
  static const String _permissionGrantedKey = 'network_permission_granted';

  /// Checks if the user has previously indicated they've granted the permission
  static Future<bool> hasGrantedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionGrantedKey) ?? false;
  }
  
  /// Marks that the user has granted network permission
  static Future<void> markPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionGrantedKey, true);
    _hasTriggeredDialog = true;
  }

  /// Attempts multiple approaches to trigger the iOS local network permission dialog
  static Future<void> triggerLocalNetworkPermissionDialog() async {
    // Only run on iOS
    if (!Platform.isIOS) return;
    
    // Check if permission is already granted
    final hasPermission = await hasGrantedPermission();
    if (hasPermission) {
      debugPrint('Network permission already granted, skipping dialog');
      return;
    }
    
    // Only trigger once per app session if not granted
    if (_hasTriggeredDialog) return;
    _hasTriggeredDialog = true;
    
    debugPrint('Attempting to trigger iOS local network permission dialog...');
    
    // Make multiple attempts with a small delay between them
    for (int i = 0; i < 3; i++) {
      debugPrint('Attempt ${i+1} to trigger permission dialog');
      
      // Try to request location permission first to ensure system is ready
      if (i == 0) {
        debugPrint('Requesting location permission to prime system dialogs');
        await Permission.locationWhenInUse.request();
        // Give iOS time to process the permission request
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // First approach: Bind to localhost with different ports
      final bindSuccess = await _tryBindToLocalhost();
      
      // Second approach: Try to establish connection to our own socket
      if (!bindSuccess) {
        final connectSuccess = await _tryConnectToLocalhost();
        if (connectSuccess) break;
      } else {
        break;
      }
      
      // Wait between attempts
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // Give time for the dialog to appear
    await Future.delayed(const Duration(seconds: 2));
  }

  /// Try to bind to localhost on multiple ports to trigger the permission dialog
  static Future<bool> _tryBindToLocalhost() async {
    // Try multiple ports in case some are already in use
    final ports = [12345, 54321, 8123, 8124, 8080, 9090, 0];
    
    for (final port in ports) {
      try {
        debugPrint('Attempting to bind to localhost:$port to trigger network permission dialog');
        
        // Use a longer timeout for binding operations
        final socket = await ServerSocket.bind(
          'localhost', 
          port, 
          shared: true
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Binding timed out for port $port');
          throw TimeoutException('Binding timed out');
        });
        
        // Keep the socket open a bit longer to ensure dialog appears
        await Future.delayed(const Duration(seconds: 1));
        
        // Try to accept connections to make the dialog more likely to appear
        socket.listen((client) {
          debugPrint('Received connection on localhost:${socket.port}');
          client.close();
        });
        
        // Keep socket open a bit longer
        await Future.delayed(const Duration(seconds: 1));
        
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
  
  /// Call this if you need to manually reset the permission status
  static Future<void> reset() async {
    _hasTriggeredDialog = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionGrantedKey);
  }
}
