import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminLivestockDashboard extends StatefulWidget {
  const AdminLivestockDashboard({super.key});

  @override
  State<AdminLivestockDashboard> createState() =>
      _AdminLivestockDashboardState();
}

class _AdminLivestockDashboardState extends State<AdminLivestockDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userStats = [];
  List<Map<String, dynamic>> _filteredUserStats = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserLivestockStats();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUserStats = _userStats.where((user) {
        final name = user['name'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchUserLivestockStats() async {
    try {
      // Get all users who have livestock records
      final usersSnapshot = await _firestore.collection('users').get();

      List<Map<String, dynamic>> stats = [];

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();

        // Get livestock for this user
        final livestockSnapshot = await _firestore
            .collection('livestocks')
            .where('userId', isEqualTo: userId)
            .get();

        if (livestockSnapshot.docs.isNotEmpty) {
          int totalCollections = livestockSnapshot.docs.length;
          int totalIll = 0;
          int totalPregnant = 0;

          for (var livestockDoc in livestockSnapshot.docs) {
            final data = livestockDoc.data();

            // Count ill animals (hasIllness == true)
            if (data['hasIllness'] == true) {
              totalIll++;
            }

            // Count pregnant females (isPregnant == true && gender == 'female')
            if (data['gender'] == 'female' && data['isPregnant'] == true) {
              totalPregnant++;
            }
          }

          stats.add({
            'userId': userId,
            'name': userData['fullname'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'total': totalCollections,
            'pregnant': totalPregnant,
            'ill': totalIll,
          });
        }
      }

      setState(() {
        _userStats = stats;
        _filteredUserStats = List.from(stats);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.lightBlue,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUserStats.isEmpty
                ? const Center(child: Text('No matching users found'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUserStats.length,
                    itemBuilder: (context, index) {
                      final stats = _filteredUserStats[index];
                      return _UserLivestockCard(stats: stats);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchUserLivestockStats,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _UserLivestockCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _UserLivestockCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.lightBlue, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              stats['email'],
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  icon: Icons.pets,
                  value: stats['total'],
                  label: 'Total',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.child_friendly,
                  value: stats['pregnant'],
                  label: 'Pregnant',
                  color: Colors.pink,
                ),
                _StatItem(
                  icon: Icons.medical_services,
                  value: stats['ill'],
                  label: 'Ill',
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
