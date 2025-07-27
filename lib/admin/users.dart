// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../farm/notify.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  final Map<String, bool> _expandedUsers = {};
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
    _isLoading;
  }

  // Yooh i fixed this to only edit 'null' role
  Future<void> _updateUserRoles(String userId, String newRole) async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      List roles =
          (userDoc.data()?['roles'] as List?)?.cast<String>() ??
          ['member', 'null'];
      if (roles.length < 2) {
        roles = [roles.isNotEmpty ? roles[0] : 'member', 'null'];
      }
      roles[1] = newRole;
      await _firestore.collection('users').doc(userId).update({
        'roles': roles,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationBar.show(
        context: context,
        message: 'User role updated successfully',
      );
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error updating role: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(userId).update({
        'membership_status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationBar.show(
        context: context,
        message: 'User approved successfully',
      );
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error approving user: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('users').doc(userId).delete();
      NotificationBar.show(
        context: context,
        message: 'User deleted successfully',
      );
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error deleting user: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleExpandUser(String userId) {
    setState(() {
      _expandedUsers[userId] = !(_expandedUsers[userId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.lightBlue, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search users',
                    hintText: 'Search by email or name',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchQuery.isEmpty
                  ? _firestore
                        .collection('users')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : _firestore
                        .collection('users')
                        .where('email', isGreaterThanOrEqualTo: _searchQuery)
                        .where('email', isLessThan: '${_searchQuery}z')
                        .orderBy('email')
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final email = userData['email'] ?? 'No email';
                    final roles =
                        (userData['roles'] as List?)?.cast<String>() ??
                        ['member'];
                    final primaryRole = roles.firstWhere(
                      (r) => r != 'null',
                      orElse: () => 'member',
                    );
                    final name = userData['fullname'] ?? 'Unknown';
                    final status = userData['membership_status'] ?? 'pending';
                    final createdAt = (userData['createdAt'] as Timestamp?)
                        ?.toDate();
                    final isExpanded = _expandedUsers[userId] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Colors.lightBlue,
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        key: Key(userId),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) =>
                            _toggleExpandUser(userId),
                        leading: CircleAvatar(
                          backgroundColor: Colors.lightBlue[100],
                          child: Icon(
                            _getRoleIcon(primaryRole),
                            color: Colors.lightBlue[700],
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: _buildStatusBadge(status),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Role', primaryRole),
                                _buildDetailRow('Status', status),
                                if (createdAt != null)
                                  _buildDetailRow(
                                    'Joined',
                                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (status == 'pending')
                                      SizedBox(
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: () => _approveUser(userId),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(70, 32),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            backgroundColor: Colors.lightBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: const BorderSide(
                                                color: Colors.lightBlue,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Approve',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    DropdownButton<String>(
                                      value: primaryRole,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      elevation: 10,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      underline: Container(
                                        height: 2,
                                        color: Colors.green,
                                      ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          _updateUserRoles(userId, newValue);
                                        }
                                      },
                                      items:
                                          // ignore: prefer_collection_literals
                                          ([
                                            'admin',
                                            'farmer',
                                            'veterinary',
                                            'secretary',
                                            'null',
                                            if (![
                                              'admin',
                                              'farmer',
                                              'veterinary',
                                              'secretary',
                                              'null',
                                            ].contains(primaryRole))
                                              primaryRole,
                                          ].toSet().toList()).map<
                                            DropdownMenuItem<String>
                                          >((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value.toUpperCase(),
                                                style: TextStyle(
                                                  color: _getRoleColor(value),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(70, 32),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.red,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: const BorderSide(
                                                color: Colors.lightBlue,
                                                width: 1,
                                              ),
                                            ),
                                            title: Center(
                                              child: Text(
                                                'Confirm Delete',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete user "$email"?',
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 15,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.lightBlue[700],
                                                  backgroundColor:
                                                      Colors.lightBlue[50],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  backgroundColor:
                                                      Colors.red[700],
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 18,
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context, true);
                                                },
                                                child: const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayStatus;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.lightBlue[100]!;
        textColor = Colors.lightBlue[800]!;
        displayStatus = 'Approved';
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        displayStatus = 'Pending';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
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
        return Colors.lightBlue;
      case 'veterinary':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
