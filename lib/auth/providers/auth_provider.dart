import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config.dart';


class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole;
  String? _userId;
  // --- CHANGE: Added isLoading state back to satisfy compiler ---
  bool _isLoading = false;
  String? _userEmail;
  String? get userEmail => _userEmail; // Add this getter

  String? _userName;
  String? _userPhone;
  String? _userPosition;
  String? _userAffiliation;


  bool _isProfileComplete = true; // Default to true so 'user' role isn't blocked
  bool get isProfileComplete => _isProfileComplete;

  final String baseUrl = Config.apiUrl;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userRole => _userRole;
  // --- CHANGE: Added isLoading getter back ---
  bool get isLoading => _isLoading;
  String? get userName => _userName;           // Fixes Error 1
  String? get userPhone => _userPhone;         // Fixes Error 2
  String? get userPosition => _userPosition;   // Fixes Error 3
  String? get userAffiliation => _userAffiliation;
  String? get userId => _userId;


  // --- CHANGE: Added empty tryAutoLogin method back to satisfy compiler ---
  // This method does nothing, effectively disabling auto-login.
  Future<void> tryAutoLogin() async {
    // final prefs = await SharedPreferences.getInstance();
    //
    // if (!prefs.containsKey('jwt_token')) return;
    //
    // _token = prefs.getString('jwt_token');
    // _userRole = prefs.getString('user_role');
    // _userId = prefs.getString('user_id');
    // _userEmail = prefs.getString('user_email'); // Add this line
    // _isProfileComplete = prefs.getBool('is_profile_complete') ?? true;

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print("LOGIN STATUS = ${response.statusCode}");
      print("LOGIN BODY = ${response.body}");

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data['access_token'] == null) {
        print("No token in response");
        return false;
      }

      _token = data['access_token'];
      _userRole = data['role'];
      _userId = data['userId'];
      _isProfileComplete = data['isProfileComplete'] ?? true;

      _userName = data['fullName'];
      _userPhone = data['phone'];
      _userPosition = data['position'];
      _userAffiliation = data['affiliation'];

      final parts = _token!.split('.');
      if (parts.length == 3) {
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        _userEmail = payload['email']; // Now this will be populated!
      }

      // decode JWT safely (optional now since userId provided)
      if (_userId == null && _token != null) {
        final parts = _token!.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );
          _userId = payload['sub'];
          _userEmail = payload['email'];
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('user_role', _userRole ?? "");
      await prefs.setString('user_id', _userId ?? "");
      await prefs.setBool('is_profile_complete', _isProfileComplete);
      await prefs.setString('user_email', _userEmail ?? "");
      await prefs.setString('user_name', _userName ?? "");
      await prefs.setString('user_phone', _userPhone ?? "");
      await prefs.setString('user_position', _userPosition ?? "");
      await prefs.setString('user_affiliation', _userAffiliation ?? "");


      notifyListeners();
      return true;

    } catch (e) {
      print("LOGIN ERROR = $e");
      return false;
    }
  }


  // Future<bool> login(String email, String password) async {
  //   final url = Uri.parse('$baseUrl/login'); // Make sure this IP is correct
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({'email': email, 'password': password}),
  //     );
  //
  //     // Check if the request was successful
  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);
  //
  //       // Ensure responseData is not null and contains the expected keys
  //       if (responseData != null && responseData['access_token'] != null && responseData['role'] != null) {
  //         _token = responseData['access_token'];
  //         _userRole = responseData['role'];
  //
  //         // Decode JWT to get user ID if needed (optional)
  //         final parts = _token!.split('.');
  //         if (parts.length == 3) {
  //           final payload = json.decode(
  //             utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  //           );
  //           _userId = payload['sub']['id'];
  //         }
  //
  //         // --- CHANGE: Removed SharedPreferences to disable auto-login ---
  //         // final prefs = await SharedPreferences.getInstance();
  //         // prefs.setString('jwt_token', _token!);
  //         // prefs.setString('user_role', _userRole!);
  //
  //         notifyListeners();
  //         return true; // Login successful
  //       }
  //     }
  //
  //     // If statusCode is not 200 or response is invalid, login fails
  //     return false;
  //
  //   } catch (error) {
  //     // Handle network errors or other exceptions
  //     print(error.toString());
  //     return false;
  //   }
  // }
  //


  Future<String?> signup(String email, String password, String phone, String role) async {
    final url = Uri.parse('$baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'phone': phone,
          'role': role, // ✅ Pass role to backend
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return null; // success
      } else {
        return responseData['msg'] ?? 'Signup failed';
      }
    } catch (error) {
      return error.toString();
    }
  }

  // Future<String?> signup(String email, String password, String phone) async {
  //   final url = Uri.parse('$baseUrl/signup');
  //
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'email': email,
  //         'password': password,
  //         'phone': phone,
  //       }),
  //     );
  //
  //     final responseData = json.decode(response.body);
  //
  //     if (response.statusCode == 201) {
  //       return null; // success
  //     } else {
  //       return responseData['msg'] ?? 'Signup failed';
  //     }
  //   } catch (error) {
  //     return error.toString();
  //   }
  // }

  // Future<String?> signup(String email, String password, String role) async {
  //   final url = Uri.parse('$baseUrl/signup'); // Make sure this IP is correct
  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode({
  //         'email': email,
  //         'password': password,
  //         'role': role,
  //       }),
  //     );
  //     final responseData = json.decode(response.body);
  //
  //     if (response.statusCode == 201) {
  //       return null; // Success, no error message
  //     } else {
  //       return responseData['msg'] ?? 'An unknown error occurred.';
  //     }
  //   } catch (error) {
  //     return error.toString();
  //   }
  // }

  Future<bool> completeCuratorProfile(Map<String, String> details) async {
    final url = Uri.parse('$baseUrl/complete-curator-profile');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token', // Pass the JWT for security
        },
        body: json.encode(details),
      );

      if (response.statusCode == 200) {
        _isProfileComplete = true;

        // Update local storage so they don't see the form again
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_profile_complete', true);

        notifyListeners();
        return true;
      } else {
        print("Profile Update Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Profile Update Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userRole = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}



