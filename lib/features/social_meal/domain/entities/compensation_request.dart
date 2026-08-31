/// Type of meal compensation request.
enum CompensationRequestType { medical, exam }

/// Approval status of a compensation request.
enum CompensationStatus { pending, approved, rejected }

/// A meal compensation request submitted by a student.
///
/// Covers two scenarios:
/// - [CompensationRequestType.medical]: student was ill and missed a meal.
/// - [CompensationRequestType.exam]:    student had an exam during a meal slot.
///
/// On approval of a medical request the missed meal is restored to the
/// student's weekly balance.  On approval of an exam request the student
/// receives an extra dinner for the affected day.
class CompensationRequest {
  final String id;
  final String studentId;
  final String studentName;
  final CompensationRequestType type;

  /// The date the meal was missed.
  final DateTime mealDate;

  /// 'breakfast', 'lunch', or 'dinner'.
  final String mealType;

  /// Filename of the supporting document (simulated; no real file I/O).
  final String documentName;

  final CompensationStatus status;
  final DateTime submittedAt;

  const CompensationRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.mealDate,
    required this.mealType,
    required this.documentName,
    required this.status,
    required this.submittedAt,
  });

  CompensationRequest copyWith({
    String? id,
    String? studentId,
    String? studentName,
    CompensationRequestType? type,
    DateTime? mealDate,
    String? mealType,
    String? documentName,
    CompensationStatus? status,
    DateTime? submittedAt,
  }) {
    return CompensationRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      type: type ?? this.type,
      mealDate: mealDate ?? this.mealDate,
      mealType: mealType ?? this.mealType,
      documentName: documentName ?? this.documentName,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'type': type.name,
      'mealDate': mealDate.toIso8601String(),
      'mealType': mealType,
      'documentName': documentName,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory CompensationRequest.fromJson(Map<String, dynamic> json) {
    return CompensationRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      type: CompensationRequestType.values.byName(json['type'] as String),
      mealDate: DateTime.parse(json['mealDate'] as String),
      mealType: json['mealType'] as String,
      documentName: json['documentName'] as String,
      status: CompensationStatus.values.byName(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}
