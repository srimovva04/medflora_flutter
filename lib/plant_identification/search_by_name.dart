import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart'; // Ensure this points to your config file
import 'plant_result.dart';   // Ensure this points to your result page


// --- 1. MODEL CLASS ---
// Defines the structure for a plant item in the list
class PlantSearchItem {
  final String scientificName;
  final String commonName;

  PlantSearchItem({
    required this.scientificName,
    required this.commonName
  });

  factory PlantSearchItem.fromJson(Map<String, dynamic> json) {
    return PlantSearchItem(
      // These keys match the updated Python API response
      scientificName: json['scientific_name'] ?? '',
      commonName: json['common_name'] ?? '',
    );
  }
}

// --- 2. SERVICE CLASS ---
// Handles fetching data from the backend
class PlantDataService {
  static const String baseUrl = Config.apiUrl;

  // Fetches list of objects (Scientific + Common Name)
  static Future<List<PlantSearchItem>> loadAllPlantNames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/plants/all_names'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success' && data['plants'] != null) {
          List<dynamic> list = data['plants'];
          // Convert JSON list to List<PlantSearchItem>
          return list.map((item) => PlantSearchItem.fromJson(item)).toList();
        } else {
          debugPrint("API returned success but no data found.");
          return [];
        }
      } else {
        debugPrint("Server error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching plant names from API: $e");
      return [];
    }
  }
}

// --- 3. UI PAGE ---
class SearchByNamePage extends StatefulWidget {
  const SearchByNamePage({super.key});

  @override
  State<SearchByNamePage> createState() => _SearchByNamePageState();
}

class _SearchByNamePageState extends State<SearchByNamePage> {
  // Store list of objects instead of simple Strings
  List<PlantSearchItem>? _allPlants;
  List<PlantSearchItem> _filteredPlants = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to text changes to filter in real-time
    _searchController.addListener(_filterPlants);
  }

  Future<void> _loadData() async {
    try {
      final plants = await PlantDataService.loadAllPlantNames();
      if (mounted) {
        setState(() {
          _allPlants = plants;
          _filteredPlants = plants; // Initially show all
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not connect to server.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPlants);
    _searchController.dispose();
    super.dispose();
  }

  // --- FILTER LOGIC (The Key Part) ---
  void _filterPlants() {
    final query = _searchController.text.toLowerCase().trim();

    // Safety check
    if (_allPlants == null) return;

    setState(() {
      if (query.isEmpty) {
        _filteredPlants = _allPlants!;
      } else {
        // Filter checks BOTH Scientific AND Common Names
        _filteredPlants = _allPlants!.where((plant) {
          final sName = plant.scientificName.toLowerCase();
          final cName = plant.commonName.toLowerCase();
          return sName.contains(query) || cName.contains(query);
        }).toList();
      }
    });
  }

  void _onPlantTap(BuildContext context, PlantSearchItem plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the Scientific Name to the detail page (as required by your API)
        builder: (context) => PlantResultPage(
          plantName: plant.scientificName,
          imageUrl: 'null',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Flora'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Scientific or Common Name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.all(14.0),
              ),
            ),
          ),

          // --- List Content ---
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF388E3C)))
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(_errorMessage!),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _loadData();
                    },
                    child: const Text("Retry"),
                  )
                ],
              ),
            )
                : _filteredPlants.isEmpty
                ? const Center(child: Text('No plants found.'))
                : Scrollbar(
              child: ListView.builder(
                itemCount: _filteredPlants.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemBuilder: (context, index) {
                  final plant = _filteredPlants[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 6.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 8.0),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(10)),
                          child: Icon(Icons.grass,
                              color: Theme.of(context).primaryColor,
                              size: 28),
                        ),

                        // Scientific Name (Title)
                        title: Text(plant.scientificName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF388E3C))),

                        // Common Name (Subtitle)
                        // Only show if it exists and isn't identical to scientific name
                        subtitle: (plant.commonName.isNotEmpty &&
                            plant.commonName.toLowerCase() != plant.scientificName.toLowerCase())
                            ? Text(
                          "Common: ${plant.commonName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        )
                            : null,

                        trailing: const Icon(Icons.chevron_right,
                            size: 20, color: Colors.grey),
                        onTap: () => _onPlantTap(context, plant),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// only search by scientific name
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:convert'; // For JSON decoding
// import 'package:http/http.dart' as http; // Import HTTP package
// import '../core/config.dart';
// import 'plant_result.dart';
//
// // --- SERVICE CLASS ---
// class PlantDataService {
//   static const String baseUrl = Config.apiUrl;
//   // Fetch only the names for the list view
//   static Future<List<String>> loadAllPlantNames() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/plants/all_names'));
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//
//         if (data['status'] == 'success' && data['names'] != null) {
//           // Convert the dynamic list to a List<String>
//           List<String> names = List<String>.from(data['names']);
//           return names;
//         } else {
//           debugPrint("API returned success but no names found.");
//           return [];
//         }
//       } else {
//         debugPrint("Server error: ${response.statusCode}");
//         return [];
//       }
//     } catch (e) {
//       debugPrint("Error fetching plant names from API: $e");
//       // Return empty list on error so the UI doesn't crash
//       return [];
//     }
//   }
//
//   // OPTIONAL: Helper to fetch full details (useful for your PlantResultPage)
//   static Future<Map<String, dynamic>?> fetchPlantDetails(String plantName) async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/search/plant/$plantName'));
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//     } catch (e) {
//       debugPrint("Error fetching details: $e");
//     }
//     return null;
//   }
// }
//
// // --- UI PAGE (Logic updated to use the new Service) ---
// class SearchByNamePage extends StatefulWidget {
//   const SearchByNamePage({super.key});
//
//   @override
//   State<SearchByNamePage> createState() => _SearchByNamePageState();
// }
//
// class _SearchByNamePageState extends State<SearchByNamePage> {
//   // We use nullable to distinguish between "loading" (null) and "empty" ([])
//   List<String>? _allPlantNames;
//   List<String> _filteredPlantNames = [];
//   final TextEditingController _searchController = TextEditingController();
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//     _searchController.addListener(_filterPlants);
//   }
//
//   // Separate method to handle async loading
//   Future<void> _loadData() async {
//     try {
//       final names = await PlantDataService.loadAllPlantNames();
//       if (mounted) {
//         setState(() {
//           _allPlantNames = names;
//           _filteredPlantNames = names;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = "Could not connect to server.";
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_filterPlants);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterPlants() {
//     final query = _searchController.text.toLowerCase();
//
//     // Safety check: if data isn't loaded yet, do nothing
//     if (_allPlantNames == null) return;
//
//     setState(() {
//       _filteredPlantNames = _allPlantNames!
//           .where((plant) => plant.toLowerCase().contains(query))
//           .toList();
//     });
//   }
//
//   void _onPlantTap(BuildContext context, String plantName) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         // Assuming PlantResultPage handles fetching the full details
//         // using the plantName passed here.
//         builder: (context) => PlantResultPage(
//           plantName: plantName,
//           imageUrl: 'null', // Placeholder as per your previous code
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Search Flora by Name'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search by Scientific Name...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: _searchController.text.isNotEmpty
//                     ? IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     _searchController.clear();
//                     _filterPlants();
//                     FocusScope.of(context).unfocus();
//                   },
//                 )
//                     : null,
//                 border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(15.0),
//                     borderSide: BorderSide.none),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 contentPadding: const EdgeInsets.all(14.0),
//               ),
//             ),
//           ),
//
//           // List Content
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
//                 : _errorMessage != null
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, size: 48, color: Colors.grey),
//                   const SizedBox(height: 10),
//                   Text(_errorMessage!),
//                   TextButton(
//                     onPressed: () {
//                       setState(() {
//                         _isLoading = true;
//                         _errorMessage = null;
//                       });
//                       _loadData();
//                     },
//                     child: const Text("Retry"),
//                   )
//                 ],
//               ),
//             )
//                 : _filteredPlantNames.isEmpty
//                 ? const Center(child: Text('No plants found.'))
//                 : Scrollbar(
//               child: ListView.builder(
//                 itemCount: _filteredPlantNames.length,
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 itemBuilder: (context, index) {
//                   final plant = _filteredPlantNames[index];
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16.0, vertical: 6.0),
//                     child: Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 20.0, vertical: 8.0),
//                         leading: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                               color: Theme.of(context)
//                                   .primaryColor
//                                   .withOpacity(0.1),
//                               borderRadius:
//                               BorderRadius.circular(10)),
//                           child: Icon(Icons.grass,
//                               color: Theme.of(context).primaryColor,
//                               size: 28),
//                         ),
//                         title: Text(plant,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 17,
//                                 color: Color(0xFF388E3C))),
//                         trailing: const Icon(Icons.chevron_right,
//                             size: 20, color: Colors.grey),
//                         onTap: () => _onPlantTap(context, plant),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//

/// OLD CODE
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle, ByteData;
// import 'dart:async';
// import 'package:excel/excel.dart' as excel;
// import 'plant_result.dart';
//
// class PlantDataService {
//   static const String SCIENTIFIC_NAME_KEY = 'Scientific Name';
//   static const String STATE_AVAILABILITY_KEY = 'Statewise Availability';
//   static const String _assetPath = 'assets/plant_data.xlsx';
//
//   static Future<List<Map<String, dynamic>>> _loadRawPlantRecords() async {
//     try {
//       ByteData data = await rootBundle.load(_assetPath);
//       var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//       var excelFile = excel.Excel.decodeBytes(bytes);
//       final sheetName = excelFile.tables.keys.first;
//       var sheet = excelFile.tables[sheetName];
//
//       if (sheet == null || sheet.maxRows < 2) return [];
//
//       final headerRow = sheet.row(0).map((cell) => cell?.value.toString().trim() ?? '').toList();
//       final List<Map<String, dynamic>> rawRecords = [];
//
//       for (int i = 1; i < sheet.maxRows; i++) {
//         final row = sheet.row(i);
//         if (row.isEmpty) continue;
//
//         final Map<String, dynamic> record = {};
//         for (int j = 0; j < headerRow.length; j++) {
//           if (j < row.length) {
//             record[headerRow[j]] = row[j]?.value.toString();
//           }
//         }
//         if (record.containsKey(SCIENTIFIC_NAME_KEY) && record.containsKey(STATE_AVAILABILITY_KEY)) {
//           rawRecords.add(record);
//         }
//       }
//       return rawRecords;
//     } catch (e) {
//       debugPrint("Error loading raw plant data file: $e");
//       return [];
//     }
//   }
//
//   static Future<List<String>> loadAllPlantNames() async {
//     final rawRecords = await _loadRawPlantRecords();
//     final Set<String> names = {};
//     for (final record in rawRecords) {
//       final String scientificName = record[SCIENTIFIC_NAME_KEY]?.toString().trim() ?? '';
//       if (scientificName.isNotEmpty) names.add(scientificName);
//     }
//     final List<String> sortedNames = names.toList();
//     sortedNames.sort();
//     return sortedNames;
//   }
// }
//
// class SearchByNamePage extends StatefulWidget {
//   const SearchByNamePage({super.key});
//
//   @override
//   State<SearchByNamePage> createState() => _SearchByNamePageState();
// }
//
// class _SearchByNamePageState extends State<SearchByNamePage> {
//   late Future<List<String>> _plantNamesFuture;
//   List<String> _allPlantNames = [];
//   List<String> _filteredPlantNames = [];
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _plantNamesFuture = PlantDataService.loadAllPlantNames();
//     _plantNamesFuture.then((data) {
//       setState(() {
//         _allPlantNames = data;
//         _filteredPlantNames = data;
//       });
//     });
//     _searchController.addListener(_filterPlants);
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_filterPlants);
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _filterPlants() {
//     final query = _searchController.text.toLowerCase();
//     setState(() {
//       _filteredPlantNames = _allPlantNames
//           .where((plant) => plant.toLowerCase().contains(query))
//           .toList();
//     });
//   }
//
//   void _onPlantTap(BuildContext context, String plantName) {
//
//
//     // --- CALL THE COMPONENT ---
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         // We reuse the PlantResultPage from plant_result.dart
//         // It handles loading the specific details internally.
//         builder: (context) => PlantResultPage(
//           plantName: plantName,
//           imageUrl: 'null',
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Search Flora by Name'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: FutureBuilder<List<String>>(
//         future: _plantNamesFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)));
//           }
//           if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('Failed to load data.'));
//           }
//
//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: 'Search by Scientific Name...',
//                     prefixIcon: const Icon(Icons.search),
//                     suffixIcon: _searchController.text.isNotEmpty
//                         ? IconButton(
//                       icon: const Icon(Icons.clear),
//                       onPressed: () {
//                         _searchController.clear();
//                         _filterPlants();
//                         FocusScope.of(context).unfocus();
//                       },
//                     )
//                         : null,
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
//                     filled: true,
//                     fillColor: Colors.grey.shade100,
//                     contentPadding: const EdgeInsets.all(14.0),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: Scrollbar(
//                   child: ListView.builder(
//                     itemCount: _filteredPlantNames.length,
//                     padding: const EdgeInsets.symmetric(vertical: 8.0),
//                     itemBuilder: (context, index) {
//                       final plant = _filteredPlantNames[index];
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
//                         child: Card(
//                           elevation: 2,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           child: ListTile(
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
//                             leading: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//                               child: Icon(Icons.grass, color: Theme.of(context).primaryColor, size: 28),
//                             ),
//                             title: Text(plant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF388E3C))),
//                             trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
//                             onTap: () => _onPlantTap(context, plant),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
//
