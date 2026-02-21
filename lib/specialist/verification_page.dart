import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import 'verification_details.dart';

class VerificationListPage extends StatefulWidget {
  const VerificationListPage({super.key});

  @override
  State<VerificationListPage> createState() => _VerificationListPageState();
}

class _VerificationListPageState extends State<VerificationListPage> {
  List<dynamic> _submissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  // --- API CALL: FETCH ALL PREDICTION HISTORY ---
  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('${Config.apiUrl}/admin/all-submissions');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          // Extracts the 'data' list from your backend JSON response
          _submissions = responseData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection failed. Check if backend is running at ${Config.apiUrl}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        title: const Text(
          'Verify Submissions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D5245)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF3D5245)),
            onPressed: _fetchSubmissions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchSubmissions, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_submissions.isEmpty) {
      return const Center(
        child: Text("No user submissions found in history.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final item = _submissions[index];

        // Construct the full image URL dynamically using the imageId from DB
        final String imageUrl = "${Config.apiUrl}/history/image/${item['imageId']}";

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.eco, color: Colors.green, size: 24),
                  ),
                ),
              ),
            ),
            title: Text(
              item['submittedName']?.toString() ?? 'Unknown Plant', // Null safety
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D5245)),
            ),
            subtitle: Text(
              'Match: ${item['score'] ?? "0%"} • ${item['date'] ?? "N/A"}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              // Pass the item (including the constructed imageUrl) to the detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationDetailPage(
                    submissionData: {
                      ...item,
                      'imageUrl': imageUrl, // Ensure detail page has the full URL
                    },
                  ),
                ),
              ).then((_) => _fetchSubmissions()); // Refresh list when returning
            },
          ),
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'verification_details.dart';
//
// class VerificationListPage extends StatelessWidget {
//   const VerificationListPage({super.key});
//
//   // --- UPDATED DUMMY DATA WITH DYNAMIC SUGGESTIONS FOR EACH PLANT ---
//   final List<Map<String, dynamic>> submissions = const [
//     {
//       'id': '201',
//       'submittedName': 'Matucana Krahnii',
//       'date': '2025-10-30',
//       'imageUrl': 'https://res.cloudinary.com/dyi7dglot/image/upload/v1761972424/vlifmmki5gx6hojqbxpt.jpg',
//     },
//     {
//       'id': '202',
//       'submittedName': 'Eschscholzia',
//       'date': '2025-10-29',
//       'imageUrl': 'https://res.cloudinary.com/dyi7dglot/image/upload/v1770437045/n5wtcraeizlxcgcqoquv.jpg',
//     },
//     {
//       'id': '203',
//       'submittedName': 'Scutellaria',
//       'date': '2025-10-28',
//       'imageUrl': 'https://res.cloudinary.com/dyi7dglot/image/upload/v1770133237/yiecqa1gg3ru9jdvxiel.jpg',
//     },
//   ];
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Submissions'),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: submissions.length,
//         itemBuilder: (context, index) {
//           final submission = submissions[index];
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 12.0),
//             child: Card(
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                 leading: ClipOval(
//                   child: SizedBox.fromSize(
//                     size: const Size.fromRadius(25), // Image radius
//                     child: Image.network(
//                       submission['imageUrl'],
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(child: CircularProgressIndicator());
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         debugPrint('Image failed to load for ${submission['submittedName']}: $error');
//                         return Container(
//                           color: Colors.grey.shade200,
//                           child: const Icon(Icons.eco, color: Colors.green, size: 30),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 title: Text(
//                   submission['submittedName'],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('Submitted on: ${submission['date']}'),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//                 onTap: () {
//                   // The entire submission map (including suggestions) is passed here
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => VerificationDetailPage(submissionData: submission),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
//
//
// ///OLD CODE WITH SAME IMAGES
// // import 'package:flutter/material.dart';
// // import 'verification_details.dart'; // Make sure this file exists in your project
// //
// // class VerificationListPage extends StatelessWidget {
// //   const VerificationListPage({super.key});
// //
// //   // --- FIXED DUMMY DATA WITH WORKING IMAGE URLS ---
// //   // Using placeholder images from reliable sources that work without special headers
// //   final List<Map<String, dynamic>> submissions = const [
// //     {
// //       'id': '201',
// //       'submittedName': 'Matucana Krahnii',
// //       'date': '2025-10-30',
// //       'score': '25%',
// //       // Using a reliable placeholder - replace with your own hosted images or stable URLs
// //       'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Matucana_krahnii.JPG',
// //     },
// //     {
// //       'id': '202',
// //       'submittedName': 'Eschscholzia',
// //       'date': '2025-10-29',
// //       'score': '41%',
// //       'imageUrl': 'https://as1.ftcdn.net/v2/jpg/14/47/93/76/1000_F_1447937685_JpwbqJl3p7V6L5IDf87PFbxuP8OD0STM.jpg',
// //     },
// //     {
// //       'id': '203',
// //       'submittedName': 'Scutellaria',
// //       'date': '2025-10-28',
// //       'score': '85%',
// //       'imageUrl': 'https://as2.ftcdn.net/v2/jpg/15/75/02/71/1000_F_1575027124_juV9JLgb5hMA6WeeAFaPn9MQRDC1zzJQ.jpg',
// //     },
// //     {
// //       'id': '204',
// //       'submittedName': 'Cannabaceae',
// //       'date': '2025-10-27',
// //       'score': '91%',
// //       'imageUrl': 'https://plus.unsplash.com/premium_photo-1669687380166-bc9d3c806955?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
// //     }
// //   ];
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Verify Submissions'),
// //       ),
// //       body: ListView.builder(
// //         padding: const EdgeInsets.all(16.0),
// //         itemCount: submissions.length,
// //         itemBuilder: (context, index) {
// //           final submission = submissions[index];
// //           return Padding(
// //             padding: const EdgeInsets.only(bottom: 12.0),
// //             child: Card(
// //               child: ListTile(
// //                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
// //                 leading: ClipOval(
// //                   child: SizedBox.fromSize(
// //                     size: const Size.fromRadius(25), // Image radius
// //                     child: Image.network(
// //                       submission['imageUrl'],
// //                       fit: BoxFit.cover,
// //                       loadingBuilder: (context, child, loadingProgress) {
// //                         if (loadingProgress == null) return child;
// //                         return const Center(child: CircularProgressIndicator());
// //                       },
// //                       errorBuilder: (context, error, stackTrace) {
// //                         debugPrint('Image failed to load for ${submission['submittedName']}: $error');
// //                         return Container(
// //                           color: Colors.grey.shade200,
// //                           child: const Icon(Icons.eco, color: Colors.green, size: 30),
// //                         );
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //                 title: Text(
// //                   submission['submittedName'],
// //                   style: const TextStyle(fontWeight: FontWeight.bold),
// //                 ),
// //                 subtitle: Text('Submitted on: ${submission['date']}'),
// //                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
// //                 onTap: () {
// //                   // Navigate to the detail page on tap.
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => VerificationDetailPage(submissionData: submission),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// ///OLD CODE
// // import 'package:flutter/material.dart';
// // import 'verification_details.dart'; // Import the detail page
// //
// // class VerificationListPage extends StatelessWidget {
// //   const VerificationListPage({super.key});
// //
// //   // --- DUMMY DATA FOR THE SUBMISSION LIST ---
// //   // This list creates the entries that appear on the page.
// //   final List<Map<String, dynamic>> submissions = const [
// //     {
// //       'id': '101',
// //       'submittedName': 'Tulsi',
// //       'date': '2025-10-17',
// //       'score': '92%',
// //       'imageUrl': 'https://plus.unsplash.com/premium_photo-1671070369255-a459b1a85a4a?q=80&w=2071&auto=format&fit=crop',
// //     },
// //     {
// //       'id': '102',
// //       'submittedName': 'Unknown Leaf',
// //       'date': '2025-10-16',
// //       'score': '88%',
// //       'imageUrl': 'https://images.unsplash.com/photo-1629828328229-37a5e0108502?q=80&w=2070&auto=format&fit=crop',
// //     },
// //     {
// //       'id': '103',
// //       'submittedName': 'Ashwagandha?',
// //       'date': '2025-10-16',
// //       'score': '76%',
// //       'imageUrl': 'https://images.unsplash.com/photo-1595152772236-4b8156157154?q=80&w=1974&auto=format&fit=crop',
// //     },
// //     {
// //       'id': '104',
// //       'submittedName': 'Mint Leaf',
// //       'date': '2025-10-15',
// //       'score': '95%',
// //       'imageUrl': 'https://images.unsplash.com/photo-1620075436900-a8865646f901?q=80&w=2070&auto=format&fit=crop',
// //     }
// //   ];
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Verify Submissions'),
// //       ),
// //       body: ListView.builder(
// //         // Use padding on the ListView for better spacing
// //         padding: const EdgeInsets.all(16.0),
// //         itemCount: submissions.length,
// //         itemBuilder: (context, index) {
// //           final submission = submissions[index];
// //           // Use Padding for spacing between cards
// //           return Padding(
// //             padding: const EdgeInsets.only(bottom: 12.0),
// //             child: Card( // This card uses the global theme from main.dart
// //               child: ListTile(
// //                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
// //                 leading: CircleAvatar(
// //                   backgroundImage: NetworkImage(submission['imageUrl']),
// //                   radius: 25,
// //                 ),
// //                 title: Text(
// //                   submission['submittedName'],
// //                   style: const TextStyle(fontWeight: FontWeight.bold),
// //                 ),
// //                 subtitle: Text('Submitted on: ${submission['date']}'),
// //                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
// //                 onTap: () {
// //                   // Navigate to the detail page, passing the selected submission's data
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                       builder: (context) => VerificationDetailPage(submissionData: submission),
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }