import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'notify.dart';

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
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
    final role = _userData['role']?.toString().toUpperCase() ?? 'MEMBER';
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[700]!, Colors.green[400]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              height: 180,
              width: double.infinity,
              child: Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    _getRoleIcon(_userData['role'] ?? 'member'),
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
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEditing ? Icons.save : Icons.edit,
                    color: Colors.green[700],
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(
                        _userData['role'] ?? 'member',
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: _getRoleColor(_userData['role'] ?? 'member'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.circle, size: 6, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    'Joined $formattedDate',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
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
        const Divider(height: 20),
        _buildInfoTile(
          icon: Icons.phone,
          title: 'Phone',
          value: _userData['primary_phone'] ?? 'Not provided',
          controller: _phoneController,
          isEditable: _isEditing,
        ),
        const Divider(height: 20),
        _buildInfoTile(
          icon: Icons.phone_android,
          title: 'Secondary Phone',
          value: _userData['secondary_phone'] ?? 'Not provided',
          controller: _secondaryPhoneController,
          isEditable: _isEditing,
          optional: true,
        ),
        const Divider(height: 20),
        _buildInfoTile(
          icon: Icons.location_on,
          title: 'Address',
          value: _userData['address'] ?? 'Not provided',
          controller: _addressController,
          isEditable: _isEditing,
          maxLines: 3,
        ),
        const Divider(height: 20),
        _buildInfoTile(
          icon: Icons.cake,
          title: 'Age',
          value: _userData['age']?.toString() ?? 'Not provided',
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
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: isEditable
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: value == 'Not provided' ? '' : value,
                border: UnderlineInputBorder(),
                isDense: true,
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,
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
              _loadUserData(); // Reset changes
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
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
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'farmer':
        return Colors.green;
      case 'veterinary':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
