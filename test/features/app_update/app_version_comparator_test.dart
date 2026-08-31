import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/app_update/domain/services/app_version_comparator.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  group('AppVersionComparator.tryParse', () {
    test('parses a full semver string', () {
      expect(AppVersionComparator.tryParse('1.2.3'), Version(1, 2, 3));
    });

    test('pads a missing patch component', () {
      expect(AppVersionComparator.tryParse('1.2'), Version(1, 2, 0));
    });

    test('pads missing minor and patch components', () {
      expect(AppVersionComparator.tryParse('1'), Version(1, 0, 0));
    });

    test('strips a build-number suffix', () {
      expect(AppVersionComparator.tryParse('1.2.3+8'), Version(1, 2, 3));
    });

    test('preserves a pre-release suffix', () {
      final parsed = AppVersionComparator.tryParse('1.2.3-beta.1');
      expect(parsed, isNotNull);
      expect(parsed!.isPreRelease, isTrue);
      expect(parsed < Version(1, 2, 3), isTrue);
    });

    test('returns null for an empty string', () {
      expect(AppVersionComparator.tryParse(''), isNull);
    });

    test('returns null for whitespace-only input', () {
      expect(AppVersionComparator.tryParse('   '), isNull);
    });

    test('returns null for a non-numeric leading segment', () {
      expect(AppVersionComparator.tryParse('v1.2.3'), isNull);
    });

    test('returns null for garbage input', () {
      expect(AppVersionComparator.tryParse('not-a-version'), isNull);
    });

    test('returns null for too many components', () {
      expect(AppVersionComparator.tryParse('1.2.3.4'), isNull);
    });
  });

  group('AppVersionComparator.isBelow', () {
    test('true when current is strictly below target', () {
      expect(AppVersionComparator.isBelow(Version(1, 0, 0), Version(1, 1, 0)), isTrue);
    });

    test('false when current equals target', () {
      expect(AppVersionComparator.isBelow(Version(1, 1, 0), Version(1, 1, 0)), isFalse);
    });

    test('false when current is above target', () {
      expect(AppVersionComparator.isBelow(Version(2, 0, 0), Version(1, 1, 0)), isFalse);
    });

    test('false when target is null (unset/unparseable Remote Config value)', () {
      expect(AppVersionComparator.isBelow(Version(0, 0, 1), null), isFalse);
    });

    // This is the whole reason to use pub_semver instead of string
    // comparison: '2.10.0' < '2.9.0' as strings, but not as versions.
    test('correctly orders double-digit version segments', () {
      expect(AppVersionComparator.isBelow(Version(2, 9, 0), Version(2, 10, 0)), isTrue);
      expect(AppVersionComparator.isBelow(Version(2, 10, 0), Version(2, 9, 0)), isFalse);
    });
  });
}
