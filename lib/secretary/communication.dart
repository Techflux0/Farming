import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunicationHomeScreen extends StatefulWidget {
  const CommunicationHomeScreen({super.key});

  @override
  _CommunicationHomeScreenState createState() => _CommunicationHomeScreenState();
}

class _CommunicationHomeScreenState extends State<CommunicationHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedType = 'Meeting Announcement';
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false; // Suggestion 2: Loading indicator

  Future<void> sendMessage(String senderId, String receiverId, String message, String type) async {
    setState(() {
      _isSending = true;
    });
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Success feedback is handled below
    } catch (e) {
      // Suggestion 4: Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Stream<QuerySnapshot> getMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardColor = Colors.blue[50]!;

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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: const [
                        DropdownMenuItem(value: 'Meeting Announcement', child: Text('Meeting Announcement')),
                        DropdownMenuItem(value: 'Deadline Notification', child: Text('Deadline Notification')),
                        DropdownMenuItem(value: 'System-wide Message', child: Text('System-wide Message')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Message Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _receiverController,
                      decoration: const InputDecoration(labelText: 'Receiver ID (leave blank for all)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(labelText: 'Message'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSending ? 'Sending...' : 'Send'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        onPressed: _isSending
                            ? null
                            : () async {
                                final senderId = 'secretary'; // Replace with actual sender ID logic
                                final receiverId = _receiverController.text.trim();
                                final message = _messageController.text.trim();
                                // Suggestion 3: Input validation
                                if (message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Message cannot be empty')),
                                  );
                                  return;
                                }
                                // Optionally validate receiverId here if needed
                                await sendMessage(senderId, receiverId, message, _selectedType);
                                _messageController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message sent!')),
                                );
                              },
                      ),
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
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            data['type'] == 'Meeting Announcement'
                                ? Icons.event
                                : data['type'] == 'Deadline Notification'
                                    ? Icons.timer
                                    : Icons.campaign,
                            color: primaryColor,
                          ),
                          title: Text(data['type'] ?? 'Message'),
                          subtitle: Text(data['message'] ?? ''),
                          trailing: Text(
                            data['timestamp'] != null && data['timestamp'] is Timestamp
                                ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split('.').first
                                : '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
}
