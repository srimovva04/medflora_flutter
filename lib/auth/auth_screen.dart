import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/role_page.dart';
import '../plant_identification/functionality_page.dart';
import '../specialist/specialist_dashboard_page.dart';
import '../specialist/specialist_page.dart';
import 'curator_registration.dart';
import 'providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


enum AuthMode { signup, login }
enum UserRole { admin, curator }

class AuthScreen extends StatefulWidget {
  final UserRole role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.login;
  final Map<String, String> _authData = {'email': '', 'password': ''};
  String _phone = '';
  String _otp = '';
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isSendingOtp = false;
  var _isLoading = false;
  final _passwordController = TextEditingController();

  String getRoleString() {
    return widget.role == UserRole.admin ? 'admin' : 'curator';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('An Error Occurred!'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }



  Future<void> _sendOtp() async {
    setState(() => _isSendingOtp = true);

    final response = await http.post(
      Uri.parse('${Config.apiUrl}/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': _phone}),
    );

    setState(() => _isSendingOtp = false);

    if (response.statusCode == 200) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('OTP sent')));
    } else {
      _showErrorDialog('Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final response = await http.post(
      Uri.parse('${Config.apiUrl}/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': _phone,
        'otp': _otp,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        _otpVerified = true;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('OTP verified')));
    } else {
      _showErrorDialog('Invalid or expired OTP');
    }
  }

  Future<void> _submit() async {
    if (_authMode == AuthMode.signup) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // ================= LOGIN =================
      if (_authMode == AuthMode.login) {
        bool success = await authProvider.login(
          _authData['email']!,
          _authData['password']!,
        );

        if (!success) {
          _showErrorDialog("Login failed. Please check your credentials.");
          setState(() => _isLoading = false);
          return;
        }

        // // Role-based navigation
        // if (authProvider.userRole == 'curator') {
        //   Navigator.of(context).pushReplacement(
        //     // MaterialPageRoute(builder: (_) => const SpecialistPage()),
        //     MaterialPageRoute(builder: (_) => const SpecialistDashboardPage()),
        //   );
        // }
        // Inside _submit() under the LOGIN section
        if (authProvider.userRole == 'curator') {
          // Check if they've already filled out their professional details
          // You might need to add a 'isProfileComplete' boolean to your AuthProvider
          if (authProvider.isProfileComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SpecialistDashboardPage()),
            );
          } else {
            // REDIRECT TO PROFESSIONAL REGISTRATION FORM
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CuratorRegistrationScreen()),
            );
          }
        } else if (authProvider.userRole == 'user') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const FunctionalityPage()),
          );
        } else {
          _showErrorDialog("Unknown user role: ${authProvider.userRole}");
        }

        // ================= SIGNUP =================
      } else {
        // 🔒 BLOCK signup unless OTP is verified
        if (!_otpVerified) {
          _showErrorDialog("Please verify your phone number first");
          setState(() => _isLoading = false);
          return;
        }

        final error = await authProvider.signup(
          _authData['email']!,
          _authData['password']!,
          _phone, // ✅ verified phone
        );

        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signup successful! Please log in.'),
            ),
          );

          // Reset OTP state for safety
          setState(() {
            _authMode = AuthMode.login;
            _otpSent = false;
            _otpVerified = false;
            _otp = '';
            _phone = '';
          });
        } else {
          _showErrorDialog(error);
        }
      }
    } catch (error) {
      _showErrorDialog("An unexpected error occurred: $error");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _switchAuthMode() {
    setState(() {
      _authMode =
      _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700; // Define a consistent primary color

    // Define a consistent border style for the input fields
    final inputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 24),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        border: inputBorderStyle,
                        focusedBorder: inputBorderStyle.copyWith(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Invalid email!';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _authData['email'] = value.trim();   // ✅ FIX
                      },
                      onSaved: (value) {
                        _authData['email'] = value!.trim();  // ✅ KEEP
                      },
                    ),

                    const SizedBox(height: 10),
                  if (_authMode == AuthMode.signup)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone, color: primaryColor),
                        border: inputBorderStyle,
                        focusedBorder: inputBorderStyle.copyWith(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Enter valid phone number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _phone = value.trim();
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    if (_authMode == AuthMode.signup && !_otpSent)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _phone.length < 10 || _isSendingOtp
                              ? null
                              : _sendOtp,
                          child: _isSendingOtp
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Send OTP'),
                        ),
                      ),
                    const SizedBox(height: 10),

                    if (_authMode == AuthMode.signup && _otpSent && !_otpVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _otp = value.trim();
                            });
                          },
                        ),
                      ),
                    if (_authMode == AuthMode.signup && _otpSent && !_otpVerified)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _otp.length < 6 ? null : _verifyOtp,
                          child: const Text('Verify OTP'),
                        ),
                      ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                        border: inputBorderStyle,
                        focusedBorder: inputBorderStyle.copyWith(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      obscureText: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty || value.length < 6) {
                          return 'Password is too short!';
                        }
                        return null;
                      },
                      onSaved: (value) => _authData['password'] = value!,
                    ),
                    const SizedBox(height: 10),
                    if (_authMode == AuthMode.signup)
                      TextFormField(
                        enabled: _authMode == AuthMode.signup,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                          border: inputBorderStyle,
                          focusedBorder: inputBorderStyle.copyWith(
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match!';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          // onPressed: _submit,
                          onPressed: (_authMode == AuthMode.signup && !_otpVerified)
                              ? null
                              : _submit,

                          child: Text(
                            _authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                      onPressed: _switchAuthMode,
                      child: Text(
                          '${_authMode == AuthMode.login ? 'Sign up' : 'Login'} instead'),
                    ),
                  ],
                ),
              ),
      );
  }

}




// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'auth_provider.dart';
//
// enum AuthMode { signup, login }
// enum UserRole { admin, curator }
//
// class AuthScreen extends StatefulWidget {
//   final UserRole role;
//   const AuthScreen({super.key, required this.role});
//
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   final GlobalKey<FormState> _formKey = GlobalKey();
//   AuthMode _authMode = AuthMode.login;
//   final Map<String, String> _authData = {'email': '', 'password': ''};
//   var _isLoading = false;
//   final _passwordController = TextEditingController();
//
//   String getRoleString() {
//     return widget.role == UserRole.admin ? 'admin' : 'curator';
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('An Error Occurred!'),
//         content: Text(message),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('Okay'),
//             onPressed: () {
//               Navigator.of(ctx).pop();
//             },
//           )
//         ],
//       ),
//     );
//   }
//
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//     _formKey.currentState!.save();
//     setState(() => _isLoading = true);
//
//     try {
//       if (_authMode == AuthMode.login) {
//         // Updated: login doesn't need a role parameter anymore
//         await Provider.of<AuthProvider>(context, listen: false).login(
//             _authData['email']!, _authData['password']!);
//       } else {
//         await Provider.of<AuthProvider>(context, listen: false).signup(
//             _authData['email']!, _authData['password']!, getRoleString());
//         // Switch to login mode after successful signup for user convenience
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Signup successful! Please log in.')),
//         );
//         setState(() => _authMode = AuthMode.login);
//       }
//     } catch (error) {
//       _showErrorDialog(error.toString());
//     }
//
//     if(mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _switchAuthMode() {
//     setState(() {
//       _authMode =
//       _authMode == AuthMode.login ? AuthMode.signup : AuthMode.login;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final deviceSize = MediaQuery.of(context).size;
//     return Scaffold(
//       body: Container(
//         height: deviceSize.height,
//         width: deviceSize.width,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF00796B), Color(0xFF004D40)], // Teal gradient
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Card(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               elevation: 8,
//               margin: const EdgeInsets.all(20),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: <Widget>[
//                       Text(
//                         '${getRoleString().toUpperCase()} ${_authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP'}',
//                         style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).primaryColor),
//                       ),
//                       const SizedBox(height: 20),
//                       TextFormField(
//                         decoration: const InputDecoration(labelText: 'E-Mail'),
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value == null || value.isEmpty || !value.contains('@')) {
//                             return 'Invalid email!';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) => _authData['email'] = value!,
//                       ),
//                       const SizedBox(height: 12),
//                       TextFormField(
//                         decoration: const InputDecoration(labelText: 'Password'),
//                         obscureText: true,
//                         controller: _passwordController,
//                         validator: (value) {
//                           if (value == null || value.isEmpty || value.length < 6) {
//                             return 'Password is too short!';
//                           }
//                           return null;
//                         },
//                         onSaved: (value) => _authData['password'] = value!,
//                       ),
//                       if (_authMode == AuthMode.signup)
//                         Column(
//                           children: [
//                             const SizedBox(height: 12),
//                             TextFormField(
//                               enabled: _authMode == AuthMode.signup,
//                               decoration: const InputDecoration(
//                                   labelText: 'Confirm Password'),
//                               obscureText: true,
//                               validator: _authMode == AuthMode.signup
//                                   ? (value) {
//                                 if (value != _passwordController.text) {
//                                   return 'Passwords do not match!';
//                                 }
//                                 return null;
//                               }
//                                   : null,
//                             ),
//                           ],
//                         ),
//                       const SizedBox(height: 25),
//                       if (_isLoading)
//                         const CircularProgressIndicator()
//                       else
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _submit,
//                             child: Text(
//                                 _authMode == AuthMode.login ? 'LOGIN' : 'SIGN UP'),
//                           ),
//                         ),
//                       TextButton(
//                         onPressed: _switchAuthMode,
//                         child: Text(
//                             '${_authMode == AuthMode.login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
