import 'package:flutter/material.dart';

import '../types.dart';

/// Centered popup that shows a moderator's reply to the user's feedback,
/// mirroring the React Native `ResponseModal`. Dismissing it (button or barrier
/// tap) marks it as read via [onRead].
class ResponseModal extends StatelessWidget {
  const ResponseModal({
    super.key,
    required this.response,
    this.readButtonLabel = 'Read',
    this.customStyles,
    required this.onRead,
  });

  final ResponseMessage response;
  final String readButtonLabel;
  final ReMarkaStyles? customStyles;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final styles = customStyles;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRead,
      child: Container(
        color: const Color(0x73000000),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 360,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            decoration: BoxDecoration(
              color: styles?.responseContainerColor ?? Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (response.title != null && response.title!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      response.title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ).merge(styles?.responseTitleStyle),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      response.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ).merge(styles?.responseDescriptionStyle),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color:
                      styles?.responseButtonColor ?? const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onRead,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(
                        readButtonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ).merge(styles?.responseButtonTextStyle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
