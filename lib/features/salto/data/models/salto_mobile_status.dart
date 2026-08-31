class SaltoMobileStatus {
  const SaltoMobileStatus({
    required this.linked,
    required this.saltoVerified,
    required this.mobileAccessEnabled,
    required this.activationRequired,
    required this.hasCachedKey,
    this.cardId,
    this.extUserId,
    this.mobileAccessEnabledAt,
    this.deviceBindingRequired = false,
    this.shipKeyRefreshRecommended = false,
    this.shipKeyReady = false,
    this.shipSyncedAt,
    this.shipMobileAppType,
    this.shipPhoneNumber,
    this.shipCurrentKeyExists,
    this.shipCurrentKeyStatus,
    this.shipCurrentKeyStatusLabel,
    this.shipCurrentKeyIssuedAt,
    this.shipCurrentKeyExpiresAt,
    this.activated = false,
    this.alreadyActive = false,
    this.keyIssued = false,
    this.message,
  });

  final String? cardId;
  final String? extUserId;
  final bool linked;
  final bool saltoVerified;
  final bool mobileAccessEnabled;
  final DateTime? mobileAccessEnabledAt;
  final bool deviceBindingRequired;
  final bool shipKeyRefreshRecommended;
  final bool shipKeyReady;
  final DateTime? shipSyncedAt;
  final int? shipMobileAppType;
  final String? shipPhoneNumber;
  final bool? shipCurrentKeyExists;
  final int? shipCurrentKeyStatus;
  final String? shipCurrentKeyStatusLabel;
  final DateTime? shipCurrentKeyIssuedAt;
  final DateTime? shipCurrentKeyExpiresAt;
  final bool activationRequired;
  final bool hasCachedKey;
  final bool activated;
  final bool alreadyActive;
  final bool keyIssued;
  final String? message;

  factory SaltoMobileStatus.fromJson(Map<String, dynamic> json) {
    return SaltoMobileStatus(
      cardId: json['card_id'] as String?,
      extUserId: json['ext_user_id'] as String?,
      linked: json['linked'] as bool? ?? false,
      saltoVerified: json['salto_verified'] as bool? ?? false,
      mobileAccessEnabled: json['mobile_access_enabled'] as bool? ?? false,
      mobileAccessEnabledAt: json['mobile_access_enabled_at'] != null
          ? DateTime.tryParse(json['mobile_access_enabled_at'] as String)
          : null,
      deviceBindingRequired: json['device_binding_required'] as bool? ?? false,
      shipKeyRefreshRecommended:
          json['ship_key_refresh_recommended'] as bool? ?? false,
      shipKeyReady: json['ship_key_ready'] as bool? ?? false,
      shipSyncedAt: json['ship_synced_at'] != null
          ? DateTime.tryParse(json['ship_synced_at'] as String)
          : null,
      shipMobileAppType: json['ship_mobile_app_type'] as int?,
      shipPhoneNumber: json['ship_phone_number'] as String?,
      shipCurrentKeyExists: json['ship_current_key_exists'] as bool?,
      shipCurrentKeyStatus: json['ship_current_key_status'] as int?,
      shipCurrentKeyStatusLabel: json['ship_current_key_status_label'] as String?,
      shipCurrentKeyIssuedAt: json['ship_current_key_issued_at'] != null
          ? DateTime.tryParse(json['ship_current_key_issued_at'] as String)
          : null,
      shipCurrentKeyExpiresAt: json['ship_current_key_expires_at'] != null
          ? DateTime.tryParse(json['ship_current_key_expires_at'] as String)
          : null,
      activationRequired: json['activation_required'] as bool? ?? true,
      hasCachedKey: json['has_cached_key'] as bool? ?? false,
      activated: json['activated'] as bool? ?? false,
      alreadyActive: json['already_active'] as bool? ?? false,
      keyIssued: json['key_issued'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'ext_user_id': extUserId,
      'linked': linked,
      'salto_verified': saltoVerified,
      'mobile_access_enabled': mobileAccessEnabled,
      'mobile_access_enabled_at': mobileAccessEnabledAt?.toIso8601String(),
      'device_binding_required': deviceBindingRequired,
      'ship_key_refresh_recommended': shipKeyRefreshRecommended,
      'ship_key_ready': shipKeyReady,
      'ship_synced_at': shipSyncedAt?.toIso8601String(),
      'ship_mobile_app_type': shipMobileAppType,
      'ship_phone_number': shipPhoneNumber,
      'ship_current_key_exists': shipCurrentKeyExists,
      'ship_current_key_status': shipCurrentKeyStatus,
      'ship_current_key_status_label': shipCurrentKeyStatusLabel,
      'ship_current_key_issued_at': shipCurrentKeyIssuedAt?.toIso8601String(),
      'ship_current_key_expires_at': shipCurrentKeyExpiresAt?.toIso8601String(),
      'activation_required': activationRequired,
      'has_cached_key': hasCachedKey,
      'activated': activated,
      'already_active': alreadyActive,
      'key_issued': keyIssued,
      'message': message,
    };
  }
}
