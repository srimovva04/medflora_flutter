import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'plant_result.dart'; // Ensure this points to your PlantResultPage file

// --- Service to Fetch Data from API ---
class TherapeuticDataService {
  // REPLACE with your API Base URL
  // Android Emulator: 'http://10.0.2.2:5001/api'
  // iOS Simulator: 'http://127.0.0.1:5001/api'
  // static const String baseUrl = 'http://127.0.0.1:5001/api';

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


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle, ByteData;
// import 'package:excel/excel.dart';
// import 'plant_result.dart';
//
// class TherapeuticDataService {
//   static const String _assetPath = 'assets/plant_data.xlsx';
//   static const String SCIENTIFIC_NAME_KEY = 'Scientific Name';
//   static const String THERAPEUTIC_USES_KEY = 'Therapeutic Uses';
//
//
//   static Future<Map<String, List<Map<String, String>>>> loadPlantsByUse() async {
//     try {
//       // 1. Load the Excel file
//       ByteData data = await rootBundle.load(_assetPath);
//       var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//       var excelFile = Excel.decodeBytes(bytes);
//
//       // 2. Get the first sheet
//       final sheetName = excelFile.tables.keys.first;
//       var sheet = excelFile.tables[sheetName];
//
//       if (sheet == null || sheet.maxRows < 2) {
//         return {};
//       }
//
//       // 3. Identify Header Columns
//       final headerRow = sheet.row(0).map((cell) => cell?.value.toString().trim() ?? '').toList();
//       final int nameIndex = headerRow.indexOf(SCIENTIFIC_NAME_KEY);
//       final int useIndex = headerRow.indexOf(THERAPEUTIC_USES_KEY);
//
//       if (nameIndex == -1 || useIndex == -1) {
//         debugPrint("Required columns not found in Excel.");
//         return {};
//       }
//
//       final Map<String, List<Map<String, String>>> groupedData = {};
//
//       // 4. Iterate through rows and parse
//       for (int i = 1; i < sheet.maxRows; i++) {
//         final row = sheet.row(i);
//         if (row.isEmpty) continue;
//
//         // Safely get cell values
//         final String scientificName = _getCellValue(row, nameIndex);
//         final String rawUses = _getCellValue(row, useIndex);
//
//         if (scientificName.isEmpty || rawUses.isEmpty || rawUses.toLowerCase() == 'nan') {
//           continue;
//         }
//
//         // 5. PARSING LOGIC
//         // Format example: "fruit: Hair loss | leaf: Fever, Cough"
//
//         // A. Split by '|' to separate different plant parts
//         final List<String> partSegments = rawUses.split('|');
//
//         for (final segment in partSegments) {
//           // B. Split by ':' to separate Part from Ailments
//           final List<String> parts = segment.split(':');
//
//           String plantPart = "Unspecified Part";
//           String ailmentsString = "";
//
//           if (parts.length >= 2) {
//             plantPart = parts[0].trim();
//             if (plantPart.isEmpty) plantPart = "Unspecified Part";
//             ailmentsString = parts[1];
//           } else if (parts.length == 1) {
//             ailmentsString = parts[0]; // Fallback if no colon exists
//           }
//
//           // C. Split ailments by comma ','
//           final List<String> ailments = ailmentsString.split(',')
//               .map((u) => u.trim())
//               .where((u) => u.isNotEmpty)
//               .toList();
//
//           for (final ailment in ailments) {
//             // Normalize text (Capitalize first letter)
//             final String normalizedUse = ailment.length > 1
//                 ? ailment[0].toUpperCase() + ailment.substring(1).toLowerCase()
//                 : ailment.toUpperCase();
//
//             if (!groupedData.containsKey(normalizedUse)) {
//               groupedData[normalizedUse] = [];
//             }
//
//             // Avoid duplicates for the same plant+part under the same use
//             final bool alreadyExists = groupedData[normalizedUse]!.any((element) =>
//             element['name'] == scientificName && element['part'] == plantPart);
//
//             if (!alreadyExists) {
//               groupedData[normalizedUse]!.add({
//                 'name': scientificName,
//                 'part': plantPart,
//               });
//             }
//           }
//         }
//       }
//
//       // Sort keys alphabetically
//       return Map.fromEntries(groupedData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
//
//     } catch (e) {
//       debugPrint("Error loading plant uses: $e");
//       return {};
//     }
//   }
//
//   static String _getCellValue(List<Data?> row, int index) {
//     if (index >= row.length || row[index] == null) return '';
//     return row[index]!.value.toString().trim();
//   }
// }
//
// /// -----------------------------------------------------------------------
// /// Main Page: Search By Use
// /// -----------------------------------------------------------------------
// class SearchByUsePage extends StatefulWidget {
//   const SearchByUsePage({super.key});
//
//   @override
//   State<SearchByUsePage> createState() => _SearchByUsePageState();
// }
//
// class _SearchByUsePageState extends State<SearchByUsePage> {
//   Map<String, List<Map<String, String>>> _allUses = {};
//   List<String> _filteredUseKeys = [];
//   bool _isLoading = true;
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadData() async {
//     final data = await TherapeuticDataService.loadPlantsByUse();
//     if (mounted) {
//       setState(() {
//         _allUses = data;
//         _filteredUseKeys = data.keys.toList();
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _onSearchChanged() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredUseKeys = _allUses.keys
//           .where((key) => key.toLowerCase().contains(query))
//           .toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Search by Use'),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//       ),
//       body: Column(
//         children: [
//           // --- Search Bar ---
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search ailments (e.g. Hair loss, Fever)...',
//                 prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide(color: Theme.of(context).primaryColor),
//                 ),
//               ),
//             ),
//           ),
//
//           // --- Content Area ---
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
//                 : _filteredUseKeys.isEmpty
//                 ? _buildEmptyState()
//                 : GridView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2, // Two columns
//                 childAspectRatio: 2.2, // Rectangular aspect ratio
//                 crossAxisSpacing: 12,
//                 mainAxisSpacing: 12,
//               ),
//               itemCount: _filteredUseKeys.length,
//               itemBuilder: (context, index) {
//                 final useName = _filteredUseKeys[index];
//                 final count = _allUses[useName]?.length ?? 0;
//
//                 return InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PlantsForUsePage(
//                           useName: useName,
//                           plants: _allUses[useName] ?? [],
//                         ),
//                       ),
//                     );
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       // border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.08),
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Row(
//                       children: [
//                         // Icon
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Theme.of(context).primaryColor.withOpacity(0.1),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                               Icons.healing,
//                               size: 18,
//                               color: Theme.of(context).primaryColor
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         // Text
//                         Expanded(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 useName,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 13,
//                                   color: Color(0xFF333333),
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 "$count plants",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
//           const SizedBox(height: 10),
//           Text(
//             "No matching ailments found",
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// -----------------------------------------------------------------------
// /// Detail Page: List of Plants for a Specific Use
// /// -----------------------------------------------------------------------
// class PlantsForUsePage extends StatelessWidget {
//   final String useName;
//   final List<Map<String, String>> plants;
//
//   const PlantsForUsePage({
//     super.key,
//     required this.useName,
//     required this.plants,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(useName),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//       ),
//       body: ListView.builder(
//         itemCount: plants.length,
//         padding: const EdgeInsets.all(16),
//         itemBuilder: (context, index) {
//           final plant = plants[index];
//           final plantName = plant['name']!;
//           final plantPart = plant['part']!;
//
//           return Card(
//             elevation: 2,
//             margin: const EdgeInsets.only(bottom: 12),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             child: InkWell(
//               borderRadius: BorderRadius.circular(15),
//               onTap: () {
//                 // Navigate to the main Result Page to show full details
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => PlantResultPage(
//                       plantName: plantName,
//                       imageUrl: "null", // We don't have an image URL here, pass a placeholder or null string
//                     ),
//                   ),
//                 );
//               },
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Row(
//                   children: [
//                     // Plant Avatar
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(Icons.grass, color: Colors.green.shade700),
//                     ),
//                     const SizedBox(width: 16),
//
//                     // Text Content
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             plantName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Color(0xFF333333),
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   "Effective Part: $plantPart",
//                                   style: TextStyle(
//                                       color: Colors.grey.shade700,
//                                       fontSize: 13,
//                                       fontStyle: FontStyle.italic
//                                   ),
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Arrow
//                     Icon(Icons.chevron_right, color: Colors.grey.shade400),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }