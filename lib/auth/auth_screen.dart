import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (_authMode == AuthMode.login) {
        await Provider.of<AuthProvider>(context, listen: false).login(
            _authData['email']!, _authData['password']!);
      } else {
        await Provider.of<AuthProvider>(context, listen: false).signup(
            _authData['email']!, _authData['password']!, getRoleString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please log in.')),
        );
        setState(() => _authMode = AuthMode.login);
      }
    } catch (error) {
      _showErrorDialog(error.toString());
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

    return Scaffold(
      // Add an AppBar for easy navigation back to role selection
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor), // Ensure back arrow is visible
      ),
      // Use the light green background theme
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.green.shade100,
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.eco_outlined, size: 48, color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      '${getRoleString().toUpperCase()} ${_authMode == AuthMode.login ? 'Login' : 'Sign Up'}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
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
                      onSaved: (value) => _authData['email'] = value!,
                    ),
                    const SizedBox(height: 16),
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
                    if (_authMode == AuthMode.signup)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
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
                      ),
                    const SizedBox(height: 25),
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
                          onPressed: _submit,
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
            ),
          ),
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
