import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/meal_slot.dart';

/// Re-shows the redeemed-meal confirmation for an already-received meal —
/// e.g. the student closed the live scan confirmation before the cashier
/// got a look at it. Mirrors the card shown right after a QR scan
/// (`SVCQrScanPage`): same fixed Russian copy, since this screen is read by
/// the canteen cashier, not the student, regardless of device language.
void showReceivedMealSheet(BuildContext context, WidgetRef ref, MealEntry entry) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _ReceivedMealSheet(entry: entry),
    ),
  );
}

class _ReceivedMealSheet extends ConsumerWidget {
  const _ReceivedMealSheet({required this.entry});

  final MealEntry entry;

  static String _slotName(MealSlot slot) => switch (slot) {
        MealSlot.breakfast => 'Завтрак',
        MealSlot.lunch => 'Обед',
        MealSlot.dinner => 'Ужин',
      };

  static String _formatDate(DateTime dt) {
    const months = [
      'янв', 'фев', 'мар', 'апр', 'май', 'июн',
      'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(userProvider).valueOrNull;
    final studentName = student?.fullName;
    final avatarUrl = student?.avatarUrl;
    final hasAvatarUrl = avatarUrl != null && avatarUrl.isNotEmpty;
    final receivedAt = entry.receivedAt;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        decoration: const BoxDecoration(
          color: Color(0xFF16172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.28), width: 1.5),
                ),
                child: const AppIcon(AppIcons.check, color: AppColors.green, size: 34),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Приём пищи получен',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.14), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CashierBanner(),
                  const SizedBox(height: 16),
                  if (studentName != null && studentName.isNotEmpty) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: AppColors.green.withValues(alpha: 0.16),
                          backgroundImage: hasAvatarUrl ? NetworkImage(avatarUrl) : null,
                          child: hasAvatarUrl
                              ? null
                              : Text(
                                  _initials(studentName),
                                  style: const TextStyle(color: AppColors.green, fontSize: 14.5, fontWeight: FontWeight.w700),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (student?.studentId != null && student!.studentId!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  student.studentId!,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.48), fontSize: 12.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _CardDivider(),
                    const SizedBox(height: 14),
                  ],
                  _DetailRow(label: 'Меню', value: _slotName(entry.slot), valueColor: AppColors.green),
                  const SizedBox(height: 11),
                  const _CardDivider(),
                  const SizedBox(height: 11),
                  _DetailRow(label: 'Дата', value: _formatDate(entry.date)),
                  if (receivedAt != null) ...[
                    const SizedBox(height: 11),
                    const _CardDivider(),
                    const SizedBox(height: 11),
                    _DetailRow(label: 'Время', value: _formatTime(receivedAt)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Закрыть', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierBanner extends StatelessWidget {
  const _CashierBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const AppIcon(AppIcons.visibility, color: AppColors.orange, size: 17),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Покажите кассиру',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.15),
                ),
                SizedBox(height: 2),
                Text(
                  'Эта страница подтверждает получение питания',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.48), fontSize: 14.5)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.08));
  }
}
