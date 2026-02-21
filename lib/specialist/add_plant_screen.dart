import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import '../core/config.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';


class AddPlantScreen extends StatefulWidget {
  final String? initialImageUrl;

  const AddPlantScreen({
    super.key,
    this.initialImageUrl,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // Controllers
  late final TextEditingController _commonNameController;
  late final TextEditingController _scientificNameController;
  late final TextEditingController _locationController;

  // State Variables
  String? _currentImagePath;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _commonNameController = TextEditingController();
    _scientificNameController = TextEditingController();
    _locationController = TextEditingController();

    _currentImagePath = widget.initialImageUrl;

    if (_currentImagePath != null) {
      _processLocation(_currentImagePath!);
    }
  }

  @override
  void dispose() {
    _commonNameController.dispose();
    _scientificNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ================= 1. PICKING LOGIC (Native UI) =================
  Future<void> _pickImageFromFiles() async {
    setState(() => _isLoading = true);
    try {
      // The trick: Use custom with a list that includes 'pdf' or 'txt'
      // but only actually let the user select images.
      // This often forces the 'File' view because the 'Photo' view
      // can't handle non-image extensions.
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        // This is the key: some versions of Android only show the
        // File Browser (2nd screen) if you don't use 'FileType.image'
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() => _currentImagePath = path);
        await _processLocation(path);
      }
    } catch (e) {
      debugPrint("File Picker Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        requestFullMetadata: true, // Prevents OS from stripping GPS tags
      );

      if (photo != null) {
        setState(() => _currentImagePath = photo.path);
        await _processLocation(photo.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= 2. LOCATION ORCHESTRATOR =================
  Future<void> _processLocation(String path) async {
    setState(() => _isLoading = true);
    try {
      String? coords;

      // First try to extract from the image metadata
      if (!kIsWeb) {
        coords = await _getCoordinatesFromExif(path);
      }

      // If EXIF has no GPS, fallback to the phone's live GPS
      if (coords == null) {
        debugPrint("📍 No EXIF GPS found, attempting Live GPS...");
        coords = await _getLiveCoordinates();
      }

      if (mounted && coords != null) {
        _locationController.text = coords;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 3. EXIF COORDINATE EXTRACTION =================
  Future<String?> _getCoordinatesFromExif(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('http')) {
        final res = await http.get(Uri.parse(path));
        bytes = res.bodyBytes;
      } else {
        final file = File(path);
        if (!await file.exists()) return null;
        bytes = await file.readAsBytes();
      }

      final exifData = await readExifFromBytes(bytes);
      exifData.forEach((key, value) {
        if (key.contains('GPS')) {
          debugPrint("Found Tag: $key = $value");
        }
      });

      // Some devices use different tag naming conventions
      final latTag = exifData['GPS GPSLatitude'];
      final latRef = exifData['GPS GPSLatitudeRef'];
      final lonTag = exifData['GPS GPSLongitude'];
      final lonRef = exifData['GPS GPSLongitudeRef'];


      if (latTag == null || lonTag == null || latRef == null || lonRef == null) {
        debugPrint("Metadata found, but GPS tags are missing.");
        return null;
      }

      double lat = _convertExifToDouble(latTag);
      double lon = _convertExifToDouble(lonTag);

      // Apply North/South and East/West references
      if (latRef.printable.contains('S')) lat = -lat;
      if (lonRef.printable.contains('W')) lon = -lon;

      return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
    } catch (e) {
      debugPrint("EXIF Extraction Error: $e");
      return null;
    }
  }
  // Future<String?> _getCoordinatesFromExif(String path) async {
  //   try {
  //     Uint8List bytes;
  //     if (path.startsWith('http')) {
  //       final res = await http.get(Uri.parse(path));
  //       bytes = res.bodyBytes;
  //     } else {
  //       bytes = await File(path).readAsBytes();
  //     }
  //
  //     final exifData = await readExifFromBytes(bytes);
  //
  //     final latTag = exifData['GPS GPSLatitude'];
  //     final lonTag = exifData['GPS GPSLongitude'];
  //
  //     if (latTag == null || lonTag == null) return null;
  //
  //     double lat = _convertExifToDouble(latTag);
  //     double lon = _convertExifToDouble(lonTag);
  //
  //     final latRef = exifData['GPS GPSLatitudeRef']?.printable ?? 'N';
  //     final lonRef = exifData['GPS GPSLongitudeRef']?.printable ?? 'E';
  //
  //     if (latRef.contains('S')) lat = -lat;
  //     if (lonRef.contains('W')) lon = -lon;
  //
  //     return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
  //   } catch (e) {
  //     debugPrint("EXIF Extraction Error: $e");
  //     return null;
  //   }
  // }

  // ================= 4. LIVE GPS COORDINATES =================
  Future<String?> _getLiveCoordinates() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return "Permission Denied";

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
    } catch (e) {
      debugPrint("Live GPS Error: $e");
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
  // Helper: Converts Exif Rational format to Double
  double _convertExifToDouble(IfdTag tag) {
    final values = tag.values.toList();
    double toDouble(Ratio r) => r.numerator / r.denominator;
    return toDouble(values[0]) + (toDouble(values[1]) / 60) + (toDouble(values[2]) / 3600);
  }
  Future<void> _uploadPlant() async {
    if (_currentImagePath == null) {
      _showErrorDialog("No image selected.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Construct the URI using your Config apiUrl
      final uri = Uri.parse('${Config.apiUrl}/plants/add');
      var request = http.MultipartRequest('POST', uri);

      final token = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).token;

      request.headers['Authorization'] = 'Bearer $token';


      // 1. Add the text data
      request.fields['common_name'] = _commonNameController.text.trim();
      request.fields['scientific_name'] = _scientificNameController.text.trim();
      request.fields['location'] = _locationController.text.trim();

      // 2. Add the LOCAL IMAGE file
      // 'image' must match request.files['image'] in your Python backend
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _currentImagePath!,
      ));

      // 3. Send to Python Backend
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Plant saved successfully to MongoDB!")),
          );
          Navigator.pop(context); // Return to Specialist Dashboard
        }
      } else {
        _showErrorDialog("Server Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      _showErrorDialog("An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ================= 5. UI BUILDING =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Plant'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 24),
            _buildField(_commonNameController, 'Common Name', Icons.local_florist),
            const SizedBox(height: 16),
            _buildField(_scientificNameController, 'Scientific Name', Icons.science, italic: true),
            const SizedBox(height: 16),
            _buildField(
              _locationController,
              'Coordinates (Lat, Lon)',
              Icons.gps_fixed,
              loading: _isLoading,
              suffix: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: () {
                  if (_currentImagePath != null) _processLocation(_currentImagePath!);
                },
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Disable button while loading to prevent double-taps
              onPressed: _isLoading ? null : _uploadPlant,
              child: _isLoading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
                  : const Text("SAVE TO MEDFLORA", style: TextStyle(fontWeight: FontWeight.bold)),
            )
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.green[700],
            //     foregroundColor: Colors.white,
            //     minimumSize: const Size(double.infinity, 54),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //   ),
            //   onPressed: _isLoading ? null : _uploadPlant,
            //   child: const Text("SAVE TO MEDFLORA", style: TextStyle(fontWeight: FontWeight.bold)),
            // )
          ],
        ),
      ),
    );
  }
  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () => _showPickerOptions(context),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          image: _currentImagePath != null
              ? DecorationImage(
            // Since it's a local path from SpecialistPage, we use FileImage
            image: FileImage(File(_currentImagePath!)),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: _currentImagePath == null
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("Tap to add plant image", style: TextStyle(color: Colors.grey)),
          ],
        )
            : null,
      ),
    );
  }
  // Widget _buildImagePreview() {
  //   return GestureDetector(
  //     onTap: () => _showPickerOptions(context),
  //     child: Container(
  //       height: 250,
  //       width: double.infinity,
  //       decoration: BoxDecoration(
  //         color: Colors.grey[200],
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(color: Colors.grey[300]!),
  //         image: _currentImagePath != null
  //             ? DecorationImage(
  //           image: _currentImagePath!.startsWith('http')
  //               ? NetworkImage(_currentImagePath!) as ImageProvider
  //               : FileImage(File(_currentImagePath!)),
  //           fit: BoxFit.cover,
  //         )
  //             : null,
  //       ),
  //       child: _currentImagePath == null
  //           ? const Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
  //           SizedBox(height: 8),
  //           Text("Tap to add plant image", style: TextStyle(color: Colors.grey)),
  //         ],
  //       )
  //           : null,
  //     ),
  //   );
  // }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                // _pickImage(ImageSource.gallery);
                _pickImageFromFiles(); // Use the new file picker here
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {bool italic = false, bool loading = false, Widget? suffix}) {
    return TextField(
      controller: c,
      readOnly: label.contains('Coordinates'), // Coordinates usually auto-filled
      style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: loading
            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
            : suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}


/// same as above before changes
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:exif/exif.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:file_picker/file_picker.dart';
//
// import '../core/config.dart';
//
// class AddPlantScreen extends StatefulWidget {
//   final String? initialImageUrl;
//
//   const AddPlantScreen({
//     super.key,
//     this.initialImageUrl,
//   });
//
//   @override
//   State<AddPlantScreen> createState() => _AddPlantScreenState();
// }
//
// class _AddPlantScreenState extends State<AddPlantScreen> {
//   // Controllers
//   late final TextEditingController _commonNameController;
//   late final TextEditingController _scientificNameController;
//   late final TextEditingController _locationController;
//
//   // State Variables
//   String? _currentImagePath;
//   bool _isLoading = false;
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     _commonNameController = TextEditingController();
//     _scientificNameController = TextEditingController();
//     _locationController = TextEditingController();
//
//     _currentImagePath = widget.initialImageUrl;
//
//     if (_currentImagePath != null) {
//       _processLocation(_currentImagePath!);
//     }
//   }
//
//   @override
//   void dispose() {
//     _commonNameController.dispose();
//     _scientificNameController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
//
//   // ================= 1. PICKING LOGIC (Native UI) =================
//   Future<void> _pickImageFromFiles() async {
//     setState(() => _isLoading = true);
//     try {
//       // The trick: Use custom with a list that includes 'pdf' or 'txt'
//       // but only actually let the user select images.
//       // This often forces the 'File' view because the 'Photo' view
//       // can't handle non-image extensions.
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
//         // This is the key: some versions of Android only show the
//         // File Browser (2nd screen) if you don't use 'FileType.image'
//       );
//
//       if (result != null && result.files.single.path != null) {
//         final path = result.files.single.path!;
//         setState(() => _currentImagePath = path);
//         await _processLocation(path);
//       }
//     } catch (e) {
//       debugPrint("File Picker Error: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//   Future<void> _pickImage(ImageSource source) async {
//     setState(() => _isLoading = true);
//     try {
//       final XFile? photo = await _picker.pickImage(
//         source: source,
//         requestFullMetadata: true, // Prevents OS from stripping GPS tags
//       );
//
//       if (photo != null) {
//         setState(() => _currentImagePath = photo.path);
//         await _processLocation(photo.path);
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // ================= 2. LOCATION ORCHESTRATOR =================
//   Future<void> _processLocation(String path) async {
//     setState(() => _isLoading = true);
//     try {
//       String? coords;
//
//       // First try to extract from the image metadata
//       if (!kIsWeb) {
//         coords = await _getCoordinatesFromExif(path);
//       }
//
//       // If EXIF has no GPS, fallback to the phone's live GPS
//       if (coords == null) {
//         debugPrint("📍 No EXIF GPS found, attempting Live GPS...");
//         coords = await _getLiveCoordinates();
//       }
//
//       if (mounted && coords != null) {
//         _locationController.text = coords;
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   // ================= 3. EXIF COORDINATE EXTRACTION =================
//   Future<String?> _getCoordinatesFromExif(String path) async {
//     try {
//       Uint8List bytes;
//       if (path.startsWith('http')) {
//         final res = await http.get(Uri.parse(path));
//         bytes = res.bodyBytes;
//       } else {
//         final file = File(path);
//         if (!await file.exists()) return null;
//         bytes = await file.readAsBytes();
//       }
//
//       final exifData = await readExifFromBytes(bytes);
//       exifData.forEach((key, value) {
//         if (key.contains('GPS')) {
//           debugPrint("Found Tag: $key = $value");
//         }
//       });
//
//       // Some devices use different tag naming conventions
//       final latTag = exifData['GPS GPSLatitude'];
//       final latRef = exifData['GPS GPSLatitudeRef'];
//       final lonTag = exifData['GPS GPSLongitude'];
//       final lonRef = exifData['GPS GPSLongitudeRef'];
//
//
//       if (latTag == null || lonTag == null || latRef == null || lonRef == null) {
//         debugPrint("Metadata found, but GPS tags are missing.");
//         return null;
//       }
//
//       double lat = _convertExifToDouble(latTag);
//       double lon = _convertExifToDouble(lonTag);
//
//       // Apply North/South and East/West references
//       if (latRef.printable.contains('S')) lat = -lat;
//       if (lonRef.printable.contains('W')) lon = -lon;
//
//       return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
//     } catch (e) {
//       debugPrint("EXIF Extraction Error: $e");
//       return null;
//     }
//   }
//   // Future<String?> _getCoordinatesFromExif(String path) async {
//   //   try {
//   //     Uint8List bytes;
//   //     if (path.startsWith('http')) {
//   //       final res = await http.get(Uri.parse(path));
//   //       bytes = res.bodyBytes;
//   //     } else {
//   //       bytes = await File(path).readAsBytes();
//   //     }
//   //
//   //     final exifData = await readExifFromBytes(bytes);
//   //
//   //     final latTag = exifData['GPS GPSLatitude'];
//   //     final lonTag = exifData['GPS GPSLongitude'];
//   //
//   //     if (latTag == null || lonTag == null) return null;
//   //
//   //     double lat = _convertExifToDouble(latTag);
//   //     double lon = _convertExifToDouble(lonTag);
//   //
//   //     final latRef = exifData['GPS GPSLatitudeRef']?.printable ?? 'N';
//   //     final lonRef = exifData['GPS GPSLongitudeRef']?.printable ?? 'E';
//   //
//   //     if (latRef.contains('S')) lat = -lat;
//   //     if (lonRef.contains('W')) lon = -lon;
//   //
//   //     return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
//   //   } catch (e) {
//   //     debugPrint("EXIF Extraction Error: $e");
//   //     return null;
//   //   }
//   // }
//
//   // ================= 4. LIVE GPS COORDINATES =================
//   Future<String?> _getLiveCoordinates() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.deniedForever) return "Permission Denied";
//
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       return "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
//     } catch (e) {
//       debugPrint("Live GPS Error: $e");
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
//   // Helper: Converts Exif Rational format to Double
//   double _convertExifToDouble(IfdTag tag) {
//     final values = tag.values.toList();
//     double toDouble(Ratio r) => r.numerator / r.denominator;
//     return toDouble(values[0]) + (toDouble(values[1]) / 60) + (toDouble(values[2]) / 3600);
//   }
//   Future<void> _uploadPlant() async {
//     if (_currentImagePath == null) {
//       _showErrorDialog("No image selected.");
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       // Construct the URI using your Config apiUrl
//       final uri = Uri.parse('${Config.apiUrl}/plants/add');
//       var request = http.MultipartRequest('POST', uri);
//
//       // 1. Add the text data
//       request.fields['common_name'] = _commonNameController.text.trim();
//       request.fields['scientific_name'] = _scientificNameController.text.trim();
//       request.fields['location'] = _locationController.text.trim();
//
//       // 2. Add the LOCAL IMAGE file
//       // 'image' must match request.files['image'] in your Python backend
//       request.files.add(await http.MultipartFile.fromPath(
//         'image',
//         _currentImagePath!,
//       ));
//
//       // 3. Send to Python Backend
//       var streamedResponse = await request.send();
//       var response = await http.Response.fromStream(streamedResponse);
//
//       if (response.statusCode == 201) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("✅ Plant saved successfully to MongoDB!")),
//           );
//           Navigator.pop(context); // Return to Specialist Dashboard
//         }
//       } else {
//         _showErrorDialog("Server Error (${response.statusCode}): ${response.body}");
//       }
//     } catch (e) {
//       debugPrint("Upload Error: $e");
//       _showErrorDialog("An error occurred: $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//   // ================= 5. UI BUILDING =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add New Plant'),
//         backgroundColor: Colors.green[700],
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             _buildImagePreview(),
//             const SizedBox(height: 24),
//             _buildField(_commonNameController, 'Common Name', Icons.local_florist),
//             const SizedBox(height: 16),
//             _buildField(_scientificNameController, 'Scientific Name', Icons.science, italic: true),
//             const SizedBox(height: 16),
//             _buildField(
//               _locationController,
//               'Coordinates (Lat, Lon)',
//               Icons.gps_fixed,
//               loading: _isLoading,
//               suffix: IconButton(
//                 icon: const Icon(Icons.my_location),
//                 onPressed: () {
//                   if (_currentImagePath != null) _processLocation(_currentImagePath!);
//                 },
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green[700],
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 54),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               // Disable button while loading to prevent double-taps
//               onPressed: _isLoading ? null : _uploadPlant,
//               child: _isLoading
//                   ? const SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
//               )
//                   : const Text("SAVE TO MEDFLORA", style: TextStyle(fontWeight: FontWeight.bold)),
//             )
//             // ElevatedButton(
//             //   style: ElevatedButton.styleFrom(
//             //     backgroundColor: Colors.green[700],
//             //     foregroundColor: Colors.white,
//             //     minimumSize: const Size(double.infinity, 54),
//             //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             //   ),
//             //   onPressed: _isLoading ? null : _uploadPlant,
//             //   child: const Text("SAVE TO MEDFLORA", style: TextStyle(fontWeight: FontWeight.bold)),
//             // )
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _buildImagePreview() {
//     return GestureDetector(
//       onTap: () => _showPickerOptions(context),
//       child: Container(
//         height: 250,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey[300]!),
//           image: _currentImagePath != null
//               ? DecorationImage(
//             // Since it's a local path from SpecialistPage, we use FileImage
//             image: FileImage(File(_currentImagePath!)),
//             fit: BoxFit.cover,
//           )
//               : null,
//         ),
//         child: _currentImagePath == null
//             ? const Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
//             SizedBox(height: 8),
//             Text("Tap to add plant image", style: TextStyle(color: Colors.grey)),
//           ],
//         )
//             : null,
//       ),
//     );
//   }
//   // Widget _buildImagePreview() {
//   //   return GestureDetector(
//   //     onTap: () => _showPickerOptions(context),
//   //     child: Container(
//   //       height: 250,
//   //       width: double.infinity,
//   //       decoration: BoxDecoration(
//   //         color: Colors.grey[200],
//   //         borderRadius: BorderRadius.circular(16),
//   //         border: Border.all(color: Colors.grey[300]!),
//   //         image: _currentImagePath != null
//   //             ? DecorationImage(
//   //           image: _currentImagePath!.startsWith('http')
//   //               ? NetworkImage(_currentImagePath!) as ImageProvider
//   //               : FileImage(File(_currentImagePath!)),
//   //           fit: BoxFit.cover,
//   //         )
//   //             : null,
//   //       ),
//   //       child: _currentImagePath == null
//   //           ? const Column(
//   //         mainAxisAlignment: MainAxisAlignment.center,
//   //         children: [
//   //           Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
//   //           SizedBox(height: 8),
//   //           Text("Tap to add plant image", style: TextStyle(color: Colors.grey)),
//   //         ],
//   //       )
//   //           : null,
//   //     ),
//   //   );
//   // }
//
//   void _showPickerOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () {
//                 // _pickImage(ImageSource.gallery);
//                 _pickImageFromFiles(); // Use the new file picker here
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () {
//                 _pickImage(ImageSource.camera);
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildField(TextEditingController c, String label, IconData icon, {bool italic = false, bool loading = false, Widget? suffix}) {
//     return TextField(
//       controller: c,
//       readOnly: label.contains('Coordinates'), // Coordinates usually auto-filled
//       style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         suffixIcon: loading
//             ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
//             : suffix,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//     );
//   }
// }



/// NOSAVE To mongo other same code as above
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:exif/exif.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:file_picker/file_picker.dart';
//
// class AddPlantScreen extends StatefulWidget {
//   final String? initialImageUrl;
//
//   const AddPlantScreen({
//     super.key,
//     this.initialImageUrl,
//   });
//
//   @override
//   State<AddPlantScreen> createState() => _AddPlantScreenState();
// }
//
// class _AddPlantScreenState extends State<AddPlantScreen> {
//   // Controllers
//   late final TextEditingController _commonNameController;
//   late final TextEditingController _scientificNameController;
//   late final TextEditingController _locationController;
//
//   // State Variables
//   String? _currentImagePath;
//   bool _isLoading = false;
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     _commonNameController = TextEditingController();
//     _scientificNameController = TextEditingController();
//     _locationController = TextEditingController();
//
//     _currentImagePath = widget.initialImageUrl;
//
//     if (_currentImagePath != null) {
//       _processLocation(_currentImagePath!);
//     }
//   }
//
//   @override
//   void dispose() {
//     _commonNameController.dispose();
//     _scientificNameController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
//
//   // ================= 1. PICKING LOGIC (Native UI) =================
//   Future<void> _pickImageFromFiles() async {
//     setState(() => _isLoading = true);
//     try {
//       // The trick: Use custom with a list that includes 'pdf' or 'txt'
//       // but only actually let the user select images.
//       // This often forces the 'File' view because the 'Photo' view
//       // can't handle non-image extensions.
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
//         // This is the key: some versions of Android only show the
//         // File Browser (2nd screen) if you don't use 'FileType.image'
//       );
//
//       if (result != null && result.files.single.path != null) {
//         final path = result.files.single.path!;
//         setState(() => _currentImagePath = path);
//         await _processLocation(path);
//       }
//     } catch (e) {
//       debugPrint("File Picker Error: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//   Future<void> _pickImage(ImageSource source) async {
//     setState(() => _isLoading = true);
//     try {
//       final XFile? photo = await _picker.pickImage(
//         source: source,
//         requestFullMetadata: true, // Prevents OS from stripping GPS tags
//       );
//
//       if (photo != null) {
//         setState(() => _currentImagePath = photo.path);
//         await _processLocation(photo.path);
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // ================= 2. LOCATION ORCHESTRATOR =================
//   Future<void> _processLocation(String path) async {
//     setState(() => _isLoading = true);
//     try {
//       String? coords;
//
//       // First try to extract from the image metadata
//       if (!kIsWeb) {
//         coords = await _getCoordinatesFromExif(path);
//       }
//
//       // If EXIF has no GPS, fallback to the phone's live GPS
//       if (coords == null) {
//         debugPrint("📍 No EXIF GPS found, attempting Live GPS...");
//         coords = await _getLiveCoordinates();
//       }
//
//       if (mounted && coords != null) {
//         _locationController.text = coords;
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   // ================= 3. EXIF COORDINATE EXTRACTION =================
//   Future<String?> _getCoordinatesFromExif(String path) async {
//     try {
//       Uint8List bytes;
//       if (path.startsWith('http')) {
//         final res = await http.get(Uri.parse(path));
//         bytes = res.bodyBytes;
//       } else {
//         final file = File(path);
//         if (!await file.exists()) return null;
//         bytes = await file.readAsBytes();
//       }
//
//       final exifData = await readExifFromBytes(bytes);
//       exifData.forEach((key, value) {
//         if (key.contains('GPS')) {
//           debugPrint("Found Tag: $key = $value");
//         }
//       });
//
//       // Some devices use different tag naming conventions
//       final latTag = exifData['GPS GPSLatitude'];
//       final latRef = exifData['GPS GPSLatitudeRef'];
//       final lonTag = exifData['GPS GPSLongitude'];
//       final lonRef = exifData['GPS GPSLongitudeRef'];
//
//
//       if (latTag == null || lonTag == null || latRef == null || lonRef == null) {
//         debugPrint("Metadata found, but GPS tags are missing.");
//         return null;
//       }
//
//       double lat = _convertExifToDouble(latTag);
//       double lon = _convertExifToDouble(lonTag);
//
//       // Apply North/South and East/West references
//       if (latRef.printable.contains('S')) lat = -lat;
//       if (lonRef.printable.contains('W')) lon = -lon;
//
//       return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
//     } catch (e) {
//       debugPrint("EXIF Extraction Error: $e");
//       return null;
//     }
//   }
//   // Future<String?> _getCoordinatesFromExif(String path) async {
//   //   try {
//   //     Uint8List bytes;
//   //     if (path.startsWith('http')) {
//   //       final res = await http.get(Uri.parse(path));
//   //       bytes = res.bodyBytes;
//   //     } else {
//   //       bytes = await File(path).readAsBytes();
//   //     }
//   //
//   //     final exifData = await readExifFromBytes(bytes);
//   //
//   //     final latTag = exifData['GPS GPSLatitude'];
//   //     final lonTag = exifData['GPS GPSLongitude'];
//   //
//   //     if (latTag == null || lonTag == null) return null;
//   //
//   //     double lat = _convertExifToDouble(latTag);
//   //     double lon = _convertExifToDouble(lonTag);
//   //
//   //     final latRef = exifData['GPS GPSLatitudeRef']?.printable ?? 'N';
//   //     final lonRef = exifData['GPS GPSLongitudeRef']?.printable ?? 'E';
//   //
//   //     if (latRef.contains('S')) lat = -lat;
//   //     if (lonRef.contains('W')) lon = -lon;
//   //
//   //     return "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
//   //   } catch (e) {
//   //     debugPrint("EXIF Extraction Error: $e");
//   //     return null;
//   //   }
//   // }
//
//   // ================= 4. LIVE GPS COORDINATES =================
//   Future<String?> _getLiveCoordinates() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.deniedForever) return "Permission Denied";
//
//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       return "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
//     } catch (e) {
//       debugPrint("Live GPS Error: $e");
//       return null;
//     }
//   }
//
//   // Helper: Converts Exif Rational format to Double
//   double _convertExifToDouble(IfdTag tag) {
//     final values = tag.values.toList();
//     double toDouble(Ratio r) => r.numerator / r.denominator;
//     return toDouble(values[0]) + (toDouble(values[1]) / 60) + (toDouble(values[2]) / 3600);
//   }
//
//   // ================= 5. UI BUILDING =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add New Plant'),
//         backgroundColor: Colors.green[700],
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             _buildImagePreview(),
//             const SizedBox(height: 24),
//             _buildField(_commonNameController, 'Common Name', Icons.local_florist),
//             const SizedBox(height: 16),
//             _buildField(_scientificNameController, 'Scientific Name', Icons.science, italic: true),
//             const SizedBox(height: 16),
//             _buildField(
//               _locationController,
//               'Coordinates (Lat, Lon)',
//               Icons.gps_fixed,
//               loading: _isLoading,
//               suffix: IconButton(
//                 icon: const Icon(Icons.my_location),
//                 onPressed: () {
//                   if (_currentImagePath != null) _processLocation(_currentImagePath!);
//                 },
//               ),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green[700],
//                 foregroundColor: Colors.white,
//                 minimumSize: const Size(double.infinity, 54),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: () {
//                 // Handle your MedFlora API upload here
//               },
//               child: const Text("SAVE TO MEDFLORA", style: TextStyle(fontWeight: FontWeight.bold)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImagePreview() {
//     return GestureDetector(
//       onTap: () => _showPickerOptions(context),
//       child: Container(
//         height: 250,
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Colors.grey[200],
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey[300]!),
//           image: _currentImagePath != null
//               ? DecorationImage(
//             image: _currentImagePath!.startsWith('http')
//                 ? NetworkImage(_currentImagePath!) as ImageProvider
//                 : FileImage(File(_currentImagePath!)),
//             fit: BoxFit.cover,
//           )
//               : null,
//         ),
//         child: _currentImagePath == null
//             ? const Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
//             SizedBox(height: 8),
//             Text("Tap to add plant image", style: TextStyle(color: Colors.grey)),
//           ],
//         )
//             : null,
//       ),
//     );
//   }
//
//   void _showPickerOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () {
//                 // _pickImage(ImageSource.gallery);
//                 _pickImageFromFiles(); // Use the new file picker here
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () {
//                 _pickImage(ImageSource.camera);
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildField(TextEditingController c, String label, IconData icon, {bool italic = false, bool loading = false, Widget? suffix}) {
//     return TextField(
//       controller: c,
//       readOnly: label.contains('Coordinates'), // Coordinates usually auto-filled
//       style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         suffixIcon: loading
//             ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
//             : suffix,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//     );
//   }
// }
//
//


/// WORKS!!!! no save
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:exif/exif.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
//
// class AddPlantScreen extends StatefulWidget {
//   final String? initialImageUrl; // Can be null if we haven't picked yet
//
//   const AddPlantScreen({
//     super.key,
//     this.initialImageUrl,
//   });
//
//   @override
//   State<AddPlantScreen> createState() => _AddPlantScreenState();
// }
//
// class _AddPlantScreenState extends State<AddPlantScreen> {
//   late final TextEditingController _commonNameController;
//   late final TextEditingController _scientificNameController;
//   late final TextEditingController _locationController;
//
//   String? _currentImagePath;
//   bool _isLoading = false;
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     _commonNameController = TextEditingController();
//     _scientificNameController = TextEditingController();
//     _locationController = TextEditingController();
//     _currentImagePath = widget.initialImageUrl;
//
//     if (_currentImagePath != null) {
//       _processImageLocation(_currentImagePath!);
//     }
//   }
//
//   @override
//   void dispose() {
//     _commonNameController.dispose();
//     _scientificNameController.dispose();
//     _locationController.dispose();
//     super.dispose();
//   }
//
//   // ================= PICKING LOGIC (The New Part) =================
//   Future<void> _pickImage(ImageSource source) async {
//     setState(() => _isLoading = true);
//     try {
//       final XFile? photo = await _picker.pickImage(
//         source: source,
//         requestFullMetadata: true, // Key: prevents OS from stripping EXIF
//       );
//
//       if (photo != null) {
//         setState(() => _currentImagePath = photo.path);
//         await _processImageLocation(photo.path);
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // ================= LOCATION PROCESSING =================
//   Future<void> _processImageLocation(String path) async {
//     setState(() => _isLoading = true);
//     try {
//       String? detectedLocation;
//
//       // 1. Try EXIF
//       if (!kIsWeb) {
//         detectedLocation = await _getLocationFromExif(path);
//       }
//
//       // 2. Fallback to Live GPS if EXIF fails or is missing
//       if (detectedLocation == null) {
//         debugPrint("📍 No EXIF GPS found, attempting Live GPS...");
//         detectedLocation = await _getLiveLocation();
//       }
//
//       if (mounted && detectedLocation != null) {
//         _locationController.text = detectedLocation;
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<String?> _getLocationFromExif(String path) async {
//     try {
//       Uint8List bytes;
//       if (path.startsWith('http')) {
//         final res = await http.get(Uri.parse(path));
//         bytes = res.bodyBytes;
//       } else {
//         bytes = await File(path).readAsBytes();
//       }
//
//       final exifData = await readExifFromBytes(bytes);
//
//       final latTag = exifData['GPS GPSLatitude'];
//       final lonTag = exifData['GPS GPSLongitude'];
//
//       if (latTag == null || lonTag == null) return null;
//
//       double lat = _convertExifToDouble(latTag);
//       double lon = _convertExifToDouble(lonTag);
//
//       final latRef = exifData['GPS GPSLatitudeRef']?.printable ?? 'N';
//       final lonRef = exifData['GPS GPSLongitudeRef']?.printable ?? 'E';
//
//       if (latRef.contains('S')) lat = -lat;
//       if (lonRef.contains('W')) lon = -lon;
//
//       final placemarks = await placemarkFromCoordinates(lat, lon);
//       if (placemarks.isEmpty) return "${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}";
//
//       final p = placemarks.first;
//       return "${p.locality}, ${p.administrativeArea}, ${p.country}";
//     } catch (e) {
//       debugPrint("EXIF Error: $e");
//       return null;
//     }
//   }
//
//   Future<String?> _getLiveLocation() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.deniedForever) return "Permission Denied";
//
//     final pos = await Geolocator.getCurrentPosition();
//     final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
//
//     if (placemarks.isEmpty) return "${pos.latitude}, ${pos.longitude}";
//     final p = placemarks.first;
//     return "${p.locality}, ${p.administrativeArea}, ${p.country}";
//   }
//
//   double _convertExifToDouble(IfdTag tag) {
//     final values = tag.values.toList();
//     double toDouble(Ratio r) => r.numerator / r.denominator;
//     return toDouble(values[0]) + (toDouble(values[1]) / 60) + (toDouble(values[2]) / 3600);
//   }
//
//   // ================= UI BUILDER =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Add New Plant')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             // Image Preview Area
//             GestureDetector(
//               onTap: () => _showPickerOptions(context),
//               child: Container(
//                 height: 250,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(16),
//                   image: _currentImagePath != null
//                       ? DecorationImage(
//                     image: _currentImagePath!.startsWith('http')
//                         ? NetworkImage(_currentImagePath!) as ImageProvider
//                         : FileImage(File(_currentImagePath!)),
//                     fit: BoxFit.cover,
//                   )
//                       : null,
//                 ),
//                 child: _currentImagePath == null
//                     ? const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
//                     Text("Tap to add image"),
//                   ],
//                 )
//                     : null,
//               ),
//             ),
//             const SizedBox(height: 24),
//             _field(_commonNameController, 'Common Name', Icons.local_florist),
//             const SizedBox(height: 16),
//             _field(_scientificNameController, 'Scientific Name', Icons.science, italic: true),
//             const SizedBox(height: 16),
//             _field(
//               _locationController,
//               'Location',
//               Icons.pin_drop,
//               loading: _isLoading,
//               suffix: IconButton(
//                 icon: const Icon(Icons.my_location),
//                 onPressed: () => _processImageLocation(_currentImagePath ?? ""),
//               ),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
//               onPressed: () { /* Submit Logic */ },
//               child: const Text("Save Plant"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showPickerOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () {
//                 _pickImage(ImageSource.gallery);
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () {
//                 _pickImage(ImageSource.camera);
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _field(TextEditingController c, String label, IconData icon, {bool italic = false, bool loading = false, Widget? suffix}) {
//     return TextField(
//       controller: c,
//       style: italic ? const TextStyle(fontStyle: FontStyle.italic) : null,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         suffixIcon: loading
//             ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
//             : suffix,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
// }
//




/// Sinlge attribute code
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// // Converted to a StatefulWidget to better handle form inputs later.
// class AddPlantScreen extends StatefulWidget {
//   // 1. This final variable holds the URL passed from the previous page.
//   final String imageUrl;
//
//   // 2. The constructor now correctly requires the imageUrl.
//   const AddPlantScreen({super.key, required this.imageUrl});
//
//   @override
//   State<AddPlantScreen> createState() => _AddPlantScreenState();
// }
//
// class _AddPlantScreenState extends State<AddPlantScreen> {
//   // It's good practice to manage text fields with controllers.
//   late final TextEditingController _plantNameController;
//
//   @override
//   void initState() {
//     super.initState();
//     _plantNameController = TextEditingController();
//   }
//
//   @override
//   void dispose() {
//     // Clean up the controller when the widget is removed from the tree.
//     _plantNameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add New Plant'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Display for the uploaded image
//             Container(
//               height: 200,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300, width: 1.5),
//                 image: DecorationImage(
//                   // 3. Use the passed-in imageUrl here via `widget.imageUrl`
//                   image: NetworkImage(widget.imageUrl),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               // Add a loading indicator while the network image loads
//               child: Center(
//                 child: widget.imageUrl.isEmpty
//                     ? const Icon(Icons.error, color: Colors.red)
//                     : const SizedBox.shrink(),
//               ),
//             ),
//             const SizedBox(height: 32),
//
//             // Plant Name Input Field
//             _buildTextField(
//               controller: _plantNameController,
//               label: 'Plant Name',
//               hint: 'e.g., Aloe Vera',
//             ),
//             const SizedBox(height: 40),
//
//             // Save Button
//             ElevatedButton(
//               onPressed: () {
//                 // You can get the plant name like this:
//                 final plantName = _plantNameController.text;
//                 print('Saving plant: $plantName with image: ${widget.imageUrl}');
//                 // TODO: Add logic to save the plant name and image URL
//                 Navigator.of(context).pop(); // Go back after saving
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Helper widget to create a styled text field.
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.lato(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller, // Use the controller here
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: Colors.white.withOpacity(0.7),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//



/// OLD code
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class AddPlantScreen extends StatelessWidget {
//   const AddPlantScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add New Plant'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Display for the "already uploaded" image
//             Container(
//               height: 200,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.shade300, width: 1.5),
//                 image: const DecorationImage(
//                   // Using the static asset as a placeholder
//                   image: NetworkImage(
//                     'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=600&q=80',
//                   ),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 32),
//
//             // Plant Name Input Field
//             _buildTextField(label: 'Plant Name', hint: 'e.g., Carrot'),
//             const SizedBox(height: 40),
//
//             // Save Button
//             ElevatedButton(
//               onPressed: () {
//                 // TODO: Add logic to save the plant name
//                 Navigator.of(context).pop(); // Go back after saving
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Helper widget to create a styled text field.
//   Widget _buildTextField({required String label, required String hint}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.lato(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           decoration: InputDecoration(
//             hintText: hint,
//             filled: true,
//             fillColor: Colors.white.withOpacity(0.7),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
