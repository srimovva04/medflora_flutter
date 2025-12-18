// /// ACTUAL AUTH CODE
// import 'package:flutter/material.dart';
//
// import '../auth/auth_screen.dart';
// import '../plant_identification/functionality_page.dart';
//
// class RoleSelectionPage extends StatelessWidget {
//   const RoleSelectionPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Define a consistent button style to match the app's theme
//     final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
//       foregroundColor: Colors.white, // Text and icon color
//       backgroundColor: Colors.green.shade600, // Main button color
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       elevation: 4,
//       shadowColor: Colors.green.shade100,
//     );
//
//     return Scaffold(
//       // Use a light, soft green background consistent with your app's UI
//       backgroundColor: Colors.green.shade50,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // App Icon for brand identity
//               Icon(
//                 Icons.eco_outlined,
//                 size: 80,
//                 color: Colors.green.shade700,
//               ),
//               const SizedBox(height: 24),
//
//               // Updated Title Text
//               Text(
//                 'Welcome to MedFlora',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green.shade800, // Dark green for readability
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // Updated Subtitle Text
//               Text(
//                 'Please select your role to continue',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.grey.shade600, // Softer grey for subtitle
//                 ),
//               ),
//               const SizedBox(height: 60),
//
//               // Button for General User with the new style
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.person_outline, size: 24),
//                 label: const Text('I am a User'),
//                 style: buttonStyle,
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const FunctionalityPage(),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//
//               // Button for Specialist with the new style
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.science_outlined, size: 24),
//                 label: const Text('I am a Specialist'),
//                 style: buttonStyle,
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                       const AuthScreen(role: UserRole.curator),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//



/// ROUGH ROLE SELECTION PAGE
import 'package:flutter/material.dart';
import '../plant_identification/functionality_page.dart';
import '../specialist/specialist_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to MedFlora'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please select your role to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('I am a User'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FunctionalityPage()),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.science_outlined),
                label: const Text('I am a Specialist'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpecialistPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}