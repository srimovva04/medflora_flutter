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
                    'Welcome to MedFlora',
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



/// ROUGH ROLE SELECTION PAGE
// import 'package:flutter/material.dart';
// import '../plant_identification/functionality_page.dart';
// import '../plant_identification/plant_gallery.dart';
// import '../specialist/get_data.dart';
// import '../specialist/specialist_page.dart';
//
// class RoleSelectionPage extends StatelessWidget {
//   const RoleSelectionPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Welcome to MedFlora'),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'Please select your role to continue',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 18, color: Colors.black54),
//               ),
//               const SizedBox(height: 40),
//
//               // Button 1: User
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.person_outline),
//                 label: const Text('I am a User'),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const FunctionalityPage()),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//
//               // Button 2: Specialist
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.science_outlined),
//                 label: const Text('I am a Specialist'),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const SpecialistPage()),
//                   );
//                 },
//               ),
//
//               const SizedBox(height: 32), // Spacing before the text link
//
//               // --- NEW CLICKABLE TEXT ---
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       // Replace this with your actual Gallery/Grid page
//                       builder: (context) => const BrowseImagesPage(),
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   "Browse Images",
//                   style: TextStyle(
//                     fontSize: 16,
//                     decoration: TextDecoration.underline, // Optional: adds underline
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const FullMetadataPage(),
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   "Upload or camera",
//                   style: TextStyle(
//                     fontSize: 16,
//                     decoration: TextDecoration.underline,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import '../plant_identification/functionality_page.dart';
// import '../specialist/specialist_page.dart';
//
// class RoleSelectionPage extends StatelessWidget {
//   const RoleSelectionPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Welcome to MedFlora'),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'Please select your role to continue',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 18, color: Colors.black54),
//               ),
//               const SizedBox(height: 40),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.person_outline),
//                 label: const Text('I am a User'),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const FunctionalityPage()),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.science_outlined),
//                 label: const Text('I am a Specialist'),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const SpecialistPage()),
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