import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('other_payments')
        .orderBy('timestamp', descending: true)
        .get();

    print("📦 Fetched ${snapshot.docs.length} documents from Firestore");

    setState(() {
      _payments.clear();
      _payments.addAll(snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList());
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
    if (_nameController.text.isEmpty ||
        _paymentTypeController.text.isEmpty ||
        _amountController.text.isEmpty) {
      print("❌ Some fields are empty");
      return;
    }

    final paymentData = {
      'name': _nameController.text.trim(),
      'type': _paymentTypeController.text.trim(),
      'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
      'date': DateTime.now().toString().substring(0, 10),
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('other_payments')
          .add(paymentData);

      setState(() {
        _payments.add({...paymentData, 'docId': docRef.id});
        _nameController.clear();
        _paymentTypeController.clear();
        _amountController.clear();
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
    _nameController.text = payment['name'];
    _paymentTypeController.text = payment['type'];
    _amountController.text = payment['amount'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Payment'),
        content: const Text('Update this payment?'),
        actions: [
          TextButton(
            onPressed: () async {
              final updatedData = {
                'name': _nameController.text.trim(),
                'type': _paymentTypeController.text.trim(),
                'amount': double.tryParse(_amountController.text.trim()) ?? 0.0,
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
                      (p) => p['docId'] == payment['docId']);
                  _payments[indexInList] = {
                    ...updatedData,
                    'docId': payment['docId']
                  };
                });

                Navigator.pop(context);
                _nameController.clear();
                _paymentTypeController.clear();
                _amountController.clear();
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

  double get _totalAmount => _filteredPayments.fold(
      0.0, (sum, item) => sum + (item['amount'] ?? 0.0));

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
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or payment type',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Member Name',
                    border: OutlineInputBorder(),
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
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
                child: const Text('Submit', style: TextStyle(color: Colors.white)),
              )
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
                          leading:
                              const Icon(Icons.money, color: Colors.green),
                          title: Text('${payment['name']} - ${payment['type']}'),
                          subtitle: Text(
                              'Ksh ${payment['amount']} on ${payment['date']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editPayment(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
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
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
