// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notify.dart';
import 'home.dart';

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

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const GoatFarmLandingPage()),
      (route) => false,
    );
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // backgroundColor: Colors.lightBlue[900],
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
                elevation: 0,
              ),
              onPressed: _logout,
              child: const Icon(Icons.logout, color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.lightBlue, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildUserInfoSection(),
                            const SizedBox(height: 20),
                            if (_isEditing) _buildEditButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final roles = (_userData['roles'] as List?)?.cast<String>() ?? ['member'];
    final primaryRole = roles.firstWhere(
      (r) => r != 'null',
      orElse: () => 'member',
    );
    final createdAt = _userData['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('MMM d, y').format(createdAt.toDate())
        : 'Unknown';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightBlue[700]!, Colors.lightBlue[400]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withAlpha(51), // 0.2 * 255 = 51
                  child: Icon(
                    _getRoleIcon(primaryRole),
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230), // 0.9 * 255 = 230
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.save : Icons.edit,
                    color: Colors.lightBlue[700],
                  ),
                ),
                onPressed: () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                _userData['fullname'] ?? 'No Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: roles
                    .where((r) => r != 'null')
                    .map(
                      (role) => Chip(
                        label: Text(role.toUpperCase()),
                        backgroundColor: _getRoleColor(
                          role,
                        ).withAlpha(38), // 0.15 * 255 = 38
                        labelStyle: TextStyle(
                          color: _getRoleColor(role),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Joined $formattedDate',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      children: [
        _buildInfoTile(
          icon: Icons.email,
          title: 'Email',
          value: _userData['email'] ?? 'Not provided',
          isEditable: false,
        ),
        const Divider(height: 20, color: Colors.lightBlue),
        _buildInfoTile(
          icon: Icons.phone,
          title: 'Phone',
          value: _userData['primary_phone'] ?? '',
          controller: _phoneController,
          isEditable: _isEditing,
        ),
        const Divider(height: 20, color: Colors.lightBlue),
        _buildInfoTile(
          icon: Icons.phone_android,
          title: 'Secondary Phone',
          value: _userData['secondary_phone'] ?? '',
          controller: _secondaryPhoneController,
          isEditable: _isEditing,
          optional: true,
        ),
        const Divider(height: 20, color: Colors.lightBlue),
        _buildInfoTile(
          icon: Icons.location_on,
          title: 'Address',
          value: _userData['address'] ?? '',
          controller: _addressController,
          isEditable: _isEditing,
          maxLines: 3,
        ),
        const Divider(height: 20, color: Colors.lightBlue),
        _buildInfoTile(
          icon: Icons.cake,
          title: 'Age',
          value: _userData['age']?.toString() ?? '',
          controller: _ageController,
          isEditable: _isEditing,
          keyboardType: TextInputType.number,
          optional: true,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.lightBlue[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: isEditable
          ? TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: value,
                border: UnderlineInputBorder(),
                isDense: true,
              ),
              validator: (val) {
                if (!optional && (val == null || val.isEmpty)) {
                  return 'Please enter $title';
                }
                return null;
              },
            )
          : Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
    );
  }

  Widget _buildEditButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadUserData();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'farmer':
        return Icons.agriculture;
      case 'veterinary':
        return Icons.medical_services;
      case 'secretary':
        return Icons.assignment_ind;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'farmer':
        return Colors.lightBlue;
      case 'veterinary':
        return Colors.blue;
      case 'secretary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
