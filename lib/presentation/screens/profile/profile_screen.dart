import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petromind/services/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final provider =
        Provider.of<UserProvider>(context, listen: false);
    _firstNameController =
        TextEditingController(text: provider.firstName);
    _lastNameController =
        TextEditingController(text: provider.lastName);
    _emailController =
        TextEditingController(text: provider.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all fields.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider =
        Provider.of<UserProvider>(context, listen: false);
    final success = await provider.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Profile updated successfully!'
            : 'Failed to update profile.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                  color: Colors.grey, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 8),
            const Text('Set New Photo',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _editableField(_firstNameController, 'First name'),
            const SizedBox(height: 8),
            _editableField(_lastNameController, 'Last name'),
            const Text(
                'Enter your name and an optional profile photo',
                style:
                    TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            _editableField(_emailController, 'Email',
                keyboardType: TextInputType.emailAddress),
            const Text('Enter your Email address',
                style:
                    TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save edits',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableField(
      TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          suffixIcon: const Icon(Icons.edit,
              color: Colors.white, size: 16),
        ),
      ),
    );
  }
}