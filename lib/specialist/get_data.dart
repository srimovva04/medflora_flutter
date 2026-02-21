import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Standard Native UI
import 'package:exif/exif.dart';

class FullMetadataPage extends StatefulWidget {
  const FullMetadataPage({super.key});

  @override
  State<FullMetadataPage> createState() => _FullMetadataPageState();
}

class _FullMetadataPageState extends State<FullMetadataPage> {
  Map<String, IfdTag> _allTags = {};
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      // pickImage opens the NATIVE system UI (Normal phone UI)
      final XFile? photo = await _picker.pickImage(
        source: source,
        // Crucial: This tells the OS not to strip metadata
        requestFullMetadata: true,
      );

      if (photo != null) {
        final bytes = await File(photo.path).readAsBytes();
        final tags = await readExifFromBytes(bytes);

        setState(() {
          _allTags = tags;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Native Metadata Picker")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Native Gallery"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Native Camera"),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _allTags.length,
              itemBuilder: (context, index) {
                String key = _allTags.keys.elementAt(index);
                return ListTile(
                  title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text(_allTags[key].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}