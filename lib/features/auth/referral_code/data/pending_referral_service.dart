import 'package:shared_preferences/shared_preferences.dart';

/// Persists a referral code entered during registration so it can be sent
/// to the backend once the endpoint is ready.
///
/// BACKEND INTEGRATION:
///   After successful login / profile completion, read [get] and POST the code
///   to the backend attribution endpoint, then call [clear].
class PendingReferralService {
  static const _key = 'pending_referral_code_v1';

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code.trim().toUpperCase());
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
