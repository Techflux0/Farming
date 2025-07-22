import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VeterinaryLivestockPage extends StatefulWidget {
  const VeterinaryLivestockPage({super.key});

  @override
  State<VeterinaryLivestockPage> createState() =>
      _VeterinaryLivestockPageState();
}

class _VeterinaryLivestockPageState extends State<VeterinaryLivestockPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedAnimals = {};
  String _searchQuery = '';
  bool _isVeterinary = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _verifyVeterinaryRole();
  }

  Future<void> _verifyVeterinaryRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = (data['roles'] as List?)?.cast<String>() ?? ['member'];
          setState(() {
            _isVeterinary = roles[0] == 'veterinary';
            _loading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error verifying role: $e')));
    }
  }

  Future<void> _updateIllnessStatus(
    String docId,
    bool hasIllness,
    String description,
  ) async {
    try {
      await _firestore.collection('livestocks').doc(docId).update({
        'hasIllness': hasIllness,
        'illnessDescription': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Illness status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating record: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isVeterinary) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Veterinary Authorization Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Only authorized veterinary personnel can access this page.',
              ),
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
        title: const Text('Veterinary Livestock Records'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Animal ID',
                    hintText: 'Enter animal ID',
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
                        .collection('livestocks')
                        .where('type', isEqualTo: 'goat')
                        .where('hasIllness', isEqualTo: true)
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : _firestore
                        .collection('livestocks')
                        .where('count', isEqualTo: _searchQuery)
                        .where('type', isEqualTo: 'goat')
                        .where('hasIllness', isEqualTo: true)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading livestock',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No ill goats found'
                              : 'No matching ill goat found',
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
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final animalId = doc.id;
                    final isExpanded = _expandedAnimals[animalId] ?? false;
                    final illnessDescription =
                        data['illnessDescription'] ?? 'No description provided';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        key: Key(animalId),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _expandedAnimals[animalId] = expanded;
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[100],
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.red[700],
                          ),
                        ),
                        title: Text(
                          'Goat ID: ${data['count']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Age: ${data['age']} Months | ${data['gender']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Animal ID',
                                  data['count'].toString(),
                                ),
                                _buildDetailRow('Age', '${data['age']} Months'),
                                _buildDetailRow('Gender', data['gender']),
                                _buildDetailRow(
                                  'Price',
                                  'Kes${data['price']}',
                                ),
                                if (data['gender'] == 'female')
                                  _buildDetailRow(
                                    'Pregnancy Status',
                                    data['isPregnant']
                                        ? 'Pregnant'
                                        : 'Not Pregnant',
                                  ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Illness Details:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(illnessDescription),
                                const SizedBox(height: 16),
                                if (data['notes'] != null &&
                                    data['notes'].isNotEmpty)
                                  _buildDetailRow('Owner Notes', data['notes']),
                                _buildDetailRow(
                                  'Registered On',
                                  (data['createdAt'] as Timestamp)
                                      .toDate()
                                      .toString(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showIllnessUpdateDialog(
                                              context,
                                              doc.id,
                                              data['hasIllness'],
                                              illnessDescription,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text(
                                          'Update Illness Status',
                                        ),
                                      ),
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
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Future<void> _showIllnessUpdateDialog(
    BuildContext context,
    String docId,
    bool currentStatus,
    String currentDescription,
  ) async {
    final TextEditingController descriptionController = TextEditingController(
      text: currentDescription,
    );
    bool hasIllness = currentStatus;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update Illness Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Animal is ill'),
                  value: hasIllness,
                  onChanged: (value) => setState(() => hasIllness = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Illness Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateIllnessStatus(
                    docId,
                    hasIllness,
                    descriptionController.text,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
