import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Entity representing education / academy entry (synced with backend).
class AcademyEntity {
  final String id;
  final String userId;
  final String institutionName;
  /// API values: bachelor, master, doctoral, associate, certificate, other
  final String degreeKind;
  final String? degreeOther;
  final String specialization;
  final int startYear;
  final int? startMonth;
  final int? endYear;
  final int? endMonth;
  final bool isCurrentlyStudying;
  final double? gpa;
  final String? description;
  final DateTime? createdAt;

  const AcademyEntity({
    required this.id,
    required this.userId,
    required this.institutionName,
    required this.degreeKind,
    this.degreeOther,
    required this.specialization,
    required this.startYear,
    this.startMonth,
    this.endYear,
    this.endMonth,
    this.isCurrentlyStudying = false,
    this.gpa,
    this.description,
    this.createdAt,
  });

  /// Localized degree line for profile UI.
  String degreeDisplayLabel(AppLocalizations l10n) {
    if (degreeKind == 'other') {
      final o = degreeOther?.trim();
      if (o != null && o.isNotEmpty) return o;
      return l10n.resume_degreeOther;
    }
    switch (degreeKind) {
      case 'bachelor':
        return l10n.resume_degreeBachelor;
      case 'master':
        return l10n.resume_degreeMaster;
      case 'doctoral':
        return l10n.resume_degreeDoctoral;
      case 'associate':
        return l10n.resume_degreeAssociate;
      case 'certificate':
        return l10n.resume_degreeCertificate;
      default:
        return degreeKind;
    }
  }

  AcademyEntity copyWith({
    String? id,
    String? userId,
    String? institutionName,
    String? degreeKind,
    String? degreeOther,
    String? specialization,
    int? startYear,
    int? startMonth,
    int? endYear,
    int? endMonth,
    bool? isCurrentlyStudying,
    double? gpa,
    String? description,
    DateTime? createdAt,
  }) {
    return AcademyEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      institutionName: institutionName ?? this.institutionName,
      degreeKind: degreeKind ?? this.degreeKind,
      degreeOther: degreeOther ?? this.degreeOther,
      specialization: specialization ?? this.specialization,
      startYear: startYear ?? this.startYear,
      startMonth: startMonth ?? this.startMonth,
      endYear: endYear ?? this.endYear,
      endMonth: endMonth ?? this.endMonth,
      isCurrentlyStudying: isCurrentlyStudying ?? this.isCurrentlyStudying,
      gpa: gpa ?? this.gpa,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String dateRangeDisplay(String locale, String presentLabel) {
    String monthLabel(int? month) {
      if (month == null) return '';
      return '${DateFormat.MMM(locale).format(DateTime(2000, month))} ';
    }

    final start = '${monthLabel(startMonth)}$startYear';

    if (isCurrentlyStudying) {
      return '$start - $presentLabel';
    }

    if (endYear != null) {
      return '$start - ${monthLabel(endMonth)}$endYear';
    }

    return start;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'institutionName': institutionName,
    'degreeKind': degreeKind,
    'degreeOther': degreeOther,
    'specialization': specialization,
    'startYear': startYear,
    'startMonth': startMonth,
    'endYear': endYear,
    'endMonth': endMonth,
    'isCurrentlyStudying': isCurrentlyStudying,
    'gpa': gpa,
    'description': description,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory AcademyEntity.fromJson(Map<String, dynamic> json) {
    final kind = json['degreeKind'] as String? ?? json['degree_kind'] as String?;
    final legacyDegree = json['degree'] as String?;
    final resolvedKind = kind ??
        (legacyDegree != null && legacyDegree.isNotEmpty ? 'other' : 'bachelor');
    final other = json['degreeOther'] as String? ??
        json['degree_other'] as String? ??
        (kind == null && legacyDegree != null ? legacyDegree : null);

    return AcademyEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? json['student_id'] as String? ?? '',
      institutionName: json['institutionName'] as String? ??
          json['institution_name'] as String? ??
          '',
      degreeKind: resolvedKind,
      degreeOther: other,
      specialization: json['specialization'] as String? ?? '',
      startYear: json['startYear'] as int? ?? 2020,
      startMonth: json['startMonth'] as int?,
      endYear: json['endYear'] as int?,
      endMonth: json['endMonth'] as int?,
      isCurrentlyStudying:
          json['isCurrentlyStudying'] as bool? ?? json['is_current'] as bool? ?? false,
      gpa: (json['gpa'] as num?)?.toDouble(),
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : (json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString())
                : null),
    );
  }

  static const AcademyEntity empty = AcademyEntity(
    id: '',
    userId: '',
    institutionName: '',
    degreeKind: 'bachelor',
    specialization: '',
    startYear: 2020,
  );
}
