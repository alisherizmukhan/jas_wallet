import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../widgets/salto_student_card_widget.dart';

class SaltoStudentCardPage extends StatelessWidget {
  const SaltoStudentCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppAppBar(title: _title(context), showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _subtitle(context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
              ),
              const SizedBox(height: 16),
              const SaltoStudentCardDetailsSection(),
            ],
          ),
        ),
      ),
    );
  }

  String _language(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  String _title(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Студенческий ID';
      case 'kk':
        return 'Студент ID';
      default:
        return 'Student ID Card';
    }
  }

  String _subtitle(BuildContext context) {
    switch (_language(context)) {
      case 'ru':
        return 'Полная информация профиля и выбор дизайна карты.';
      case 'kk':
        return 'Профильдің толық ақпараты және карта дизайнын таңдау.';
      default:
        return 'Full profile information and card design selection.';
    }
  }
}
