import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../auth/providers/auth_provider.dart';
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

  /// Fetches only the unverified submissions from the backend.
  /// The backend now filters out items where 'is_verified' is true.
  // Future<void> _fetchSubmissions() async {
  //   setState(() {
  //     _isLoading = true;
  //     _error = null;
  //   });
  //
  //   try {
  //     final url = Uri.parse('${Config.apiUrl}/admin/all-submissions');
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = jsonDecode(response.body);
  //       setState(() {
  //         _submissions = responseData['data'] ?? [];
  //         _isLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         _error = "Server Error: ${response.statusCode}";
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _error = "Connection failed. Check backend status.";
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String role = authProvider.userRole ?? 'user';

    try {
      final url = Uri.parse('${Config.apiUrl}/admin/all-submissions?role=$role');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        List<dynamic> fetchedList = responseData['data'] ?? [];

        // --- SORTING LOGIC START ---
        fetchedList.sort((a, b) {
          int getPriority(Map<String, dynamic> item) {
            final String status = item['status'] ?? 'pending';
            final String uploaderRole = item['uploader_role'] ?? 'unknown';

            // Priority 1: Regular Curator has reviewed it and it's waiting for Senior approval
            if (status == 'pending_senior_review') {
              return 1;
            }
            // Priority 3: Uploaded by another Senior Curator (Lowest Priority)
            else if (uploaderRole == 'senior_curator') {
              return 3;
            }
            // Priority 2: Brand new AI Predictions or regular Manual Uploads
            else {
              return 2;
            }
          }

          int priorityA = getPriority(a);
          int priorityB = getPriority(b);

          // Compare priorities (1 comes before 2, 2 comes before 3)
          return priorityA.compareTo(priorityB);
        });
        // --- SORTING LOGIC END ---

        setState(() {
          _submissions = fetchedList;
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
        _error = "Connection failed. Check backend status.";
        _isLoading = false;
      });
    }
  }
  ///works
  // Future<void> _fetchSubmissions() async {
  //   setState(() {
  //     _isLoading = true;
  //     _error = null;
  //   });
  //
  //   // 1. Get the AuthProvider to find out who is logged in
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final String role = authProvider.userRole ?? 'user';
  //
  //   try {
  //     // 2. Pass the role to the backend in the URL
  //     final url = Uri.parse('${Config.apiUrl}/admin/all-submissions?role=$role');
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> responseData = jsonDecode(response.body);
  //       setState(() {
  //         _submissions = responseData['data'] ?? [];
  //         _isLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         _error = "Server Error: ${response.statusCode}";
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _error = "Connection failed. Check backend status.";
  //       _isLoading = false;
  //     });
  //   }
  // }


  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'senior_curator': return Colors.red.shade700;
      case 'curator': return Colors.blue.shade700;
      case 'prediction': return Colors.purple.shade700;
      default: return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F5),
      appBar: AppBar(
        title: const Text(
            'Pending Verifications',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D5245))
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3D5245)),
              onPressed: _fetchSubmissions
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _error != null
          ? _buildErrorWidget()
          : _buildList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchSubmissions, child: const Text("Retry")),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all_rounded, size: 64, color: Colors.green.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "All caught up!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const Text("No pending submissions to verify."),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final item = _submissions[index];
        final String imageUrl = "${Config.apiUrl}/history/image/${item['imageId']}";
        final String role = item['uploader_role'] ?? 'unknown';
        final Color roleColor = _getRoleColor(role);

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            leading: Hero(
              tag: item['id'], // Smooth transition for the image
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Colors.green),
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['submittedName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D5245)),
                  ),
                ),
                _buildRoleBadge(role, roleColor),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                  'Source: ${item['type'] == 'prediction' ? "AI Prediction" : "Manual Upload"}\nDate: ${item['date']}',
                  style: const TextStyle(fontSize: 12, height: 1.4)
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () async {
              // Wait for the result from the detail page
              final bool? refreshNeeded = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerificationDetailPage(
                    submissionData: {...item, 'imageUrl': imageUrl},
                  ),
                ),
              );

              // If refreshNeeded is true, it means a plant was successfully verified
              if (refreshNeeded == true) {
                _fetchSubmissions();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}


