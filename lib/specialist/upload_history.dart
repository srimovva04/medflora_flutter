import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../core/config.dart';

class UploadHistoryPage extends StatefulWidget {
  const UploadHistoryPage({super.key});

  @override
  State<UploadHistoryPage> createState() => _UploadHistoryPageState();
}

class _UploadHistoryPageState extends State<UploadHistoryPage> {
  List records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUploads();
  }

  Future<void> fetchUploads() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await http.get(
      Uri.parse("${Config.apiUrl}/uploads/history"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("UPLOAD HISTORY STATUS = ${res.statusCode}");
    print(res.body);

    if (res.statusCode == 200) {
      setState(() {
        records = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Upload History"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())

          : records.isEmpty
          ? const Center(
        child: Text(
          "No uploads yet",
          style: TextStyle(fontSize: 16),
        ),
      )

          : RefreshIndicator(
        onRefresh: fetchUploads,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (c, i) {
            final r = records[i];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UploadDetailPage(record: r),
                  ),
                );
              },

              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(.06),
                      offset: const Offset(0, 4),
                    )
                  ],
                ),

                child: Row(
                  children: [

                    /// IMAGE
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                      child: Image.network(
                        "${Config.apiUrl}${r['image_url']}",
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 14),

                    /// TEXT
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              r['name_common'] ?? "Unknown",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              r['name_scientific'] ?? "",
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 14,
                                    color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    r['location'] ?? "",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.chevron_right),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




class UploadDetailPage extends StatelessWidget {
  final Map record;

  const UploadDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final imageUrl = "${Config.apiUrl}${record['image_url']}";

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Details")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullImageView(imageUrl: imageUrl),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _infoCard("Common Name", record['name_common']),
          _infoCard("Scientific Name", record['name_scientific']),
          _infoCard("Coordinates", record['location']),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              value ?? "-",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class FullImageView extends StatelessWidget {
  final String imageUrl;

  const FullImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}



//
//
//
// class UploadDetailPage extends StatelessWidget {
//   final Map record;
//
//   const UploadDetailPage({super.key, required this.record});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Upload Details")),
//
//       body: ListView(
//         padding: const EdgeInsets.all(20),
//         children: [
//
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16),
//             child: Image.network(
//               "${Config.apiUrl}${record['image_url']}",
//               height: 260,
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           const SizedBox(height: 24),
//
//           _infoCard("Common Name", record['name_common']),
//           _infoCard("Scientific Name", record['name_scientific']),
//           _infoCard("Coordinates", record['location']),
//           _infoCard("Source", record['source']),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoCard(String label, String? value) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 14),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label,
//                 style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey)),
//             const SizedBox(height: 6),
//             Text(value ?? "-",
//                 style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }
// }
