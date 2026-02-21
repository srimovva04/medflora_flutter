import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';

// --- THEME COLORS ---
const Color kScaffoldBackground = Color(0xFFF7F9F5);
const Color kPrimaryTextColor = Color(0xFF3D5245);
const Color kCardBackground = Color(0xFFEBF1E8);
const Color kAccentGreen = Color(0xFF4CAF50);

class VerificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> submissionData;

  const VerificationDetailPage({super.key, required this.submissionData});

  @override
  State<VerificationDetailPage> createState() => _VerificationDetailPageState();
}

class _VerificationDetailPageState extends State<VerificationDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.submissionData['submittedName'] ??
        widget.submissionData['plant_name'] ?? '';
    _fetchLiveSuggestions();
  }

  Future<void> _fetchLiveSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('${Config.apiUrl}/get-suggestions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_url': widget.submissionData['imageUrl'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestions = data['results'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "AI Service Error (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Connection failed. Ensure backend is running.";
        _isLoading = false;
      });
    }
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REFINED DETAIL TILE COMPONENT ---
  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kCardBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: kPrimaryTextColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String confidenceText = widget.submissionData['score'] ??
        "${((widget.submissionData['confidence'] ?? 0) * 100).toStringAsFixed(1)}%";

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('Verify Submission', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryTextColor,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER SECTION: IMAGE & TILES ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDE: Image with "Polaroid" frame effect
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, widget.submissionData['imageUrl']),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PREVIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Image.network(
                                  widget.submissionData['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black54],
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // RIGHT SIDE: The Refined Detail Tiles
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                      const SizedBox(height: 8),
                      _buildDetailTile("Original", widget.submissionData['submittedName'] ?? "Unknown", Icons.eco_outlined),
                      _buildDetailTile("AI Score", confidenceText, Icons.auto_awesome_outlined),
                      _buildDetailTile("Date", widget.submissionData['date'] ?? "N/A", Icons.calendar_today_rounded),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // --- SUGGESTIONS ---
            const Text('Identification Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryTextColor)),
            const SizedBox(height: 4),
            const Text('Tap a card to update the final name', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildSuggestionSection(),

            const SizedBox(height: 28),

            // --- FINAL EDIT SECTION ---
            const Text("Final Verified Name", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Select a suggestion or type manually...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.check_circle, color: kAccentGreen),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccentGreen, width: 2)),
              ),
            ),

            const SizedBox(height: 32),

            // --- ACTION BUTTON ---
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: kPrimaryTextColor,
                    content: Text('Submission updated to: ${_nameController.text}'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryTextColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Confirm Verification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection() {
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: kAccentGreen, strokeWidth: 2)));
    if (_errorMessage != null) return Text(_errorMessage!, style: const TextStyle(color: Colors.red));
    if (_suggestions.isEmpty) return const Text("No matches found for this image.");

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final res = _suggestions[index];
          final species = res['species'];
          return _buildSuggestionItem(
            name: species['scientificNameWithoutAuthor'] ?? 'Unknown',
            family: species['family']?['scientificNameWithoutAuthor'] ?? 'Unknown Family',
            score: (res['score'] ?? 0).toDouble(),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionItem({required String name, required String family, required double score}) {
    bool isSelected = _nameController.text == name;
    double scorePercent = score * 100;
    Color scoreColor = scorePercent > 70 ? kAccentGreen : (scorePercent > 40 ? Colors.orange : Colors.grey);

    return InkWell(
      onTap: () => setState(() => _nameController.text = name),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kAccentGreen : Colors.grey.shade200, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: kAccentGreen.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.eco, color: scoreColor, size: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${scorePercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scoreColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(family, style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}


/// Without suggestions code

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
//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
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
//                 height: 200,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 250,
//                   color: Colors.grey[200],
//                   child: const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 15),
//
//             // --- NEW REFINED INFO CARDS ---
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: _buildBetterInfoBlock(
//                     icon: Icons.label_important_outline,
//                     title: 'Predicted Name',
//                     description: widget.submissionData['submittedName'],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildBetterInfoBlock(
//                     icon: Icons.star_rate_rounded,
//                     title: 'Score',
//                     description: widget.submissionData['score'],
//                   ),
//                 ),
//               ],
//             ),
//
//             _buildSuggestionsSection(suggestions),
//             const SizedBox(height: 15),
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
//   // --- MODERNIZED INFO CARD WIDGET ---
//   Widget _buildBetterInfoBlock({
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: kCardBackground,
//         borderRadius: BorderRadius.circular(16.0),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Container(
//           //   width: 45,
//           //   height: 45,
//           //   decoration: BoxDecoration(
//           //     color: kIconBackground,
//           //     borderRadius: BorderRadius.circular(10.0),
//           //   ),
//           //   // child: Icon(icon, color: kPrimaryTextColor, size: 22),
//           // ),
//           // const SizedBox(height: 10),
//           Text(
//             title,
//             style: const TextStyle(
//               fontWeight: FontWeight.w700,
//               fontSize: 15,
//               color: kPrimaryTextColor,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 6),
//           Text(
//             description,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: kPrimaryTextColor.withOpacity(0.9),
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSuggestionsSection(List<dynamic> suggestions) {
//     if (suggestions.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 15),
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
//             itemCount: suggestions.length,
//             itemBuilder: (context, index) {
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
//   Widget _buildSuggestionItem({
//     required String imageUrl,
//     required String name,
//     required String score,
//   }) {
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

//
// Widget _buildSuggestionSection() {
//   if (_isLoading) {
//     return const SizedBox(
//       height: 150,
//       child: Center(child: CircularProgressIndicator(color: kAccentGreen)),
//     );
//   }
//
//   if (_errorMessage != null) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         children: [
//           Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800)),
//           TextButton(onPressed: _fetchLiveSuggestions, child: const Text("Retry"))
//         ],
//       ),
//     );
//   }
//
//   if (_suggestions.isEmpty) {
//     return const Center(child: Text("No suggestions available."));
//   }
//
//   return SizedBox(
//     height: 220,
//     child: ListView.separated(
//       clipBehavior: Clip.none,
//       scrollDirection: Axis.horizontal,
//       itemCount: _suggestions.length,
//       itemBuilder: (context, index) {
//         final res = _suggestions[index];
//         final species = res['species'];
//         // final images = res['images'] as List<dynamic>?;
//
//         return _buildSuggestionItem(
//           // imageUrl: (images != null && images.isNotEmpty) ? images[0]['url'] : null,
//           name: species['scientificNameWithoutAuthor'] ?? 'Unknown',
//           family: species['family']?['scientificNameWithoutAuthor'] ?? 'Unknown Family',
//           score: '${((res['score'] ?? 0) * 100).toStringAsFixed(1)}%',
//         );
//       },
//       separatorBuilder: (context, index) => const SizedBox(width: 12),
//     ),
//   );
// }
//
// Widget _buildSuggestionItem({
//   // String? imageUrl,
//   required String name,
//   required String family,
//   required String score,
// }) {
//   return SizedBox(
//     width: 160,
//     child: Card(
//       color: Colors.white,
//       elevation: 3,
//       shadowColor: Colors.black12,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _nameController.text = name;
//           });
//         },
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Expanded(
//             //   child: imageUrl != null
//             //       ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
//             //       : Container(
//             //       color: kIconBackground,
//             //       width: double.infinity,
//             //       child: const Icon(Icons.eco, color: kPrimaryTextColor)
//             //   ),
//             // ),
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryTextColor),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   Text(
//                     family,
//                     style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
//                     maxLines: 1,
//                   ),
//                   const SizedBox(height: 6),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                       color: kScaffoldBackground,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Text(
//                       'Match: $score',
//                       style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }


