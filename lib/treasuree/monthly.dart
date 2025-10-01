// ignore_for_file: use_build_context_synchronously, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'export_monthly.dart';

class MonthlyPaymentPage extends StatefulWidget {
  const MonthlyPaymentPage({super.key});

  @override
  State<MonthlyPaymentPage> createState() => _MonthlyPaymentPageState();
}

class _MonthlyPaymentPageState extends State<MonthlyPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountPayableController = TextEditingController();
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
  double _previousBalance = 0.0;
  bool _hasExistingPayment = false;
  String? _existingPaymentId;

  DocumentSnapshot? _editingDoc;

  double get baseAmountPayable {
    return 200.0;
  }

  double get calculatedAmountPayable {
    if (_selectedDate == null) return baseAmountPayable;

    // Add penalty of KES 100 if payment is made after the 10th of the month
    final day = _selectedDate!.day;
    return day > 10 ? baseAmountPayable + 100 : baseAmountPayable;
  }

  double get totalAmountPayable {
    return calculatedAmountPayable + _previousBalance;
  }

  double get balance {
    final paid = double.tryParse(_amountPaidController.text) ?? 0;
    return totalAmountPayable - paid;
  }

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _selectedDate = DateTime.now();
    _updateAmountPayable();

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

  Future<void> _selectMember(Map<String, dynamic> member) async {
    setState(() {
      _selectedMemberId = member['id'];
      _selectedMemberName = member['fullname'];
      _memberSearchController.text = member['fullname'];
      _removeOverlay();
      _memberFocusNode.unfocus();
    });

    await _checkExistingPayment();
  }

  Future<void> _checkExistingPayment() async {
    if (_selectedMemberId == null) return;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('monthly_payment')
          .where('member_id', isEqualTo: _selectedMemberId)
          .where('payment_date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .orderBy('payment_date', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final paymentData = querySnapshot.docs.first.data();
        setState(() {
          _hasExistingPayment = true;
          _existingPaymentId = querySnapshot.docs.first.id;
          _previousBalance = (paymentData['balance'] as num).toDouble();
          _amountPaidController.text = '0';
          _updateAmountPayable();
        });
      } else {
        final debtQuery = await FirebaseFirestore.instance
            .collection('monthly_payment')
            .where('member_id', isEqualTo: _selectedMemberId)
            .orderBy('payment_date', descending: true)
            .limit(1)
            .get();

        if (debtQuery.docs.isNotEmpty) {
          final lastPayment = debtQuery.docs.first.data();
          final lastBalance = (lastPayment['balance'] as num).toDouble();

          setState(() {
            _hasExistingPayment = false;
            _previousBalance = lastBalance > 0 ? lastBalance : 0;
            _amountPaidController.text = '0';
            _updateAmountPayable();
          });
        } else {
          setState(() {
            _hasExistingPayment = false;
            _previousBalance = 0;
            _amountPaidController.text = '0';
            _updateAmountPayable();
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking existing payment: $e');
    }
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
      setState(() {
        _selectedDate = picked;
        _updateAmountPayable();
      });
    }
  }

  void _updateAmountPayable() {
    _amountPayableController.text = totalAmountPayable.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Please select a member')));
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'member_id': _selectedMemberId,
      'name': _selectedMemberName,
      'amount_payable': totalAmountPayable,
      'amount_paid': double.parse(_amountPaidController.text),
      'balance': balance,
      'payment_date': _selectedDate,
      'timestamp': FieldValue.serverTimestamp(),
      'has_penalty': _selectedDate != null && _selectedDate!.day > 10,
      'previous_balance': _previousBalance,
    };

    try {
      if (_editingDoc != null) {
        await FirebaseFirestore.instance
            .collection('monthly_payment')
            .doc(_editingDoc!.id)
            .update(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ Record updated successfully')),
        );
      } else if (_hasExistingPayment && _existingPaymentId != null) {
        await FirebaseFirestore.instance
            .collection('monthly_payment')
            .doc(_existingPaymentId)
            .update(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ Payment updated successfully')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('monthly_payment')
            .add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✔ Monthly payment recorded')),
        );
      }

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _selectedMemberId = null;
    _selectedMemberName = null;
    _memberSearchController.clear();
    _amountPaidController.clear();
    _selectedDate = DateTime.now();
    _previousBalance = 0;
    _hasExistingPayment = false;
    _existingPaymentId = null;
    _updateAmountPayable();
    _editingDoc = null;
    setState(() {});
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingDoc = doc;
      _selectedMemberId = data['member_id'];
      _selectedMemberName = data['name'];
      _memberSearchController.text = data['name'];
      _amountPaidController.text = data['amount_paid'].toString();
      _selectedDate = (data['payment_date'] as Timestamp).toDate();
      _previousBalance = (data['previous_balance'] as num?)?.toDouble() ?? 0;
      _updateAmountPayable();
    });
  }

  Future<void> _deleteRecord(String id) async {
    await FirebaseFirestore.instance
        .collection('monthly_payment')
        .doc(id)
        .delete();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑️ Record deleted')));
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Export functionality will be implemented'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' Monthly Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CompositedTransformTarget(
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
                  const SizedBox(height: 10),

                  // Display member's payment status
                  if (_selectedMemberId != null)
                    Card(
                      color: _hasExistingPayment
                          ? Colors.blue[50]
                          : Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasExistingPayment
                                  ? '📋 Member has already made a payment this month'
                                  : '✅ No payment recorded for this month',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _hasExistingPayment
                                    ? Colors.blue[700]
                                    : Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Previous balance: KES ${_previousBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: _previousBalance > 0
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountPayableController,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Total Amount Payable (KES)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.money),
                      suffixIcon:
                          _selectedDate != null && _selectedDate!.day > 10
                          ? Tooltip(
                              message: 'Includes KES 100 late payment penalty',
                              child: const Icon(
                                Icons.warning_amber,
                                color: Colors.orange,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (KES)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
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
                            _editingDoc == null
                                ? (_hasExistingPayment
                                      ? Icons.update
                                      : Icons.add)
                                : Icons.update,
                          ),
                          label: Text(
                            _editingDoc == null
                                ? (_hasExistingPayment
                                      ? 'Update Payment'
                                      : 'Submit Payment')
                                : 'Update Record',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasExistingPayment
                                ? Colors.orange
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final exporter = PaymentExporter();
                          try {
                            final filePath = await exporter
                                .exportPaymentsToExcel(context);
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
                hintText: 'Search payment records by name...',
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
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('monthly_payment')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final hasPenalty = data['has_penalty'] ?? false;
                    final previousBalance =
                        (data['previous_balance'] as num?)?.toDouble() ?? 0;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(data['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payable: KES ${data['amount_payable'].toStringAsFixed(2)} | Paid: KES ${data['amount_paid'].toStringAsFixed(2)}',
                            ),
                            if (previousBalance > 0)
                              Text(
                                'Previous debt: KES ${previousBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            if (hasPenalty)
                              const Text(
                                'Includes KES 100 late penalty',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'Balance: KES ${data['balance'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: (data['balance'] > 0)
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                              ),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecord(docId),
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
