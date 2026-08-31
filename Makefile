# JasWallet build targets
# Usage: make <target>
# Requires: Flutter in PATH, key.properties configured, Sentry/cert pin dart-defines set

# ── Secrets (set in your shell or CI environment) ──────────────────────────────
SENTRY_DSN        ?=
API_CERT_PIN      ?=
BIOMETRIC_API_KEY ?=

# ── Dev build (debug APK, dev API, no cert pinning) ───────────────────────────
.PHONY: dev
dev:
	flutter run \
	  --dart-define=APP_ENV=development \
	  --dart-define=API_BASE_URL=https://dev.api.jasaim.kz \
	  --dart-define=BIOMETRIC_API_KEY=$(BIOMETRIC_API_KEY)

# ── Dev AAB (debug-signed, dev API) ───────────────────────────────────────────
.PHONY: dev-bundle
dev-bundle:
	flutter build appbundle --debug \
	  --dart-define=APP_ENV=development \
	  --dart-define=API_BASE_URL=https://dev.api.jasaim.kz \
	  --dart-define=BIOMETRIC_API_KEY=$(BIOMETRIC_API_KEY)

# ── Production AAB (release-signed, prod API, pinning + Sentry active) ────────
.PHONY: prod
prod:
	flutter build appbundle --release \
	  --dart-define=APP_ENV=production \
	  --dart-define=API_BASE_URL=https://api.jasaim.kz \
	  --dart-define=SENTRY_DSN=$(SENTRY_DSN) \
	  --dart-define=API_CERT_PIN=$(API_CERT_PIN) \
	  --dart-define=BIOMETRIC_API_KEY=$(BIOMETRIC_API_KEY)

# ── Production IPA ─────────────────────────────────────────────────────────────
.PHONY: prod-ios
prod-ios:
	flutter build ipa --release \
	  --dart-define=APP_ENV=production \
	  --dart-define=API_BASE_URL=https://api.jasaim.kz \
	  --dart-define=SENTRY_DSN=$(SENTRY_DSN) \
	  --dart-define=API_CERT_PIN=$(API_CERT_PIN) \
	  --dart-define=BIOMETRIC_API_KEY=$(BIOMETRIC_API_KEY)

# ── Clean ─────────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	flutter clean && flutter pub get

# ── Bump build number and tag ─────────────────────────────────────────────────
.PHONY: bump
bump:
	@pwsh -File scripts/bump_version.ps1 || bash scripts/bump_version.sh

# ── Generate cert pin for api.jasaim.kz ───────────────────────────────────────
.PHONY: cert-pin
cert-pin:
	@echo "SHA-256 DER pin for api.jasaim.kz:"
	@openssl s_client -servername api.jasaim.kz -connect api.jasaim.kz:443 \
	  </dev/null 2>/dev/null | openssl x509 -outform DER | base64
