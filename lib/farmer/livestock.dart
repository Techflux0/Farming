// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _sireController = TextEditingController();
  final TextEditingController _damController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _weighingWeeksController =
      TextEditingController();
  final TextEditingController _offspringCountController =
      TextEditingController();
  final TextEditingController _removalReasonController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown values
  String _gender = 'ram';
  String _breed = 'Merino';
  String _birthType = 'single';
  DateTime? _birthDate;
  DateTime? _weanDate;
  DateTime? _removalDate;
  bool _isLoading = false;
  bool _showAddForm = false;
  String? _editingLivestockId;
  bool _isExpanded = false;

  // Sheep breeds list
  final List<String> _breeds = [
    'Merino',
    'Dorper',
    'Suffolk',
    'Dorset',
    'Hampshire',
    'Katahdin',
    'Rambouillet',
    'Cheviot',
    'Columbia',
    'Corriedale',
    'Finnsheep',
    'Icelandic',
    'Jacob',
    'Karakul',
    'Lincoln',
    'Montadale',
    'Oxford',
    'Polypay',
    'Romney',
    'Southdown',
    'Targhee',
    'Texel',
  ];

  // Birth types
  final List<String> _birthTypes = ['single', 'twin', 'triplet', 'quad'];

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _sireController.dispose();
    _damController.dispose();
    _weightController.dispose();
    _weighingWeeksController.dispose();
    _offspringCountController.dispose();
    _removalReasonController.dispose();
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
        'name': _nameController.text.trim(),
        'count': int.tryParse(_countController.text) ?? 1,
        'type': 'sheep',
        'gender': _gender,
        'breed': _breed,
        'sire': _sireController.text.trim(),
        'dam': _damController.text.trim(),
        'weight': double.tryParse(_weightController.text),
        'weighingWeeks': int.tryParse(_weighingWeeksController.text),
        'birthType': _birthType,
        'birthDate': _birthDate,
        'weanDate': _weanDate,
        'removalDate': _removalDate,
        'removalReason': _removalReasonController.text.trim(),
        'offspringCount': int.tryParse(_offspringCountController.text) ?? 0,
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
          message: 'Sheep record updated successfully!',
          isError: false,
        );
      } else {
        // Add new livestock
        livestockData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('livestocks').add(livestockData);
        NotificationBar.show(
          context: context,
          message: 'Sheep record added successfully!',
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
      _nameController.text = data['name'] ?? '';
      _countController.text = data['count']?.toString() ?? '1';
      _gender = data['gender'] ?? 'ram';
      _breed = data['breed'] ?? 'Merino';
      _sireController.text = data['sire'] ?? '';
      _damController.text = data['dam'] ?? '';
      _weightController.text = data['weight']?.toString() ?? '';
      _weighingWeeksController.text = data['weighingWeeks']?.toString() ?? '';
      _birthType = data['birthType'] ?? 'single';
      _birthDate = data['birthDate']?.toDate();
      _weanDate = data['weanDate']?.toDate();
      _removalDate = data['removalDate']?.toDate();
      _removalReasonController.text = data['removalReason'] ?? '';
      _offspringCountController.text =
          data['offspringCount']?.toString() ?? '0';
      _notesController.text = data['notes'] ?? '';
      _showAddForm = true;
    });
  }

  Future<void> _deleteLivestock(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.lightBlue, width: 1),
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
        content: const Text(
          'Are you sure you want to delete this sheep record?',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.lightBlue[700],
              backgroundColor: Colors.lightBlue[50],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('livestocks').doc(docId).delete();
        NotificationBar.show(
          context: context,
          message: 'Sheep record deleted successfully!',
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
    _gender = 'ram';
    _breed = 'Merino';
    _birthType = 'single';
    _birthDate = null;
    _weanDate = null;
    _removalDate = null;
    _editingLivestockId = null;
    _isExpanded = false;
    setState(() => _showAddForm = false);
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else if (isBirthDate == false &&
            _birthDate != null &&
            picked.isAfter(_birthDate!)) {
          _weanDate = picked;
        } else if (isBirthDate == false && _birthDate == null) {
          _birthDate = picked;
        }
      });
    }
  }

  Future<void> _selectRemovalDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _removalDate = picked;
      });
    }
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
                      'Sheep Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.lightBlue[800],
                      ),
                    ),
                    const Spacer(),
                    if (!_showAddForm)
                      GestureDetector(
                        onTap: () => setState(() => _showAddForm = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue[700],
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
                      .where('type', isEqualTo: 'sheep')
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
                              'No sheep recorded yet',
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
                                'Add Sheep',
                                style: TextStyle(
                                  color: Colors.lightBlue[700],
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
                              'You have ${livestock.length} sheep',
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
                        final isEwe = data['gender'] == 'ewe';

                        return GestureDetector(
                          onTap: () => setState(() {
                            _isExpanded = !_isExpanded;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.lightBlue,
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
                                          color: Colors.lightBlue[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.pets,
                                          color: Colors.lightBlue[700],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${data['name'] ?? 'Unnamed'} (ID: ${data['count']})',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${data['breed'] ?? 'Unknown'} • ${data['gender'] == 'ewe' ? 'Ewe' : 'Ram'}',
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
                                            width: 60,
                                            child: TextButton(
                                              onPressed: () =>
                                                  _editLivestock(doc),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Colors.lightBlue[700],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Edit',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          SizedBox(
                                            width: 60,
                                            child: TextButton(
                                              onPressed: () =>
                                                  _deleteLivestock(doc.id),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor:
                                                    Colors.red[700],
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 2,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (_isExpanded) ...[
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: Colors.grey[200]),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildDetailItem(
                                          Icons.scale,
                                          '${data['weight'] ?? 'N/A'} kg',
                                          Colors.blue[600]!,
                                        ),
                                        _buildDetailItem(
                                          Icons.calendar_today,
                                          data['birthDate'] != null
                                              ? DateFormat('MMM d, y').format(
                                                  (data['birthDate']
                                                          as Timestamp)
                                                      .toDate(),
                                                )
                                              : 'No birth date',
                                          Colors.orange[600]!,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.family_restroom,
                                          size: 16,
                                          color: Colors.purple[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sire: ${data['sire'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.purple[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.family_restroom,
                                          size: 16,
                                          color: Colors.purple[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Dam: ${data['dam'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.purple[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.child_care,
                                          size: 16,
                                          color: Colors.pink[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Birth type: ${data['birthType'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: Colors.pink[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (data['weanDate'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            size: 16,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Weaned: ${DateFormat('MMM d, y').format((data['weanDate'] as Timestamp).toDate())}',
                                            style: TextStyle(
                                              color: Colors.green[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (data['removalDate'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 16,
                                            color: Colors.red[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Removed: ${DateFormat('MMM d, y').format((data['removalDate'] as Timestamp).toDate())}',
                                            style: TextStyle(
                                              color: Colors.red[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reason: ${data['removalReason'] ?? 'Not specified'}',
                                        style: TextStyle(
                                          color: Colors.red[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (isEwe) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.child_friendly,
                                            size: 16,
                                            color: Colors.pink[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Offspring: ${data['offspringCount'] ?? 0}',
                                            style: TextStyle(
                                              color: Colors.pink[600],
                                              fontSize: 12,
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                        bottom: Radius.circular(0),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.lightBlue, width: 1),
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
                                    ? 'Edit Sheep Record'
                                    : 'Add Sheep Record',
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
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Sheep Name',
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
                                return 'Please enter sheep name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _countController,
                                  decoration: InputDecoration(
                                    labelText: 'Sheep ID',
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
                                      return 'Please enter sheep ID';
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
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    labelText: 'Gender',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.male,
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
                                  items: [
                                    DropdownMenuItem(
                                      value: 'ram',
                                      child: Text('Ram'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ewe',
                                      child: Text('Ewe'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _gender = value!;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select gender';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _breed,
                            decoration: InputDecoration(
                              labelText: 'Breed',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.category,
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
                            items: _breeds.map((breed) {
                              return DropdownMenuItem(
                                value: breed,
                                child: Text(breed),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _breed = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select breed';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: Text(
                              'Parent Information',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _sireController,
                                decoration: InputDecoration(
                                  labelText: 'Sire (Father) ID',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.male,
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
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _damController,
                                decoration: InputDecoration(
                                  labelText: 'Dam (Mother) ID',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.female,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: Text(
                              'Weight Information',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: 'Weight (kg)',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.scale,
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
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _weighingWeeksController,
                                decoration: InputDecoration(
                                  labelText: 'Age at Weighing (weeks)',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.timelapse,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: Text(
                              'Birth Information',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _birthType,
                                decoration: InputDecoration(
                                  labelText: 'Birth Type',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.child_care,
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
                                items: _birthTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.capitalize()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _birthType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                ),
                                title: Text(
                                  _birthDate == null
                                      ? 'Select Birth Date'
                                      : 'Birth Date: ${DateFormat('MMM d, y').format(_birthDate!)}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                leading: Icon(
                                  Icons.event,
                                  color: Colors.grey[600],
                                ),
                                title: Text(
                                  _weanDate == null
                                      ? 'Select Wean Date'
                                      : 'Wean Date: ${DateFormat('MMM d, y').format(_weanDate!)}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),
                          if (_gender == 'ewe') ...[
                            const SizedBox(height: 16),
                            ExpansionTile(
                              title: Text(
                                'Ewe Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              children: [
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _offspringCountController,
                                  decoration: InputDecoration(
                                    labelText: 'Number of Offspring',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: Icon(
                                      Icons.child_friendly,
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
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: Text(
                              'Removal Information',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              ListTile(
                                leading: Icon(
                                  Icons.event_busy,
                                  color: Colors.grey[600],
                                ),
                                title: Text(
                                  _removalDate == null
                                      ? 'Select Removal Date'
                                      : 'Removal Date: ${DateFormat('MMM d, y').format(_removalDate!)}',
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _selectRemovalDate(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _removalReasonController,
                                decoration: InputDecoration(
                                  labelText: 'Removal Reason',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: Icon(
                                    Icons.info,
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
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: 'Additional Notes',
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
                              backgroundColor: Colors.lightBlue[700],
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
                                        ? 'Update Sheep Record'
                                        : 'Add Sheep Record',
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
