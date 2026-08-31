import 'dart:convert';

/// The NU schools a student can belong to, plus the Foundation Year Programme.
///
/// Declared by the student in Orientation Week rather than read from a
/// profile: `UserEntity` carries no school today, and the Salto card design is
/// a picture the student chose, not a fact about them. When a real field
/// lands, [OrientationIdentity] is the only thing that has to change.
enum NuSchool { ssh, seds, som, gsb, gspp, gse, smg, scai, nufyp }

extension NuSchoolX on NuSchool {
  /// Short code — what travels in the QR payload and what the comparison
  /// actually runs on.
  String get code => switch (this) {
        NuSchool.ssh => 'SSH',
        NuSchool.seds => 'SEDS',
        NuSchool.som => 'SoM',
        NuSchool.gsb => 'GSB',
        NuSchool.gspp => 'GSPP',
        NuSchool.gse => 'GSE',
        NuSchool.smg => 'SMG',
        NuSchool.scai => 'SCAI',
        NuSchool.nufyp => 'NUFYP',
      };

  String get label => switch (this) {
        NuSchool.ssh => 'School of Sciences and Humanities',
        NuSchool.seds => 'School of Engineering and Digital Sciences',
        NuSchool.som => 'School of Medicine',
        NuSchool.gsb => 'Graduate School of Business',
        NuSchool.gspp => 'Graduate School of Public Policy',
        NuSchool.gse => 'Graduate School of Education',
        NuSchool.smg => 'School of Mining and Geosciences',
        NuSchool.scai => 'School of Computing and Artificial Intelligence',
        NuSchool.nufyp => 'Foundation Year Programme',
      };

  /// The Foundation Year is not a school in the same sense — it is the year
  /// before one — but it is what the "find a NUFYP student" task matches on.
  bool get isFoundationYear => this == NuSchool.nufyp;

  static NuSchool? fromCode(String? raw) {
    if (raw == null) return null;
    final needle = raw.trim().toUpperCase();
    for (final school in NuSchool.values) {
      if (school.code.toUpperCase() == needle) return school;
    }
    return null;
  }
}

/// Who a student is, for the purposes of a peer scan.
///
/// Deliberately the smallest thing that makes the two QR tasks decidable: a
/// stable id to stop a student scanning the same person twice, a name to show
/// in the confirmation, and the school the rule compares on. No contact
/// details — a code passed between strangers should not carry an email.
class OrientationIdentity {
  const OrientationIdentity({
    required this.studentId,
    required this.displayName,
    required this.school,
  });

  final String studentId;
  final String displayName;
  final NuSchool school;

  /// Bumped if the payload shape ever changes, so an old code scanned by a new
  /// build is rejected cleanly instead of being misread.
  static const int payloadVersion = 1;

  /// What the QR image encodes.
  String encode() => jsonEncode({
        'v': payloadVersion,
        'id': studentId,
        'n': displayName,
        's': school.code,
      });

  /// Reads a scanned payload. Null for anything that is not one of ours —
  /// a student will point the camera at every code on campus, and none of
  /// those should produce an error dialog.
  static OrientationIdentity? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['v'] != payloadVersion) return null;

      final id = decoded['id']?.toString() ?? '';
      final school = NuSchoolX.fromCode(decoded['s']?.toString());
      if (id.isEmpty || school == null) return null;

      return OrientationIdentity(
        studentId: id,
        displayName: decoded['n']?.toString() ?? 'Student',
        school: school,
      );
    } catch (_) {
      return null;
    }
  }
}

/// What a scanned identity has to satisfy for a challenge to count.
enum QrScanRule { differentSchool, foundationYear, sameBirthMonth }

extension QrScanRuleX on QrScanRule {
  static QrScanRule? fromKey(String? raw) => switch (raw) {
        'different_school' => QrScanRule.differentSchool,
        'nufyp' => QrScanRule.foundationYear,
        'same_birth_month' => QrScanRule.sameBirthMonth,
        _ => null,
      };

  /// Evaluated on the two payloads where possible. Birth months are not in
  /// the QR — the backend compares them from its own records, so locally the
  /// rule is treated as satisfied and the server has the final word.
  bool isSatisfiedBy(OrientationIdentity me, OrientationIdentity them) =>
      switch (this) {
        QrScanRule.differentSchool => me.school != them.school,
        QrScanRule.foundationYear => them.school.isFoundationYear,
        QrScanRule.sameBirthMonth => true,
      };

  /// Why a scan did not count, in the student's words.
  String rejectionReason(OrientationIdentity them) => switch (this) {
        QrScanRule.differentSchool =>
          'You are both in ${them.school.code}. Find someone from another school.',
        QrScanRule.foundationYear =>
          '${them.displayName} is in ${them.school.code}, not the Foundation Year Programme.',
        QrScanRule.sameBirthMonth =>
          '${them.displayName} was born in a different month. Keep looking!',
      };
}

/// The outcome of scanning someone's code, as the sheet reports it.
sealed class ScanOutcome {
  const ScanOutcome();
}

/// Not one of our codes at all.
class ScanUnrecognised extends ScanOutcome {
  const ScanUnrecognised();
}

/// Our code, but the student's own.
class ScanSelf extends ScanOutcome {
  const ScanSelf();
}

/// Already used for this challenge.
class ScanDuplicate extends ScanOutcome {
  const ScanDuplicate(this.identity);

  final OrientationIdentity identity;
}

/// A real student, but the rule was not met.
class ScanRejected extends ScanOutcome {
  const ScanRejected(this.identity, this.reason);

  final OrientationIdentity identity;
  final String reason;
}

/// Counted.
class ScanAccepted extends ScanOutcome {
  const ScanAccepted(this.identity, this.awardedTokens);

  final OrientationIdentity identity;
  final int awardedTokens;
}
