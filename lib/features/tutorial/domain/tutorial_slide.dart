import 'package:flutter/material.dart';

class TutorialSlide {
  const TutorialSlide({
    required this.title,
    required this.body,
    required this.imagePath,
    required this.gradientBegin,
    required this.gradientEnd,
    this.duration = const Duration(seconds: 15),
  });

  final String title;
  final String body;
  final String imagePath;
  final Color gradientBegin;
  final Color gradientEnd;
  final Duration duration;
}
