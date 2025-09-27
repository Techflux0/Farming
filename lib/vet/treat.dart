// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../farm/notify.dart';

class MedicalTreatmentScreen extends StatefulWidget {
  const MedicalTreatmentScreen({super.key});

  @override
  State<MedicalTreatmentScreen> createState() => _MedicalTreatmentScreenState();
}

class _MedicalTreatmentScreenState extends State<MedicalTreatmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  Map<String, dynamic>? _foundSheep;
  Map<String, dynamic>? _farmerDetails;
  Map<String, dynamic>? _lastTreatment;
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _diagnosisController.dispose();
    _costController.dispose();
    _medicineController.dispose();
    _dosageController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _searchSheep() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundSheep = null;
      _farmerDetails = null;
      _lastTreatment = null;
    });

    try {
      final sheepId = _searchController.text.trim();

      // Search in livestocks collection for the sheep
      final livestockQuery = await _firestore
          .collection('livestocks')
          .where('count', isEqualTo: int.tryParse(sheepId) ?? 0)
          .where('type', isEqualTo: 'sheep')
          .limit(1)
          .get();

      if (livestockQuery.docs.isEmpty) {
        NotificationBar.show(
          context: context,
          message: 'Sheep with ID $sheepId not found',
          isError: true,
        );
        return;
      }

      final sheepData = livestockQuery.docs.first.data();
      final userId = sheepData['userId'];

      // Get farmer details from users collection
      final userDoc = await _firestore.collection('users').doc(userId).get();

      // Get last treatment for this sheep
      final treatmentQuery = await _firestore
          .collection('medicals')
          .where('sheepId', isEqualTo: sheepId)
          .orderBy('treatmentDate', descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? lastTreatment;
      if (treatmentQuery.docs.isNotEmpty) {
        lastTreatment = treatmentQuery.docs.first.data();
      }

      setState(() {
        _foundSheep = sheepData;
        _farmerDetails = userDoc.data();
        _lastTreatment = lastTreatment;
      });
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error searching for sheep: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showTreatmentDialog() {
    if (_foundSheep == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medical Treatment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.lightBlue[800],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Sheep Info Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.lightBlue[100]!),
                      ),
                      child: Row(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_foundSheep!['name'] ?? 'Unnamed'} (ID: ${_foundSheep!['count']})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  '${_foundSheep!['breed'] ?? 'Unknown'} • ${_foundSheep!['gender'] == 'ewe' ? 'Ewe' : 'Ram'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Treatment Form
                    TextFormField(
                      controller: _diagnosisController,
                      decoration: InputDecoration(
                        labelText: 'Diagnosis *',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.medical_services,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter diagnosis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _medicineController,
                      decoration: InputDecoration(
                        labelText: 'Medicine Given *',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(
                          Icons.medication,
                          color: Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medicine name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dosageController,
                            decoration: InputDecoration(
                              labelText: 'Dosage *',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: Icon(
                                Icons.science,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
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
                                return 'Please enter dosage';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _costController,
                            decoration: InputDecoration(
                              labelText: 'Cost (KSH) *',
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
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter cost';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        labelText: 'Remarks',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.note, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTreatment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : const Text(
                              'Save Treatment Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveTreatment() async {
    if (_diagnosisController.text.isEmpty ||
        _medicineController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _costController.text.isEmpty) {
      NotificationBar.show(
        context: context,
        message: 'Please fill all required fields',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final treatmentData = {
        'sheepId': _foundSheep!['count'].toString(),
        'sheepData': _foundSheep,
        'userId': _foundSheep!['userId'],
        'farmerDetails': _farmerDetails, // Store farmer details for easy access
        'diagnosis': _diagnosisController.text.trim(),
        'medicine': _medicineController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'cost': double.tryParse(_costController.text) ?? 0.0,
        'remarks': _remarksController.text.trim(),
        'treatedBy': user.uid,
        'treatedByName': user.displayName ?? 'Veterinarian',
        'treatmentDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('medicals').add(treatmentData);

      NotificationBar.show(
        context: context,
        message: 'Treatment record saved successfully!',
        isError: false,
      );

      // Clear form and close dialog
      _diagnosisController.clear();
      _medicineController.clear();
      _dosageController.clear();
      _costController.clear();
      _remarksController.clear();

      Navigator.pop(context);

      // Refresh the search to show the new treatment
      _searchSheep();
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error saving treatment: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(birthDate);

    if (difference.inDays < 30) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months';
    } else {
      return '${(difference.inDays / 365).floor()} years';
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    return DateFormat('MMM d, y - HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                  'Medical Treatment',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.lightBlue[800],
                  ),
                ),
              ],
            ),
          ),

          // Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Sheep ID',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _searchSheep(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchSheep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _foundSheep == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Enter Sheep ID to search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Sheep Details Card
                        Container(
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
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.lightBlue[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_foundSheep!['name'] ?? 'Unnamed'} (ID: ${_foundSheep!['count']})',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          Text(
                                            '${_foundSheep!['breed'] ?? 'Unknown'} • ${_foundSheep!['gender'] == 'ewe' ? 'Ewe' : 'Ram'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _showTreatmentDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'TREAT',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(height: 1, color: Colors.grey[200]),
                                const SizedBox(height: 12),

                                // Sheep Details
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildDetailItem(
                                      Icons.cake,
                                      'Age: ${_calculateAge(_foundSheep!['birthDate']?.toDate())}',
                                      Colors.orange[600]!,
                                    ),
                                    _buildDetailItem(
                                      Icons.scale,
                                      'Weight: ${_foundSheep!['weight']?.toString() ?? 'N/A'} kg',
                                      Colors.blue[600]!,
                                    ),
                                    _buildDetailItem(
                                      Icons.child_care,
                                      'Birth Type: ${_foundSheep!['birthType'] ?? 'Unknown'}',
                                      Colors.pink[600]!,
                                    ),
                                    if (_foundSheep!['weanDate'] != null)
                                      _buildDetailItem(
                                        Icons.event,
                                        'Weaned: ${DateFormat('MMM d, y').format(_foundSheep!['weanDate']!.toDate())}',
                                        Colors.green[600]!,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Last Treatment Card
                        if (_lastTreatment != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
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
                                          color: Colors.orange[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.medical_services,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Last Treatment',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(height: 1, color: Colors.grey[200]),
                                  const SizedBox(height: 12),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildTreatmentDetail(
                                        'Diagnosis:',
                                        _lastTreatment!['diagnosis'],
                                      ),
                                      _buildTreatmentDetail(
                                        'Medicine:',
                                        _lastTreatment!['medicine'],
                                      ),
                                      _buildTreatmentDetail(
                                        'Dosage:',
                                        _lastTreatment!['dosage'],
                                      ),
                                      _buildTreatmentDetail(
                                        'Cost:',
                                        '₦${_lastTreatment!['cost']?.toStringAsFixed(2) ?? '0.00'}',
                                      ),
                                      _buildTreatmentDetail(
                                        'Treated by:',
                                        _lastTreatment!['treatedByName'] ??
                                            'Veterinarian',
                                      ),
                                      _buildTreatmentDetail(
                                        'Date:',
                                        _formatDate(
                                          _lastTreatment!['treatmentDate'],
                                        ),
                                      ),
                                      if (_lastTreatment!['remarks'] != null &&
                                          _lastTreatment!['remarks'].isNotEmpty)
                                        _buildTreatmentDetail(
                                          'Remarks:',
                                          _lastTreatment!['remarks'],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Farmer Details Card
                        if (_farmerDetails != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 1),
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
                                          Icons.person,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Farmer Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(height: 1, color: Colors.grey[200]),
                                  const SizedBox(height: 12),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFarmerDetail(
                                        'Full Name:',
                                        _farmerDetails!['fullname'] ?? 'N/A',
                                      ),
                                      _buildFarmerDetail(
                                        'Phone:',
                                        _farmerDetails!['primary_phone'] ??
                                            'N/A',
                                      ),
                                      if (_farmerDetails!['secondary_phone'] !=
                                          null)
                                        _buildFarmerDetail(
                                          'Secondary Phone:',
                                          _farmerDetails!['secondary_phone'],
                                        ),
                                      _buildFarmerDetail(
                                        'Address:',
                                        _farmerDetails!['address'] ?? 'N/A',
                                      ),
                                      _buildFarmerDetail(
                                        'Email:',
                                        _farmerDetails!['email'] ?? 'N/A',
                                      ),
                                      _buildFarmerDetail(
                                        'Membership:',
                                        _farmerDetails!['membership_status'] ??
                                            'N/A',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
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

  Widget _buildTreatmentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
