import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medlife/plant_identification/plant_gallery.dart';
import '../core/config.dart';
import 'plant_details.dart';

class PlantResultPage extends StatefulWidget {
  final String plantName;
  final String imageUrl;
  final double? confidence;
  final double? latitude;
  final double? longitude;

  const PlantResultPage({
    super.key,
    required this.plantName,
    required this.imageUrl,
    this.confidence,
    this.latitude,
    this.longitude,
  });


  @override
  State<PlantResultPage> createState() => _PlantResultPageState();
}

class _PlantResultPageState extends State<PlantResultPage> {
  late Future<Map<String, dynamic>?> _plantDataFuture;
  final String baseUrl = Config.apiUrl;


  @override
  void initState() {
    super.initState();
    _plantDataFuture = _fetchPlantDetailsFromApi(widget.plantName);
  }

  Future<Map<String, dynamic>?> _fetchPlantDetailsFromApi(String name) async {
    try {
      final uri = Uri.parse("$baseUrl/search/plant/${Uri.encodeComponent(name)}");
      debugPrint("Fetching plant details from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          final apiData = jsonResponse['data'];
          return {
            "Common Name": apiData['name_common'] ?? name,
            "Scientific Name": apiData['name_scientific'] ?? "Unknown",
            "Kingdom": apiData['kingdom'] ?? "Plantae",
            "Family": apiData['family'] ?? "Unknown",
            "Description": apiData['description'] ?? "No description available.",
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

          final plantData = snapshot.data ?? {
            "Common Name": widget.plantName,
            "Scientific Name": "Not found in database",
            "Kingdom": "Unknown"
          };

          final bool isNotFound = snapshot.data == null;

          return PlantResultView(
            plantData: plantData,
            imageUrl: widget.imageUrl,
            confidence: widget.confidence,
            latitude: widget.latitude,
            longitude: widget.longitude,
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
  final double? confidence;
  final double? latitude;
  final double? longitude;


  const PlantResultView({
    super.key,
    required this.plantData,
    required this.imageUrl,
    this.isNotFound = false,
    this.confidence,
    this.latitude,
    this.longitude,
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
  // LAYOUT 1: IMAGE EXISTS (UPDATED)
  // ===========================================================================
  Widget _buildLayoutWithImage(BuildContext context) {
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
              // 1. Circle Avatar with Click-to-View functionality
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageView(imageUrl: imageUrl),
                        ),
                      );
                    },
                    child: Hero(
                      tag: imageUrl, // Unique tag for smooth animation
                      child: Container(
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Prediction', style: TextStyle(fontSize: 16, color: Colors.black54)),

                  Text(
                    commonName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  if (confidence != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Confidence: ${(confidence! * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],

                  if (latitude != null && longitude != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Location: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],

                  // const Text('Prediction', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  // Text(
                  //   commonName,
                  //   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  //   textAlign: TextAlign.center,
                  // ),
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
                  const SizedBox(height: 12),
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         // Replace this with your actual Gallery/Grid page
                  //         builder: (context) => const BrowseImagesPage(),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text(
                  //     "Browse Images",
                  //     style: TextStyle(
                  //       fontSize: 16,
                  //       decoration: TextDecoration.underline, // Optional: adds underline
                  //     ),
                  //   ),
                  // ),
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
    // ... [Previous code for _buildLayoutNoImage remains exactly the same]
    // Including it briefly for context but keeping logic identical to your snippet
    final String commonName = plantData["Common Name"]?.toString() ?? "Unknown Plant";
    final String scientificName = plantData["Scientific Name"]?.toString() ?? "";
    final String kingdom = plantData["Kingdom"]?.toString() ?? "N/A";

    return Column(
      children: [
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
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Scientific Name: $scientificName",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         // Replace this with your actual Gallery/Grid page
                  //         builder: (context) => const BrowseImagesPage(),
                  //       ),
                  //     );
                  //   },
                  //   child: const Text(
                  //     "Browse Images",
                  //     style: TextStyle(
                  //       fontSize: 16,
                  //       color: Color(0xFF388E3C), // This matches your "View Full Details" button color
                  //       decoration: TextDecoration.underline,
                  //       decorationColor: Color(0xFF388E3C), // Optional: makes the underline match the text color
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 10),
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

// =============================================================================
// NEW: Full Screen Image View with Zoom/Pan
// =============================================================================
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better viewing
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl, // Matches the tag in the previous screen
          child: InteractiveViewer(
            panEnabled: true, // Allow panning
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0, // Allow zooming in up to 4x
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );
  }
}

