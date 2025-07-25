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
        top:
            MediaQuery.of(context).padding.top + 8, // Position below status bar
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isError ? colorScheme.error : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Colored accent bar
                    Container(
                      width: 4,
                      color: isError ? colorScheme.error : colorScheme.primary,
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isError
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  _logoAssetPath,
                                  width: 16,
                                  height: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Message
                            Expanded(
                              child: Text(
                                message,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isError
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            // Close button
                            GestureDetector(
                              onTap: dismiss,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: isError
                                      ? Colors.white.withOpacity(0.8)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
