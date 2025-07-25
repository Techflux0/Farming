import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../farm/notify.dart';

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
  final TextEditingController _illnessController = TextEditingController();

  String _gender = 'male';
  bool _isPregnant = false;
  bool _hasIllness = false;
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
    _illnessController.dispose();
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
        'hasIllness': _hasIllness,
        if (_hasIllness) 'illnessDescription': _illnessController.text.trim(),
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingLivestockId != null) {
        // Update existing livestock
        await _firestore
            .collection('livestocks')
            .doc(_editingLivestockId)
            .update(livestockData);
        NotificationBar.show(
          context: context,
          message: 'Livestock updated successfully!',
          isError: false,
        );
      } else {
        // Add new livestock
        livestockData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('livestocks').add(livestockData);
        NotificationBar.show(
          context: context,
          message: 'Livestock added successfully!',
          isError: false,
        );
      }

      // Reset form
      _resetForm();
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: e.toString(),
        isError: true,
      );
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
      _hasIllness = data['hasIllness'] ?? false;
      _illnessController.text = data['illnessDescription'] ?? '';
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
        NotificationBar.show(
          context: context,
          message: 'Livestock deleted successfully!',
          isError: false,
        );
      } catch (e) {
        NotificationBar.show(
          context: context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _gender = 'male';
    _isPregnant = false;
    _hasIllness = false;
    _illnessController.clear();
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Livestock',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                    const Spacer(),
                    if (!_showAddForm)
                      GestureDetector(
                        onTap: () => setState(() => _showAddForm = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
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
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showAddForm = true),
                              child: Text(
                                'Add Livestock',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 16,
                                ),
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Your Livestock (${livestock.length})',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          );
                        }

                        final doc = livestock[index - 1];
                        final data = doc.data() as Map<String, dynamic>;
                        final isFemale = data['gender'] == 'female';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['type'] ?? 'Unknown Type',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${data['age']} months • ${data['gender']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: TextButton(
                                            onPressed: () =>
                                                _editLivestock(doc),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.green[700],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Edit',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 80,
                                          child: TextButton(
                                            onPressed: () =>
                                                _deleteLivestock(doc.id),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red[600],
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildDetailItem(
                                      Icons.numbers,
                                      'ID ${data['count']}',
                                      Colors.blue[600]!,
                                    ),
                                    _buildDetailItem(
                                      Icons.attach_money,
                                      '${data['price']}',
                                      Colors.green[600]!,
                                    ),
                                    _buildDetailItem(
                                      Icons.calendar_today,
                                      'Added ${DateFormat('MMM d').format((data['createdAt'] as Timestamp).toDate())}',
                                      Colors.orange[600]!,
                                    ),
                                  ],
                                ),
                                if (isFemale) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.pink[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.child_friendly,
                                          size: 16,
                                          color: Colors.pink[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          data['isPregnant'] == true
                                              ? 'Pregnant'
                                              : 'Not Pregnant',
                                          style: TextStyle(
                                            color: Colors.pink[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (data['hasIllness'] == true) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.medical_services,
                                          size: 16,
                                          color: Colors.red[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Illness: ${data['illnessDescription'] ?? 'Not specified'}',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                                      fontSize: 12,
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
            ],
          ),
          // Add/Edit Livestock Form
          if (_showAddForm)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (_, controller) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                                    : 'Add Livestock',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _resetForm,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _typeController,
                            decoration: InputDecoration(
                              labelText: 'Livestock Type',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.pets,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                                    labelText: 'Age (months)',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.cake,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
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
                                    labelText: 'ID',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.numbers,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
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
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _gender = 'male';
                                      _isPregnant = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _gender == 'male'
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                    side: BorderSide(
                                      color: _gender == 'male'
                                          ? Colors.green[700]!
                                          : Colors.grey[300]!,
                                    ),
                                    backgroundColor: _gender == 'male'
                                        ? Colors.green[50]
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Male'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() => _gender = 'female');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _gender == 'female'
                                        ? Colors.pink[700]
                                        : Colors.grey[600],
                                    side: BorderSide(
                                      color: _gender == 'female'
                                          ? Colors.pink[700]!
                                          : Colors.grey[300]!,
                                    ),
                                    backgroundColor: _gender == 'female'
                                        ? Colors.pink[50]
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Female'),
                                ),
                              ),
                            ],
                          ),
                          if (_gender == 'female') ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.pink[100]!),
                              ),
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Pregnant',
                                  style: TextStyle(
                                    color: Colors.pink[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: _isPregnant,
                                onChanged: (value) {
                                  setState(() => _isPregnant = value);
                                },
                                activeColor: Colors.pink[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Has Illness',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: _hasIllness,
                              onChanged: (value) {
                                setState(() => _hasIllness = value);
                              },
                              activeColor: Colors.red[700],
                            ),
                          ),
                          if (_hasIllness) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _illnessController,
                              decoration: InputDecoration(
                                labelText: 'Illness Description',
                                labelStyle: TextStyle(color: Colors.grey[600]),
                                prefixIcon: Icon(
                                  Icons.medical_services,
                                  color: Colors.grey[600],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (_hasIllness &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please describe the illness';
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Additional Notes (optional)',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.note,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
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
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _editingLivestockId != null
                                        ? 'Update Livestock'
                                        : 'Add Livestock',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
