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
      final response = await http.get(Uri.parse('$baseUrl/states'));

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

/// no details
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// // =======================================================
// // 🔹 SERVICE CLASS – API HANDLER
// // =======================================================
// class PlantDataService {
//   // ⚠️ Change this if running on emulator / device
//   // Android Emulator → http://10.0.2.2:5001/api
//   // Physical device → your LAN IP
//   static const String baseUrl = 'http://127.0.0.1:5001/api';
//
//   // Fetch all states with plant count
//   static Future<List<Map<String, dynamic>>> loadAllStates() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/states'));
//
//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         if (decoded['status'] == 'success' && decoded['data'] != null) {
//           return List<Map<String, dynamic>>.from(decoded['data']);
//         }
//       }
//     } catch (e) {
//       debugPrint("Error loading states: $e");
//     }
//     return [];
//   }
//
//   // Fetch plants by state
//   static Future<List<Map<String, String>>> loadPlantsByState(String state) async {
//     try {
//       final response =
//       await http.get(Uri.parse('$baseUrl/search/state/$state'));
//
//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         if (decoded['status'] == 'success' && decoded['plants'] != null) {
//           final List list = decoded['plants'];
//
//           return list.map<Map<String, String>>((item) {
//             return {
//               'scientificName': item['botanical_name'] ?? 'Unknown',
//               'commonName': item['common_name'] ?? '',
//             };
//           }).toList();
//         }
//       }
//     } catch (e) {
//       debugPrint("Error loading plants: $e");
//     }
//     return [];
//   }
// }
//
// // =======================================================
// // 🔹 PAGE – GRID OF STATES (MODERN UI)
// // =======================================================
// class SearchByStatePage extends StatefulWidget {
//   const SearchByStatePage({super.key});
//
//   @override
//   State<SearchByStatePage> createState() => _SearchByStatePageState();
// }
//
// class _SearchByStatePageState extends State<SearchByStatePage> {
//   late Future<List<Map<String, dynamic>>> _statesFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _statesFuture = PlantDataService.loadAllStates();
//   }
//
//   void _openState(BuildContext context, String state) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PlantsInStatePage(stateName: state),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final primary = Theme.of(context).primaryColor;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Explore Flora by State"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _statesFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(color: Color(0xFF388E3C)),
//             );
//           }
//
//           final states = snapshot.data ?? [];
//
//           if (states.isEmpty) {
//             return const Center(child: Text("No states found"));
//           }
//
//           return Padding(
//             padding: const EdgeInsets.all(16),
//             child: GridView.builder(
//               itemCount: states.length,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 1.1,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//               ),
//               itemBuilder: (context, index) {
//                 final state = states[index];
//                 final String name = state['name'] ?? 'Unknown';
//                 final int count = state['count'] ?? 0;
//
//                 return InkWell(
//                   borderRadius: BorderRadius.circular(18),
//                   onTap: () => _openState(context, name),
//                   child: Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(18),
//                       border: Border.all(
//                         color: primary.withOpacity(0.15),
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.08),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: primary.withOpacity(0.1),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.location_on_outlined,
//                             color: primary,
//                             size: 26,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           name,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 16.5,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "$count varieties",
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // =======================================================
// // 🔹 PAGE – PLANTS IN SELECTED STATE
// // =======================================================
// class PlantsInStatePage extends StatefulWidget {
//   final String stateName;
//   const PlantsInStatePage({super.key, required this.stateName});
//
//   @override
//   State<PlantsInStatePage> createState() => _PlantsInStatePageState();
// }
//
// class _PlantsInStatePageState extends State<PlantsInStatePage> {
//   bool loading = true;
//   List<Map<String, String>> plants = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPlants();
//   }
//
//   Future<void> _loadPlants() async {
//     final data = await PlantDataService.loadPlantsByState(widget.stateName);
//     if (mounted) {
//       setState(() {
//         plants = data;
//         loading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Plants in ${widget.stateName}"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: loading
//           ? const Center(
//         child: CircularProgressIndicator(color: Color(0xFF388E3C)),
//       )
//           : ListView.builder(
//         itemCount: plants.length,
//         padding: const EdgeInsets.all(12),
//         itemBuilder: (context, index) {
//           final plant = plants[index];
//
//           return Card(
//             elevation: 4,
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ListTile(
//                 leading: const Icon(Icons.grass, color: Color(0xFF388E3C)),
//                 title: Text(
//                   plant['scientificName'] ?? '',
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 subtitle:
//                 Text("Common: ${plant['commonName'] ?? ''}"),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }




/// data from excel
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
//
//       var excelFile = excel.Excel.decodeBytes(bytes);
//       final sheetName = excelFile.tables.keys.first;
//       var sheet = excelFile.tables[sheetName];
//
//       if (sheet == null || sheet.maxRows < 2) {
//         debugPrint("Excel sheet not found or is empty.");
//         return [];
//       }
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
//
//         if (record.containsKey(SCIENTIFIC_NAME_KEY) && record.containsKey(STATE_AVAILABILITY_KEY)) {
//           rawRecords.add(record);
//         }
//       }
//
//       return rawRecords;
//     } catch (e) {
//       debugPrint("Error loading raw plant data file: $e");
//       return [];
//     }
//   }
//
//   static Map<String, List<String>> _groupRawDataByState(List<Map<String, dynamic>> rawData) {
//     final Map<String, List<String>> groupedData = {};
//
//     for (final record in rawData) {
//       final String scientificName = record[SCIENTIFIC_NAME_KEY]?.toString().trim() ?? '';
//       final String statesString = record[STATE_AVAILABILITY_KEY]?.toString().trim() ?? '';
//
//       if (scientificName.isEmpty || statesString.isEmpty) {
//         continue;
//       }
//
//       final List<String> states = statesString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
//
//       for (final state in states) {
//         final normalizedState = state.trim();
//
//         if (!groupedData.containsKey(normalizedState)) {
//           groupedData[normalizedState] = [];
//         }
//         groupedData[normalizedState]!.add(scientificName);
//       }
//     }
//
//     return groupedData;
//   }
//
//   static Future<Map<String, List<String>>> loadPlantsByState() async {
//     final rawRecords = await _loadRawPlantRecords();
//     return _groupRawDataByState(rawRecords);
//   }
// }
//
// class PlantsInStatePage extends StatelessWidget {
//   final String stateName;
//   const PlantsInStatePage({super.key, required this.stateName});
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Map<String, List<String>>>(
//       future: PlantDataService.loadPlantsByState(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(
//             appBar: AppBar(title: Text('Plants in $stateName'),
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               scrolledUnderElevation: 0,
//               surfaceTintColor: Colors.transparent,
//             ),
//             body: const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C))),
//           );
//         }
//
//         final Map<String, List<String>> plantsByState = snapshot.data ?? {};
//         final List<String> plants = plantsByState[stateName.trim()] ?? [];
//
//         if (snapshot.hasError || !snapshot.hasData || plantsByState.isEmpty || plants.isEmpty) {
//           bool isLoadError = snapshot.hasError || plantsByState.isEmpty;
//           return Scaffold(
//             appBar: AppBar(title: Text('Plants in $stateName'),
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               scrolledUnderElevation: 0,
//               surfaceTintColor: Colors.transparent,
//             ),
//             body: _buildNoPlantsFound(context, stateName, isLoadError: isLoadError),
//           );
//         }
//
//         return Scaffold(
//           appBar: AppBar(
//             title: Text('Plants in ${stateName.toUpperCase()}'),
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             scrolledUnderElevation: 0,
//             surfaceTintColor: Colors.transparent,
//           ),
//           body: _buildPlantsList(context, plants),
//         );
//       },
//     );
//   }
//
//   Widget _buildPlantsList(BuildContext context, List<String> plants) {
//     return Scrollbar(
//       child: ListView.builder(
//         itemCount: plants.length,
//         padding: const EdgeInsets.symmetric(vertical: 8.0),
//         itemBuilder: (context, index) {
//           final plant = plants[index];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
//             child: Card(
//               elevation: 4,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//                 leading: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     Icons.grass,
//                     color: Theme.of(context).primaryColor,
//                     size: 28,
//                   ),
//                 ),
//                 title: Text(
//                   plant,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 17,
//                     color: Color(0xFF388E3C),
//                   ),
//                 ),
//                 subtitle: Text(
//                   'Scientific Name',
//                   style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
//                 ),
//                 trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
//                 onTap: () {
//                   // DEMO LOGIC:
//                   // 1. To see the "Green Header" layout, pass '' or 'null'
//                   // 2. To see the "Circle Avatar" layout, pass a valid URL
//                   // const String placeholderImageUrl = 'https://picsum.photos/400?random=1';
//
//                   // --- USING THE COMPONENT ---
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => PlantResultPage(
//                         plantName: plant,
//                         imageUrl: 'null',
//                       ),
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
//
//   Widget _buildNoPlantsFound(BuildContext context, String stateName, {bool isLoadError = false}) {
//     String title = isLoadError ? 'Error Loading Data' : 'No Plants Documented';
//     String message = isLoadError
//         ? 'Failed to load the plant data file.'
//         : 'The database is currently missing native plants for $stateName.';
//     IconData icon = isLoadError ? Icons.cloud_off_outlined : Icons.nature_people;
//
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(40.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 100,
//               color: isLoadError ? Colors.red.shade400 : Theme.of(context).primaryColor.withOpacity(0.4),
//             ),
//             const SizedBox(height: 30),
//             Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.grey.shade800)),
//             const SizedBox(height: 15),
//             Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class SearchByStatePage extends StatefulWidget {
//   const SearchByStatePage({super.key});
//
//   @override
//   State<SearchByStatePage> createState() => _SearchByStatePageState();
// }
//
// class _SearchByStatePageState extends State<SearchByStatePage> {
//   late Future<Map<String, List<String>>> _plantDataFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _plantDataFuture = PlantDataService.loadPlantsByState();
//   }
//
//   void _onStateTap(BuildContext context, String stateName) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PlantsInStatePage(stateName: stateName.trim()),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Explore Flora by State'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       body: FutureBuilder<Map<String, List<String>>>(
//         future: _plantDataFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)));
//           }
//           if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("Data Load Error"));
//           }
//
//           final Map<String, List<String>> plantsByState = snapshot.data!;
//           final List<String> stateNames = plantsByState.keys.toList()..sort();
//
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: GridView.builder(
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 1.1,
//                 crossAxisSpacing: 16.0,
//                 mainAxisSpacing: 16.0,
//               ),
//               itemCount: stateNames.length,
//               itemBuilder: (context, index) {
//                 final stateName = stateNames[index];
//                 final plantCount = plantsByState[stateName]?.length ?? 0;
//
//                 return GestureDetector(
//                   onTap: () => _onStateTap(context, stateName),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Theme.of(context).primaryColor.withOpacity(0.2),
//                           spreadRadius: 1,
//                           blurRadius: 5,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                       gradient: LinearGradient(
//                         colors: [
//                           Theme.of(context).primaryColor.withOpacity(0.8),
//                           Theme.of(context).primaryColor,
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                     child: Card(
//                       color: Colors.transparent,
//                       elevation: 0,
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Icon(Icons.location_on_outlined, color: Colors.white, size: 28),
//                             const SizedBox(height: 8),
//                             Text(
//                               stateName,
//                               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               '$plantCount varieties',
//                               style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w300),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
