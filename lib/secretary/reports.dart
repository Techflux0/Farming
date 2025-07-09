import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({Key? key}) : super(key: key);

  @override
  _ReportsHomeScreenState createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateReport(String reportType, String content) async {
    try {
      await _firestore.collection('reports').add({
        'reportType': reportType,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error generating report: $e');
    }
  }

  Stream<QuerySnapshot> getReports() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _exportReportsToPDF(List<QueryDocumentSnapshot> reports) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Reports Summary', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          ...reports.map((report) {
            final data = report.data() as Map<String, dynamic>;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Type: ${data['reportType'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Content: ${data['content'] ?? ''}'),
                  pw.Text('Date: ${data['timestamp'] != null && data['timestamp'] is Timestamp ? (data['timestamp'] as Timestamp).toDate().toLocal().toString().split('.').first : ''}', style: pw.TextStyle(fontSize: 10)),
                  pw.Divider(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: getReports(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export to PDF',
                  onPressed: () => _exportReportsToPDF(snapshot.data!.docs),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    data['reportType'] == 'Member Report'
                        ? Icons.person
                        : data['reportType'] == 'Financial Summary'
                            ? Icons.attach_money
                            : Icons.assignment,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(data['reportType'] ?? ''),
                  subtitle: Text(data['content'] ?? ''),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showReportDialog,
        child: const Icon(Icons.add),
        tooltip: 'Generate Report',
      ),
    );
  }

  Future<void> _showReportDialog() async {
    String reportType = 'Member Report';
    String content = '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: reportType,
                items: const [
                  DropdownMenuItem(value: 'Member Report', child: Text('Member Report')),
                  DropdownMenuItem(value: 'Financial Summary', child: Text('Financial Summary')),
                  DropdownMenuItem(value: 'Activity Report', child: Text('Activity Report')),
                ],
                onChanged: (value) {
                  if (value != null) reportType = value;
                },
                decoration: const InputDecoration(labelText: 'Report Type'),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Content'),
                onChanged: (value) => content = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Generate'),
              onPressed: () {
                generateReport(reportType, content);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}