import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'plant_details.dart';

class PlantResultPage extends StatefulWidget {
  final String plantName;
  final String imageUrl;

  const PlantResultPage({
    super.key,
    required this.plantName,
    required this.imageUrl,
  });

  @override
  State<PlantResultPage> createState() => _PlantResultPageState();
}

class _PlantResultPageState extends State<PlantResultPage> {
  late Future<Map<String, dynamic>?> _plantDataFuture;
  final String baseUrl = Config.apiUrl;
  // final String baseUrl = "http://127.0.0.1:5001/api";
  @override
  void initState() {
    super.initState();
    // We search based on the name passed to the widget
    _plantDataFuture = _fetchPlantDetailsFromApi(widget.plantName);
  }

  Future<Map<String, dynamic>?> _fetchPlantDetailsFromApi(String name) async {
    try {
      // 1. Construct the API URL
      // Ensure the name is URL encoded to handle spaces
      final uri = Uri.parse("$baseUrl/search/plant/${Uri.encodeComponent(name)}");

      debugPrint("Fetching plant details from: $uri");

      // 2. Make the GET request
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final apiData = jsonResponse['data'];

          // 3. MAP MONGO FIELDS TO UI FIELDS
          // The UI (PlantResultView) expects keys like "Common Name", "Kingdom", etc.
          // But Mongo returns "name_common", "kingdom", etc.
          // We create a mapped object here to keep the UI code compatible.
          return {
            "Common Name": apiData['name_common'] ?? name,
            "Scientific Name": apiData['name_scientific'] ?? "Unknown",
            "Kingdom": apiData['kingdom'] ?? "Plantae", // Default if missing
            "Family": apiData['family'] ?? "Unknown",
            "Description": apiData['description'] ?? "No description available.",
            // Pass the whole raw object if PlantDetailsPage needs specific complex fields
            ...apiData
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint("Plant not found in database.");
        return null;
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching plant data: $e");
      // Return null so the UI shows the "Not Found" state rather than crashing
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImage = widget.imageUrl.isNotEmpty && widget.imageUrl != 'null';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hasImage ? Colors.black87 : Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: hasImage
            ? const Text("Identification Result", style: TextStyle(color: Colors.black87))
            : const Text("Identification Result", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _plantDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Container(
              color: Colors.white,
              child: Center(child: Text("Connection Error. Please try again.\n${snapshot.error}")),
            );
          }

          // Prepare data (Found or Not Found)
          // If api returns null, we show the "Not Found" UI
          final plantData = snapshot.data ?? {
            "Common Name": widget.plantName,
            "Scientific Name": "Not found in database",
            "Kingdom": "Unknown"
          };

          final bool isNotFound = snapshot.data == null;

          return PlantResultView(
            plantData: plantData,
            imageUrl: widget.imageUrl,
            isNotFound: isNotFound,
          );
        },
      ),
    );
  }
}

class PlantResultView extends StatelessWidget {
  final Map<String, dynamic> plantData;
  final String imageUrl;
  final bool isNotFound;

  const PlantResultView({
    super.key,
    required this.plantData,
    required this.imageUrl,
    this.isNotFound = false,
  });

  @override
  Widget build(BuildContext context) {
    bool hasImage = imageUrl.isNotEmpty && imageUrl != 'null';

    if (hasImage) {
      return _buildLayoutWithImage(context);
    } else {
      return _buildLayoutNoImage(context);
    }
  }

  // ===========================================================================
  // LAYOUT 1: IMAGE EXISTS
  // ===========================================================================
  Widget _buildLayoutWithImage(BuildContext context) {
    // Note: Keys match the mapping done in _fetchPlantDetailsFromApi
    final String commonName = plantData["Common Name"]?.toString() ?? "Unknown Plant";
    final String scientificName = plantData["Scientific Name"]?.toString() ?? "";
    final String kingdom = plantData["Kingdom"]?.toString() ?? "N/A";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.teal.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Circle Avatar
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Prediction', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  Text(
                    commonName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // 2. Details
              Column(
                children: [
                  _buildDetailCard(Icons.grass, "Common Name", commonName),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.science_outlined, "Scientific Name", scientificName),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.account_tree_outlined, "Kingdom", kingdom),
                ],
              ),

              // 3. Button
              if (!isNotFound)
                ElevatedButton(
                  onPressed: () => _navigateToDetails(context),
                  child: const Text('View Details'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutNoImage(BuildContext context) {
    final String commonName = plantData["Common Name"]?.toString() ?? "Unknown Plant";
    final String scientificName = plantData["Scientific Name"]?.toString() ?? "";
    final String kingdom = plantData["Kingdom"]?.toString() ?? "N/A";

    return Column(
      children: [
        // 1. Solid Green Header
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            color: const Color(0xFF388E3C),
            child: Stack(
              children: [
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        commonName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Scientific Name: $scientificName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Body Details
        Expanded(
          flex: 6,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (isNotFound)
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(child: Text("Details not found in our database.")),
                        ],
                      ),
                    ),
                  )
                else ...[
                  _buildDetailRowSimple(Icons.grass, "Common Name", commonName),
                  const Divider(),
                  _buildDetailRowSimple(Icons.science, "Scientific Name", scientificName),
                  const Divider(),
                  _buildDetailRowSimple(Icons.account_tree, "Kingdom", kingdom),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388E3C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () => _navigateToDetails(context),
                    child: const Text("View Full Details"),
                  ),
                  const SizedBox(height: 20),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // Ensure PlantDetailsPage is updated to accept the API map structure if needed,
        // or relies on the keys we mapped ("Common Name", etc)
        builder: (context) => PlantDetailsPage(plantData: plantData),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowSimple(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF388E3C)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show ByteData, rootBundle;
// import 'package:excel/excel.dart' as excel;
//
// import 'plant_details.dart';
//
// class PlantResultPage extends StatefulWidget {
//   final String plantName;
//   final String imageUrl;
//
//   const PlantResultPage({
//     super.key,
//     required this.plantName,
//     required this.imageUrl,
//   });
//
//   @override
//   State<PlantResultPage> createState() => _PlantResultPageState();
// }
//
// class _PlantResultPageState extends State<PlantResultPage> {
//   late Future<Map<String, dynamic>?> _plantDataFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _plantDataFuture = _loadAndSearchExcel(widget.plantName);
//   }
//
//   Future<Map<String, dynamic>?> _loadAndSearchExcel(String name) async {
//     try {
//       ByteData data = await rootBundle.load("assets/plant_data.xlsx");
//       var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//       var excelFile = excel.Excel.decodeBytes(bytes);
//       var sheet = excelFile.tables[excelFile.tables.keys.first];
//
//       if (sheet == null) throw Exception("Excel sheet not found.");
//
//       final headers = sheet.rows.first.map((cell) => cell?.value.toString().trim() ?? '').toList();
//       int scientificNameIndex = headers.indexOf('Scientific Name');
//       if (scientificNameIndex == -1) throw Exception("'Scientific Name' column not found.");
//
//       for (var i = 1; i < sheet.maxRows; i++) {
//         var row = sheet.rows[i];
//         if (row.length <= scientificNameIndex) continue;
//         String scientificName = row[scientificNameIndex]?.value.toString() ?? '';
//
//         if (scientificName.toLowerCase().startsWith(name.toLowerCase())) {
//           Map<String, dynamic> rowData = {};
//           for (var j = 0; j < headers.length; j++) {
//             if (headers[j].isNotEmpty) {
//               rowData[headers[j]] = j < row.length ? row[j]?.value : null;
//             }
//           }
//           return rowData;
//         }
//       }
//       return null;
//     } catch (e) {
//       debugPrint("Error processing Excel file: $e");
//       throw Exception("Failed to load plant data from Excel.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     bool hasImage = widget.imageUrl.isNotEmpty && widget.imageUrl != 'null';
//
//     return Scaffold(
//       // extendBodyBehindAppBar is crucial for the transparent/gradient look
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: hasImage ? Colors.black87 : Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: hasImage
//             ? const Text("Identification Result", style: TextStyle(color: Colors.black87))
//             : const Text("Identification Result", style: TextStyle(color: Colors.white)),
//         centerTitle: true,
//       ),
//       body: FutureBuilder<Map<String, dynamic>?>(
//         future: _plantDataFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//
//           // Prepare data (Found or Not Found)
//           final plantData = snapshot.data ?? {
//             "Common Name": widget.plantName,
//             "Scientific Name": "Not found in database",
//             "Kingdom": "Unknown"
//           };
//
//           final bool isNotFound = snapshot.data == null;
//
//           return PlantResultView(
//             plantData: plantData,
//             imageUrl: widget.imageUrl,
//             isNotFound: isNotFound,
//           );
//         },
//       ),
//     );
//   }
// }
//
// class PlantResultView extends StatelessWidget {
//   final Map<String, dynamic> plantData;
//   final String imageUrl;
//   final bool isNotFound;
//
//   const PlantResultView({
//     super.key,
//     required this.plantData,
//     required this.imageUrl,
//     this.isNotFound = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     bool hasImage = imageUrl.isNotEmpty && imageUrl != 'null';
//
//     // SWITCH LOGIC: Check if image exists and return the specific layout
//     if (hasImage) {
//       return _buildLayoutWithImage(context);
//     } else {
//       return _buildLayoutNoImage(context);
//     }
//   }
//
//   // ===========================================================================
//   // LAYOUT 1: IMAGE EXISTS (Circle Avatar, Centered Text, Gradient BG)
//   // ===========================================================================
//   Widget _buildLayoutWithImage(BuildContext context) {
//     final String commonName = plantData["Common Name"]?.toString() ?? "Unknown Plant";
//     final String scientificName = plantData["Scientific Name"]?.toString() ?? "";
//     final String kingdom = plantData["Kingdom"]?.toString() ?? "N/A";
//
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green.shade100, Colors.teal.shade50, Colors.white],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // 1. Circle Avatar
//               Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 4),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.15),
//                           blurRadius: 10,
//                           offset: const Offset(0, 5),
//                         ),
//                       ],
//                     ),
//                     child: CircleAvatar(
//                       radius: 80,
//                       backgroundColor: Colors.grey.shade200,
//                       backgroundImage: NetworkImage(imageUrl),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('Prediction', style: TextStyle(fontSize: 16, color: Colors.black54)),
//                   Text(
//                     commonName,
//                     style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//
//               // 2. Details
//               Column(
//                 children: [
//                   _buildDetailCard(Icons.grass, "Common Name", commonName),
//                   const SizedBox(height: 12),
//                   _buildDetailCard(Icons.science_outlined, "Scientific Name", scientificName),
//                   const SizedBox(height: 12),
//                   _buildDetailCard(Icons.account_tree_outlined, "Kingdom", kingdom),
//                 ],
//               ),
//
//               // 3. Button
//               if (!isNotFound)
//                 ElevatedButton(
//                   onPressed: () => _navigateToDetails(context),
//                   child: const Text('View Details'),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLayoutNoImage(BuildContext context) {
//     final String commonName = plantData["Common Name"]?.toString() ?? "Unknown Plant";
//     final String scientificName = plantData["Scientific Name"]?.toString() ?? "";
//     final String kingdom = plantData["Kingdom"]?.toString() ?? "N/A";
//
//     return Column(
//       children: [
//         // 1. Solid Green Header (Matches your screenshot)
//         Expanded(
//           flex: 4,
//           child: Container(
//             width: double.infinity,
//             color: const Color(0xFF388E3C), // Material Green 700
//             child: Stack(
//               children: [
//                 Positioned(
//                   left: 20,
//                   right: 20,
//                   bottom: 20,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         commonName,
//                         style: const TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         "Scientific Name: $scientificName",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontStyle: FontStyle.italic,
//                           color: Colors.white70,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//         // 2. Body Details (White background)
//         Expanded(
//           flex: 6,
//           child: Container(
//             color: Colors.white,
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 if (isNotFound)
//                   Card(
//                     color: Colors.orange.shade50,
//                     child: const Padding(
//                       padding: EdgeInsets.all(16.0),
//                       child: Row(
//                         children: [
//                           Icon(Icons.warning_amber, color: Colors.orange),
//                           SizedBox(width: 10),
//                           Expanded(child: Text("Details not found in our database.")),
//                         ],
//                       ),
//                     ),
//                   )
//                 else ...[
//                   _buildDetailRowSimple(Icons.grass, "Common Name", commonName),
//                   const Divider(),
//                   _buildDetailRowSimple(Icons.science, "Scientific Name", scientificName),
//                   const Divider(),
//                   _buildDetailRowSimple(Icons.account_tree, "Kingdom", kingdom),
//                   const Spacer(),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF388E3C),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 50),
//                     ),
//                     onPressed: () => _navigateToDetails(context),
//                     child: const Text("View Full Details"),
//                   ),
//                   const SizedBox(height: 20),
//                 ]
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // --- Helper Methods ---
//
//   void _navigateToDetails(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => PlantDetailsPage(plantData: plantData),
//       ),
//     );
//   }
//
//   // Card Style (Used in Circle Layout)
//   Widget _buildDetailCard(IconData icon, String label, String value) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: Colors.white.withOpacity(0.85),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.green.shade700, size: 28),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
//                   Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Simple Row Style (Used in Green Header Layout)
//   Widget _buildDetailRowSimple(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0),
//       child: Row(
//         children: [
//           Icon(icon, color: const Color(0xFF388E3C)),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
//                 Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
//


/// old code
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show ByteData, rootBundle;
// import 'package:excel/excel.dart' as excel; // Prefixed to avoid conflicts
// import 'plant_details.dart'; // Make sure this page exists for the "View More" button
//
// class PlantResultPage extends StatefulWidget {
//   final String plantName;
//   final String imageUrl;
//
//   const PlantResultPage({
//     super.key,
//     required this.plantName,
//     required this.imageUrl,
//   });
//
//   @override
//   State<PlantResultPage> createState() => _PlantResultPageState();
// }
//
// class _PlantResultPageState extends State<PlantResultPage> {
//   late Future<Map<String, dynamic>?> _plantDataFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // Start fetching data from the local Excel file
//     _plantDataFuture = _loadAndSearchExcel(widget.plantName);
//   }
//
//   /// Loads and searches the local Excel file for a plant.
//   Future<Map<String, dynamic>?> _loadAndSearchExcel(String name) async {
//     try {
//       // Load the Excel file from assets
//       ByteData data = await rootBundle.load("plant_data.xlsx"); // Ensure path is correct in pubspec.yaml
//       var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
//       var excelFile = excel.Excel.decodeBytes(bytes);
//       var sheet = excelFile.tables[excelFile.tables.keys.first];
//
//       if (sheet == null) {
//         throw Exception("Excel sheet not found.");
//       }
//
//       // Extract headers to use as map keys
//       final headers = sheet.rows.first
//           .map((cell) => cell?.value.toString().trim() ?? '')
//           .toList();
//
//       int scientificNameIndex = headers.indexOf('Scientific Name');
//       if (scientificNameIndex == -1) {
//         throw Exception("'Scientific Name' column not found in Excel file.");
//       }
//
//       // Iterate through rows to find a match
//       for (var i = 1; i < sheet.maxRows; i++) {
//         var row = sheet.rows[i];
//         if (row.length <= scientificNameIndex) continue;
//
//         String scientificName = row[scientificNameIndex]?.value.toString() ?? '';
//
//         // Perform the case-insensitive "starts with" check
//         if (scientificName.toLowerCase().startsWith(name.toLowerCase())) {
//           Map<String, dynamic> rowData = {};
//           for (var j = 0; j < headers.length; j++) {
//             final cellValue = j < row.length ? row[j]?.value : null;
//             // Filter out the null:null entry
//             if (headers[j].isNotEmpty) {
//               rowData[headers[j]] = cellValue;
//             }
//           }
//           return rowData;
//         }
//       }
//
//       return null; // Plant not found
//
//     } catch (e) {
//       debugPrint("Error processing Excel file: $e");
//       throw Exception("Failed to load plant data from Excel.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: FutureBuilder<Map<String, dynamic>?>(
//         future: _plantDataFuture,
//         builder: (context, snapshot) {
//           // --- LOADING STATE ---
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           // --- ERROR STATE ---
//           if (snapshot.hasError) {
//             return Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
//                 )
//             );
//           }
//           // --- NOT FOUND STATE ---
//           if (!snapshot.hasData || snapshot.data == null) {
//             return Center(
//               child: Text(
//                 'Details for "${widget.plantName}" not found in our database.',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 16),
//               ),
//             );
//           }
//
//           // --- SUCCESS STATE ---
//           final plantData = snapshot.data!;
//           return PlantResultView(
//             plantData: plantData,
//             imageUrl: widget.imageUrl,
//           );
//         },
//       ),
//     );
//   }
// }
//
//
// /// Widget that displays the UI once the plant data has been successfully loaded.
// class PlantResultView extends StatefulWidget {
//   final Map<String, dynamic> plantData;
//   final String imageUrl;
//
//   const PlantResultView({
//     super.key,
//     required this.plantData,
//     required this.imageUrl,
//   });
//
//   @override
//   State<PlantResultView> createState() => _PlantResultViewState();
// }
//
// class _PlantResultViewState extends State<PlantResultView> {
//   bool showDescription = false;
//   bool showLocations = false;
//
//   @override
//   Widget build(BuildContext context) {
//     // --- PARSE THE DATA FROM THE MAP ---
//     // Use the "Common Name" field for the main display name
//     final String plantName = widget.plantData["Common Name"]?.toString() ?? "Unknown Plant";
//     // Use "Therapeutic Uses" as the description for this preview screen
//     final String plantDescription = widget.plantData["Therapeutic Uses"]?.toString() ?? "No description available.";
//     // Use "Statewise Availability" for the locations
//     final String plantLocations = widget.plantData["Statewise Availability"]?.toString() ?? "Locations not specified.";
//
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             'Plant Identified',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           const Spacer(flex: 1),
//           Center(
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.grey.shade300, width: 1),
//               ),
//               child: CircleAvatar(
//                 radius: 100,
//                 backgroundColor: Colors.grey.shade200,
//                 child: ClipOval(
//                   child: Image.network(
//                     widget.imageUrl,
//                     fit: BoxFit.cover,
//                     width: 200,
//                     height: 200,
//                     loadingBuilder: (context, child, loadingProgress) {
//                       if (loadingProgress == null) return child;
//                       return const Center(child: CircularProgressIndicator());
//                     },
//                     errorBuilder: (context, error, stackTrace) {
//                       return const Icon(Icons.error, color: Colors.red, size: 50);
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text.rich(
//             TextSpan(
//               text: 'Predicted Plant: ',
//               style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
//               children: [
//                 TextSpan(
//                   text: plantName, // Displaying the parsed Common Name
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//               ],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     showDescription = !showDescription;
//                     if (showDescription) showLocations = false; // Close other tab
//                   });
//                 },
//                 child: _buildInfoChip(icon: Icons.description_outlined, label: 'Uses'),
//               ),
//               const SizedBox(width: 16),
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     showLocations = !showLocations;
//                     if (showLocations) showDescription = false; // Close other tab
//                   });
//                 },
//                 child: _buildInfoChip(icon: Icons.location_on_outlined, label: 'Found in'),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Animated container for a smoother appearance/disappearance
//           Expanded(
//             flex: 2,
//             child: SingleChildScrollView(
//               child: AnimatedSize(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//                 child: Column(
//                   children: [
//                     if (showDescription)
//                       Text(
//                         plantDescription, // Displaying Therapeutic Uses
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
//                       ),
//                     if (showLocations)
//                       Text(
//                         plantLocations, // Displaying Statewise Availability
//                         textAlign: TextAlign.center,
//                         style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.4),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Navigate to the full details page, passing the complete data map
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => PlantDetailsPage(plantData: widget.plantData),
//                 ),
//               );
//             },
//             child: const Text('View More Information'),
//           ),
//
//           // --- ADDED DISCLAIMER ---
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12.0),
//             child: Text(
//               "AI predictions may not always be accurate; please verify the results.",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontStyle: FontStyle.italic,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//           ),
//           // --- END ---
//           const Spacer(flex: 1),
//         ],
//       ),
//     );
//   }
//
//   // Helper widget to build the tappable info chips
//   Widget _buildInfoChip({required IconData icon, required String label}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.grey.shade300, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: const Offset(0, 1),
//           )
//         ],
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.grey.shade600, size: 20),
//           const SizedBox(width: 8),
//           Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }
//