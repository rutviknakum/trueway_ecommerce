import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/auth_provider.dart';
import 'package:trueway_ecommerce/screens/onboarding_screen.dart';
import 'package:trueway_ecommerce/screens/main_screen.dart';
import 'package:trueway_ecommerce/screens/login_screen.dart';
import 'package:trueway_ecommerce/utils/onboarding_manager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Allow a bit more time for the AuthProvider to initialize properly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start checking auth state after the build is complete
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hasSeenOnboarding = await OnboardingManager.hasSeenOnboarding();

    // First, check if the user has seen the onboarding
    if (!hasSeenOnboarding) {
      // First time user, show onboarding regardless of login status
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
      return;
    }
    
    // Wait for authProvider to finish initializing (checking if isLoading is false)
    // This ensures we have the correct login state before making navigation decisions
    if (authProvider.isLoading) {
      // Wait for loading to complete by watching for changes
      await Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return authProvider.isLoading;
      });
    }
    
    // User has seen onboarding before
    // Now we can safely check the login status
    if (authProvider.isLoggedIn) {
      // User is logged in, go directly to main screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      // User has seen onboarding but is not logged in (or logged out), go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo.png", width: 200),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              "Starting up...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }
}
