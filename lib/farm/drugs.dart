import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FarmerDrugsPage extends StatefulWidget {
  const FarmerDrugsPage({super.key});

  @override
  State<FarmerDrugsPage> createState() => _FarmerDrugsPageState();
}

class _FarmerDrugsPageState extends State<FarmerDrugsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String _searchQuery = '';

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDrugIcon(String category) {
    switch (category) {
      case 'Antibiotic':
        return Icon(Icons.medical_services, color: Colors.blue[700]);
      case 'Vaccine':
        return Icon(Icons.medical_information, color: Colors.green[700]);
      case 'Vitamin':
        return Icon(Icons.health_and_safety, color: Colors.orange[700]);
      case 'Antiparasitic':
        return Icon(Icons.bug_report, color: Colors.purple[700]);
      case 'Disinfectant':
        return Icon(Icons.clean_hands, color: Colors.teal[700]);
      default:
        return Icon(Icons.medication, color: Colors.red[700]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Farm Drugs'),
        backgroundColor: Colors.green[700],
        actions: [],
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
                    labelText: 'Search drugs',
                    hintText: 'Enter drug name or category',
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
                        .collection('drugs')
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : _firestore
                        .collection('drugs')
                        .where('name', isGreaterThanOrEqualTo: _searchQuery)
                        .where('name', isLessThan: _searchQuery + 'z')
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading drugs',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No drugs added yet'
                              : 'No matching drugs found',
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[200],
                                  child: _buildDrugIcon(data['category']),
                                  foregroundImage: data['imageUrl'] != null
                                      ? NetworkImage(data['imageUrl'])
                                      : null,
                                ),
                                title: Text(
                                  data['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${data['category']} • ${data['quantity']} available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Text(
                                  'Kes${data['price'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => _showDrugDetails(context, data),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [],
                            ),
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
    );
  }

  Future<void> _showDrugDetails(
    BuildContext context,
    Map<String, dynamic> drug,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(drug['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (drug['imageUrl'] != null)
                Center(
                  child: Image.network(
                    drug['imageUrl'],
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailItem('Category', drug['category']),
              _buildDetailItem('Description', drug['description']),
              _buildDetailItem('Dosage', drug['dosage']),
              _buildDetailItem(
                'Price',
                'Kes${drug['price'].toStringAsFixed(2)}',
              ),
              _buildDetailItem('Quantity', drug['quantity'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
