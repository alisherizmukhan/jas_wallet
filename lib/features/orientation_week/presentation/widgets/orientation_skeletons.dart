import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer-wrapped skeleton blocks for the Overview page's first load.
class OrientationDashboardSkeleton extends StatelessWidget {
  const OrientationDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
      highlightColor: isLight ? AppColors.white : AppColors.borderDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _block(height: 220, radius: AppSpacing.radiusXl),
            const SizedBox(height: AppSpacing.xl),
            _block(height: 22, width: 160),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < 3; i++) ...[
              _block(height: 76, radius: AppSpacing.radiusLg),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _block({required double height, double? width, double radius = 12}) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Skeleton for the Networking Bingo grid's first load.
class OrientationBingoSkeleton extends StatelessWidget {
  const OrientationBingoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight ? AppColors.fieldBackground : AppColors.surfaceDark,
      highlightColor: isLight ? AppColors.white : AppColors.borderDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
          ),
          itemBuilder: (context, i) => Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: AppSpacing.borderRadiusMd),
          ),
        ),
      ),
    );
  }
}
