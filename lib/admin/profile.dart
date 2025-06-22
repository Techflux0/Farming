import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../farm/notify.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _secondaryPhoneController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() ?? {};
          _fullNameController.text = _userData['fullname'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _phoneController.text = _userData['primary_phone'] ?? '';
          _secondaryPhoneController.text = _userData['secondary_phone'] ?? '';
          _addressController.text = _userData['address'] ?? '';
          _ageController.text = _userData['age']?.toString() ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
              'fullname': _fullNameController.text,
              'primary_phone': _phoneController.text,
              'secondary_phone': _secondaryPhoneController.text,
              'address': _addressController.text,
              'age': int.tryParse(_ageController.text),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        NotificationBar.show(
          // ignore: use_build_context_synchronously
          context: context,
          message: 'Profile updated successfully!',
        );
        setState(() => _isEditing = false);
      } catch (e) {
        NotificationBar.show(
          context: context,
          message: 'Error updating profile: ${e.toString()}',
          isError: true,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildEditableField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      icon: Icons.person,
                      enabled: _isEditing,
                    ),
                    _buildEditableField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email,
                      enabled: false, // Email shouldn't be editable here
                    ),
                    _buildEditableField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildEditableField(
                      label: 'Secondary Phone',
                      controller: _secondaryPhoneController,
                      icon: Icons.phone_android,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      optional: true,
                    ),
                    _buildEditableField(
                      label: 'Address',
                      controller: _addressController,
                      icon: Icons.location_on,
                      enabled: _isEditing,
                      maxLines: 3,
                    ),
                    _buildEditableField(
                      label: 'Age',
                      controller: _ageController,
                      icon: Icons.cake,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      optional: true,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.green[100],
          child: Icon(Icons.person, size: 50, color: Colors.green[700]),
        ),
        const SizedBox(height: 16),
        Text(
          _userData['fullname'] ?? 'No Name',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          _userData['email'] ?? '',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (optional ? ' (Optional)' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: !enabled,
          fillColor: Colors.grey[100],
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
