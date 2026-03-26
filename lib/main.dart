import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/role_page.dart';
import 'auth/providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final auth = AuthProvider();
        auth.tryAutoLogin();
        return auth;
      },
      child: MaterialApp(
        title: 'FloraMediX',
        theme: _buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const RoleSelectionPage(),
      ),
    );
  }
}


// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (context) => AuthProvider(),
//       child: MaterialApp(
//         title: 'MedFlora',
//         theme: _buildAppTheme(), // Apply the custom theme
//         debugShowCheckedModeBanner: false,
//         home: const RoleSelectionPage(),
//       ),
//     );
//   }
// }

// --- CENTRAL THEME DEFINITION ---
ThemeData _buildAppTheme() {
  final Color primaryColor = Colors.green.shade700;
  final Color secondaryColor = Colors.green.shade50;

  return ThemeData(
    primarySwatch: Colors.green,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA), // A very light grey for the background

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87, // Color for title and icons
      elevation: 1,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),

    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero, // We will control margins manually
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // Text Field Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey.shade600,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 3.0),
      ),
    ),
  );
}
