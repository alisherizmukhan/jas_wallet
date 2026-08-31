import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/exchange_data.dart';
import '../providers/exchange_provider.dart';

/// Compact exchange-rate card for the home page.
///
/// Loads from persistent cache instantly (offline-first) then background-refreshes.
/// Shows spinner only on first load (no cache). Taps to details.
class ExchangeCard extends ConsumerWidget {
  const ExchangeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exchangeProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: () {
        final data = state.valueOrNull;
        if (data != null) {
          context.push(AppRoutes.exchangeDetails, extra: data);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: state.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => _noDataWidget(context),
          data: (data) =>
              data != null ? _dataWidget(data, isLight, context) : _noDataWidget(context),
        ),
      ),
    );
  }

  Widget _noDataWidget(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.exchange_noData,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ),
    );
  }

  Widget _dataWidget(ExchangeData data, bool isLight, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('💱', style: TextStyle(fontSize: 28)),
            const Spacer(),
            Text(
              l10n.exchange_label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLight ? AppColors.grey : AppColors.textDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RateLine(flag: '🇺🇸', value: data.usdToKzt, isLight: isLight, isMain: true),
        const SizedBox(height: 6),
        _RateLine(flag: '🇪🇺', value: data.eurToKzt, isLight: isLight, isMain: false),
        if (data.rubToKzt != null) ...[
          const SizedBox(height: 6),
          _RateLine(flag: '🇷🇺', value: data.rubToKzt!, isLight: isLight, isMain: false),
        ],
      ],
    );
  }
}

class _RateLine extends StatelessWidget {
  const _RateLine({
    required this.flag,
    required this.value,
    required this.isLight,
    required this.isMain,
  });

  final String flag;
  final double value;
  final bool isLight;
  final bool isMain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(flag, style: TextStyle(fontSize: isMain ? 16 : 14)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${value.toStringAsFixed(2)} ₸',
            style: TextStyle(
              fontSize: isMain ? 16 : 12,
              fontWeight: isMain ? FontWeight.w700 : FontWeight.w500,
              color: isLight ? AppColors.textColor : AppColors.textColorDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
