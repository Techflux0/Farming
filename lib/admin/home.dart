// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../farm/notify.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _veterinarians = 0;
  int _farmers = 0;
  int _members = 0;
  int _treasurers = 0;
  int _secretaries = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where(
            'roles',
            arrayContainsAny: [
              'admin',
              'veterinary',
              'farmer',
              'treasurer',
              'secretary',
              'member',
            ],
          )
          .get();

      int vets = 0;
      int farmers = 0;
      int members = 0;

      for (final doc in usersQuery.docs) {
        final roles = (doc['roles'] as List?)?.cast<String>() ?? [];
        final roleSet = roles.toSet();

        if (roleSet.contains('veterinary')) vets++;
        if (roleSet.contains('farmer')) farmers++;
        if (roleSet.contains('treasurer')) _treasurers++;
        if (roleSet.contains('secretary')) _secretaries++;
        if (roleSet.contains('member') || roleSet.isEmpty) members++;
      }

      setState(() {
        _totalUsers = usersQuery.size;
        _veterinarians = vets;
        _farmers = farmers;
        _members = members;
        _treasurers = _treasurers;
        _secretaries = _secretaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationBar.show(
        context: context,
        message: 'Error loading user data: $e',
        isError: true,
      );
      debugPrint('Error details: $e');
    }
  }

  Future<void> _clearAllChats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages'),
        content: const Text(
          'Are you sure you want to delete all chat messages? \nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final querySnapshot = await _firestore.collection('chats').get();
        final batch = _firestore.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        NotificationBar.show(
          context: context,
          message: 'All messages cleared successfully',
          isError: false,
        );

        setState(() {});
      } catch (e) {
        NotificationBar.show(
          context: context,
          message: 'Error clearing messages: $e',
          isError: true,
        );
      }
    }
  }

  Widget _buildRoleCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.lightBlue, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildRoleCard(
                        'Total Users',
                        _totalUsers,
                        Icons.group,
                        Colors.lightBlue,
                      ),
                      _buildRoleCard(
                        'Veterinarians',
                        _veterinarians,
                        Icons.medical_services,
                        Colors.blue,
                      ),
                      _buildRoleCard(
                        'Treasurers',
                        _treasurers,
                        Icons.account_balance_wallet,
                        Colors.amber,
                      ),
                      _buildRoleCard(
                        'Farmers',
                        _farmers,
                        Icons.agriculture,
                        Colors.orange,
                      ),
                      _buildRoleCard(
                        'Secretaries',
                        _secretaries,
                        Icons.assignment_ind,
                        Colors.pink,
                      ),
                      _buildRoleCard(
                        'Members',
                        _members,
                        Icons.people,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fetchUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _clearAllChats,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Clear Chats'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
