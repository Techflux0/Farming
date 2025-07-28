// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'communication.dart';
import 'minutes.dart';
import 'reports.dart';
import '../farm/profile.dart';
import '../farm/chat.dart';
import '../farm/notify.dart';

class SecretaryHomeScreen extends StatefulWidget {
  const SecretaryHomeScreen({super.key});

  @override
  State<SecretaryHomeScreen> createState() => _SecretaryHomeScreenState();
}

class _SecretaryHomeScreenState extends State<SecretaryHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _totalUsers = 0;
  int _veterinarians = 0;
  int _farmers = 0;
  int _members = 0;
  bool _isLoading = true;
  bool _isSecretary = false;

  @override
  void initState() {
    super.initState();
    _verifySecretaryRole();
    _fetchUserData();
  }

  Future<void> _verifySecretaryRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = (data['roles'] as List?)?.cast<String>() ?? ['member'];
          if (!roles.contains('secretary')) {
            Navigator.pop(context);
          } else {
            setState(() => _isSecretary = true);
          }
        }
      }
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error verifying secretary role: $e',
        isError: true,
      );
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final usersQuery = await _firestore.collection('users').get();

      int vets = 0;
      int farmers = 0;
      int members = 0;

      for (final doc in usersQuery.docs) {
        final roles = (doc['roles'] as List?)?.cast<String>() ?? [];
        if (roles.contains('veterinary')) vets++;
        if (roles.contains('farmer')) farmers++;
        if (roles.contains('member') || roles.isEmpty) members++;
      }

      setState(() {
        _totalUsers = usersQuery.size;
        _veterinarians = vets;
        _farmers = farmers;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      NotificationBar.show(
        context: context,
        message: 'Error loading user data: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isSecretary) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                'Secretary Authorization Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Only authorized secretaries can access this page.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Secretary Dashboard'),
        backgroundColor: Colors.lightBlue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.lightBlue, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Secretary',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.lightBlue[800],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage communications, reports, and meeting minutes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Quick stats cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Users',
                  '$_totalUsers',
                  Icons.people,
                  Colors.blue[700]!,
                ),
                _buildStatCard(
                  'Veterinarians',
                  '$_veterinarians',
                  Icons.medical_services,
                  Colors.lightBlue[700]!,
                ),
                _buildStatCard(
                  'Farmers',
                  '$_farmers',
                  Icons.agriculture,
                  Colors.orange[700]!,
                ),
                _buildStatCard(
                  'Members',
                  '$_members',
                  Icons.person,
                  Colors.purple[700]!,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dashboard cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDashboardCard(
                  title: 'Notice',
                  icon: Icons.notifications,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunicationHomeScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  title: 'Reports',
                  icon: Icons.assignment,
                  color: Colors.lightBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsHomeScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  title: 'Minutes',
                  icon: Icons.event_note,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MinutesHomeScreen(),
                    ),
                  ),
                ),
                _buildDashboardCard(
                  title: 'Chat',
                  icon: Icons.chat,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatPage()),
                  ),
                ),
                _buildDashboardCard(
                  title: 'Profile',
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent activities
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.lightBlue, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RecentActivitiesCard(firestore: _firestore),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.lightBlue, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Card(
          color: color.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivitiesCard extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _RecentActivitiesCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No recent activities',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;

            return ListTile(
              leading: const Icon(
                Icons.assignment_turned_in,
                color: Colors.lightBlue,
              ),
              title: Text(
                data['reportType']?.toString() ?? 'Untitled Report',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                data['content']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: timestamp != null
                  ? Text(
                      _formatDate(timestamp.toDate()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
