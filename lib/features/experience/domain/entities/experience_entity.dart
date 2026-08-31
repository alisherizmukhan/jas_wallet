import 'package:intl/intl.dart';

/// Entity representing work experience
class ExperienceEntity {
  final String id;
  final String userId;
  final String companyName;
  final String position;
  final int startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;
  final bool isCurrentJob;
  final DateTime? createdAt;

  const ExperienceEntity({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.position,
    required this.startYear,
    this.startMonth,
    this.endYear,
    this.endMonth,
    this.isCurrentJob = false,
    this.createdAt,
  });

  ExperienceEntity copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? position,
    int? startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
    bool? isCurrentJob,
    DateTime? createdAt,
  }) {
    return ExperienceEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      endYear: endYear ?? this.endYear,
      endMonth: endMonth ?? this.endMonth,
      isCurrentJob: isCurrentJob ?? this.isCurrentJob,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String dateRangeDisplay(String locale, String presentLabel) {
    String monthLabel(int? month) {
      if (month == null) return '';
      return '${DateFormat.MMM(locale).format(DateTime(2000, month))} ';
    }

    final start = '${monthLabel(startMonth)}$startYear';

    if (isCurrentJob) {
      return '$start - $presentLabel';
    }

    if (endYear != null) {
      return '$start - ${monthLabel(endMonth)}$endYear';
    }

    return start;
  }

  static const ExperienceEntity empty = ExperienceEntity(
    id: '',
    userId: '',
    companyName: '',
    position: '',
    startYear: 2023,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'companyName': companyName,
    'position': position,
    'startYear': startYear,
    'startMonth': startMonth,
    'endYear': endYear,
    'endMonth': endMonth,
    'isCurrentJob': isCurrentJob,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory ExperienceEntity.fromJson(Map<String, dynamic> json) {
    return ExperienceEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      position: json['position'] as String? ?? '',
      startYear: json['startYear'] as int? ?? 2023,
      startMonth: json['startMonth'] as int?,
      endYear: json['endYear'] as int?,
      endMonth: json['endMonth'] as int?,
      isCurrentJob: json['isCurrentJob'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
