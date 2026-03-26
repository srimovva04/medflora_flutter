import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'plant_result.dart'; // Ensure this points to your PlantResultPage file

// --- Service to Fetch Data from API ---
class TherapeuticDataService {

  static const String baseUrl = Config.apiUrl;
  // 1. Fetch All Therapeutic Uses (for the Grid)
  static Future<List<Map<String, dynamic>>> loadTherapeuticUses() async {
    try {
      final uri = Uri.parse('$baseUrl/therapeutic/uses');
      debugPrint("Fetching uses from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Expected API format: {"data": [{"name": "Fever", "count": 5}, ...]}
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching therapeutic uses: $e");
      return [];
    }
  }

  // 2. Fetch Plants for a Specific Use (when user taps a card)
  static Future<List<Map<String, String>>> loadPlantsForUse(String useName) async {
    try {
      final uri = Uri.parse('$baseUrl/search/therapeutic/${Uri.encodeComponent(useName)}');
      debugPrint("Fetching plants for use: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // The API returns a list of plants.
          // We need to parse this into a simple list for the UI.
          List<dynamic> plantsRaw = data['plants'];

          List<Map<String, String>> parsedPlants = [];

          for (var plant in plantsRaw) {
            String name = plant['botanical_name'] ?? 'Unknown';
            // The API returns 'therapeutic_details' which is a list of parts:
            // [{"part": "Leaf", "use": "Fever"}, ...]
            // We want to join these parts into a string like "Leaf, Root"
            List<dynamic> details = plant['therapeutic_details'] ?? [];
            String parts = details.map((d) => d['part'].toString().toUpperCase()).toSet().join(", ");

            if (parts.isEmpty) parts = "General";

            parsedPlants.add({
              'name': name,
              'part': parts,
            });
          }
          return parsedPlants;
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching plants for use: $e");
      return [];
    }
  }
}

/// -----------------------------------------------------------------------
/// Main Page: Search By Use (Grid View)
/// -----------------------------------------------------------------------
class SearchByUsePage extends StatefulWidget {
  const SearchByUsePage({super.key});

  @override
  State<SearchByUsePage> createState() => _SearchByUsePageState();
}

class _SearchByUsePageState extends State<SearchByUsePage> {
  // Stores raw data: [{"name": "Fever", "count": 10}, ...]
  List<Map<String, dynamic>> _allUses = [];
  List<Map<String, dynamic>> _filteredUses = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await TherapeuticDataService.loadTherapeuticUses();
    if (mounted) {
      setState(() {
        _allUses = data;
        _filteredUses = data;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUses = _allUses
          .where((item) => item['name'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Use'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ailments (e.g. Hair loss, Fever)...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),

          // --- Content Area ---
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : _filteredUses.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns
                childAspectRatio: 2.2, // Rectangular aspect ratio
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredUses.length,
              itemBuilder: (context, index) {
                final useItem = _filteredUses[index];
                final useName = useItem['name'];
                final count = useItem['count'];

                return InkWell(
                  onTap: () {
                    // Navigate to details, fetching plants for this use
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantsForUsePage(
                          useName: useName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              Icons.healing,
                              size: 18,
                              color: Theme.of(context).primaryColor
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Text
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                useName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "$count plants",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            "No matching ailments found",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// Detail Page: List of Plants for a Specific Use (Fetched from API)
/// -----------------------------------------------------------------------
class PlantsForUsePage extends StatefulWidget {
  final String useName;

  const PlantsForUsePage({
    super.key,
    required this.useName,
  });

  @override
  State<PlantsForUsePage> createState() => _PlantsForUsePageState();
}

class _PlantsForUsePageState extends State<PlantsForUsePage> {
  List<Map<String, String>> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    final plants = await TherapeuticDataService.loadPlantsForUse(widget.useName);
    if (mounted) {
      setState(() {
        _plants = plants;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.useName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : _plants.isEmpty
          ? const Center(child: Text("No plants found for this use."))
          : ListView.builder(
        itemCount: _plants.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final plant = _plants[index];
          final plantName = plant['name']!;
          final plantPart = plant['part']!;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                // Navigate to the main Result Page (which now uses API too)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantResultPage(
                      plantName: plantName,
                      imageUrl: "null",
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Plant Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.grass, color: Colors.green.shade700),
                    ),
                    const SizedBox(width: 16),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Effective Part: $plantPart",
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


