import 'package:flutter/material.dart';
import 'package:app_ui/app_ui.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exchange_data.dart';

class ExchangeDetailsPage extends StatelessWidget {
  const ExchangeDetailsPage({super.key, required this.data});

  final ExchangeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppAppBar(title: l10n.exchange_title, showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RateCard(
            flag: '🇺🇸',
            currency: 'USD',
            name: l10n.exchange_usDollar,
            value: data.usdToKzt,
            isLight: isLight,
          ),
          const SizedBox(height: 12),
          _RateCard(
            flag: '🇪🇺',
            currency: 'EUR',
            name: l10n.exchange_euro,
            value: data.eurToKzt,
            isLight: isLight,
          ),
          if (data.rubToKzt != null) ...[
            const SizedBox(height: 12),
            _RateCard(
              flag: '🇷🇺',
              currency: 'RUB',
              name: l10n.exchange_russianRuble,
              value: data.rubToKzt!,
              isLight: isLight,
            ),
          ],
          if (data.lastUpdated != null) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                l10n.exchange_updated(DateFormat('MMM d, HH:mm').format(data.lastUpdated!)),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RATE CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.flag,
    required this.currency,
    required this.name,
    required this.value,
    required this.isLight,
  });

  final String flag;
  final String currency;
  final String name;
  final double value;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight ? AppColors.borderGrey : AppColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 $currency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLight ? AppColors.textColor : AppColors.textColorDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isLight ? AppColors.grey : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} ₸',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
          ),
        ],
      ),
    );
  }
}
