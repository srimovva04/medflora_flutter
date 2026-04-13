import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'plant_result.dart'; // <--- IMPORT THIS FILE

class PlantDataService {
  static const String baseUrl = Config.apiUrl;
  // Fetch all states with plant count
  static Future<List<Map<String, dynamic>>> loadAllStates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/states'));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
    } catch (e) {
      debugPrint("Error loading states: $e");
    }
    return [];
  }

  // Fetch plants by state
  static Future<List<Map<String, String>>> loadPlantsByState(String state) async {
    try {
      final response =
      await http.get(Uri.parse('$baseUrl/search/state/$state'));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['plants'] != null) {
          final List list = decoded['plants'];

          return list.map<Map<String, String>>((item) {
            return {
              'scientificName': item['botanical_name'] ?? 'Unknown',
              'commonName': item['common_name'] ?? '',
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error loading plants: $e");
    }
    return [];
  }
}

// =======================================================
// 🔹 PAGE – GRID OF STATES (MODERN UI)
// =======================================================
class SearchByStatePage extends StatefulWidget {
  const SearchByStatePage({super.key});

  @override
  State<SearchByStatePage> createState() => _SearchByStatePageState();
}

class _SearchByStatePageState extends State<SearchByStatePage> {
  late Future<List<Map<String, dynamic>>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = PlantDataService.loadAllStates();
  }

  void _openState(BuildContext context, String state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantsInStatePage(stateName: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Flora by State"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF388E3C)),
            );
          }

          final states = snapshot.data ?? [];

          if (states.isEmpty) {
            return const Center(child: Text("No states found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: states.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final state = states[index];
                final String name = state['name'] ?? 'Unknown';
                final int count = state['count'] ?? 0;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openState(context, name),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primary.withOpacity(0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$count varieties",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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

// =======================================================
// 🔹 PAGE – PLANTS IN SELECTED STATE
// =======================================================
class PlantsInStatePage extends StatefulWidget {
  final String stateName;
  const PlantsInStatePage({super.key, required this.stateName});

  @override
  State<PlantsInStatePage> createState() => _PlantsInStatePageState();
}

class _PlantsInStatePageState extends State<PlantsInStatePage> {
  bool loading = true;
  List<Map<String, String>> plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final data = await PlantDataService.loadPlantsByState(widget.stateName);
    if (mounted) {
      setState(() {
        plants = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plants in ${widget.stateName}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF388E3C)),
      )
          : ListView.builder(
        itemCount: plants.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final plant = plants[index];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading:
                const Icon(Icons.grass, color: Color(0xFF388E3C)),
                title: Text(
                  plant['scientificName'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("Common: ${plant['commonName'] ?? ''}"),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Visual cue
                // 👇 ADDED ONTAP HANDLER HERE
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantResultPage(
                        plantName: plant['scientificName']!, imageUrl: '',
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
