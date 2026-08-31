import 'package:flutter/services.dart';

/// Restricts username input to the allowed charset (a-z, 0-9, `_`), forces
/// lowercase, and caps the length at 30 — so the field always matches the
/// backend username format and only availability has to be checked.
class UsernameInputFormatter extends TextInputFormatter {
  static const int maxLength = 30;
  static final RegExp _disallowed = RegExp(r'[^a-z0-9_]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var filtered = newValue.text.toLowerCase().replaceAll(_disallowed, '');
    if (filtered.length > maxLength) {
      filtered = filtered.substring(0, maxLength);
    }
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
