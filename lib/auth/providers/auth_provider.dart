// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AuthProvider with ChangeNotifier {
//   String? _token;
//   String? _userRole;
//   bool _isLoading = true;
//
//   // --- Getters ---
//   bool get isAuthenticated => _token != null;
//   String? get token => _token;
//   String? get userRole => _userRole;
//   bool get isLoading => _isLoading;
//
//   // --- API Base URL ---
//   // IMPORTANT: For Android emulator, use 10.0.2.2 to access localhost of your machine.
//   // For iOS simulator, use localhost or 127.0.0.1.
//   // For a physical device, use your computer's network IP address (e.g., http://192.168.1.10:5000).
//   static const String _baseUrl = 'http://127.0.0.1:5000';
//
//   // --- Authentication Helper ---
//   Future<void> _authenticate(String email, String password, String? role, String endpoint) async {
//     final url = Uri.parse('$_baseUrl/$endpoint');
//     try {
//       final requestBody = {
//         'email': email,
//         'password': password,
//       };
//
//       // Only add 'role' to the body for the signup endpoint
//       if (endpoint == 'signup' && role != null) {
//         requestBody['role'] = role;
//       }
//
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );
//
//       final responseData = json.decode(response.body);
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         if (endpoint == 'login') {
//           // Updated to handle 'access_token' from Flask
//           _token = responseData['access_token'];
//           _userRole = responseData['user']['role'];
//
//           // Persist auth data
//           final prefs = await SharedPreferences.getInstance();
//           final userData = json.encode({
//             'token': _token,
//             'role': _userRole,
//           });
//           await prefs.setString('userData', userData);
//
//           notifyListeners();
//         } else {
//           // For signup, we just need to confirm success.
//           // The user will be prompted to log in.
//           print('Signup successful: ${responseData['message']}');
//         }
//       } else {
//         // Use the 'message' key from the Flask JSON response
//         throw Exception(responseData['message'] ?? 'Authentication Failed');
//       }
//     } catch (error) {
//       rethrow;
//     }
//   }
//
//   // --- Public Methods ---
//   Future<void> signup(String email, String password, String role) async {
//     return _authenticate(email, password, role, 'signup');
//   }
//
//   Future<void> login(String email, String password) async {
//     // Role is not needed for login
//     return _authenticate(email, password, null, 'login');
//   }
//
//   Future<void> tryAutoLogin() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (!prefs.containsKey('userData')) {
//       _isLoading = false;
//       notifyListeners();
//       return;
//     }
//
//     final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
//     _token = extractedUserData['token'];
//     _userRole = extractedUserData['role'];
//
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> logout() async {
//     _token = null;
//     _userRole = null;
//
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('userData');
//
//     notifyListeners();
//   }
// }
//

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole;
  String? _userId;
  // --- CHANGE: Added isLoading state back to satisfy compiler ---
  bool _isLoading = false;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userRole => _userRole;
  // --- CHANGE: Added isLoading getter back ---
  bool get isLoading => _isLoading;

  // --- CHANGE: Added empty tryAutoLogin method back to satisfy compiler ---
  // This method does nothing, effectively disabling auto-login.
  Future<void> tryAutoLogin() async {
    // Intentionally left empty.
    return;
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('http://127.0.0.1:5000/login'); // Make sure this IP is correct
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Ensure responseData is not null and contains the expected keys
        if (responseData != null && responseData['access_token'] != null && responseData['role'] != null) {
          _token = responseData['access_token'];
          _userRole = responseData['role'];

          // Decode JWT to get user ID if needed (optional)
          // final parts = _token!.split('.');
          // if (parts.length == 3) {
          //   final payload = json.decode(
          //     utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          //   );
          //   _userId = payload['sub']['id'];
          // }

          if (responseData['userId'] != null) {
            _userId = responseData['userId'];
          }

          // --- CHANGE: Removed SharedPreferences to disable auto-login ---
          // final prefs = await SharedPreferences.getInstance();
          // prefs.setString('jwt_token', _token!);
          // prefs.setString('user_role', _userRole!);

          notifyListeners();
          return true; // Login successful
        }
      }

      // If statusCode is not 200 or response is invalid, login fails
      return false;

    } catch (error) {
      // Handle network errors or other exceptions
      print(error.toString());
      return false;
    }
  }

  Future<String?> signup(String email, String password, String role) async {
    final url = Uri.parse('http://127.0.0.1:5000/signup'); // Make sure this IP is correct
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return null; // Success, no error message
      } else {
        return responseData['msg'] ?? 'An unknown error occurred.';
      }
    } catch (error) {
      return error.toString();
    }
  }

  Future<void> logout() async {
    _token = null;
    _userRole = null;
    _userId = null;
    // --- CHANGE: Also ensure SharedPreferences is cleared on logout ---
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}



