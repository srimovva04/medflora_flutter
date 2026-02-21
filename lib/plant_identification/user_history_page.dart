import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../core/config.dart';
import 'plant_result.dart';

class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  static VoidCallback? reload;

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  List records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();

    // register callback
    UserHistoryPage.reload = fetchHistory;
  }

  Future<void> fetchHistory() async {
    setState(() => loading = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await http.get(
        Uri.parse("${Config.apiUrl}/history"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("History status = ${res.statusCode}");
      debugPrint("History body = ${res.body}");

      if (res.statusCode == 200) {
        setState(() {
          records = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("History fetch error: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return const Center(child: Text("No predictions yet"));
    }

    return RefreshIndicator(
      onRefresh: fetchHistory,
      child: ListView.builder(
        itemCount: records.length,
        itemBuilder: (c, i) {
          final r = records[i];

          final imageUrl = "${Config.apiUrl}${r['image_url']}";
          final plantName = r['plant_name'] ?? "Unknown";
          final confidence =
          ((r['confidence'] ?? 0) * 100).toStringAsFixed(1);

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: ListTile(
              leading: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported),
              ),

              title: Text(
                plantName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              subtitle: Text("Confidence: $confidence%"),

              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantResultPage(
                      plantName: plantName,
                      imageUrl: imageUrl,
                      confidence:
                      (r['confidence'] as num?)?.toDouble(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
