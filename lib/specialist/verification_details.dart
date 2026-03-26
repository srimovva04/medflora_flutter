import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../auth/providers/auth_provider.dart';

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
  final TextEditingController _scientificController = TextEditingController();

  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 1. Look for proposed names (from a regular Curator's review)
    final proposedCommon = widget.submissionData['proposed_common_name'];
    final proposedScientific = widget.submissionData['proposed_scientific_name'];

    // 2. If proposed names exist, use them. Otherwise, fall back to the original names.
    _nameController.text = proposedCommon ?? widget.submissionData['submittedName'] ?? '';
    _scientificController.text = proposedScientific ?? widget.submissionData['scientific_name'] ?? '';
    // _nameController.text = widget.submissionData['submittedName'] ?? '';
    // _scientificController.text = widget.submissionData['scientific_name'] ?? '';
    _fetchLiveSuggestions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final url = Uri.parse('${Config.apiUrl}/get-suggestions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': widget.submissionData['imageUrl']}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestions = data['results'] ?? [];
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingSuggestions = false);
    }
  }

  Future<void> _submitVerification() async {
    if (_nameController.text.isEmpty || _scientificController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both names before confirming.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/admin/verify-submission'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": widget.submissionData['id'],
          "type": widget.submissionData['type'],
          "imageId": widget.submissionData['imageId'],
          "common_name": _nameController.text.trim(),
          "scientific_name": _scientificController.text.trim(),
          "curator_id": authProvider.userId ?? "unknown",
          // ADD THIS LINE SO THE BACKEND KNOWS THE ROLE:
          "curator_role": authProvider.userRole ?? "user",
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  //
  // Future<void> _submitVerification() async {
  //   if (_nameController.text.isEmpty || _scientificController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please fill in both names before confirming.')),
  //     );
  //     return;
  //   }
  //
  //   setState(() => _isSubmitting = true);
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('${Config.apiUrl}/admin/verify-submission'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "id": widget.submissionData['id'],
  //         "type": widget.submissionData['type'],
  //         "imageId": widget.submissionData['imageId'],
  //         "common_name": _nameController.text.trim(),
  //         "scientific_name": _scientificController.text.trim(),
  //         "curator_id": authProvider.userId ?? "unknown", // Using public getter
  //       }),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       if (!mounted) return;
  //       Navigator.pop(context, true);
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  //   } finally {
  //     if (mounted) setState(() => _isSubmitting = false);
  //   }
  // }

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

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: kCardBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: kPrimaryTextColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kPrimaryTextColor), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String hint, IconData icon, {bool isItalic = false}) {
    return TextField(
      controller: controller,
      style: TextStyle(fontWeight: FontWeight.w600, fontStyle: isItalic ? FontStyle.italic : FontStyle.normal),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: kAccentGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccentGreen, width: 2)),
      ),
    );
  }

  Widget _buildSuggestionSection() {
    if (_isLoadingSuggestions) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    if (_suggestions.isEmpty) return const Text("No AI suggestions available.", style: TextStyle(color: Colors.grey, fontSize: 12));

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (ctx, i) {
          final name = _suggestions[i]['species']['scientificNameWithoutAuthor'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: kCardBackground,
              side: BorderSide.none,
              label: Text(name, style: const TextStyle(color: kPrimaryTextColor, fontWeight: FontWeight.w500)),
              onPressed: () => setState(() => _scientificController.text = name),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? currentUserRole = authProvider.userRole;
    final String? itemUploaderRole = widget.submissionData['uploader_role'];

    bool canEdit = false;
    String buttonText = "Confirm Verification"; // Default fallback

    if (currentUserRole == 'senior_curator') {
      // Senior Curators can finalize anything (except maybe other Senior Curators' work)
      if (itemUploaderRole != 'senior_curator') {
        canEdit = true;
        buttonText = "Finalize & Verify";
      }
    } else if (currentUserRole == 'curator') {
      // Regular Curators can review pending items, but they are just submitting for review
      if (itemUploaderRole != 'senior_curator') {
        canEdit = true;
        buttonText = "Submit for Senior Review";
      }
    }
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final String? currentUserRole = authProvider.userRole;
    // final String? itemUploaderRole = widget.submissionData['uploader_role'];
    // final String itemType = widget.submissionData['type'] ?? '';
    //
    // bool canEdit = false;
    //
    // if (currentUserRole == 'senior_curator') {
    //   // Senior Curator can edit:
    //   // 1. All Predictions
    //   // 2. All Curator uploads
    //   // CANNOT edit: Other Senior Curators
    //   if (itemUploaderRole != 'senior_curator') {
    //     canEdit = true;
    //   }
    // } else if (currentUserRole == 'curator') {
    //   // Curator can edit:
    //   // 1. All Predictions
    //   // 2. All other Curator uploads
    //   // CANNOT edit: Any Senior Curator uploads
    //   if (itemUploaderRole != 'senior_curator') {
    //     canEdit = true;
    //   }
    // }
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final String? currentUserRole = authProvider.userRole;
    // final String? itemUploaderRole = widget.submissionData['uploader_role'];
    // final String itemType = widget.submissionData['type'] ?? ''; // 'prediction' or 'manual_upload'
    //
    // bool canEdit = false;
    //
    // if (currentUserRole == 'senior_curator') {
    //   // Senior Curators can edit everything except other Senior Curators
    //   if (itemUploaderRole != 'senior_curator') {
    //     canEdit = true;
    //   }
    // } else if (currentUserRole == 'curator') {
    //   // Curators can only edit AI Predictions
    //   if (itemType == 'prediction') {
    //     canEdit = true;
    //   }
    // }
    // bool canEdit = (currentUserRole == 'senior_curator' && itemUploaderRole != 'senior_curator');

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
            // --- HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(context, widget.submissionData['imageUrl']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(widget.submissionData['imageUrl'], height: 200, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildDetailTile("Original Name", widget.submissionData['submittedName'] ?? "N/A", Icons.eco_outlined),
                      _buildDetailTile("AI Score", widget.submissionData['score'] ?? "Manual", Icons.auto_awesome_outlined),
                      _buildDetailTile("Date", widget.submissionData['date'] ?? "N/A", Icons.calendar_today_rounded),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Text('AI SUGGESTIONS (Tap to select)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            _buildSuggestionSection(),

            const SizedBox(height: 28),

            // --- FINAL EDIT SECTION ---
            if (canEdit) ...[
              const Text("Final Common Name", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor)),
              const SizedBox(height: 10),
              _buildEditField(_nameController, "Enter common name", Icons.eco),

              const SizedBox(height: 20),

              const Text("Final Scientific Name", style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryTextColor)),
              const SizedBox(height: 10),
              _buildEditField(_scientificController, "Enter scientific name", Icons.science, isItalic: true),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryTextColor,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                // UPDATE THIS LINE TO USE THE DYNAMIC TEXT:
                    : Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              // ElevatedButton(
              //   onPressed: _isSubmitting ? null : _submitVerification,
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: kPrimaryTextColor,
              //     minimumSize: const Size(double.infinity, 54),
              //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              //   ),
              //   child: _isSubmitting
              //       ? const CircularProgressIndicator(color: Colors.white)
              //       : const Text("Confirm & Move to Verified", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              // ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  "Read-Only Mode: Only Senior Curators can confirm verifications for this entry.",
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

