import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

class MinutesHomeScreen extends StatefulWidget {
  const MinutesHomeScreen({Key? key}) : super(key: key);

  @override
  _MinutesHomeScreenState createState() => _MinutesHomeScreenState();
}

class _MinutesHomeScreenState extends State<MinutesHomeScreen> {
  String _searchQuery = '';

  Future<void> _createMinuteDialog() async {
    String title = '';
    String content = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Minute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (value) => title = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
              onChanged: (value) => content = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (title.isNotEmpty && content.isNotEmpty) {
                await FirebaseFirestore.instance.collection('minutes').add({
                  'title': title,
                  'content': content,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minutes Home'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search minutes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('minutes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final minutes = snapshot.data?.docs ?? [];
          final filtered = minutes.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final content = (data['content'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery) || content.contains(_searchQuery);
          }).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No minutes found.'));
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled'),
                  subtitle: Text(data['content'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      final shareText = 'Minutes: ${data['title']}\n\n${data['content']}';
                      Share.share(shareText);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createMinuteDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create New Minute',
      ),
    );
  }
}