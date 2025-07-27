import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../farm/notify.dart';

class FarmerDrugsPage extends StatefulWidget {
  const FarmerDrugsPage({super.key});

  @override
  State<FarmerDrugsPage> createState() => _FarmerDrugsPageState();
}

class _FarmerDrugsPageState extends State<FarmerDrugsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final String _imgbbApiKey = '55ff84fd00968e159a31fe769343ef0e';

  File? _selectedImage;
  bool _loading = false;
  String _searchQuery = '';
  String? _editingDrugId;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'Antibiotic';
  final List<String> _categories = [
    'Antibiotic',
    'Vaccine',
    'Vitamin',
    'Antiparasitic',
    'Disinfectant',
    'Other',
  ];

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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      NotificationBar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Error picking image: $e',
        isError: true,
      );
    }
  }

  Future<String?> _uploadImageToImgBB() async {
    if (_selectedImage == null) return null;

    setState(() => _loading = true);
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final mimeType = lookupMimeType(_selectedImage!.path);
      final fileName = path.basename(_selectedImage!.path);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (jsonResponse['status'] == 200) {
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Failed to upload image to ImgBB');
      }
    } catch (e) {
      NotificationBar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Image upload failed: $e',
        isError: true,
      );
      return null;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOrUpdateDrug() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty) {
      NotificationBar.show(
        context: context,
        message: 'Please fill all required fields',
        isError: true,
      );
      return;
    }

    if (double.tryParse(_priceController.text) == null ||
        int.tryParse(_quantityController.text) == null) {
      NotificationBar.show(
        context: context,
        message: 'Please enter valid numbers for price and quantity',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final imageUrl = await _uploadImageToImgBB();
      final user = _auth.currentUser;

      if (user != null) {
        final drugData = {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'dosage': _dosageController.text,
          'price': double.parse(_priceController.text),
          'quantity': int.parse(_quantityController.text),
          'farmerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add image URL if available (keep existing if editing and no new image)
        if (imageUrl != null) {
          drugData['imageUrl'] = imageUrl;
        }

        if (_editingDrugId == null) {
          // Add new drug
          drugData['createdAt'] = FieldValue.serverTimestamp();
          await _firestore.collection('drugs').add(drugData);
          NotificationBar.show(
            // ignore: use_build_context_synchronously
            context: context,
            message: 'Drug added successfully',
            isError: false,
          );
        } else {
          // Update existing drug
          await _firestore
              .collection('drugs')
              .doc(_editingDrugId)
              .update(drugData);
          NotificationBar.show(
            // ignore: use_build_context_synchronously
            context: context,
            message: 'Drug updated successfully',
            isError: false,
          );
        }

        // Clear form
        _clearForm();
      }
    } catch (e) {
      NotificationBar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Error saving drug: $e',
        isError: true,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteDrug(String drugId) async {
    try {
      await _firestore.collection('drugs').doc(drugId).delete();
      NotificationBar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Drug deleted successfully',
        isError: false,
      );
    } catch (e) {
      NotificationBar.show(
        // ignore: use_build_context_synchronously
        context: context,
        message: 'Error deleting drug: $e',
        isError: true,
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _dosageController.clear();
    _priceController.clear();
    _quantityController.clear();
    setState(() {
      _selectedImage = null;
      _editingDrugId = null;
    });
  }

  void _loadDrugForEditing(Map<String, dynamic> drug, String drugId) {
    _nameController.text = drug['name'];
    _descriptionController.text = drug['description'] ?? '';
    _dosageController.text = drug['dosage'] ?? '';
    _priceController.text = drug['price'].toString();
    _quantityController.text = drug['quantity'].toString();
    _selectedCategory = drug['category'] ?? 'Antibiotic';
    setState(() {
      _editingDrugId = drugId;
    });
  }

  Widget _buildDrugIcon(String category) {
    switch (category) {
      case 'Antibiotic':
        return Icon(Icons.medical_services, color: Colors.blue[700]);
      case 'Vaccine':
        return Icon(Icons.medical_information, color: Colors.lightBlue[700]);
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
        title: const Text('Farm Drugs Management'),
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearForm();
              _showAddDrugDialog(context);
            },
          ),
        ],
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
                        // ignore: prefer_interpolation_to_compose_strings
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
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _clearForm();
                            _showAddDrugDialog(context);
                          },
                          child: const Text('Add First Drug'),
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
                    final drugId = doc.id;

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
                                  // ignore: sort_child_properties_last
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
                                    color: Colors.lightBlue,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => _showDrugDetails(context, data),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    _loadDrugForEditing(data, drugId);
                                    _showAddDrugDialog(context);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _showDeleteConfirmation(context, drugId),
                                ),
                              ],
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

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String drugId,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this drug?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteDrug(drugId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDrugDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingDrugId == null ? 'Add New Drug' : 'Edit Drug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Drug Name*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (Kes)*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity*',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty ||
                  _priceController.text.isEmpty ||
                  _quantityController.text.isEmpty) {
                NotificationBar.show(
                  context: context,
                  message: 'Please fill all required fields (*)',
                  isError: true,
                );
                return;
              }

              await _addOrUpdateDrug();
              if (!mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(_editingDrugId == null ? 'Add Drug' : 'Update Drug'),
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
 //--