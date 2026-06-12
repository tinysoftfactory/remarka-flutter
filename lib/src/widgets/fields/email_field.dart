import 'package:flutter/material.dart';

/// Optional/required email input, mirroring the React Native `EmailField`.
class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.focusNode,
    this.required = false,
    this.hasError = false,
    this.placeholder = 'your@email.com',
    this.label = 'E-mail',
    this.inputStyle,
    this.labelStyle,
    this.borderColor,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool required;
  final bool hasError;
  final String placeholder;
  final String label;
  final TextStyle? inputStyle;
  final TextStyle? labelStyle;
  final Color? borderColor;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = hasError
        ? const Color(0xFFEF4444)
        : (borderColor ?? const Color(0xFFD1D5DB));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$label${required ? ' *' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ).merge(labelStyle),
            ),
          ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(fontSize: 17, color: Color(0xFF111827))
                .merge(inputStyle),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: effectiveBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: effectiveBorder),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: effectiveBorder),
              ),
            ),
          ),
          if (hasError)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Please enter a valid email address',
                style: TextStyle(fontSize: 13, color: Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
    );
  }
}
