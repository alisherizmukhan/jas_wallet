import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/sos/config/sos_config.dart';

/// SOS is this app's safety feature — a typo in a phone number or a broken
/// `tel:` URI would ship silently with no other coverage catching it, so
/// this is a small but disproportionately important smoke test.
void main() {
  group('SosConfig.telUri()', () {
    test('police number dials the correct tel: URI', () {
      final uri = SosConfig.telUri(SosConfig.policeNumber);
      expect(uri.scheme, 'tel');
      expect(uri.path, '102');
      expect(uri.toString(), 'tel:102');
    });

    test('ambulance number dials the correct tel: URI', () {
      final uri = SosConfig.telUri(SosConfig.ambulanceNumber);
      expect(uri.scheme, 'tel');
      expect(uri.path, '103');
      expect(uri.toString(), 'tel:103');
    });

    test('fire number dials the correct tel: URI', () {
      final uri = SosConfig.telUri(SosConfig.fireNumber);
      expect(uri.scheme, 'tel');
      expect(uri.path, '101');
      expect(uri.toString(), 'tel:101');
    });

    test('emergency number dials the correct tel: URI', () {
      final uri = SosConfig.telUri(SosConfig.emergencyNumber);
      expect(uri.scheme, 'tel');
      expect(uri.path, '112');
      expect(uri.toString(), 'tel:112');
    });

    test('every configured number is non-empty and numeric', () {
      for (final number in [
        SosConfig.policeNumber,
        SosConfig.ambulanceNumber,
        SosConfig.fireNumber,
        SosConfig.emergencyNumber,
      ]) {
        expect(number, isNotEmpty);
        expect(
          RegExp(r'^\d+$').hasMatch(number),
          isTrue,
          reason: '"$number" should contain only digits',
        );
      }
    });
  });
}
