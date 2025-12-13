
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:medlife/plant_identification/search_by_name.dart';
import 'plant_result.dart';
import '../core/config.dart';
import 'search_by_state.dart';
import 'search_by_use.dart';



class FunctionalityPage extends StatefulWidget {
  const FunctionalityPage({super.key});

  @override
  FunctionalityPageState createState() => FunctionalityPageState();
}

class FunctionalityPageState extends State<FunctionalityPage> {
  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
  final String uploadPreset = "medleaf_preset";
  final String apiUrl = Config.apiUrl;
  bool _isSearchExpanded = false;

  // State variables
  bool _isLoading = false;
  // New state variable to show the search bar when the user taps the search icon
  bool _isSearching = false;

  /// --- Core Logic for Image Processing (Omitted for brevity, unchanged) ---
  Future<void> _pickImage(ImageSource source) async {
    // Prevent user from starting a new process if one is already running
    if (_isLoading) return;

    Position? location;

    if (source == ImageSource.camera) {
      location = await _getCurrentLocation();
      if (location == null) {
        return; // User cancelled or failed to get location
      }
    }

    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return; // User cancelled the image picker

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss the dialog by tapping outside
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Identifying your plant..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // 2. Upload to Cloudinary
      String? originalUrl = await _uploadToCloudinary(pickedFile);

      if (originalUrl != null) {
        String transformedUrl = originalUrl.replaceFirst('/upload/', '/upload/f_jpg/');
        final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');

        debugPrint("Cloudinary URL for display: $finalUrl");

        // 3. Fetch plant data from your backend
        Map<String, dynamic>? plantData = await _fetchPlantData(
          finalUrl,
          location: location,
        );

        // ✨ 4. Dismiss the loader *before* navigating or showing an error
        if (mounted) Navigator.of(context).pop();

        if (plantData != null && plantData.containsKey('name') && mounted) {
          final String plantName = plantData['name'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantResultPage(
                plantName: plantName,
                imageUrl: finalUrl,
              ),
            ),
          );
        } else {
          _showErrorDialog("Failed to identify the plant. Please try a clearer image.");
        }
      } else {
        if (mounted) Navigator.of(context).pop(); // Dismiss loader on failure too
        _showErrorDialog("Image upload failed. Please try again.");
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Dismiss on any exception
      _showErrorDialog("An unexpected error occurred: $e");
    } finally {
      // 5. Reset the loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
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
      appBar: AppBar(
        title: const Text('MedFlora'),
        centerTitle: true,
      ),
      body: Padding(
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
                        'MedFlora',
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





/// 2 search options
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
// import 'package:medlife/plant_identification/search_by_name.dart';
// import 'plant_result.dart';
// import '../core/config.dart';
// import 'search_by_state.dart';
//
//
// class FunctionalityPage extends StatefulWidget {
//   const FunctionalityPage({super.key});
//
//   @override
//   FunctionalityPageState createState() => FunctionalityPageState();
// }
//
// class FunctionalityPageState extends State<FunctionalityPage> {
//   final picker = ImagePicker();
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl;
//   bool _isSearchExpanded = false;
//
//   // State variables
//   bool _isLoading = false;
//   // New state variable to show the search bar when the user taps the search icon
//   bool _isSearching = false;
//
//   /// --- Core Logic for Image Processing (Omitted for brevity, unchanged) ---
//   Future<void> _pickImage(ImageSource source) async {
//     // Prevent user from starting a new process if one is already running
//     if (_isLoading) return;
//
//     Position? location;
//
//     if (source == ImageSource.camera) {
//       location = await _getCurrentLocation();
//       if (location == null) {
//         return; // User cancelled or failed to get location
//       }
//     }
//
//     final pickedFile = await picker.pickImage(source: source);
//
//     if (pickedFile == null) return; // User cancelled the image picker
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     showDialog(
//       context: context,
//       barrierDismissible: false, // User cannot dismiss the dialog by tapping outside
//       builder: (BuildContext context) {
//         return const Dialog(
//           child: Padding(
//             padding: EdgeInsets.all(20.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 20),
//                 Text("Identifying your plant..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//
//     try {
//       // 2. Upload to Cloudinary
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         String transformedUrl = originalUrl.replaceFirst('/upload/', '/upload/f_jpg/');
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         debugPrint("Cloudinary URL for display: $finalUrl");
//
//         // 3. Fetch plant data from your backend
//         Map<String, dynamic>? plantData = await _fetchPlantData(
//           finalUrl,
//           location: location,
//         );
//
//         // ✨ 4. Dismiss the loader *before* navigating or showing an error
//         if (mounted) Navigator.of(context).pop();
//
//         if (plantData != null && plantData.containsKey('name') && mounted) {
//           final String plantName = plantData['name'];
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantName: plantName,
//                 imageUrl: finalUrl,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to identify the plant. Please try a clearer image.");
//         }
//       } else {
//         if (mounted) Navigator.of(context).pop(); // Dismiss loader on failure too
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     } catch (e) {
//       if (mounted) Navigator.of(context).pop(); // Dismiss on any exception
//       _showErrorDialog("An unexpected error occurred: $e");
//     } finally {
//       // 5. Reset the loading state
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   /// --- Helper Functions (Omitted for brevity, unchanged) ---
//   Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//     // ... (unchanged)
//     try {
//       final bytes = await pickedFile.readAsBytes();
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           bytes,
//           filename: pickedFile.name,
//         ));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url'];
//       } else {
//         debugPrint("Cloudinary upload failed: ${response.statusCode}");
//         final errorBody = await response.stream.bytesToString();
//         debugPrint("Error body: $errorBody");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
//     // ... (unchanged)
//     try {
//       final body = <String, dynamic>{
//         'image_url': imageUrl,
//       };
//
//       if (location != null) {
//         body['latitude'] = location.latitude;
//         body['longitude'] = location.longitude;
//         debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
//       }
//
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );
//
//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   Future<Position?> _getCurrentLocation() async {
//     // ... (unchanged)
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled && mounted) {
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Enable Location Services'),
//           content: const Text('To geotag your plant, please enable location services in your device settings.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Open Settings'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Geolocator.openLocationSettings();
//               },
//             ),
//           ],
//         ),
//       );
//       return null;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showErrorDialog("Location permission was denied. Geotagging is unavailable.");
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever && mounted) {
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Location Permission Required'),
//           content: const Text('Location permissions are permanently denied. Please enable them from your app settings to use this feature.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Open Settings'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Geolocator.openAppSettings();
//               },
//             ),
//           ],
//         ),
//       );
//       return null;
//     }
//
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       _showErrorDialog("Failed to get current location: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildGoogleStyleSearchBar(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // --- 1. The Search Bar ---
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           // No decoration here to avoid double outlines
//           child: TextField(
//             readOnly: true, // Prevents keyboard from popping up immediately
//             onTap: () {
//               setState(() {
//                 _isSearchExpanded = !_isSearchExpanded; // Toggle the dropdown
//               });
//             },
//             decoration: InputDecoration(
//               hintText: 'Search for plants...',
//               filled: true,
//               fillColor: Colors.white,
//               contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
//
//               // Search Icon
//               prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
//
//               // Close/Chevron Icon Logic
//               suffixIcon: IconButton(
//                 icon: Icon(
//                   _isSearchExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                   color: Colors.grey,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _isSearchExpanded = !_isSearchExpanded;
//                   });
//                 },
//               ),
//
//               // --- BORDER STYLING (Fixed Single Outline) ---
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//             ),
//           ),
//         ),
//
//         // --- 2. The Dropdown Options (Visible only when expanded) ---
//         if (_isSearchExpanded)
//           Container(
//             margin: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(color: Colors.grey.shade200), // Subtle border
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Option 1
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
//                     child: Icon(Icons.grass, color: Theme.of(context).primaryColor, size: 20),
//                   ),
//                   title: const Text('Search by Name', style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Text('Find specific species', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                   onTap: () {
//                     setState(() => _isSearchExpanded = false);
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByNamePage()));
//                   },
//                 ),
//
//                 Divider(height: 1, color: Colors.grey.shade100),
//
//                 // Option 2
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
//                     child: Icon(Icons.map, color: Theme.of(context).primaryColor, size: 20),
//                   ),
//                   title: const Text('Search by State', style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: const Text('Explore regional flora', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                   onTap: () {
//                     setState(() => _isSearchExpanded = false);
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByStatePage()));
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//         // Spacer to keep layout nice if dropdown is closed
//         if (!_isSearchExpanded) const SizedBox(height: 20),
//       ],
//     );
//   }
//
//
//   Widget _buildSearchBar(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // --- 1. The Search Bar ---
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           child: TextField(
//             readOnly: true, // Prevents keyboard from popping up immediately
//             onTap: () {
//               setState(() {
//                 _isSearchExpanded = !_isSearchExpanded; // Toggle the dropdown
//               });
//             },
//             decoration: InputDecoration(
//               hintText: 'Search for plants...',
//               filled: true,
//               fillColor: Colors.white,
//               contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
//
//               // Search Icon
//               prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
//
//               // Arrow Icon (Rotates based on state)
//               suffixIcon: IconButton(
//                 icon: Icon(
//                   _isSearchExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
//                   color: Colors.grey,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _isSearchExpanded = !_isSearchExpanded;
//                   });
//                 },
//               ),
//
//               // --- Border Styling (Fixed Single Outline) ---
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//             ),
//           ),
//         ),
//
//         // --- 2. The Dropdown Options (Visible only when expanded) ---
//         if (_isSearchExpanded)
//           Container(
//             margin: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(color: Colors.grey.shade200),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Option A: Search by Name
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
//                     child: Icon(Icons.grass, color: Theme.of(context).primaryColor, size: 20),
//                   ),
//                   title: const Text('Search by Name', style: TextStyle(fontWeight: FontWeight.bold)),
//                   onTap: () {
//                     setState(() => _isSearchExpanded = false);
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByNamePage()));
//                   },
//                 ),
//
//                 Divider(height: 1, color: Colors.grey.shade100),
//
//                 // Option B: Search by State
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
//                     child: Icon(Icons.map, color: Theme.of(context).primaryColor, size: 20),
//                   ),
//                   title: const Text('Search by State', style: TextStyle(fontWeight: FontWeight.bold)),
//                   onTap: () {
//                     setState(() => _isSearchExpanded = false);
//                     Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchByStatePage()));
//                   },
//                 ),
//               ],
//             ),
//           ),
//
//         // Spacer to keep layout nice if dropdown is closed
//         if (!_isSearchExpanded) const SizedBox(height: 20),
//       ],
//     );
//   }
//
//
//   /// --- UI Build Method (Updated) ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('MedFlora'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Insert the Search Bar here
//             _buildSearchBar(context),
//
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.photo_library_outlined,
//                         label: 'Upload Image',
//                         onTap: () => _pickImage(ImageSource.gallery),
//                       ),
//                       const SizedBox(height: 20),
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.camera_alt_outlined,
//                         label: 'Scan Image',
//                         onTap: () => _pickImage(ImageSource.camera),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Icon(
//                         Icons.eco_outlined,
//                         size: 60,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'MedFlora',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Nourish. Discover. Grow',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// --- UI Helper (Unchanged) ---
//   Widget _buildOptionCard({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 30,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               Icons.cloud_upload_outlined,
//               color: Colors.grey.shade500,
//               size: 28,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }




/// MODEL USED
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
//
// import 'plant_result.dart';
// import '../core/config.dart';
// import '../specialist/add_plant_screen.dart';
//
// class FunctionalityPage extends StatefulWidget {
//   const FunctionalityPage({super.key});
//
//   @override
//   FunctionalityPageState createState() => FunctionalityPageState();
// }
//
// class FunctionalityPageState extends State<FunctionalityPage> {
//   final picker = ImagePicker();
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   /// --- Core Logic for Image Processing ---
//   Future<void> _pickImage(ImageSource source) async {
//     Position? location; // Variable to hold location data
//
//     // If the source is the camera, get the current location first
//     if (source == ImageSource.camera) {
//       location = await _getCurrentLocation();
//       if (location == null) {
//         // Stop if the user cancels or fails to provide location
//         return;
//       }
//     }
//
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         // Ensure the URL is in JPG format for the backend
//         String transformedUrl = originalUrl.replaceFirst(
//           '/upload/',
//           '/upload/f_jpg/',
//         );
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         debugPrint("Final URL sent to backend: $finalUrl");
//
//         // Fetch plant data, passing the location object (it will be null if from gallery)
//         Map<String, dynamic>? plantData = await _fetchPlantData(
//           finalUrl,
//           location: location,
//         );
//
//         if (plantData != null && plantData.containsKey('name') && mounted) {
//           final String plantName = "Aloe vera"; // Using placeholder as before
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantName: plantName,
//                 imageUrl: finalUrl,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to identify the plant from the API.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   /// --- Helper Functions ---
//
//   Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//     try {
//       final bytes = await pickedFile.readAsBytes();
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           bytes,
//           filename: pickedFile.name,
//         ));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url'];
//       } else {
//         debugPrint("Cloudinary upload failed: ${response.statusCode}");
//         final errorBody = await response.stream.bytesToString();
//         debugPrint("Error body: $errorBody");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
//     try {
//       final body = <String, dynamic>{
//         'image_url': imageUrl,
//       };
//
//       // Add location data to the body if it exists
//       if (location != null) {
//         body['latitude'] = location.latitude;
//         body['longitude'] = location.longitude;
//         debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
//       }
//
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body),
//       );
//
//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   Future<Position?> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // 1. Check if location services are enabled on the device.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled && mounted) {
//       // Location services are not enabled. Show a dialog to ask the user to enable them.
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Enable Location Services'),
//           content: const Text('To geotag your plant, please enable location services in your device settings.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Open Settings'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Geolocator.openLocationSettings(); // Opens device location settings
//               },
//             ),
//           ],
//         ),
//       );
//       return null; // Stop here, as user needs to enable services first.
//     }
//
//     // 2. Check for app-specific location permissions.
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission(); // Ask for permission
//       if (permission == LocationPermission.denied) {
//         // User explicitly denied the permission.
//         _showErrorDialog("Location permission was denied. Geotagging is unavailable.");
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever && mounted) {
//       // Permissions are denied forever. Show a dialog to ask the user to go to app settings.
//       await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Location Permission Required'),
//           content: const Text('Location permissions are permanently denied. Please enable them from your app settings to use this feature.'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Open Settings'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Geolocator.openAppSettings(); // Opens this app's specific settings
//               },
//             ),
//           ],
//         ),
//       );
//       return null;
//     }
//
//     // 3. If we get here, permissions are granted. Get the location.
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       _showErrorDialog("Failed to get current location: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   /// --- UI Build Method ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Plant'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.photo_library_outlined,
//                         label: 'Upload Image',
//                         onTap: () => _pickImage(ImageSource.gallery),
//                       ),
//                       const SizedBox(height: 20),
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.camera_alt_outlined,
//                         label: 'Scan Image',
//                         onTap: () => _pickImage(ImageSource.camera),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Icon(
//                         Icons.eco_outlined,
//                         size: 60,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'MedFlora',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Nourish. Discover. Grow',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () => _pickImage(ImageSource.gallery),
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOptionCard({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 30,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               Icons.cloud_upload_outlined,
//               color: Colors.grey.shade500,
//               size: 28,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//

/// OLD
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:geolocator/geolocator.dart';
//
// import 'plant_result.dart';
// import '../core/config.dart';
// import '../specialist/add_plant_screen.dart'; // <-- Added import for the new screen
//
// class FunctionalityPage extends StatefulWidget {
//   const FunctionalityPage({super.key});
//
//   @override
//   FunctionalityPageState createState() => FunctionalityPageState();
// }
//
// class FunctionalityPageState extends State<FunctionalityPage> {
//   final picker = ImagePicker();
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//   final String apiUrl = Config.apiUrl; // Your Flask endpoint
//
//   // --- MODIFIED: Logic for Image Processing ---
//
//   Future<void> _pickImage(ImageSource source) async {
//     Position? location; // NEW: Variable to hold location data
//
//     // NEW: Check if source is camera, then get location
//     if (source == ImageSource.camera) {
//       location = await _getCurrentLocation();
//       if (location == null) {
//         // User denied permission or location services are off
//         // The _getCurrentLocation function will show the error dialog
//         return; // Stop execution if location not found
//       }
//     }
//
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       String? originalUrl = await _uploadToCloudinary(pickedFile);
//
//       if (originalUrl != null) {
//         // Ensure the URL is in JPG format for the backend
//         String transformedUrl = originalUrl.replaceFirst(
//           '/upload/',
//           '/upload/f_jpg/',
//         );
//         final finalUrl = transformedUrl.replaceAll(RegExp(r'\.[^/.]+$'), '.jpg');
//
//         debugPrint("Final URL sent to backend: $finalUrl");
//
//         // MODIFIED: Pass the location object (it will be null if from gallery)
//         Map<String, dynamic>? plantData = await _fetchPlantData(
//           finalUrl,
//           location: location,
//         );
//
//         if (plantData != null && plantData.containsKey('name') && mounted) {
//           // Extract the value from the 'name' key
//           // final String plantName = plantData['name'];
//           final String plantName = "Aloe vera"; // Using placeholder as before
//
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => PlantResultPage(
//                 plantName: plantName, // Pass the correct name
//                 imageUrl: finalUrl,
//               ),
//             ),
//           );
//         } else {
//           _showErrorDialog("Failed to identify the plant from the API.");
//         }
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   Future<String?> _uploadToCloudinary(XFile pickedFile) async {
//     try {
//       final bytes = await pickedFile.readAsBytes();
//       var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
//         ..fields['upload_preset'] = uploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           bytes,
//           filename: pickedFile.name,
//         ));
//
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         var responseData = await response.stream.bytesToString();
//         var jsonData = json.decode(responseData);
//         return jsonData['secure_url'];
//       } else {
//         debugPrint("Cloudinary upload failed: ${response.statusCode}");
//         final errorBody = await response.stream.bytesToString();
//         debugPrint("Error body: $errorBody");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Cloudinary upload error: $e");
//       return null;
//     }
//   }
//
//   // MODIFIED: Updated signature to accept optional location
//   Future<Map<String, dynamic>?> _fetchPlantData(String imageUrl, {Position? location}) async {
//     try {
//       // MODIFIED: Build the request body
//       final body = <String, dynamic>{
//         'image_url': imageUrl,
//       };
//
//       // MODIFIED: Add location data to the body if it exists
//       if (location != null) {
//         body['latitude'] = location.latitude;
//         body['longitude'] = location.longitude;
//         debugPrint("Sending location: ${location.latitude}, ${location.longitude}");
//       }
//
//       final response = await http.post(
//         Uri.parse(apiUrl),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(body), // MODIFIED: Send the new body
//       );
//
//       debugPrint("Response status: ${response.statusCode}");
//       debugPrint("Response body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Parsed JSON plant data
//       } else {
//         debugPrint("API error: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("API request failed: $e");
//       return null;
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     if (!mounted) return; // Don't show dialog if the widget is disposed.
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("Error"),
//           content: Text(message),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // --- NEW: Helper function for getting location ---
//   Future<Position?> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showErrorDialog("Location services are disabled. Please enable them.");
//       return null;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showErrorDialog("Location permissions are denied.");
//         return null;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, handle appropriately.
//       _showErrorDialog(
//           "Location permissions are permanently denied, we cannot request permissions.");
//       return null;
//     }
//
//     // When we reach here, permissions are granted and we can
//     // continue accessing the position of the device.
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (e) {
//       _showErrorDialog("Failed to get location: $e");
//       return null;
//     }
//   }
//
//   // --- UI Build Method (Unchanged) ---
//   @override
//   Widget build(BuildContext context) {
//     // Navigation function for the "Add Plant" page
//     void navigateToAddPlant() {
//       // Navigator.of(context).push(
//       //   MaterialPageRoute(builder: (context) => const AddPlantScreen()),
//       // );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Plant'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Column(
//                     children: [
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.photo_library_outlined,
//                         label: 'Upload Image',
//                         onTap: () => _pickImage(ImageSource.gallery), // Wired to gallery
//                       ),
//                       const SizedBox(height: 20),
//                       _buildOptionCard(
//                         context: context,
//                         icon: Icons.camera_alt_outlined,
//                         label: 'Scan Image',
//                         onTap: () => _pickImage(ImageSource.camera), // Wired to camera
//                       ),
//                       const SizedBox(height: 20),
//                       // New "Add Plant" button with its own navigation
//                       // _buildOptionCard(
//                       //   context: context,
//                       //   icon: Icons.add_circle_outline,
//                       //   label: 'Add New Plant',
//                       //   onTap: navigateToAddPlant,
//                       // ),
//                     ],
//                   ),
//                   Column(
//                     children: [
//                       Icon(
//                         Icons.eco_outlined,
//                         size: 60,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'MedFlora',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context).primaryColor,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Nourish. Discover. Grow',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             ElevatedButton(
//               // Default action is to upload from gallery
//               onPressed: () => _pickImage(ImageSource.gallery),
//               child: const Text('Continue'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper widget for building the option cards, moved from the original example
//   Widget _buildOptionCard({
//     required BuildContext context,
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.5),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: 1.5,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 30,
//               color: Theme.of(context).primaryColor,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//             const Spacer(),
//             Icon(
//               label == 'Add New Plant'
//                   ? Icons.arrow_forward_ios
//                   : Icons.cloud_upload_outlined,
//               color: Colors.grey.shade500,
//               size: label == 'Add New Plant' ? 20 : 28,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

