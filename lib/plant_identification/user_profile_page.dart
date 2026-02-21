import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isCurator = auth.userRole == 'curator';
    const Color primaryEmerald = Color(0xFF2D6A4F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Account Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryEmerald,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PERSONAL INFORMATION ---
            _buildSectionHeader("PERSONAL INFORMATION", primaryEmerald),
            const SizedBox(height: 16),
            _buildInfoTile(Icons.person_outline, "Full Name", auth.userName ?? "Guest"),
            _buildInfoTile(Icons.alternate_email, "Email Address", auth.userEmail ?? "Not set"),
            _buildInfoTile(Icons.phone_android, "Phone Number", auth.userPhone ?? "Not set"),

            const SizedBox(height: 20),

            // --- PROFESSIONAL CREDENTIALS (Curator Only) ---
            if (isCurator) ...[
              _buildSectionHeader("PROFESSIONAL CREDENTIALS", primaryEmerald),
              const SizedBox(height: 16),
              _buildInfoTile(Icons.badge_outlined, "Current Position", auth.userPosition ?? "Verified Staff"),
              _buildInfoTile(Icons.account_balance_outlined, "Institutional Affiliation", auth.userAffiliation ?? "TMC"),
              const SizedBox(height: 20),
            ],

            // --- LOGOUT ACTION ---
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text("SIGN OUT OF SESSION", style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () => _showLogoutDialog(context, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color.withOpacity(0.8), letterSpacing: 1.4));
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: const Color(0xFF495057)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF212529), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to end your session?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text("SIGN OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../auth/providers/auth_provider.dart';
//
// class UserProfilePage extends StatelessWidget {
//   const UserProfilePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Provider.of<AuthProvider>(context);
//     final isCurator = auth.userRole == 'curator';
//     const Color primaryEmerald = Color(0xFF2D6A4F); // A deep, professional green
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           "Account Settings",
//           style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: primaryEmerald,
//         elevation: 0,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1.0),
//           child: Container(color: Colors.grey.shade200, height: 1.0),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- HEADER SECTION ---
//             _buildSectionHeader("PERSONAL INFORMATION", primaryEmerald),
//             const SizedBox(height: 16),
//             _buildInfoTile(Icons.alternate_email_rounded, "Email Address",
//                 auth.userEmail ?? "Not signed in"),
//             _buildInfoTile(Icons.verified_user_outlined, "Account Status",
//                 (auth.userRole ?? "User").toUpperCase()),
//
//             const SizedBox(height: 20),
//
//             // --- PROFESSIONAL SECTION (Conditional) ---
//             if (isCurator) ...[
//               _buildSectionHeader("PROFESSIONAL CREDENTIALS", primaryEmerald),
//               const SizedBox(height: 16),
//               _buildInfoTile(Icons.badge_outlined, "Current Position", "Verified Specialist"),
//               _buildInfoTile(Icons.account_balance_outlined, "Institutional Affiliation", "Professional Member"),
//               const SizedBox(height: 20),
//             ],
//
//             // --- LOGOUT ACTION ---
//             // const SizedBox(height: 10),
//             SizedBox(
//               width: double.infinity,
//               height: 54,
//               child: OutlinedButton.icon(
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: Colors.red.shade700,
//                   side: BorderSide(color: Colors.red.shade200),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 icon: const Icon(Icons.logout_rounded, size: 20),
//                 label: const Text(
//                   "SIGN OUT OF SESSION",
//                   style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.1),
//                 ),
//                 onPressed: () => _showLogoutDialog(context, auth),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, Color color) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w800,
//         color: color.withOpacity(0.7),
//         letterSpacing: 1.5,
//       ),
//     );
//   }
//
//   Widget _buildInfoTile(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 24.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF8F9FA),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(icon, size: 22, color: const Color(0xFF495057)),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w500),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: const TextStyle(fontSize: 16, color: Color(0xFF212529), fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showLogoutDialog(BuildContext context, AuthProvider auth) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Sign Out"),
//         content: const Text("Are you sure you want to end your current session?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
//           TextButton(
//             onPressed: () async {
//               await auth.logout();
//               if (context.mounted) Navigator.pushReplacementNamed(context, '/');
//             },
//             child: const Text("SIGN OUT", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
// }
//






// import 'package:flutter/material.dart';
//
// class UserProfilePage extends StatelessWidget {
//   const UserProfilePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Account")),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
//           const SizedBox(height: 20),
//           const ListTile(
//             leading: Icon(Icons.person_outline),
//             title: Text("User Name"),
//             subtitle: Text("MedFlora Enthusiast"),
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.settings_outlined),
//             title: const Text("App Settings"),
//             onTap: () {},
//           ),
//           ListTile(
//             leading: const Icon(Icons.help_outline),
//             title: const Text("Help & Support"),
//             onTap: () {},
//           ),
//         ],
//       ),
//     );
//   }
// }