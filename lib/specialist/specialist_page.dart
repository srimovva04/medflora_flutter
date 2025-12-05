import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import geolocator

import 'add_plant_screen.dart';
import 'verification_page.dart';

class SpecialistPage extends StatefulWidget {
  const SpecialistPage({super.key});
  @override
  State<SpecialistPage> createState() => _SpecialistPageState();
}

class _SpecialistPageState extends State<SpecialistPage> {
  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
  final String uploadPreset = "medleaf_preset";

  /// Opens the image picker and handles location for camera source.
  Future<void> _pickImage(ImageSource source) async {
    Position? location; // Variable to hold location data

    // Check if source is camera, then get location
    if (source == ImageSource.camera) {
      location = await _getCurrentLocation();
      if (location == null) {
        // Stop if the user cancels or fails to provide location
        return;
      }
      // NEW: For verification, print the location to the console
      debugPrint("Location captured: Lat: ${location.latitude}, Lng: ${location.longitude}");
    }

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      String? imageUrl = await _uploadToCloudinary(pickedFile);

      if (imageUrl != null && mounted) {
        // MODIFIED: Navigate WITHOUT the location data, as requested.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPlantScreen(
              imageUrl: imageUrl,
            ),
          ),
        );
      } else {
        _showErrorDialog("Image upload failed. Please try again.");
      }
    }
  }

  /// Uploads the selected file to Cloudinary and returns the secure URL.
  Future<String?> _uploadToCloudinary(XFile pickedFile) async {
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

  /// Shows an error dialog with a given message.
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

  /// Helper function for getting location with user prompts
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
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

    // Check for app-specific location permissions.
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

    // If we get here, permissions are granted. Get the location.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorDialog("Failed to get current location: $e");
      return null;
    }
  }

  /// Shows a dialog to choose between Camera and Gallery.
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Scan with Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Specialist Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOptionCard(
              icon: Icons.document_scanner_outlined,
              label: 'Scan or Upload Plant',
              onTap: _showImageSourceDialog,
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              icon: Icons.playlist_add_check,
              label: 'Verify Submissions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VerificationListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Row(
            children: [
              Icon(icon, size: 30, color: theme.primaryColor),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              Icon(
                label == 'Verify Submissions' ? Icons.arrow_forward_ios : Icons.cloud_upload_outlined,
                color: Colors.grey.shade500,
                size: label == 'Verify Submissions' ? 20 : 28,
              )
            ],
          ),
        ),
      ),
    );
  }
}




/// normal working
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'add_plant_screen.dart';
// import 'verification_page.dart';
//
// class SpecialistPage extends StatefulWidget {
//   const SpecialistPage({super.key});
//   @override
//   State<SpecialistPage> createState() => _SpecialistPageState();
// }
//
// class _SpecialistPageState extends State<SpecialistPage> {
//   // --- Logic copied from FunctionalityPage ---
//   final picker = ImagePicker();
//   final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
//   final String uploadPreset = "medleaf_preset";
//
//   /// Opens the image picker for the camera or gallery.
//   Future<void> _pickImage(ImageSource source) async {
//     final pickedFile = await picker.pickImage(source: source);
//     if (pickedFile != null) {
//       // --- MODIFIED LOGIC ---
//       // 1. Upload to Cloudinary
//       String? imageUrl = await _uploadToCloudinary(pickedFile);
//
//       // 2. If upload is successful, navigate to AddPlantScreen with the URL
//       if (imageUrl != null && mounted) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             // Pass the returned URL to the next screen
//             builder: (context) => AddPlantScreen(imageUrl: imageUrl),
//           ),
//         );
//       } else {
//         _showErrorDialog("Image upload failed. Please try again.");
//       }
//     }
//   }
//
//   /// Uploads the selected file to Cloudinary and returns the secure URL.
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
//   /// Shows an error dialog with a given message.
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
//   /// Shows a dialog to choose between Camera and Gallery.
//   void _showImageSourceDialog() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: <Widget>[
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Upload from Gallery'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Scan with Camera'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   // --- End of copied logic ---
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Specialist Dashboard')),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildOptionCard(
//               icon: Icons.document_scanner_outlined,
//               label: 'Scan or Upload Plant',
//               // This now calls the dialog to choose an image source
//               onTap: _showImageSourceDialog,
//             ),
//             const SizedBox(height: 20),
//             _buildOptionCard(
//               icon: Icons.playlist_add_check,
//               label: 'Verify Submissions',
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(builder: (context) => const VerificationListPage()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Helper widget to build the option cards.
//   Widget _buildOptionCard({required IconData icon, required String label, required VoidCallback onTap}) {
//     final theme = Theme.of(context);
//     return Card(
//       elevation: 2.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
//           child: Row(
//             children: [
//               Icon(icon, size: 30, color: theme.primaryColor),
//               const SizedBox(width: 16),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.w600,
//                   color: theme.primaryColor,
//                 ),
//               ),
//               const Spacer(),
//               Icon(
//                 label == 'Verify Submissions' ? Icons.arrow_forward_ios : Icons.cloud_upload_outlined,
//                 color: Colors.grey.shade500,
//                 size: label == 'Verify Submissions' ? 20 : 28,
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
