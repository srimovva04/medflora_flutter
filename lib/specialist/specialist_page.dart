import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:medlife/specialist/upload_history.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../core/role_page.dart';
import 'add_plant_screen.dart';
import 'verification_page.dart';
import '../core/config.dart';


class SpecialistPage extends StatefulWidget {
  final bool showAppBar;
  const SpecialistPage({super.key, this.showAppBar = true});

  // const SpecialistPage({super.key});
  @override
  State<SpecialistPage> createState() => _SpecialistPageState();
}

class _SpecialistPageState extends State<SpecialistPage> {
  final picker = ImagePicker();
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dyi7dglot/image/upload";
  final String uploadPreset = "medleaf_preset";
// Inside _SpecialistPageState class

  bool _isLoading = false; // Add this to your state variables
// 1. RESTORED: This opens the system file browser
// RESTORED: This forces the System File Browser (SAF)
  Future<void> _pickImageFromFiles() async {
    try {
      // Using FileType.any forces the Document UI/SAF
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;

        // Manual check to ensure it's an image
        final String ext = path.toLowerCase();
        if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.webp')) {

          // CORRECTION: No more Cloudinary here. Just navigate.
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlantScreen(
                  initialImageUrl: path, // Passing the LOCAL file path
                ),
              ),
            );
          }
        } else {
          _showErrorDialog("Please select a valid image file (JPG/PNG).");
        }
      }
    } catch (e) {
      debugPrint("File Picker Error: $e");
    }
  }
// 2. HELPER: Simple navigation without Cloudinary
  void _handleNavigation(XFile file) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(
          initialImageUrl: file.path, // Passing the LOCAL path
        ),
      ),
    );
  }

// 3. UPDATED: Source Logic
  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      await _pickImageFromFiles(); // Uses the File Browser
      return;
    }

    if (source == ImageSource.camera) {
      Position? location = await _getCurrentLocation();
      if (location == null) return;

      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        _handleNavigation(pickedFile);
      }
    }
  }




// NEW: This forces the System File Browser (SAF)
//   Future<void> _pickImageFromFiles() async {
//     try {
//       // Using FileType.any is the most reliable way to force the Document UI
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.any,
//       );
//
//       if (result != null && result.files.single.path != null) {
//         String path = result.files.single.path!;
//
//         // Manual check to ensure it's an image before Cloudinary upload
//         final String ext = path.toLowerCase();
//         if (ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png')) {
//           XFile pickedFile = XFile(path);
//           await _handleUploadAndNavigation(pickedFile);
//         } else {
//           _showErrorDialog("Please select a valid image file (JPG/PNG).");
//         }
//       }
//     } catch (e) {
//       debugPrint("File Picker Error: $e");
//     }
//   }

// Refactored helper for upload and navigation
//   Future<void> _handleUploadAndNavigation(XFile file) async {
//     setState(() => _isLoading = true);
//     String? imageUrl = await _uploadToCloudinary(file);
//     setState(() => _isLoading = false);
//
//     if (imageUrl != null && mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AddPlantScreen(
//             initialImageUrl: imageUrl,
//           ),
//         ),
//       );
//     } else {
//       _showErrorDialog("Image upload failed. Please try again.");
//     }
//   }

// Update the source logic
//   Future<void> _pickImage(ImageSource source) async {
//     if (source == ImageSource.gallery) {
//       await _pickImageFromFiles(); // Call the SAF picker
//       return;
//     }
//
//     if (source == ImageSource.camera) {
//       Position? location = await _getCurrentLocation();
//       if (location == null) return;
//
//       final pickedFile = await picker.pickImage(source: source);
//       if (pickedFile != null) {
//         await _handleUploadAndNavigation(pickedFile);
//       }
//     }
//   }

  // /// Opens the image picker and handles location for camera source.
  // Future<void> _pickImage(ImageSource source) async {
  //   Position? location; // Variable to hold location data
  //
  //   // Check if source is camera, then get location
  //   if (source == ImageSource.camera) {
  //     location = await _getCurrentLocation();
  //     if (location == null) {
  //       // Stop if the user cancels or fails to provide location
  //       return;
  //     }
  //     // NEW: For verification, print the location to the console
  //     debugPrint("Location captured: Lat: ${location.latitude}, Lng: ${location.longitude}");
  //   }
  //
  //   final pickedFile = await picker.pickImage(source: source);
  //   if (pickedFile != null) {
  //     String? imageUrl = await _uploadToCloudinary(pickedFile);
  //
  //     if (imageUrl != null && mounted) {
  //       // MODIFIED: Navigate WITHOUT the location data, as requested.
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => AddPlantScreen(
  //             initialImageUrl: imageUrl,
  //           ),
  //         ),
  //       );
  //     } else {
  //       _showErrorDialog("Image upload failed. Please try again.");
  //     }
  //   }
  // }

  /// Uploads the selected file to Cloudinary and returns the secure URL.
  // Future<String?> _uploadToCloudinary(XFile pickedFile) async {
  //   try {
  //     final bytes = await pickedFile.readAsBytes();
  //     var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
  //       ..fields['upload_preset'] = uploadPreset
  //       ..files.add(http.MultipartFile.fromBytes(
  //         'file',
  //         bytes,
  //         filename: pickedFile.name,
  //       ));
  //
  //     var response = await request.send();
  //     if (response.statusCode == 200) {
  //       var responseData = await response.stream.bytesToString();
  //       var jsonData = json.decode(responseData);
  //       return jsonData['secure_url'];
  //     } else {
  //       debugPrint("Cloudinary upload failed: ${response.statusCode}");
  //       final errorBody = await response.stream.bytesToString();
  //       debugPrint("Error body: $errorBody");
  //       return null;
  //     }
  //   } catch (e) {
  //     debugPrint("Cloudinary upload error: $e");
  //     return null;
  //   }
  // }

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


  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out? Any unsaved progress will be lost."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // 1. Close the dialog
                Navigator.of(context).pop();

                // 2. Perform logout logic
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();

                // 3. Clear stack and go to RoleSelectionPage (or your initial route)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
                        (route) => false,
                  );
                }
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Specialist Dashboard')),
      appBar: widget.showAppBar ? AppBar(
        title: const Text('Specialist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmation(context),
            // onPressed: () async {
            //   // 1. Call the logout method from your AuthProvider
            //   await Provider.of<AuthProvider>(context, listen: false).logout();
            //
            //   // 2. Navigate back to the initial screen (Role Selection or Login)
            //   // pushAndRemoveUntil ensures the user cannot go "back" to the dashboard
            //   if (mounted) {
            //     Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            //   }
            // },
          ),
        ],
      ): null,
      // body: Padding(
      //   padding: const EdgeInsets.all(24.0),
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       _buildOptionCard(
      //         icon: Icons.document_scanner_outlined,
      //         label: 'Scan or Upload Plant',
      //         onTap: _showImageSourceDialog,
      //       ),
      //       const SizedBox(height: 20),
      //       _buildOptionCard(
      //         icon: Icons.playlist_add_check,
      //         label: 'Verify Submissions',
      //         onTap: () {
      //           Navigator.of(context).push(
      //             MaterialPageRoute(builder: (context) => const VerificationListPage()),
      //           );
      //         },
      //       ),
      //     ],
      //   ),
      // ),
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
                  MaterialPageRoute(
                    builder: (context) => const VerificationListPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ✅ NEW CARD
            _buildOptionCard(
              icon: Icons.history,
              label: 'Upload History',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UploadHistoryPage(),
                  ),
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


