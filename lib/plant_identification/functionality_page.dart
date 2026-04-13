/// new working code
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:medlife/plant_identification/search_by_name.dart';
import 'package:medlife/plant_identification/user_history_page.dart';
import 'package:medlife/plant_identification/user_profile_page.dart';
import '../core/role_page.dart';
import 'plant_result.dart';
import '../core/config.dart';
import 'search_by_state.dart';
import 'search_by_use.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:exif/exif.dart';



class FunctionalityPage extends StatefulWidget {
  final bool showAppBar;

  const FunctionalityPage({super.key, this.showAppBar = true});


  // const FunctionalityPage({super.key});

  @override
  FunctionalityPageState createState() => FunctionalityPageState();
}

class FunctionalityPageState extends State<FunctionalityPage> {
  int _navIndex = 1; // Home center selected

  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
  final String uploadPreset = "medleaf_preset";
  // final String apiUrl = Config.apiUrl;
  final String apiUrl = '${Config.apiUrl}/predict';
  final String localApiUrl = '${Config.apiUrl}/predict-local';

  bool _isSearchExpanded = false;

  // State variables
  bool _isLoading = false;
  // New state variable to show the search bar when the user taps the search icon
  bool _isSearching = false;

  /// --- Core Logic for Image Processing (Omitted for brevity, unchanged) ---
  Future<void> _pickImage(ImageSource source) async {

    if (source == ImageSource.gallery) {
      await _pickImageFromFiles(); // ← NEW
      return;
    }

    if (source == ImageSource.camera) {
      Position? location = await _getCurrentLocation();
      if (location == null) return;

      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        await _processPickedFile(pickedFile, location: location);
        // await _processPickedFile(pickedFile);
      }
    }
  }

  Future<void> _processPickedFile(XFile pickedFile,{Position? location}) async {
    // ✅ ADD HERE
    try {
      final bytes = await pickedFile.readAsBytes();
      final tags = await readExifFromBytes(bytes);

      final lat = tags['GPS GPSLatitude'];
      final lon = tags['GPS GPSLongitude'];

      debugPrint("EXIF Lat tag: $lat");
      debugPrint("EXIF Lon tag: $lon");
    } catch (e) {
      debugPrint("EXIF read failed: $e");
    }

    // existing logic continues ↓↓↓
    if (_isLoading) return;
    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Identifying your plant..."),
            ],
          ),
        ),
      ),
    );

    try {
      String? originalUrl = await _uploadToCloudinary(pickedFile);

      if (originalUrl != null) {
        String transformedUrl =
        originalUrl.replaceFirst('/upload/', '/upload/f_jpg/');
        final finalUrl =
        transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');

        // final plantData = await _fetchPlantData(finalUrl);
        final plantData = await _fetchPlantData(finalUrl, location: location);
        _fetchPlantDataLocal(pickedFile.path);
        if (mounted) Navigator.pop(context);

        if (plantData != null && plantData.containsKey('name')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlantResultPage(
                plantName: plantData['name'],
                imageUrl: finalUrl,
                confidence: plantData['score']?.toDouble(),
                latitude: plantData['location']?['latitude'],
                longitude: plantData['location']?['longitude'],
              ),
            ),
          );
        } else {
          _showErrorDialog("Failed to identify plant.");
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _pickImageFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;

        final ext = path.toLowerCase();
        if (ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png') ||
            ext.endsWith('.webp')) {

          // convert to XFile so your existing flow works unchanged
          final pickedFile = XFile(path);
          await _processPickedFile(pickedFile);

        } else {
          _showErrorDialog("Please select a valid image file.");
        }
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  /// --- Helper Functions (Omitted for brevity, unchanged) ---
  Future<String?> _uploadToCloudinary(XFile pickedFile) async {
    // ... (unchanged)
    try {
      final bytes = await pickedFile.readAsBytes();
      var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: pickedFile.name,
        ));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      } else {
        debugPrint("Cloudinary upload failed: ${response.statusCode}");
        final errorBody = await response.stream.bytesToString();
        debugPrint("Error body: $errorBody");
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary upload error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
    // ... (unchanged)

    try {
      final body = <String, dynamic>{
        'image_url': imageUrl,
      };

      if (location != null) {
        body['latitude'] = location.latitude;
        body['longitude'] = location.longitude;
        debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );


      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");


      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("API error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("API request failed: $e");
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    // ... (unchanged)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text('To geotag your plant, please enable location services in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        ),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog("Location permission was denied. Geotagging is unavailable.");
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text('Location permissions are permanently denied. Please enable them from your app settings to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        ),
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorDialog("Failed to get current location: $e");
      return null;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchPlantDataLocal(String imagePath) async {
    try {

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(localApiUrl),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          imagePath,
        ),
      );

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();

      debugPrint("LOCAL MODEL STATUS: ${response.statusCode}");
      debugPrint("LOCAL MODEL RESULT: $responseBody");

    } catch (e) {
      debugPrint("Local model error: $e");
    }
  }


  Widget _buildSearchBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. The Search Bar ---
        Container(
          margin: const EdgeInsets.only(top: 10),
          child: TextField(
            readOnly: true, // Prevents keyboard from popping up immediately
            onTap: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded; // Toggle the dropdown
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for plants...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),

              // Search Icon
              prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),

              // Arrow Icon (Rotates based on state)
              suffixIcon: IconButton(
                icon: Icon(
                  _isSearchExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                  });
                },
              ),

              // --- Border Styling ---
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
            ),
          ),
        ),

        // --- 2. The Dropdown Options (Visible only when expanded) ---
        if (_isSearchExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Option A: Search by Name
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.grass, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  title: const Text('Search by Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _isSearchExpanded = false);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByNamePage()));
                  },
                ),

                Divider(height: 1, color: Colors.grey.shade100),

                // Option B: Search by State
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: Icon(Icons.map, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  title: const Text('Search by State', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _isSearchExpanded = false);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByStatePage()));
                  },
                ),

                Divider(height: 1, color: Colors.grey.shade100),

                // Option C: Search by Use (NEW)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    // Used 'healing' icon as it fits medicinal uses perfectly
                    child: Icon(Icons.healing, color: Theme.of(context).primaryColor, size: 20),
                  ),
                  title: const Text('Search by Use', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() => _isSearchExpanded = false);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByUsePage()));
                  },
                ),
              ],
            ),
          ),

        // Spacer to keep layout nice if dropdown is closed
        if (!_isSearchExpanded) const SizedBox(height: 20),
      ],
    );
  }


  /// --- UI Build Method (Updated) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.showAppBar? AppBar(
        title: const Text('FloraMediX'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text('Do you really want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );

              if (shouldLogout != true) return;

              final authProvider =
              Provider.of<AuthProvider>(context, listen: false);

              await authProvider.logout();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                    (_) => false,
              );
            },

          ),
        ],
      ): null,
      body: IndexedStack(
        index: _navIndex,
        children: [
          const UserProfilePage(),
          _buildHomeBody(),
          const UserHistoryPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        // onTap: (i) {
        //   setState(() => _navIndex = i);
        // },

        onTap: (i) {
          setState(() => _navIndex = i);

          if (i == 2) {
            UserHistoryPage.reload?.call();
          }
        },

        backgroundColor: Colors.white,
        elevation: 8,

        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,

        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),

      // body: Padding(
      //   padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 32.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       // Insert the Search Bar here
      //       _buildSearchBar(context),
      //
      //       Expanded(
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //           children: [
      //             Column(
      //               children: [
      //                 _buildOptionCard(
      //                   context: context,
      //                   icon: Icons.photo_library_outlined,
      //                   label: 'Upload Image',
      //                   onTap: () => _pickImage(ImageSource.gallery),
      //                 ),
      //                 const SizedBox(height: 20),
      //                 _buildOptionCard(
      //                   context: context,
      //                   icon: Icons.camera_alt_outlined,
      //                   label: 'Scan Image',
      //                   onTap: () => _pickImage(ImageSource.camera),
      //                 ),
      //               ],
      //             ),
      //             Column(
      //               children: [
      //                 Icon(
      //                   Icons.eco_outlined,
      //                   size: 60,
      //                   color: Theme.of(context).primaryColor,
      //                 ),
      //                 const SizedBox(height: 8),
      //                 Text(
      //                   'MedFlora',
      //                   style: TextStyle(
      //                     fontSize: 32,
      //                     fontWeight: FontWeight.bold,
      //                     color: Theme.of(context).primaryColor,
      //                   ),
      //                 ),
      //                 const SizedBox(height: 8),
      //                 Text(
      //                   'Nourish. Discover. Grow',
      //                   style: TextStyle(
      //                     fontSize: 16,
      //                     color: Colors.grey.shade600,
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildHomeBody(){
    return  Padding(
    padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 32.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    // Insert the Search Bar here
    _buildSearchBar(context),

    Expanded(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
    Column(
    children: [
    _buildOptionCard(
    context: context,
    icon: Icons.photo_library_outlined,
    label: 'Upload Image',
    onTap: () => _pickImage(ImageSource.gallery),
    ),
    const SizedBox(height: 20),
    _buildOptionCard(
    context: context,
    icon: Icons.camera_alt_outlined,
    label: 'Scan Image',
    onTap: () => _pickImage(ImageSource.camera),
    ),
    ],
    ),
    Column(
    children: [
    Icon(
    Icons.eco_outlined,
    size: 60,
    color: Theme.of(context).primaryColor,
    ),
    const SizedBox(height: 8),
    Text(
    'FloraMediX',
    style: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).primaryColor,
    ),
    ),
    const SizedBox(height: 8),
    Text(
    'Nourish. Discover. Grow',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey.shade600,
    ),
    ),
    ],
    ),
    ],
    ),
    ),
    ],
    ),
    );
  }

  /// --- UI Helper (Unchanged) ---
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.cloud_upload_outlined,
              color: Colors.grey.shade500,
              size: 28,
            )
          ],
        ),
      ),
    );
  }
}



