import 'package:flutter_test/flutter_test.dart';

// Mirror of EditProfilePage._isValidUsername — tested as pure logic.
// The regex is: ^[a-z0-9_]{3,30}$
bool _isValidUsername(String value) {
  final usernameRegex = RegExp(r'^[a-z0-9_]{3,30}$');
  return usernameRegex.hasMatch(value);
}

void main() {
  group('Username validation — valid inputs', () {
    test('exactly 3 lowercase letters is valid', () {
      expect(_isValidUsername('abc'), isTrue);
    });

    test('exactly 30 characters is valid', () {
      expect(_isValidUsername('a' * 30), isTrue);
    });

    test('mix of lowercase letters, digits and underscore', () {
      expect(_isValidUsername('john_doe_42'), isTrue);
    });

    test('all digits is valid', () {
      expect(_isValidUsername('123'), isTrue);
    });

    test('all underscores is valid (3)', () {
      expect(_isValidUsername('___'), isTrue);
    });

    test('leading underscore is valid', () {
      expect(_isValidUsername('_username'), isTrue);
    });

    test('trailing underscore is valid', () {
      expect(_isValidUsername('username_'), isTrue);
    });

    test('multiple consecutive underscores is valid', () {
      expect(_isValidUsername('a__b'), isTrue);
    });

    test('all lowercase alphabet is valid', () {
      expect(_isValidUsername('abcdefghij'), isTrue);
    });

    test('username with only digit 0 repeated', () {
      expect(_isValidUsername('000'), isTrue);
    });
  });

  group('Username validation — invalid: too short', () {
    test('empty string is invalid', () {
      expect(_isValidUsername(''), isFalse);
    });

    test('1-char string is invalid', () {
      expect(_isValidUsername('a'), isFalse);
    });

    test('2-char string is invalid', () {
      expect(_isValidUsername('ab'), isFalse);
    });
  });

  group('Username validation — invalid: too long', () {
    test('31 characters is invalid', () {
      expect(_isValidUsername('a' * 31), isFalse);
    });

    test('50 characters is invalid', () {
      expect(_isValidUsername('a' * 50), isFalse);
    });
  });

  group('Username validation — invalid: uppercase letters', () {
    test('fully uppercase is invalid', () {
      expect(_isValidUsername('JOHN'), isFalse);
    });

    test('mixed case is invalid', () {
      expect(_isValidUsername('John'), isFalse);
    });

    test('single uppercase letter in otherwise-valid name is invalid', () {
      expect(_isValidUsername('johnA'), isFalse);
    });
  });

  group('Username validation — invalid: special characters', () {
    test('space is invalid', () {
      expect(_isValidUsername('john doe'), isFalse);
    });

    test('hyphen is invalid', () {
      expect(_isValidUsername('john-doe'), isFalse);
    });

    test('dot is invalid', () {
      expect(_isValidUsername('john.doe'), isFalse);
    });

    test('at-sign is invalid', () {
      expect(_isValidUsername('@username'), isFalse);
    });

    test('exclamation mark is invalid', () {
      expect(_isValidUsername('hello!'), isFalse);
    });

    test('slash is invalid', () {
      expect(_isValidUsername('path/user'), isFalse);
    });

    test('newline is invalid', () {
      expect(_isValidUsername('abc\n'), isFalse);
    });

    test('tab is invalid', () {
      expect(_isValidUsername('abc\t'), isFalse);
    });

    test('unicode letters are invalid', () {
      expect(_isValidUsername('алиш'), isFalse);
    });

    test('emoji is invalid', () {
      expect(_isValidUsername('abc😊'), isFalse);
    });
  });

  group('Username validation — boundary conditions', () {
    test('exactly 3 chars with valid chars passes', () {
      expect(_isValidUsername('a1_'), isTrue);
    });

    test('exactly 30 chars with mixed valid chars passes', () {
      const name = 'abcdefghij_0123456789_abcdefgh'; // exactly 30
      expect(name.length, 30);
      expect(_isValidUsername(name), isTrue);
    });

    test('31 chars that are otherwise valid fails', () {
      final name = 'a' * 30 + 'b'; // 31 chars
      expect(_isValidUsername(name), isFalse);
    });
  });
}
