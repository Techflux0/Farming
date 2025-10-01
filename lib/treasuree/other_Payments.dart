// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as ex;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class OtherPaymentPage extends StatefulWidget {
  const OtherPaymentPage({super.key});

  @override
  State<OtherPaymentPage> createState() => _OtherPaymentPageState();
}

class _OtherPaymentPageState extends State<OtherPaymentPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _paymentTypeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();

  final List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoadingMembers = true;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _memberFocusNode = FocusNode();
  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _fetchMembers();

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

  Future<void> _loadPayments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('other_payments')
        .orderBy('timestamp', descending: true)
        .get();

    print("📦 Fetched ${snapshot.docs.length} documents from Firestore");

    setState(() {
      _payments.clear();
      _payments.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['docId'] = doc.id;
          return data;
        }).toList(),
      );
    });
  }

  List<Map<String, dynamic>> get _filteredPayments {
    final keyword = _searchController.text.toLowerCase();
    return _payments.where((payment) {
      return payment['name'].toLowerCase().contains(keyword) ||
          payment['type'].toLowerCase().contains(keyword);
    }).toList();
  }

  Future<void> _addPayment() async {
    if (_memberSearchController.text.isEmpty ||
        _paymentTypeController.text.isEmpty ||
        _amountController.text.isEmpty) {
      print("❌ Some fields are empty");
      return;
    }

    final paymentData = {
      'name': _memberSearchController.text.trim(),
      'user_id': _selectedMemberId,
      'type': _paymentTypeController.text.trim(),
      'amount_paid': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'date': DateTime.now().toString().substring(0, 10),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('other_payments')
          .add(paymentData);

      setState(() {
        _payments.add({...paymentData, 'docId': docRef.id});
        _memberSearchController.clear();
        _paymentTypeController.clear();
        _amountController.clear();
        _selectedMemberId = null;
      });
    } catch (e) {
      print("❌ Failed to add to Firestore: $e");
    }
  }

  Future<void> _deletePayment(int index) async {
    final payment = _filteredPayments[index];
    final docId = payment['docId'];

    try {
      await FirebaseFirestore.instance
          .collection('other_payments')
          .doc(docId)
          .delete();

      setState(() {
        _payments.removeWhere((p) => p['docId'] == docId);
      });
    } catch (e) {
      print("❌ Failed to delete: $e");
    }
  }

  void _editPayment(int index) {
    final payment = _filteredPayments[index];
    _memberSearchController.text = payment['name'];
    _paymentTypeController.text = payment['type'];
    _amountController.text = payment['amount_paid'].toString();
    _selectedMemberId = payment['user_id'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Payment'),
        content: const Text('Update this payment?'),
        actions: [
          TextButton(
            onPressed: () async {
              final updatedData = {
                'name': _memberSearchController.text.trim(),
                'user_id': _selectedMemberId,
                'type': _paymentTypeController.text.trim(),
                'amount_paid':
                    double.tryParse(_amountController.text.trim()) ?? 0.0,
                'date': DateTime.now().toString().substring(0, 10),
                'timestamp': FieldValue.serverTimestamp(),
              };

              try {
                await FirebaseFirestore.instance
                    .collection('other_payments')
                    .doc(payment['docId'])
                    .update(updatedData);

                setState(() {
                  final indexInList = _payments.indexWhere(
                    (p) => p['docId'] == payment['docId'],
                  );
                  _payments[indexInList] = {
                    ...updatedData,
                    'docId': payment['docId'],
                  };
                });

                Navigator.pop(context);
                _memberSearchController.clear();
                _paymentTypeController.clear();
                _amountController.clear();
                _selectedMemberId = null;
              } catch (e) {
                print("❌ Failed to update: $e");
              }
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['Other Payments'];

      // Add headers
      sheet.appendRow([
        ex.TextCellValue('Member Name'),
        ex.TextCellValue('Payment Type'),
        ex.TextCellValue('Amount Paid (KES)'),
        ex.TextCellValue('Date'),
      ]);

      // Add data rows
      for (final payment in _filteredPayments) {
        sheet.appendRow([
          ex.TextCellValue(payment['name']),
          ex.TextCellValue(payment['type']),
          ex.TextCellValue(payment['amount_paid'].toString()),
          ex.TextCellValue(payment['date']),
        ]);
      }

      // Add totals
      final totalAmount = _filteredPayments.fold(
        0.0,
        (sum, item) => sum + (item['amount_paid'] ?? 0.0),
      );

      sheet.appendRow([ex.TextCellValue('')]);
      sheet.appendRow([
        ex.TextCellValue('TOTALS:'),
        ex.TextCellValue(''),
        ex.TextCellValue(totalAmount.toStringAsFixed(2)),
        ex.TextCellValue(''),
      ]);

      // Save the document
      final String fileName =
          'Other_Payments_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final fileBytes = excel.save();

      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Get directory path
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final filePath = '$path/$fileName';

      // Write to file
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Open the file
      await OpenFile.open(filePath);

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
  }

  double get _totalAmount => _filteredPayments.fold(
    0.0,
    (sum, item) => sum + (item['amount_paid'] ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Payments',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or payment type',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Input Row
          Row(
            children: [
              // Member Dropdown
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    controller: _memberSearchController,
                    focusNode: _memberFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Select Member',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
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
                    onTap: () {
                      if (_overlayEntry == null) {
                        _showOverlay();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _paymentTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (Ksh)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit and Export Buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: _addPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Payments List
          Expanded(
            child: _filteredPayments.isEmpty
                ? const Center(child: Text('No payments found'))
                : ListView.builder(
                    itemCount: _filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = _filteredPayments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.money, color: Colors.green),
                          title: Text(
                            '${payment['name']} - ${payment['type']}',
                          ),
                          subtitle: Text(
                            'Ksh ${payment['amount_paid']} on ${payment['date']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editPayment(index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePayment(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Total Payments: ${_filteredPayments.length} | Total Amount: Ksh ${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
