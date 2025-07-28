// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../farm/notify.dart';

class CommunicationHomeScreen extends StatefulWidget {
  const CommunicationHomeScreen({super.key});

  @override
  _CommunicationHomeScreenState createState() =>
      _CommunicationHomeScreenState();
}

class _CommunicationHomeScreenState extends State<CommunicationHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedType;
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String message,
    String type,
  ) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: 'Failed to send message',
        isError: true,
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
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
        content: const Text(
          'Are you sure you want to delete this message?',
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
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = const Color.fromARGB(255, 222, 231, 235);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.message, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Communication'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Secretary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.lightBlue, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Select Message Type',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Meeting Announcement',
                          child: Text('Meeting Announcement'),
                        ),
                        DropdownMenuItem(
                          value: 'Deadline Notification',
                          child: Text('Deadline Notification'),
                        ),
                        DropdownMenuItem(
                          value: 'System-wide Message',
                          child: Text('System-wide Message'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Message Type',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _receiverController,
                      decoration: const InputDecoration(
                        labelText: 'Receiver ID (leave blank for all)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(labelText: 'Message'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Send',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                            ),
                            onPressed: () async {
                              final senderId = 'secretary';
                              final receiverId = _receiverController.text
                                  .trim();
                              final message = _messageController.text.trim();
                              if (message.isNotEmpty && _selectedType != null) {
                                await sendMessage(
                                  senderId,
                                  receiverId,
                                  message,
                                  _selectedType!,
                                );
                                _messageController.clear();
                                _receiverController.clear();
                                setState(() {
                                  _selectedType = null;
                                });
                                NotificationBar.show(
                                  context: context,
                                  message: 'Message sent successfully',
                                  isError: false,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            label: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                            ),
                            onPressed: () {
                              _messageController.clear();
                              _receiverController.clear();
                              setState(() {
                                _selectedType = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Messages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Error loading messages');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No messages found.');
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.lightBlue,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            data['type'] == 'Meeting Announcement'
                                ? Icons.event
                                : data['type'] == 'Deadline Notification'
                                ? Icons.timer
                                : Icons.campaign,
                            color: Colors.lightBlue,
                          ),
                          title: Text(data['type'] ?? 'Message'),
                          subtitle: Text(data['message'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                  foregroundColor: Colors.lightBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () => _showEditDialog(doc, data),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.lightBlue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  final confirmed =
                                      await _showDeleteConfirmationDialog();
                                  if (confirmed == true) {
                                    await _firestore
                                        .collection('messages')
                                        .doc(doc.id)
                                        .delete();
                                    NotificationBar.show(
                                      context: context,
                                      message: 'Message deleted!',
                                      isError: false,
                                    );
                                  }
                                },
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
      ),
    );
  }

  Future<void> _showEditDialog(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController editController = TextEditingController(
      text: data['message'],
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.lightBlue, width: 1),
        ),
        title: const Center(
          child: Text(
            'Edit Message',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Message',
          ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightBlue[700],
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, editController.text),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await _firestore.collection('messages').doc(doc.id).update({
        'message': result.trim(),
      });
      NotificationBar.show(
        context: context,
        message: 'Message updated!',
        isError: false,
      );
    }
  }
}
