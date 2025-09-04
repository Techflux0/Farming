import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RegistrationExporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper method to convert any value to double safely
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Future<String> exportRegistrationToExcel(
    BuildContext context, {
    DateTime? startDate,
    DateTime? endDate,
    String? specificMemberId,
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
              Text('Exporting registration fees...'),
            ],
          ),
        ),
      );

      QuerySnapshot registrationSnapshot;
      String fileNamePrefix = 'all_members';

      if (specificMemberId != null) {
        final memberDoc = await _firestore
            .collection('users')
            .doc(specificMemberId)
            .get();
        final memberName = memberDoc['fullname'] ?? 'unknown_member';
        fileNamePrefix = _sanitizeFileName(memberName);

        if (startDate != null && endDate != null) {
          registrationSnapshot = await _firestore
              .collection('registration_fees')
              .where('user_id', isEqualTo: specificMemberId)
              .where('payment_date', isGreaterThanOrEqualTo: startDate)
              .where('payment_date', isLessThanOrEqualTo: endDate)
              .orderBy('payment_date', descending: true)
              .get();
        } else {
          registrationSnapshot = await _firestore
              .collection('registration_fees')
              .where('user_id', isEqualTo: specificMemberId)
              .orderBy('payment_date', descending: true)
              .get();
        }
      } else if (startDate != null && endDate != null) {
        registrationSnapshot = await _firestore
            .collection('registration_fees')
            .where('payment_date', isGreaterThanOrEqualTo: startDate)
            .where('payment_date', isLessThanOrEqualTo: endDate)
            .orderBy('payment_date', descending: true)
            .get();
      } else {
        registrationSnapshot = await _firestore
            .collection('registration_fees')
            .orderBy('payment_date', descending: true)
            .get();
      }

      if (registrationSnapshot.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No registration fee records found for export'),
          ),
        );
        throw Exception('No registration fee records found');
      }

      final excel = Excel.createExcel();
      final sheet = excel['Registration Fees'];

      sheet.appendRow([
        TextCellValue('Member Name'),
        TextCellValue('Amount Payable (KES)'),
        TextCellValue('Amount Paid (KES)'),
        TextCellValue('Balance (KES)'),
        TextCellValue('Payment Date'),
        TextCellValue('Timestamp'),
      ]);

      for (var i = 0; i < 6; i++) {
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

      final memberTotals = <String, Map<String, dynamic>>{};

      for (var doc in registrationSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final paymentDate = (data['payment_date'] as Timestamp).toDate();
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        // Use safe parsing for all numeric fields
        final amountPayable = _parseDouble(data['amount_payable']);
        final amountPaid = _parseDouble(data['amount_paid']);
        final balance = _parseDouble(data['balance']);

        final memberName = data['fullname'] ?? data['name'] ?? 'Unknown';
        final memberId = data['user_id']?.toString() ?? '';

        totalPayable += amountPayable;
        totalPaid += amountPaid;
        totalBalance += balance;

        if (!memberTotals.containsKey(memberId)) {
          memberTotals[memberId] = {
            'payable': 0.0,
            'paid': 0.0,
            'balance': 0.0,
            'name': memberName,
          };
        }
        memberTotals[memberId]!['payable'] =
            memberTotals[memberId]!['payable']! + amountPayable;
        memberTotals[memberId]!['paid'] =
            memberTotals[memberId]!['paid']! + amountPaid;
        memberTotals[memberId]!['balance'] =
            memberTotals[memberId]!['balance']! + balance;

        sheet.appendRow([
          TextCellValue(memberName),
          TextCellValue(amountPayable.toStringAsFixed(2)),
          TextCellValue(amountPaid.toStringAsFixed(2)),
          TextCellValue(balance.toStringAsFixed(2)),
          TextCellValue(DateFormat('yyyy-MM-dd').format(paymentDate)),
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(timestamp)),
        ]);

        if (balance < 0) {
          sheet.cell(CellIndex.indexByString('D$rowIndex')).cellStyle =
              CellStyle(fontColorHex: ExcelColor.fromHexString('#FF0000'));
        }

        rowIndex++;
      }

      if (specificMemberId == null && memberTotals.length > 1) {
        sheet.appendRow([TextCellValue('')]);
        sheet.appendRow([
          TextCellValue('MEMBER SUMMARY'),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
          TextCellValue(''),
        ]);

        for (var memberId in memberTotals.keys) {
          final totals = memberTotals[memberId]!;
          sheet.appendRow([
            TextCellValue(totals['name'] as String),
            TextCellValue(totals['payable']!.toStringAsFixed(2)),
            TextCellValue(totals['paid']!.toStringAsFixed(2)),
            TextCellValue(totals['balance']!.toStringAsFixed(2)),
            TextCellValue(''),
            TextCellValue(''),
          ]);
        }
      }

      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue('TOTALS:'),
        TextCellValue(totalPayable.toStringAsFixed(2)),
        TextCellValue(totalPaid.toStringAsFixed(2)),
        TextCellValue(totalBalance.toStringAsFixed(2)),
        TextCellValue(''),
        TextCellValue(''),
      ]);

      for (var i = 0; i < 6; i++) {
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
      final fileName = '${fileNamePrefix}_registration_fees_$timestamp.xlsx';

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final excelBytes = excel.save();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      } else {
        throw Exception('Failed to generate Excel file');
      }

      try {
        final storageRef = _storage.ref().child(
          'registration_exports/$fileName',
        );
        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final downloadUrl = await storageRef.getDownloadURL();

          await _firestore.collection('registration_exports').add({
            'file_name': fileName,
            'download_url': downloadUrl,
            'created_at': FieldValue.serverTimestamp(),
            'record_count': registrationSnapshot.docs.length,
            'total_payable': totalPayable,
            'total_paid': totalPaid,
            'total_balance': totalBalance,
            'local_path': filePath,
            'member_id': specificMemberId,
            'member_name': specificMemberId != null
                ? fileNamePrefix.replaceAll('_', ' ')
                : 'All Members',
          });
        }
      } catch (e) {
        print('Firestore upload failed: $e');
      }

      Navigator.pop(context);
      return filePath;
    } catch (e) {
      Navigator.pop(context);
      rethrow;
    }
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .toLowerCase();
  }

  Future<List<Map<String, dynamic>>> getExportHistory() async {
    try {
      final snapshot = await _firestore
          .collection('registration_exports')
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
          'total_payable': _parseDouble(data['total_payable']),
          'total_paid': _parseDouble(data['total_paid']),
          'total_balance': _parseDouble(data['total_balance']),
          'local_path': data['local_path'],
          'member_name': data['member_name'] ?? 'All Members',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch export history: $e');
    }
  }

  Future<void> deleteExport(String exportId, String fileName) async {
    try {
      await _firestore
          .collection('registration_exports')
          .doc(exportId)
          .delete();
      await _storage.ref().child('registration_exports/$fileName').delete();
    } catch (e) {
      throw Exception('Failed to delete export: $e');
    }
  }

  Future<File?> downloadExport(String downloadUrl, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final ref = _storage.refFromURL(downloadUrl);
      await ref.writeToFile(file);

      return file;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
