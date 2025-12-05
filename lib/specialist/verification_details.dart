import 'package:flutter/material.dart';

// --- THEME COLORS ---
const Color kScaffoldBackground = Color(0xFFF7F9F5);
const Color kPrimaryTextColor = Color(0xFF3D5245);
const Color kCardBackground = Color(0xFFEBF1E8);
const Color kIconBackground = Color(0xFFDDE6D9);
const Color kTextFieldBackground = Color(0xFFF0F0F0);

class VerificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> submissionData;

  const VerificationDetailPage({super.key, required this.submissionData});

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> suggestions = widget.submissionData['suggestions'] ?? [];

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Verify #${widget.submissionData['id']}',
          style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kScaffoldBackground,
        foregroundColor: kPrimaryTextColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                widget.submissionData['imageUrl'],
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // --- NEW REFINED INFO CARDS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildBetterInfoBlock(
                    icon: Icons.label_important_outline,
                    title: 'Predicted Name',
                    description: widget.submissionData['submittedName'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBetterInfoBlock(
                    icon: Icons.star_rate_rounded,
                    title: 'Score',
                    description: widget.submissionData['score'],
                  ),
                ),
              ],
            ),

            _buildSuggestionsSection(suggestions),
            const SizedBox(height: 15),

            TextField(
              controller: _nameController,
              cursorColor: kPrimaryTextColor,
              decoration: InputDecoration(
                labelText: 'Enter Correct Plant Name',
                labelStyle: const TextStyle(color: kPrimaryTextColor),
                filled: true,
                fillColor: kTextFieldBackground,
                prefixIcon: const Icon(Icons.eco_outlined, color: kPrimaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: kPrimaryTextColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final enteredName = _nameController.text;
                if (enteredName.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification submitted for: $enteredName')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryTextColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Submit Verification', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODERNIZED INFO CARD WIDGET ---
  Widget _buildBetterInfoBlock({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Container(
          //   width: 45,
          //   height: 45,
          //   decoration: BoxDecoration(
          //     color: kIconBackground,
          //     borderRadius: BorderRadius.circular(10.0),
          //   ),
          //   // child: Icon(icon, color: kPrimaryTextColor, size: 22),
          // ),
          // const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: kPrimaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPrimaryTextColor.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(List<dynamic> suggestions) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          'AI Suggestions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return _buildSuggestionItem(
                imageUrl: suggestion['imageUrl']!,
                name: suggestion['name']!,
                score: suggestion['score']!,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem({
    required String imageUrl,
    required String name,
    required String score,
  }) {
    return SizedBox(
      width: 130,
      child: Card(
        color: kCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _nameController.text = name;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Match: $score',
                      style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}








/// WORKS
// import 'package:flutter/material.dart';
//
// // --- THEME COLORS ---
// const Color kScaffoldBackground = Color(0xFFF7F9F5);
// const Color kPrimaryTextColor = Color(0xFF3D5245);
// const Color kCardBackground = Color(0xFFEBF1E8);
// const Color kIconBackground = Color(0xFFDDE6D9);
// const Color kTextFieldBackground = Color(0xFFF0F0F0);
//
// class VerificationDetailPage extends StatefulWidget {
//   final Map<String, dynamic> submissionData;
//
//   const VerificationDetailPage({super.key, required this.submissionData});
//
//   @override
//   State<VerificationDetailPage> createState() => _VerificationDetailPageState();
// }
//
// class _VerificationDetailPageState extends State<VerificationDetailPage> {
//   final TextEditingController _nameController = TextEditingController();
//
//   // --- REMOVE THE HARDCODED DUMMY DATA ---
//   // The 'similarSuggestions' list is no longer needed here.
//   // It will come from widget.submissionData.
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // --- ACCESS THE DYNAMIC SUGGESTIONS LIST ---
//     final List<dynamic> suggestions = widget.submissionData['suggestions'] ?? [];
//
//     return Scaffold(
//       backgroundColor: kScaffoldBackground,
//       appBar: AppBar(
//         title: Text(
//           'Verify #${widget.submissionData['id']}',
//           style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: kScaffoldBackground,
//         foregroundColor: kPrimaryTextColor,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12.0),
//               child: Image.network(
//                 widget.submissionData['imageUrl'],
//                 height: 250,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 250,
//                   color: Colors.grey[200],
//                   child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildInfoBlock(
//                     icon: Icons.label_important_outline,
//                     title: 'Predicted Name',
//                     description: widget.submissionData['submittedName'],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildInfoBlock(
//                     icon: Icons.star_border_rounded,
//                     title: 'Score',
//                     description: widget.submissionData['score'],
//                   ),
//                 ),
//               ],
//             ),
//
//             // --- PASS THE DYNAMIC LIST TO THE BUILD METHOD ---
//             _buildSuggestionsSection(suggestions),
//             const SizedBox(height: 32),
//
//             TextField(
//               controller: _nameController,
//               cursorColor: kPrimaryTextColor,
//               decoration: InputDecoration(
//                 labelText: 'Enter Correct Plant Name',
//                 labelStyle: const TextStyle(color: kPrimaryTextColor),
//                 filled: true,
//                 fillColor: kTextFieldBackground,
//                 prefixIcon: const Icon(Icons.eco_outlined, color: kPrimaryTextColor),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: const BorderSide(color: kPrimaryTextColor),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 final enteredName = _nameController.text;
//                 if (enteredName.isNotEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Verification submitted for: $enteredName')),
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kPrimaryTextColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//               ),
//               child: const Text('Submit Verification', style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoBlock({required IconData icon, required String title, required String description}) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: kCardBackground,
//         borderRadius: BorderRadius.circular(12.0),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: kIconBackground,
//             foregroundColor: kPrimaryTextColor,
//             child: Icon(icon),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: kPrimaryTextColor,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: const TextStyle(color: kPrimaryTextColor, fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- UPDATE THE METHOD TO ACCEPT THE LIST ---
//   Widget _buildSuggestionsSection(List<dynamic> suggestions) {
//     if (suggestions.isEmpty) {
//       return const SizedBox.shrink(); // Don't show anything if there are no suggestions
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 24),
//         const Text(
//           'AI Suggestions',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 180,
//           child: ListView.separated(
//             clipBehavior: Clip.none,
//             scrollDirection: Axis.horizontal,
//             // --- USE THE PASSED LIST'S LENGTH ---
//             itemCount: suggestions.length,
//             itemBuilder: (context, index) {
//               // --- USE THE ITEM FROM THE PASSED LIST ---
//               final suggestion = suggestions[index];
//               return _buildSuggestionItem(
//                 imageUrl: suggestion['imageUrl']!,
//                 name: suggestion['name']!,
//                 score: suggestion['score']!,
//               );
//             },
//             separatorBuilder: (context, index) => const SizedBox(width: 12),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSuggestionItem({required String imageUrl, required String name, required String score}) {
//     return SizedBox(
//       width: 130,
//       child: Card(
//         color: kCardBackground,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.0),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             setState(() {
//               _nameController.text = name;
//             });
//           },
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Image.network(
//                   imageUrl,
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   errorBuilder: (context, error, stackTrace) => const Center(
//                     child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Match: $score',
//                       style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
//
// // --- THEME COLORS ---
// const Color kScaffoldBackground = Color(0xFFF7F9F5);
// const Color kPrimaryTextColor = Color(0xFF3D5245);
// const Color kCardBackground = Color(0xFFEBF1E8);
// const Color kIconBackground = Color(0xFFDDE6D9);
// const Color kTextFieldBackground = Color(0xFFF0F0F0);
//
// class VerificationDetailPage extends StatefulWidget {
//   final Map<String, dynamic> submissionData;
//
//   const VerificationDetailPage({super.key, required this.submissionData});
//
//   @override
//   State<VerificationDetailPage> createState() => _VerificationDetailPageState();
// }
//
// class _VerificationDetailPageState extends State<VerificationDetailPage> {
//   final TextEditingController _nameController = TextEditingController();
//
//   // --- UPDATED DUMMY DATA WITH DIRECT WIKIMEDIA LINKS ---
//   final List<Map<String, String>> similarSuggestions = const [
//     {
//       'name': 'Matucana aurantiaca',
//       'score': '56%',
//       'imageUrl': 'https://www.llifle.com/Encyclopedia/CACTI/Family/Cactaceae/20616/photos/Matucana_aurantiaca_subs._polzii_11881_m.jpg',
//     },
//     {
//       'name': 'Matucana calliantha',
//       'score': '70%',
//       'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/6033/photos/Matucana_calliantha_2553_m.jpg',
//     },
//     {
//       'name': 'Matucana haynii',
//       'score': '75%',
//       'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/1080/photos/Matucana_haynei_11889_m.jpg',
//     },
//     {
//       'name': 'Matucana ritteri',
//       'score': '45%',
//       'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/6063/photos/Matucana_ritteri_8932_m.jpg',
//     },
//     {
//       'name': 'Matucana paucicostata',
//       'score': '15%',
//       'imageUrl': 'https://alchetron.com/cdn/matucana-359b153b-680c-4b9e-9839-20b04e8fcc5-resize-750.jpeg',
//     },
//   ];
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kScaffoldBackground,
//       appBar: AppBar(
//         title: Text(
//           'Verify #${widget.submissionData['id']}',
//           style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: kScaffoldBackground,
//         foregroundColor: kPrimaryTextColor,
//         elevation: 0,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12.0),
//               child: Image.network(
//                 widget.submissionData['imageUrl'],
//                 height: 250,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 250,
//                   color: Colors.grey[200],
//                   child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // ADD THIS NEW CODE:
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildInfoBlock(
//                     icon: Icons.label_important_outline,
//                     title: 'Predicted Name',
//                     description: widget.submissionData['submittedName'],
//                   ),
//                 ),
//                 const SizedBox(width: 12), // Use width for horizontal spacing
//                 Expanded(
//                   child: _buildInfoBlock(
//                     icon: Icons.star_border_rounded,
//                     title: 'Score',
//                     description: widget.submissionData['score'],
//                   ),
//                 ),
//               ],
//             ),
//
//             _buildSuggestionsSection(),
//             const SizedBox(height: 32),
//
//             TextField(
//               controller: _nameController,
//               cursorColor: kPrimaryTextColor,
//               decoration: InputDecoration(
//                 labelText: 'Enter Correct Plant Name',
//                 labelStyle: const TextStyle(color: kPrimaryTextColor),
//                 filled: true,
//                 fillColor: kTextFieldBackground,
//                 prefixIcon: const Icon(Icons.eco_outlined, color: kPrimaryTextColor),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: const BorderSide(color: kPrimaryTextColor),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             ElevatedButton(
//               onPressed: () {
//                 final enteredName = _nameController.text;
//                 if (enteredName.isNotEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Verification submitted for: $enteredName')),
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: kPrimaryTextColor,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//               ),
//               child: const Text('Submit Verification', style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoBlock({required IconData icon, required String title, required String description}) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: kCardBackground,
//         borderRadius: BorderRadius.circular(12.0),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: kIconBackground,
//             foregroundColor: kPrimaryTextColor,
//             child: Icon(icon),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: kPrimaryTextColor,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: const TextStyle(color: kPrimaryTextColor, fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildSuggestionsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'AI Suggestions',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 180,
//           child: ListView.separated(
//             clipBehavior: Clip.none,
//             scrollDirection: Axis.horizontal,
//             itemCount: similarSuggestions.length,
//             itemBuilder: (context, index) {
//               final suggestion = similarSuggestions[index];
//               return _buildSuggestionItem(
//                 imageUrl: suggestion['imageUrl']!,
//                 name: suggestion['name']!,
//                 score: suggestion['score']!,
//               );
//             },
//             separatorBuilder: (context, index) => const SizedBox(width: 12),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // --- WIDGET WITH CLICKABLE FUNCTIONALITY ---
//   Widget _buildSuggestionItem({required String imageUrl, required String name, required String score}) {
//     return SizedBox(
//       width: 130,
//       child: Card(
//         color: kCardBackground,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.0),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             setState(() {
//               _nameController.text = name;
//             });
//           },
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Image.network(
//                   imageUrl,
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   errorBuilder: (context, error, stackTrace) => const Center(
//                     child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       name,
//                       style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       'Match: $score',
//                       style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//


  // Widget _buildSuggestionsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Similar Suggestions',
  //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
  //       ),
  //       const SizedBox(height: 12),
  //       SizedBox(
  //         height: 180,
  //         child: ListView.separated(
  //           clipBehavior: Clip.none,
  //           scrollDirection: Axis.horizontal,
  //           itemCount: similarSuggestions.length,
  //           itemBuilder: (context, index) {
  //             final suggestion = similarSuggestions[index];
  //             return _buildSuggestionItem(
  //               imageUrl: suggestion['imageUrl']!,
  //               name: suggestion['name']!,
  //               score: suggestion['score']!,
  //             );
  //           },
  //           separatorBuilder: (context, index) => const SizedBox(width: 12),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildSuggestionItem({required String imageUrl, required String name, required String score}) {
  //   return SizedBox(
  //     width: 130,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: kCardBackground,
  //         borderRadius: BorderRadius.circular(12.0),
  //       ),
  //       clipBehavior: Clip.antiAlias,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Expanded(
  //             child: Image.network(
  //               imageUrl,
  //               fit: BoxFit.cover,
  //               width: double.infinity,
  //               errorBuilder: (context, error, stackTrace) => const Center(
  //                 child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  //               ),
  //             ),
  //           ),
  //           Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   name,
  //                   style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor),
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   'Match: $score',
  //                   style: TextStyle(color: kPrimaryTextColor.withOpacity(0.7), fontSize: 12),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }


