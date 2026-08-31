import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

// Production certificate pin — Let's Encrypt YE1 intermediate CA, base64-DER.
// Pin the intermediate CA — not the leaf cert — for rotation resilience.
// Regenerate with: openssl s_client -connect api.jasaim.kz:443 -showcerts 2>/dev/null |
//   awk '/-----BEGIN CERTIFICATE-----/{c++} c==2{print} /-----END CERTIFICATE-----/ && c==2{exit}' |
//   openssl x509 -outform DER | base64
// YE1 expires 2028-09-02 — rotate before that date.
const _kProdCertPin =
    'MIICizCCAhGgAwIBAgIQXd1w3TH4AchcGGp6BLgK/jAKBggqhkjOPQQDAzAuMQswCQYDVQQGEwJV'
    'UzENMAsGA1UEChMESVNSRzEQMA4GA1UEAxMHUm9vdCBZRTAeFw0yNTA5MDMwMDAwMDBaFw0yODA5'
    'MDIyMzU5NTlaMDMxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQwwCgYDVQQD'
    'EwNZRTEwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQHZVB1/mimla2hfSurylScjPMZaOJXLz/NnAc2'
    'sylm8WDyhU9Ccp+zASQi5vSwGGJjSGklkD9fdPR8GpyDIOIjCEfrnbt/v+ZSEPLLEGbaM6EccDbN'
    '7p9xteIm2Avf+ryjge4wgeswDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBIG'
    'A1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLsgykcL/tflnPmPCSqjjDdFsbzYMB8GA1UdIwQY'
    'MBaAFKPIJlqOoUzQNWP8myPIOq5W809WMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcwAoYWaHR0'
    'cDovL3llLmkubGVuY3Iub3JnLzATBgNVHSAEDDAKMAgGBmeBDAECATAnBgNVHR8EIDAeMBygGqAY'
    'hhZodHRwOi8veWUuYy5sZW5jci5vcmcvMAoGCCqGSM49BAMDA2gAMGUCMQDgjUEahFT/h3DRakqi'
    'PZpLvPgfZwkt6K2EOMmh1nvEzl83eMLYcod4GCl3b0J1Nn0CMBNYmEQJb4CEG5WoOe7aRn/LVKu6'
    'saHmHEynI7ysIPd8zQsK1HdmhlHKlw9Z5GpGvA==';

// --dart-define=API_CERT_PIN=<base64-der> takes precedence (CI/CD usage).
const _dartDefinedPin = String.fromEnvironment('API_CERT_PIN');

String get _activePin =>
    _dartDefinedPin.isNotEmpty ? _dartDefinedPin : _kProdCertPin;

/// Configures certificate pinning on [dio] for the JasWallet API.
///
/// Reads the pin from [_dartDefinedPin] (build-time dart-define) first,
/// then falls back to [_kProdCertPin] (hardcoded). No-op when both are empty,
/// or on web/desktop.
void applyApiCertificatePinning(Dio dio) {
  if (_activePin.isEmpty) return;
  if (kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    SecurityContext context;
    try {
      context = SecurityContext(withTrustedRoots: false);
      context.setTrustedCertificatesBytes(base64.decode(_activePin));
    } catch (e) {
      return HttpClient();
    }

    return HttpClient(context: context)
      ..badCertificateCallback = (cert, host, port) => false;
  };
}
