import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PaymentExporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> exportPaymentsToExcel(
    BuildContext context, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting payments...'),
            ],
          ),
        ),
      );

      QuerySnapshot paymentSnapshot;

      if (startDate != null && endDate != null) {
        paymentSnapshot = await _firestore
            .collection('monthly_payment')
            .where('payment_date', isGreaterThanOrEqualTo: startDate)
            .where('payment_date', isLessThanOrEqualTo: endDate)
            .orderBy('payment_date', descending: true)
            .get();
      } else {
        paymentSnapshot = await _firestore
            .collection('monthly_payment')
            .orderBy('payment_date', descending: true)
            .get();
      }

      if (paymentSnapshot.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No payment records found for export')),
        );
        throw Exception('No payment records found');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Payments'];

      sheet.appendRow([
        TextCellValue('Member Name'),
        TextCellValue('Amount Payable (KES)'),
        TextCellValue('Amount Paid (KES)'),
        TextCellValue('Balance (KES)'),
        TextCellValue('Payment Date'),
        TextCellValue('Has Penalty'),
        TextCellValue('Previous Balance (KES)'),
        TextCellValue('Timestamp'),
      ]);

      for (var i = 0; i < 8; i++) {
        sheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1'))
            .cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#4F81BD'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          bold: true,
        );
      }

      int rowIndex = 2;
      double totalPayable = 0;
      double totalPaid = 0;
      double totalBalance = 0;

      for (var doc in paymentSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final paymentDate = (data['payment_date'] as Timestamp).toDate();
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        final amountPayable = (data['amount_payable'] as num).toDouble();
        final amountPaid = (data['amount_paid'] as num).toDouble();
        final balance = (data['balance'] as num).toDouble();
        final previousBalance =
            (data['previous_balance'] as num?)?.toDouble() ?? 0;

        totalPayable += amountPayable;
        totalPaid += amountPaid;
        totalBalance += balance;

        sheet.appendRow([
          TextCellValue(data['name'] ?? 'Unknown'),
          TextCellValue(amountPayable.toStringAsFixed(2)),
          TextCellValue(amountPaid.toStringAsFixed(2)),
          TextCellValue(balance.toStringAsFixed(2)),
          TextCellValue(DateFormat('yyyy-MM-dd').format(paymentDate)),
          TextCellValue(data['has_penalty'] == true ? 'Yes' : 'No'),
          TextCellValue(previousBalance.toStringAsFixed(2)),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(timestamp)),
        ]);

        if (balance < 0) {
          sheet.cell(CellIndex.indexByString('D$rowIndex')).cellStyle =
              CellStyle(fontColorHex: ExcelColor.fromHexString('#FF0000'));
        }

        rowIndex++;
      }

      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('TOTALS:'),
        TextCellValue(totalPayable.toStringAsFixed(2)),
        TextCellValue(totalPaid.toStringAsFixed(2)),
        TextCellValue(totalBalance.toStringAsFixed(2)),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      for (var i = 0; i < 8; i++) {
        sheet
            .cell(
              CellIndex.indexByString(
                '${String.fromCharCode(65 + i)}${rowIndex + 1}',
              ),
            )
            .cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString('#D9E1F2'),
          bold: true,
        );
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'payments_export_$timestamp.xlsx';

      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final downloadsDir = Directory('${directory.path}/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      } else {
        throw Exception('Failed to generate Excel file');
      }

      final storageRef = _storage.ref().child('payment_exports/$fileName');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await storageRef.getDownloadURL();

        await _firestore.collection('payment_exports').add({
          'file_name': fileName,
          'download_url': downloadUrl,
          'created_at': FieldValue.serverTimestamp(),
          'record_count': paymentSnapshot.docs.length,
          'total_payable': totalPayable,
          'total_paid': totalPaid,
          'total_balance': totalBalance,
          'local_path': filePath,
        });

        Navigator.pop(context);
        return filePath;
      } else {
        throw Exception('Upload failed: ${snapshot.state}');
      }
    } catch (e) {
      Navigator.pop(context);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExportHistory() async {
    try {
      final snapshot = await _firestore
          .collection('payment_exports')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'file_name': data['file_name'],
          'download_url': data['download_url'],
          'created_at': (data['created_at'] as Timestamp).toDate(),
          'record_count': data['record_count'],
          'total_payable': data['total_payable'],
          'total_paid': data['total_paid'],
          'total_balance': data['total_balance'],
          'local_path': data['local_path'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch export history: $e');
    }
  }

  Future<void> deleteExport(String exportId, String fileName) async {
    try {
      await _firestore.collection('payment_exports').doc(exportId).delete();
      await _storage.ref().child('payment_exports/$fileName').delete();
    } catch (e) {
      throw Exception('Failed to delete export: $e');
    }
  }

  Future<File?> downloadExport(String downloadUrl, String fileName) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final downloadsDir = Directory('${directory.path}/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

      final ref = _storage.refFromURL(downloadUrl);
      await ref.writeToFile(file);

      return file;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
