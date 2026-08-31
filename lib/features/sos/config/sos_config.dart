/// Configuration constants for the SOS (Campus Security) feature.
///
/// Campus security number can be updated here without touching any widget code.
/// A `null` campus number hides the "Campus Security" button gracefully.
abstract final class SosConfig {
  static const String policeNumber = '102';
  static const String ambulanceNumber = '103';
  static const String fireNumber = '101';
  static const String emergencyNumber = '112';

  static Uri telUri(String number) => Uri(scheme: 'tel', path: number);
}
