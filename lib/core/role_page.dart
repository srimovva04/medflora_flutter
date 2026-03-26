/// ACTUAL AUTH CODE
import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';
import '../plant_identification/functionality_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a consistent button style to match the app's theme
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.white, // Text and icon color
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      shadowColor: Colors.green.shade100,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // const SizedBox(height: ),

              Column(
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 64,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to FloraMediX',
                    style: TextStyle(
                      fontSize: 24, // 🔽 smaller
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 5),

              // 🔥 Auth card
              AuthScreen(role: UserRole.curator),

              // Credits
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                      width: 100,
                      child: Image.asset('assets/plantnet_credit.png'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The image-based plant species identification service used, is based on the Pl@ntNet recognition API, regularly updated and accessible through the site https://my.plantnet.org/',
                        style: TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );

  }
}
class AuthForm extends StatelessWidget {
  const AuthForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const AuthScreen(role: UserRole.curator));
  }
}
