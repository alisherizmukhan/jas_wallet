import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/student_profile.dart';

const orientationAvatarColors = [
  AppColors.avatar1,
  AppColors.avatar2,
  AppColors.avatar3,
  AppColors.avatar4,
  AppColors.avatar5,
];

/// One student's avatar, shared by the podium, the ranked list and the
/// "Your Position" card: a real profile photo when [StudentProfile.photoUrl]
/// is known (the signed-in student's own, via `userProvider`), the existing
/// initials-on-colour circle otherwise. An optional [ringColor] draws the
/// same "this one is you" ring the podium and the list both use.
class OrientationAvatar extends StatelessWidget {
  const OrientationAvatar({super.key, required this.student, required this.radius, this.ringColor});

  final StudentProfile student;
  final double radius;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final photoUrl = student.photoUrl;
    final diameter = radius * 2;
    final avatar = (photoUrl == null || photoUrl.isEmpty)
        ? _Initials(student: student, radius: radius)
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              // Decode at a fixed small size instead of the source photo's
              // full resolution — this circle never grows past a few dozen
              // logical pixels.
              memCacheWidth: (diameter * 2).round(),
              memCacheHeight: (diameter * 2).round(),
              placeholder: (_, _) => _Initials(student: student, radius: radius),
              errorWidget: (_, _, _) => _Initials(student: student, radius: radius),
            ),
          );

    if (ringColor == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor!, width: 1.5)),
      child: avatar,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.student, required this.radius});

  final StudentProfile student;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: orientationAvatarColors[student.avatarColorIndex % orientationAvatarColors.length],
      child: Text(
        student.initials,
        style: FeatureStyle.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}
