import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class ExportDownloader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        const primaryPath = '/storage/emulated/0/Download';
        final primaryDir = Directory(primaryPath);

        if (await primaryDir.exists()) {
          return primaryPath;
        }

        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final fallbackPath = '${directory.path}/Download';
          final fallbackDir = Directory(fallbackPath);

          if (await fallbackDir.exists()) {
            return fallbackPath;
          }

          await fallbackDir.create(recursive: true);
          return fallbackPath;
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        return directory.path;
      }
    } catch (e) {
      debugPrint('Error getting downloads directory: $e');
    }
    return null;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted) {
          return true;
        }

        final storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }

        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }

        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
    }
    return true;
  }

  Future<File?> _downloadExportFile(
    String fileName,
    String downloadUrl,
    String downloadsPath,
  ) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName);
      final filePath = '$downloadsPath/$sanitizedFileName';
      final file = File(filePath);

      if (await file.exists()) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nameWithoutExt = sanitizedFileName.split('.').first;
        final extension = sanitizedFileName.split('.').last;
        final newFileName = '${nameWithoutExt}_$timestamp.$extension';
        return await _downloadExportFile(
          newFileName,
          downloadUrl,
          downloadsPath,
        );
      }

      if (downloadUrl.startsWith('http')) {
        final ref = _storage.refFromURL(downloadUrl);
        await ref.writeToFile(file);
      } else {
        final localFile = File(downloadUrl);
        if (await localFile.exists()) {
          final bytes = await localFile.readAsBytes();
          await file.writeAsBytes(bytes);
        } else {
          return null;
        }
      }

      if (await file.exists() && await file.length() > 0) {
        return file;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading file $fileName: $e');
      return null;
    }
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<Map<String, dynamic>> downloadAllExports(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    BuildContext? dialogContext;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Preparing exports for download...'),
              ],
            ),
          );
        },
      );

      // Check and request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (dialogContext != null) Navigator.pop(dialogContext!);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('❌ Storage permission denied')),
        );
        return {'success': false, 'downloaded': 0, 'total': 0};
      }

      // Get downloads directory
      final downloadsPath = await _getDownloadsDirectory();
      if (downloadsPath == null) {
        if (dialogContext != null) Navigator.pop(dialogContext!);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Could not access downloads directory'),
          ),
        );
        return {'success': false, 'downloaded': 0, 'total': 0};
      }

      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final List<QuerySnapshot> exportSnapshots = await Future.wait([
        _firestore.collection('payment_exports').get(),
        _firestore.collection('registration_exports').get(),
      ]);

      final allExports = exportSnapshots
          .expand((snapshot) => snapshot.docs)
          .toList();

      if (allExports.isEmpty) {
        if (dialogContext != null) Navigator.pop(dialogContext!);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No export files found')),
        );
        return {'success': true, 'downloaded': 0, 'total': 0};
      }

      int successfulDownloads = 0;
      final List<Map<String, dynamic>> results = [];

      for (final exportDoc in allExports) {
        final data = exportDoc.data() as Map<String, dynamic>;
        final fileName = data['file_name']?.toString();
        final downloadUrl = data['download_url']?.toString();
        final localPath = data['local_path']?.toString();

        if (fileName != null && (downloadUrl != null || localPath != null)) {
          final fileUrl = downloadUrl ?? localPath!;
          final file = await _downloadExportFile(
            fileName,
            fileUrl,
            downloadsPath,
          );

          if (file != null && await file.exists()) {
            successfulDownloads++;
            results.add({'name': fileName, 'path': file.path, 'success': true});
          } else {
            results.add({
              'name': fileName,
              'success': false,
              'error': 'Download failed',
            });
          }
        }
      }

      if (dialogContext != null) Navigator.pop(dialogContext!);

      if (successfulDownloads > 0) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              '✅ Downloaded $successfulDownloads/${allExports.length} files to Downloads folder',
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () => _openDownloadsFolder(downloadsPath),
            ),
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('❌ No files could be downloaded')),
        );
      }

      return {
        'success': successfulDownloads > 0,
        'downloaded': successfulDownloads,
        'total': allExports.length,
        'results': results,
      };
    } catch (e) {
      if (dialogContext != null) Navigator.pop(dialogContext!);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('❌ Download failed: $e')),
      );
      return {
        'success': false,
        'downloaded': 0,
        'total': 0,
        'error': e.toString(),
      };
    }
  }

  Future<void> _openDownloadsFolder(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        await OpenFile.open(path);
      }
    } catch (e) {
      debugPrint('Error opening downloads folder: $e');
    }
  }

  Future<Map<String, int>> getExportStats() async {
    try {
      final List<QuerySnapshot> exportSnapshots = await Future.wait([
        _firestore.collection('payment_exports').get(),
        _firestore.collection('registration_exports').get(),
      ]);

      final totalExports = exportSnapshots.fold<int>(
        0,
        (sum, snapshot) => sum + snapshot.docs.length,
      );

      return {
        'total': totalExports,
        'payment_exports': exportSnapshots[0].docs.length,
        'registration_exports': exportSnapshots[1].docs.length,
      };
    } catch (e) {
      debugPrint('Error getting export stats: $e');
      return {'total': 0, 'payment_exports': 0, 'registration_exports': 0};
    }
  }
}
