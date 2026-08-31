# JasWallet Windows build script
# Usage: .\scripts\build.ps1 -Target prod -SentryDsn "https://..." -CertPin "base64..."
#
# Targets:
#   dev       - debug run on connected device (dev API)
#   dev-bundle - debug AAB (dev API)
#   prod      - release AAB (prod API, Sentry, cert pin)
#   prod-ios  - release IPA (prod API, Sentry, cert pin)

param(
    [ValidateSet("dev", "dev-bundle", "prod", "prod-ios")]
    [string]$Target = "prod",

    [string]$SentryDsn       = $env:SENTRY_DSN,
    [string]$CertPin         = $env:API_CERT_PIN,
    [string]$BiometricApiKey = $env:BIOMETRIC_API_KEY,
    [string]$DevApiUrl       = "https://dev.api.jasaim.kz",
    [string]$ProdApiUrl      = "https://api.jasaim.kz"
)

$DevDefines = @(
    "--dart-define=APP_ENV=development",
    "--dart-define=API_BASE_URL=$DevApiUrl",
    "--dart-define=BIOMETRIC_API_KEY=$BiometricApiKey"
)

$ProdDefines = @(
    "--dart-define=APP_ENV=production",
    "--dart-define=API_BASE_URL=$ProdApiUrl",
    "--dart-define=SENTRY_DSN=$SentryDsn",
    "--dart-define=API_CERT_PIN=$CertPin",
    "--dart-define=BIOMETRIC_API_KEY=$BiometricApiKey"
)

switch ($Target) {
    "dev"         { flutter run @DevDefines }
    "dev-bundle"  { flutter build appbundle --debug @DevDefines }
    "prod"        { flutter build appbundle --release @ProdDefines }
    "prod-ios"    { flutter build ipa --release @ProdDefines }
}
