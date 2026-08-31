import 'package:flutter_test/flutter_test.dart';
import 'package:jaswallet_app/features/salto/data/models/salto_mobile_status.dart';

// Mirror of _SaltoAccessPageState._requiresReactivation — tested as pure logic.
bool _requiresReactivation(SaltoMobileStatus? status) {
  if (status == null) return false;
  return !status.mobileAccessEnabled ||
      status.activationRequired ||
      status.deviceBindingRequired ||
      status.shipCurrentKeyExists == false ||
      status.shipCurrentKeyStatus == 6;
}

SaltoMobileStatus _active({
  bool mobileAccessEnabled = true,
  bool activationRequired = false,
  bool deviceBindingRequired = false,
  bool? shipCurrentKeyExists = true,
  int? shipCurrentKeyStatus = 1,
}) {
  return SaltoMobileStatus(
    linked: true,
    saltoVerified: true,
    mobileAccessEnabled: mobileAccessEnabled,
    activationRequired: activationRequired,
    hasCachedKey: true,
    deviceBindingRequired: deviceBindingRequired,
    shipCurrentKeyExists: shipCurrentKeyExists,
    shipCurrentKeyStatus: shipCurrentKeyStatus,
  );
}

void main() {
  // ── fromJson ────────────────────────────────────────────────────────────────

  group('SaltoMobileStatus.fromJson', () {
    test('parses minimal JSON with boolean defaults', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': false,
        'salto_verified': false,
        'mobile_access_enabled': false,
        'activation_required': true,
        'has_cached_key': false,
      });
      expect(status.linked, isFalse);
      expect(status.saltoVerified, isFalse);
      expect(status.mobileAccessEnabled, isFalse);
      expect(status.activationRequired, isTrue);
      expect(status.hasCachedKey, isFalse);
      expect(status.deviceBindingRequired, isFalse);
    });

    test('parses fully-activated status', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'ship_key_ready': true,
        'ship_current_key_exists': true,
        'ship_current_key_status': 1,
      });
      expect(status.linked, isTrue);
      expect(status.mobileAccessEnabled, isTrue);
      expect(status.activationRequired, isFalse);
      expect(status.shipKeyReady, isTrue);
      expect(status.shipCurrentKeyExists, isTrue);
      expect(status.shipCurrentKeyStatus, 1);
    });

    test('deviceBindingRequired defaults to false when absent', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
      });
      expect(status.deviceBindingRequired, isFalse);
    });

    test('deviceBindingRequired parses true correctly', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'device_binding_required': true,
      });
      expect(status.deviceBindingRequired, isTrue);
    });

    test('activation_required defaults to true when key is absent', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': false,
        'salto_verified': false,
        'mobile_access_enabled': false,
        'has_cached_key': false,
      });
      expect(status.activationRequired, isTrue);
    });

    test('shipCurrentKeyExists parses false correctly', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'ship_current_key_exists': false,
      });
      expect(status.shipCurrentKeyExists, isFalse);
    });

    test('shipCurrentKeyExists is null when absent', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
      });
      expect(status.shipCurrentKeyExists, isNull);
    });

    test('parses ISO-8601 date fields', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'mobile_access_enabled_at': '2024-01-15T08:30:00.000Z',
        'ship_current_key_issued_at': '2024-06-01T00:00:00.000Z',
        'ship_current_key_expires_at': '2024-06-08T00:00:00.000Z',
      });
      expect(status.mobileAccessEnabledAt, isNotNull);
      expect(status.shipCurrentKeyIssuedAt?.year, 2024);
      expect(status.shipCurrentKeyExpiresAt?.year, 2024);
    });

    test('gracefully handles malformed date strings', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'mobile_access_enabled_at': 'not-a-date',
      });
      expect(status.mobileAccessEnabledAt, isNull);
    });

    test('parses optional string fields', () {
      final status = SaltoMobileStatus.fromJson({
        'linked': true,
        'salto_verified': true,
        'mobile_access_enabled': true,
        'activation_required': false,
        'has_cached_key': true,
        'card_id': 'CARD-001',
        'ext_user_id': 'EXT-999',
        'ship_phone_number': '+7701234567',
        'ship_current_key_status_label': 'Active',
        'message': 'Key activated',
      });
      expect(status.cardId, 'CARD-001');
      expect(status.extUserId, 'EXT-999');
      expect(status.shipPhoneNumber, '+7701234567');
      expect(status.shipCurrentKeyStatusLabel, 'Active');
      expect(status.message, 'Key activated');
    });
  });

  // ── toJson / round-trip ─────────────────────────────────────────────────────

  group('SaltoMobileStatus.toJson round-trip', () {
    test('fully-populated status survives round-trip', () {
      final original = SaltoMobileStatus(
        linked: true,
        saltoVerified: true,
        mobileAccessEnabled: true,
        activationRequired: false,
        hasCachedKey: true,
        cardId: 'CARD-XYZ',
        extUserId: 'EXT-123',
        deviceBindingRequired: false,
        shipKeyReady: true,
        shipCurrentKeyExists: true,
        shipCurrentKeyStatus: 1,
        shipCurrentKeyStatusLabel: 'Active',
        shipCurrentKeyIssuedAt: DateTime.parse('2024-06-01T00:00:00.000'),
        shipCurrentKeyExpiresAt: DateTime.parse('2024-06-08T00:00:00.000'),
        activated: true,
        alreadyActive: false,
        keyIssued: true,
        message: 'OK',
      );

      final restored = SaltoMobileStatus.fromJson(original.toJson());

      expect(restored.linked, original.linked);
      expect(restored.saltoVerified, original.saltoVerified);
      expect(restored.mobileAccessEnabled, original.mobileAccessEnabled);
      expect(restored.activationRequired, original.activationRequired);
      expect(restored.hasCachedKey, original.hasCachedKey);
      expect(restored.cardId, original.cardId);
      expect(restored.extUserId, original.extUserId);
      expect(restored.deviceBindingRequired, original.deviceBindingRequired);
      expect(restored.shipKeyReady, original.shipKeyReady);
      expect(restored.shipCurrentKeyExists, original.shipCurrentKeyExists);
      expect(restored.shipCurrentKeyStatus, original.shipCurrentKeyStatus);
      expect(restored.shipCurrentKeyStatusLabel, original.shipCurrentKeyStatusLabel);
      expect(restored.activated, original.activated);
      expect(restored.alreadyActive, original.alreadyActive);
      expect(restored.keyIssued, original.keyIssued);
      expect(restored.message, original.message);
    });

    test('minimal status survives round-trip with null optionals', () {
      final original = SaltoMobileStatus(
        linked: false,
        saltoVerified: false,
        mobileAccessEnabled: false,
        activationRequired: true,
        hasCachedKey: false,
      );
      final restored = SaltoMobileStatus.fromJson(original.toJson());
      expect(restored.cardId, isNull);
      expect(restored.shipCurrentKeyExists, isNull);
      expect(restored.message, isNull);
    });

    test('toJson uses snake_case keys matching the API contract', () {
      final status = _active();
      final json = status.toJson();
      expect(json.containsKey('mobile_access_enabled'), isTrue);
      expect(json.containsKey('activation_required'), isTrue);
      expect(json.containsKey('device_binding_required'), isTrue);
      expect(json.containsKey('ship_current_key_exists'), isTrue);
      expect(json.containsKey('ship_current_key_status'), isTrue);
    });
  });

  // ── _requiresReactivation logic ─────────────────────────────────────────────

  group('_requiresReactivation', () {
    test('returns false for null status', () {
      expect(_requiresReactivation(null), isFalse);
    });

    test('returns false for fully-active, key-ready status', () {
      expect(_requiresReactivation(_active()), isFalse);
    });

    test('returns true when mobileAccessEnabled is false', () {
      expect(_requiresReactivation(_active(mobileAccessEnabled: false)), isTrue);
    });

    test('returns true when activationRequired is true', () {
      expect(_requiresReactivation(_active(activationRequired: true)), isTrue);
    });

    test('returns true when deviceBindingRequired is true', () {
      expect(_requiresReactivation(_active(deviceBindingRequired: true)), isTrue);
    });

    test('returns true when shipCurrentKeyExists is explicitly false', () {
      expect(
        _requiresReactivation(_active(shipCurrentKeyExists: false)),
        isTrue,
      );
    });

    test('returns false when shipCurrentKeyExists is null (field not present)', () {
      expect(
        _requiresReactivation(_active(shipCurrentKeyExists: null)),
        isFalse,
      );
    });

    test('returns true when shipCurrentKeyStatus is 6 (revoked/expired)', () {
      expect(
        _requiresReactivation(_active(shipCurrentKeyStatus: 6)),
        isTrue,
      );
    });

    test('returns false when shipCurrentKeyStatus is 1 (active)', () {
      expect(
        _requiresReactivation(_active(shipCurrentKeyStatus: 1)),
        isFalse,
      );
    });

    test('any single failing condition triggers true', () {
      // Each flag independently causes reactivation
      for (final status in [
        _active(mobileAccessEnabled: false),
        _active(activationRequired: true),
        _active(deviceBindingRequired: true),
        _active(shipCurrentKeyExists: false),
        _active(shipCurrentKeyStatus: 6),
      ]) {
        expect(_requiresReactivation(status), isTrue);
      }
    });
  });
}
