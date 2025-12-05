import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Converted to a StatefulWidget to better handle form inputs later.
class AddPlantScreen extends StatefulWidget {
  // 1. This final variable holds the URL passed from the previous page.
  final String imageUrl;

  // 2. The constructor now correctly requires the imageUrl.
  const AddPlantScreen({super.key, required this.imageUrl});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // It's good practice to manage text fields with controllers.
  late final TextEditingController _plantNameController;

  @override
  void initState() {
    super.initState();
    _plantNameController = TextEditingController();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the tree.
    _plantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Plant'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display for the uploaded image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                image: DecorationImage(
                  // 3. Use the passed-in imageUrl here via `widget.imageUrl`
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              // Add a loading indicator while the network image loads
              child: Center(
                child: widget.imageUrl.isEmpty
                    ? const Icon(Icons.error, color: Colors.red)
                    : const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 32),

            // Plant Name Input Field
            _buildTextField(
              controller: _plantNameController,
              label: 'Plant Name',
              hint: 'e.g., Aloe Vera',
            ),
            const SizedBox(height: 40),

            // Save Button
            ElevatedButton(
              onPressed: () {
                // You can get the plant name like this:
                final plantName = _plantNameController.text;
                print('Saving plant: $plantName with image: ${widget.imageUrl}');
                // TODO: Add logic to save the plant name and image URL
                Navigator.of(context).pop(); // Go back after saving
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget to create a styled text field.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // Use the controller here
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}



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
