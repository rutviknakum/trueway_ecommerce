import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://map.uminber.in/wp-json";
  static const String consumerKey =
      "ck_7ddea3cc57458b1e0b0a4ec2256fa403dcab8892";
  static const String consumerSecret =
      "cs_8589a8dc27c260024b9db84712813a95a5747f9f";

  /// **Login User using WooCommerce API**
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final url = Uri.parse("$baseUrl/jwt-auth/v1/token");

    try {
      final response = await http.post(
        url,
        body: {"username": email, "password": password},
      );

      print("Login Response Code: ${response.statusCode}");
      print("Login Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("token", data["token"]);
        return data;
      } else {
        final errorData = json.decode(response.body);
        print("Login Error: ${errorData['message']}");
        return {"error": errorData['message']};
      }
    } catch (e) {
      print("Login Exception: $e");
      return {"error": "Something went wrong. Please try again."};
    }
  }

  /// **Signup New User using WooCommerce API**
  Future<Map<String, dynamic>?> signupUser(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse(
      "$baseUrl/wc/v3/customers?consumer_key=$consumerKey&consumer_secret=$consumerSecret",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "first_name": name,
        }),
      );

      print("Signup Response Code: ${response.statusCode}");
      print("Signup Response Body: ${response.body}");

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        print("Signup Error: ${errorData['message']}");
        return {"error": errorData['message']};
      }
    } catch (e) {
      print("Signup Exception: $e");
      return {"error": "Something went wrong. Please try again."};
    }
  }

  /// **Logout User and Clear Token**
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    print("User Logged Out Successfully.");
  }

  /// **Check if User is Logged In**
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }
}
