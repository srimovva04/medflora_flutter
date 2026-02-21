import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../specialist/specialist_dashboard_page.dart';

class CuratorRegistrationScreen extends StatefulWidget {
  const CuratorRegistrationScreen({super.key});

  @override
  State<CuratorRegistrationScreen> createState() => _CuratorRegistrationScreenState();
}

class _CuratorRegistrationScreenState extends State<CuratorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  var _isLoading = false;

  // Data Map for the API
  final Map<String, String> _curatorData = {
    'name': '',
    'position': '',
    'affiliation': '',
    'email': '',
  };

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Call the method in AuthProvider
      final success = await authProvider.completeCuratorProfile(_curatorData);

      if (success && mounted) {
        // Navigate to the Dashboard once successful
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SpecialistDashboardPage()),
        );
      } else {
        _showErrorDialog("Could not save profile. Please try again later.");
      }
    } catch (error) {
      _showErrorDialog("An unexpected error occurred: $error");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;
    final inputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Specialist Onboarding'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 50, color: primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your professional details to enable curator tools.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),

                    // --- NAME FIELD ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                        border: inputBorderStyle,
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                      onSaved: (value) => _curatorData['name'] = value!,
                    ),
                    const SizedBox(height: 16),

                    // --- POSITION FIELD ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Position',
                        hintText: 'e.g. Senior Botanist, Researcher',
                        prefixIcon: Icon(Icons.work_outline, color: primaryColor),
                        border: inputBorderStyle,
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your position' : null,
                      onSaved: (value) => _curatorData['position'] = value!,
                    ),
                    const SizedBox(height: 16),

                    // --- AFFILIATION FIELD ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Institute / Company',
                        hintText: 'Enter name or "Self-Affiliated"',
                        prefixIcon: Icon(Icons.business_outlined, color: primaryColor),
                        border: inputBorderStyle,
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter your affiliation' : null,
                      onSaved: (value) => _curatorData['affiliation'] = value!,
                    ),
                    const SizedBox(height: 16),

                    // --- PROFESSIONAL EMAIL ---
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Professional Email',
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                        border: inputBorderStyle,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || !value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                      onSaved: (value) => _curatorData['email'] = value!,
                    ),
                    const SizedBox(height: 30),

                    // --- SUBMIT BUTTON ---
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _submit,
                          child: const Text(
                            'ACTIVATE CURATOR TOOLS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}