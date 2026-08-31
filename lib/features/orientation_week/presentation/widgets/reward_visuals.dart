import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/reward.dart';
import '../theme/orientation_brand.dart';

/// Presentation mapping for the pure-Dart reward enums.
///
/// [Reward] carries semantic enums rather than asset paths or colours so the
/// domain layer never imports Flutter — and a backend can ship a new catalog
/// without a code change here.
abstract class RewardVisuals {
  static const _photoBase = 'assets/rewards';

  /// Product photo by catalog id, not by the localized title — otherwise
  /// Gold Café Card only matches English (`cafe`) and shows the gift bag
  /// in Russian / Kazakh.
  static String photo(Reward reward) {
    return switch (reward.id) {
      'reward_airpods_4' => '$_photoBase/airpods.png',
      'reward_apple_watch_se3' => '$_photoBase/iphone.png',
      'reward_gold_cafe_card' => '$_photoBase/coffee.png',
      _ => '$_photoBase/bag.png',
    };
  }

  /// Soft tint behind the product render — a calm four-tint palette rather
  /// than one colour per item.
  static Color tint(RewardImage image) => switch (image) {
        RewardImage.earbuds => OrientationBrand.accent,
        RewardImage.giftBox => OrientationBrand.accent,
        RewardImage.ticket => OrientationBrand.accent,
        RewardImage.bag => AppColors.success,
        RewardImage.notebook => AppColors.blue,
        RewardImage.giftCard => AppColors.blue,
        RewardImage.cup => AppColors.orange,
        RewardImage.movie => const Color(0xFFEC4899),
        RewardImage.speaker => const Color(0xFFEC4899),
      };

  static AppIconData categoryIcon(RewardCategory category) => switch (category) {
        RewardCategory.all => AppIcons.grid,
        RewardCategory.merch => AppIcons.gift,
        RewardCategory.giftCards => AppIcons.wallet,
        RewardCategory.experiences => AppIcons.star,
        RewardCategory.other => AppIcons.moreHoriz,
      };
}
