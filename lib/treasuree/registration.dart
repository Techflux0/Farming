// ignore_for_file: use_build_context_synchronously, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../farm/notify.dart';
import 'export_registration.dart';

class RegistrationFeePage extends StatefulWidget {
  const RegistrationFeePage({super.key});

  @override
  State<RegistrationFeePage> createState() => _RegistrationFeePageState();
}

class _RegistrationFeePageState extends State<RegistrationFeePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountPayableController = TextEditingController(text: '2000');
  final _amountPaidController = TextEditingController();
  final _searchController = TextEditingController();
  final _memberSearchController = TextEditingController();
  DateTime? _selectedDate;
  String _searchQuery = '';
  bool _isSubmitting = false;
  String? _selectedMemberId;
  String? _selectedMemberName;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoadingMembers = true;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _memberFocusNode = FocusNode();

  DocumentSnapshot? _editingDoc;

  double get balance {
    final payable = double.tryParse(_amountPayableController.text) ?? 0;
    final paid = double.tryParse(_amountPaidController.text) ?? 0;
    return payable - paid;
  }

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _selectedDate = DateTime.now();

    _memberFocusNode.addListener(() {
      if (_memberFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });

    _memberSearchController.addListener(() {
      _filterMembers(_memberSearchController.text);
    });

    _amountPaidController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _memberFocusNode.dispose();
    _memberSearchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((member) {
          final name = member['fullname'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _filteredMembers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No members found'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = _filteredMembers[index];
                        return ListTile(
                          title: Text(member['fullname']),
                          onTap: () {
                            _selectMember(member);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _selectMember(Map<String, dynamic> member) {
    setState(() {
      _selectedMemberId = member['id'];
      _selectedMemberName = member['fullname'];
      _memberSearchController.text = member['fullname'];
      _removeOverlay();
      _memberFocusNode.unfocus();
    });
  }

  Future<void> _fetchMembers() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('fullname')
          .get();

      setState(() {
        _members = querySnapshot.docs.map((doc) {
          return {'id': doc.id, 'fullname': doc['fullname'] ?? 'Unknown'};
        }).toList();
        _filteredMembers = _members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      debugPrint('Error fetching members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      NotificationBar.show(
        context: context,
        message: 'Please select a member',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'name': _selectedMemberName,
      'user_id': _selectedMemberId,
      'fullname': _selectedMemberName,
      'amount_payable': double.parse(_amountPayableController.text),
      'amount_paid': double.parse(_amountPaidController.text),
      'balance': balance,
      'payment_date': _selectedDate ?? DateTime.now(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingDoc != null) {
        // Update
        await FirebaseFirestore.instance
            .collection('registration_fees')
            .doc(_editingDoc!.id)
            .update(data);
        NotificationBar.show(
          context: context,
          message: '✔ Registration fee updated',
          isError: false,
        );
      } else {
        // Create
        await FirebaseFirestore.instance
            .collection('registration_fees')
            .add(data);
        NotificationBar.show(
          context: context,
          message: '✔ Registration fee added',
          isError: false,
        );
      }

      _resetForm();
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Error: $e',
        isError: true,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _exportData() async {
    // Sample function for export - to be implemented later
    NotificationBar.show(
      context: context,
      message: 'Export functionality will be implemented soon',
      isError: false,
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _selectedMemberId = null;
    _selectedMemberName = null;
    _memberSearchController.clear();
    _amountPayableController.text = '2000';
    _amountPaidController.clear();
    _selectedDate = DateTime.now();
    _editingDoc = null;
    setState(() {});
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDoc = doc;
      _selectedMemberId = data['user_id'];
      _selectedMemberName = data['fullname'] ?? data['name'];
      _memberSearchController.text = _selectedMemberName!;
      _amountPayableController.text = data['amount_payable'].toString();
      _amountPaidController.text = data['amount_paid'].toString();
      _selectedDate = (data['payment_date'] as Timestamp).toDate();
    });
  }

  Future<void> _deleteRecord(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.lightBlue, width: 1),
        ),
        title: const Center(
          child: Text(
            'Confirm Delete',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.black54, fontSize: 15),
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
        await FirebaseFirestore.instance
            .collection('registration_fees')
            .doc(id)
            .delete();
        NotificationBar.show(
          context: context,
          message: '🗑️ Record deleted',
          isError: false,
        );
      } catch (e) {
        NotificationBar.show(
          context: context,
          message: 'Error deleting record: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Fees'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Member Name Dropdown with Search (using your approach)
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: TextFormField(
                      controller: _memberSearchController,
                      focusNode: _memberFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Select Member',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.lightBlue,
                        ),
                        suffixIcon: _isLoadingMembers
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                onPressed: () {
                                  if (_memberFocusNode.hasFocus) {
                                    _memberFocusNode.unfocus();
                                  } else {
                                    _memberFocusNode.requestFocus();
                                  }
                                },
                              ),
                      ),
                      validator: (value) => _selectedMemberId == null
                          ? 'Please select a member'
                          : null,
                      onTap: () {
                        if (_overlayEntry == null) {
                          _showOverlay();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Amount Payable (readonly)
                  TextFormField(
                    controller: _amountPayableController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Amount Payable (KES)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.monetization_on,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (KES)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.monetization_on,
                        color: Colors.lightBlue,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter amount paid' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'No date selected'
                              : 'Payment Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Pick Date'),
                        onPressed: () => _pickDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Balance: KES ${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: balance > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: Icon(
                            _editingDoc == null ? Icons.add : Icons.update,
                          ),
                          label: Text(
                            _editingDoc == null ? 'Submit' : 'Update',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final exporter = RegistrationExporter();
                          try {
                            final filePath = await exporter
                                .exportRegistrationToExcel(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Export saved: $filePath'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Export failed: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '📋 Payment Records',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.lightBlue,
              ),
            ),
            const SizedBox(height: 5),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('registration_fees')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['fullname'] ?? doc['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final name = data['fullname'] ?? data['name'] ?? '';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Colors.lightBlue,
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Colors.lightBlue,
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payable: KES ${data['amount_payable']} | Paid: KES ${data['amount_paid']}',
                            ),
                            Text(
                              'Balance: KES ${data['balance']}',
                              style: TextStyle(
                                color: (data['balance'] > 0)
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (data['payment_date'] != null)
                              Text(
                                'Date: ${DateFormat('yyyy-MM-dd').format((data['payment_date'] as Timestamp).toDate())}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                                size: 20,
                              ),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deleteRecord(docId, name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
