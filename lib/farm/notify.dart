import 'package:flutter/material.dart';
import 'dart:async';

class NotificationBar {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static const String _logoAssetPath = 'assets/scafold/sprout.png';
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    int durationSeconds = 3,
  }) {
    dismiss();

    final overlayState = Overlay.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, 0, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? colorScheme.error : colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Image.asset(
                        _logoAssetPath,
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ),
                    // Message
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.white,
                      onPressed: dismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    _timer = Timer(Duration(seconds: durationSeconds), dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
