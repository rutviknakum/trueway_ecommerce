import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trueway_ecommerce/services/api_service.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      try {
        final response = await _apiService.requestPasswordReset(
          emailController.text.trim(),
        );

        setState(() {
          _isLoading = false;
          _isSuccess = response['success'] ?? false;
          _message =
              _isSuccess
                  ? response['message'] ??
                      "Password reset instructions sent to your email."
                  : response['error'] ??
                      "Failed to send reset email. Please try again.";
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message = "An error occurred. Please check your connection.";
        });
        print("Password reset error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password", style: GoogleFonts.poppins()),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/images/logo.png", height: 120),
                  SizedBox(height: 20),
                  Text(
                    "Reset Password",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Enter your email address to receive a password reset link",
                    style: GoogleFonts.poppins(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),

                  // Message container
                  if (_message != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            _isSuccess
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _message!,
                        style: GoogleFonts.poppins(
                          color: _isSuccess ? Colors.green : Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: _message != null ? 20 : 0),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 15,
                      ),
                    ),
                    validator: (value) {
                      if (value!.isEmpty || !value.contains("@")) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 25),

                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                        onPressed: _resetPassword,
                        style: ThemeConfig.getPrimaryButtonStyle(),
                        child: Text(
                          "Reset Password",
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ),

                  SizedBox(height: 15),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Back to Login",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
