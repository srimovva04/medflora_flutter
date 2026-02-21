import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrowseImagesPage extends StatefulWidget {
  const BrowseImagesPage({super.key});

  @override
  State<BrowseImagesPage> createState() => _BrowseImagesPageState();
}

class _BrowseImagesPageState extends State<BrowseImagesPage> {
  List<String> _plantImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlantImages();
  }

  Future<void> _loadPlantImages() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final imagePaths = manifestMap.keys
          .where((String key) => key.contains('assets/plants/'))
          .where((String key) =>
      key.endsWith('.jpg') ||
          key.endsWith('.jpeg') ||
          key.endsWith('.png') ||
          key.endsWith('.webp'))
          .toList();

      setState(() {
        _plantImages = imagePaths;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading assets: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Image Gallery",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plantImages.isEmpty
          ? const Center(child: Text("No images found in assets/plants/"))
          : Padding(
        padding: const EdgeInsets.all(4.0), // Reduced padding for tighter grid
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // <--- CHANGED TO 3 IMAGES HORIZONTALLY
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: _plantImages.length,
          itemBuilder: (context, index) {
            final imagePath = _plantImages[index];

            return GestureDetector(
              onTap: () {
                // Navigate to full screen view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenAssetView(imagePath: imagePath),
                  ),
                );
              },
              child: Hero(
                tag: imagePath, // Hero animation tag
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                    image: DecorationImage(
                      image: AssetImage(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- NEW HELPER CLASS FOR FULL SCREEN VIEW ---
class FullScreenAssetView extends StatelessWidget {
  final String imagePath;

  const FullScreenAssetView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background looks better for galleries
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: imagePath,
          child: InteractiveViewer(
            panEnabled: true, // Allow panning
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0, // Allow zooming in
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}