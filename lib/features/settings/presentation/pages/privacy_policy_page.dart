import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_ui/app_ui.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  static const url = 'https://jasaim.kz/jaswallet/privacy/index.html';

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  double _progress = 0;
  bool _hasError = false;
  InAppWebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppAppBar(
        title: l10n.settings_privacyPolicy,
        showBackButton: true,
        showDivider: false,
      ),
      body: Stack(
        children: [
          if (!_hasError)
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(PrivacyPolicyPage.url),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                supportZoom: false,
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
              },
              onProgressChanged: (_, progress) {
                setState(() => _progress = progress / 100);
              },
              onReceivedError: (controller, request, error) {
                setState(() => _hasError = true);
              },
              onReceivedHttpError: (controller, request, response) {
                if ((response.statusCode ?? 200) >= 400) {
                  setState(() => _hasError = true);
                }
              },
            ),

          if (_hasError)
            _ErrorView(
              onRetry: () {
                setState(() {
                  _hasError = false;
                  _progress = 0;
                });
                _controller?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(PrivacyPolicyPage.url)),
                );
              },
              onOpenBrowser: () => launchUrl(
                Uri.parse(PrivacyPolicyPage.url),
                mode: LaunchMode.externalApplication,
              ),
            ),

          if (!_hasError && _progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.onOpenBrowser});

  final VoidCallback onRetry;
  final VoidCallback onOpenBrowser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.alertCircle, size: 40, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.settings_privacyPolicyOpenFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.common_retry),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onOpenBrowser,
              child: Text(
                l10n.events_openInBrowser,
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
