import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../providers/salto_student_card_provider.dart';
import 'salto_generic_card.dart';
import 'salto_nu_card.dart';

export 'salto_card_details_section.dart' show SaltoStudentCardDetailsSection;
export 'salto_card_palette.dart' show CardPalette, cardPaletteFor;
export 'salto_generic_card.dart' show GenericStudentCard, DesignOverlay, DesignPreviewChip;
export 'salto_nu_card.dart' show NuStudentCard, NuCustomStudentCard;

class SaltoStudentCardSection extends ConsumerWidget {
  const SaltoStudentCardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final cardState = ref.watch(saltoStudentCardProvider);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final user = userAsync.valueOrNull;

    if (userAsync.isLoading && user == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: const Center(child: AppLoader()),
      );
    }

    if (user == null) return const SizedBox.shrink();

    if (!cardState.isLoaded) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLight ? AppColors.borderGrey : AppColors.borderDark,
          ),
        ),
        child: const Center(child: AppLoader()),
      );
    }

    final studentId = (user.studentId?.trim().isNotEmpty ?? false)
        ? user.studentId!.trim()
        : user.id;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.saltoStudentCard),
      child: SaltoStudentCard(
        firstName: user.firstName,
        lastName: user.lastName,
        studentId: studentId,
        avatarUrl: user.avatarUrl,
        design: cardState.selectedDesign,
        customDesignImagePath: cardState.customDesignImagePath,
        isNuStudent: (user.email?.trim().toLowerCase().endsWith('@nu.edu.kz') ?? false),
      ),
    );
  }
}

class SaltoStudentCard extends StatelessWidget {
  const SaltoStudentCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.design,
    this.avatarUrl,
    this.customDesignImagePath,
    this.isNuStudent = false,
  });

  final String firstName;
  final String lastName;
  final String studentId;
  final String? avatarUrl;
  final SaltoStudentCardDesign design;
  final String? customDesignImagePath;
  final bool isNuStudent;

  @override
  Widget build(BuildContext context) {
    if (design.isNuDesign) {
      return NuStudentCard(
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        avatarUrl: avatarUrl,
        design: design,
      );
    }
    if (design == SaltoStudentCardDesign.custom && isNuStudent) {
      return NuCustomStudentCard(
        firstName: firstName,
        lastName: lastName,
        studentId: studentId,
        avatarUrl: avatarUrl,
        customDesignImagePath: customDesignImagePath,
      );
    }
    return GenericStudentCard(
      firstName: firstName,
      lastName: lastName,
      studentId: studentId,
      avatarUrl: avatarUrl,
      design: design,
      customDesignImagePath: customDesignImagePath,
    );
  }
}

class SaltoCardDesignSelector extends StatelessWidget {
  const SaltoCardDesignSelector({
    super.key,
    required this.selectedDesign,
    required this.onSelect,
    this.enabled = true,
    this.isNuStudent = false,
  });

  final SaltoStudentCardDesign selectedDesign;
  final ValueChanged<SaltoStudentCardDesign> onSelect;
  final bool enabled;
  final bool isNuStudent;

  @override
  Widget build(BuildContext context) {
    final designs = isNuStudent
        ? SaltoStudentCardDesignX.nuDesigns
        : SaltoStudentCardDesignX.genericDesigns;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final design in designs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: DesignPreviewChip(
                design: design,
                isSelected: selectedDesign == design,
                onTap: enabled ? () => onSelect(design) : null,
              ),
            ),
        ],
      ),
    );
  }
}
