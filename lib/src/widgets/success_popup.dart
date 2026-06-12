import 'package:flutter/material.dart';

import '../types.dart';

/// Centered success popup shown after a submission, mirroring the React Native
/// `SuccessOverlay`. Tapping anywhere on the barrier dismisses it.
class SuccessPopup extends StatelessWidget {
  const SuccessPopup({
    super.key,
    required this.message,
    this.icon,
    this.customStyles,
    required this.onClose,
  });

  final String message;
  final Widget? icon;
  final ReMarkaStyles? customStyles;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Container(
        color: const Color(0x73000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
            decoration: BoxDecoration(
              color: customStyles?.sentMessageContainerColor ?? Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon ??
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 48,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                    height: 1.5,
                  ).merge(customStyles?.sentMessageTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
