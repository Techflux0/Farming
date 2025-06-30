import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunicationHomeScreen extends StatefulWidget {
  const CommunicationHomeScreen({Key? key}) : super(key: key);

  @override
  _CommunicationHomeScreenState createState() => _CommunicationHomeScreenState();
}

class _CommunicationHomeScreenState extends State<CommunicationHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    try {
      await _firestore.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
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
  Widget build(BuildContext context) {
    // TODO: Implement your UI here
    return Container();
  }
}
