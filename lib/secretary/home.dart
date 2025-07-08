import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'communication.dart';
import 'minutes.dart';
import 'reports.dart';

class SecretaryHomeScreen extends StatefulWidget {
  const SecretaryHomeScreen({super.key});

  @override
  State<SecretaryHomeScreen> createState() => _SecretaryHomeScreenState();
}

// Welcome text will be added inside the build method's widget tree.

class _SecretaryHomeScreenState extends State<SecretaryHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _totalUsers = 0;
  int _veterinarians = 0;
  int _farmers = 0;
  int _members = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final usersQuery = await _firestore.collection('users').get();

      int vets = 0;
      int farmers = 0;
      int members = 0;

      for (final doc in usersQuery.docs) {
        final role = doc['role']?.toString() ?? 'member';
        if (role == 'veterinary') vets++;
        if (role == 'farmer') farmers++;
        if (role == 'member') members++;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardColor = Colors.blue[50]!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Secretary Home'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Role: Secretary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DashboardCard(
                          title: 'Communication',
                          icon: Icons.message,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CommunicationHomeScreen()),
                            );
                          },
                        ),
                        _DashboardCard(
                          title: 'Reports',
                          icon: Icons.assignment,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReportsHomeScreen()),
                            );
                          },
                        ),
                        _DashboardCard(
                          title: 'Minutes',
                          icon: Icons.event_note,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MinutesHomeScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Quick stats
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'User Summary',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Total Users: $_totalUsers'),
                            Text('Veterinarians: $_veterinarians'),
                            Text('Farmers: $_farmers'),
                            Text('Members: $_members'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Recent activities summary
                    const Text(
                      'Recent Activities',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _RecentActivitiesCard(firestore: _firestore),
                  ],
                ),
              ),
            ),
    );
  }
}

// Dashboard card widget
class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: color.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Recent activities widget (shows last 3 reports)
class _RecentActivitiesCard extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _RecentActivitiesCard({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('reports').orderBy('timestamp', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading activities');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No recent activities.');
        }
        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: Text(data['reportType'] ?? 'Report'),
              subtitle: Text(data['content'] ?? ''),
              trailing: Text(
                data['timestamp'] != null && data['timestamp'] is Timestamp
                    ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split('.').first
                    : '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}