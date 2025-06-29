import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LivestockManagementScreen extends StatefulWidget {
  const LivestockManagementScreen({super.key});

  @override
  State<LivestockManagementScreen> createState() =>
      _LivestockManagementScreenState();
}

class _LivestockManagementScreenState extends State<LivestockManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _gender = 'male';
  bool _isPregnant = false;
  bool _isLoading = false;
  bool _showAddForm = false;
  String? _editingLivestockId;

  @override
  void dispose() {
    _typeController.dispose();
    _ageController.dispose();
    _countController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLivestock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final livestockData = {
        'userId': user.uid,
        'type': _typeController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'count': int.tryParse(_countController.text) ?? 1,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'gender': _gender,
        'isPregnant': _gender == 'female' ? _isPregnant : false,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingLivestockId != null) {
        // Update existing livestock
        await _firestore
            .collection('livestocks')
            .doc(_editingLivestockId)
            .update(livestockData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livestock updated successfully!')),
        );
      } else {
        // Add new livestock
        livestockData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('livestocks').add(livestockData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livestock added successfully!')),
        );
      }

      // Reset form
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editLivestock(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingLivestockId = doc.id;
      _typeController.text = data['type'] ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _countController.text = data['count']?.toString() ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _gender = data['gender'] ?? 'male';
      _isPregnant = data['isPregnant'] ?? false;
      _notesController.text = data['notes'] ?? '';
      _showAddForm = true;
    });
  }

  Future<void> _deleteLivestock(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this livestock record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('livestocks').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livestock deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting livestock: $e')));
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _gender = 'male';
    _isPregnant = false;
    _editingLivestockId = null;
    setState(() => _showAddForm = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Please login to manage livestock'));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),

              // Livestock List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('livestocks')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No livestock recorded yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final livestock = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: livestock.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Your Livestock (${livestock.length})',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }

                        final doc = livestock[index - 1];
                        final data = doc.data() as Map<String, dynamic>;
                        final isFemale = data['gender'] == 'female';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data['type'] ?? 'Unknown Type',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => _editLivestock(doc),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cleaning_services,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _deleteLivestock(doc.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildDetailItem(
                                      Icons.numbers,
                                      '${data['count']}',
                                      'Count',
                                    ),
                                    const SizedBox(width: 16),
                                    _buildDetailItem(
                                      Icons.cake,
                                      '${data['age']} yrs',
                                      'Age',
                                    ),
                                    const SizedBox(width: 16),
                                    _buildDetailItem(
                                      Icons.attach_money,
                                      '${data['price']}',
                                      'Price',
                                    ),
                                  ],
                                ),
                                if (isFemale) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.child_friendly,
                                        size: 20,
                                        color: Colors.pink[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        data['isPregnant'] == true
                                            ? 'Pregnant'
                                            : 'Not Pregnant',
                                        style: TextStyle(
                                          color: Colors.pink[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (data['notes'] != null &&
                                    data['notes'].isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Notes: ${data['notes']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Add Livestock Button
              if (!_showAddForm)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showAddForm = true),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Livestock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Add/Edit Livestock Form
          if (_showAddForm)
            DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: controller,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingLivestockId != null
                                  ? 'Edit Livestock'
                                  : 'Add New Livestock',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _resetForm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _typeController,
                          decoration: InputDecoration(
                            labelText: 'Livestock Type',
                            prefixIcon: const Icon(Icons.pets),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter livestock type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                decoration: InputDecoration(
                                  labelText: 'Age (years)',
                                  prefixIcon: const Icon(Icons.cake),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter age';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _countController,
                                decoration: InputDecoration(
                                  labelText: 'Count',
                                  prefixIcon: const Icon(Icons.numbers),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter count';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price per unit',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Male'),
                                value: 'male',
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value!;
                                    _isPregnant = false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Female'),
                                value: 'female',
                                groupValue: _gender,
                                onChanged: (value) {
                                  setState(() => _gender = value!);
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_gender == 'female') ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Pregnant'),
                            value: _isPregnant,
                            onChanged: (value) {
                              setState(() => _isPregnant = value);
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Additional Notes (optional)',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveLivestock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  _editingLivestockId != null
                                      ? 'Update Livestock'
                                      : 'Save Livestock',
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
