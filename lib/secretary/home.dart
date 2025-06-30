import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecretaryHomeScreen extends StatefulWidget {
  const SecretaryHomeScreen({super.key});

  @override
  State<SecretaryHomeScreen> createState() => _SecretaryHomeScreenState();
}

// Add a welcome text widget above the stateful widget
final welcomeText = const Padding(
  padding: EdgeInsets.all(16.0),
  child: Text(
    'Welcome to the Secretary Home Screen',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secretary Home'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Users: $_totalUsers'),
                  Text('Veterinarians: $_veterinarians'),
                  Text('Farmers: $_farmers'),
                  Text('Members: $_members'),
                ],
              ),
            ),
    );
  }