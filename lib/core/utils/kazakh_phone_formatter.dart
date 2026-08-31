import 'package:flutter/services.dart';

/// Formats a Kazakh phone number as `+7 XXX XXX XX XX` while the user types.
///
/// - Strips all non-digit characters from input
/// - Drops a leading `7` or `8` (country-code prefix) when it is our own
///   formatted prefix — NOT when it is the first digit of the local number
/// - Caps at 10 local digits
/// - Rebuilds as `+7 [3] [3] [2] [2]`
/// - Returns empty string (not `+7`) when no digits are present so the
///   placeholder hint remains visible
class KazakhPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    var digits = raw.replaceAll(RegExp(r'\D'), '');

    // ── Case A: text still has our formatted '+7 ' prefix (normal typing) ──
    // Our formatter always returns "+7 ...", so the next newValue also starts
    // with "+7". The leading '7' in digits comes from the prefix, not local.
    final hasPrefix = raw.startsWith('+7') || raw.startsWith('+8');

    // ── Case B: paste of full E.164-style number without '+' (11+ digits) ──
    final isPastedFull = digits.length > 10 &&
        (digits.startsWith('7') || digits.startsWith('8'));

    if (hasPrefix || isPastedFull) {
      if (digits.startsWith('7') || digits.startsWith('8')) {
        digits = digits.substring(1);
      }
    } else if (digits.startsWith('7') || digits.startsWith('8')) {
      // ── Case C: Android phone keyboard replaced our text with bare
      // country-prefixed digits (e.g. user types '5' in "+7 5", keyboard
      // sends "755" = "7"+"55" instead of "+7 55").
      // Detect: stripping '7' gives a count consistent with ±1 digit change.
      final stripped = digits.substring(1);
      final oldLocal = _extractOldLocal(oldValue);
      if (stripped.isNotEmpty && stripped.length <= oldLocal.length + 1) {
        digits = stripped;
      }
      // else: genuine paste of local number starting with '7' — keep all.
    }

    if (digits.length > 10) digits = digits.substring(0, 10);
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    }

    final buf = StringBuffer('+7 ');
    buf.write(digits.substring(0, digits.length.clamp(0, 3)));
    if (digits.length > 3) {
      buf.write(' ');
      buf.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length > 6) {
      buf.write(' ');
      buf.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length > 8) {
      buf.write(' ');
      buf.write(digits.substring(8, digits.length.clamp(8, 10)));
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }

  /// Extracts the authoritative local digits from the previous formatter output.
  static String _extractOldLocal(TextEditingValue old) {
    final text = old.text;
    var d = text.replaceAll(RegExp(r'\D'), '');
    if (text.startsWith('+7') || text.startsWith('+8')) {
      if (d.startsWith('7') || d.startsWith('8')) d = d.substring(1);
    } else if (d.length > 10 && (d.startsWith('7') || d.startsWith('8'))) {
      d = d.substring(1);
    }
    return d.length > 10 ? d.substring(0, 10) : d;
  }

  /// Format any raw phone string (with or without spaces/+) into
  /// `+7 XXX XXX XX XX`. Returns empty string when there are no digits.
  /// Used for static formatting (e.g. populating a field from stored data).
  static String formatPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');

    // Strip country-code digit when raw already has our '+7' prefix or when
    // it's clearly a full number (11+ digits).
    if (raw.startsWith('+7') || raw.startsWith('+8') ||
        (digits.length > 10 &&
            (digits.startsWith('7') || digits.startsWith('8')))) {
      if (digits.startsWith('7') || digits.startsWith('8')) {
        digits = digits.substring(1);
      }
    }

    if (digits.length > 10) digits = digits.substring(0, 10);
    if (digits.isEmpty) return '';

    final buf = StringBuffer('+7 ');
    buf.write(digits.substring(0, digits.length.clamp(0, 3)));
    if (digits.length > 3) {
      buf.write(' ');
      buf.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length > 6) {
      buf.write(' ');
      buf.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length > 8) {
      buf.write(' ');
      buf.write(digits.substring(8, digits.length.clamp(8, 10)));
    }
    return buf.toString();
  }
}
