// file: update_checker.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({super.key});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  // configure these here
  final String currentVersion = "4.5.6-Beta";
  final String versionUrl = "https://pastebin.com/raw/RGqzqJai";
  final String updateLinkUrl = "https://pastebin.com/raw/n5d1RzeX";

  String? latestUpdateUrl;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      // Fetch latest version
      final versionRes = await http.get(Uri.parse(versionUrl));
      if (versionRes.statusCode == 200) {
        final latestVersion = versionRes.body.trim();

        if (latestVersion != currentVersion) {
          // Fetch update link
          final linkRes = await http.get(Uri.parse(updateLinkUrl));
          if (linkRes.statusCode == 200) {
            latestUpdateUrl = linkRes.body.trim();
          }

          if (mounted) {
            _showUpdateDialog(latestVersion);
          }
        }
      }
    } catch (e) {
      debugPrint("Version check failed: $e");
    }
  }

  void _launchUpdateUrl() async {
    if (latestUpdateUrl == null) {
      debugPrint("No update URL found.");
      return;
    }

    final urlStr = latestUpdateUrl!.trim();
    try {
      final uri = Uri.parse(urlStr);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // ✅ Always external browser
      );

      if (!launched) {
        debugPrint("Could not launch in external browser: $urlStr");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No browser found to open $urlStr")),
          );
        }
      }
    } catch (e) {
      debugPrint("Invalid update URL: $urlStr -> $e");
    }
  }

  void _showUpdateDialog(String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot close by tapping outside
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          title: const Text("Update Required"),
          content: Text(
            "A new version ($latestVersion) is available.\n\n"
            "Please update to continue.",
          ),
          actions: [
            TextButton(
              onPressed: _launchUpdateUrl,
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget itself doesn’t display anything
    return const SizedBox.shrink();
  }
}
