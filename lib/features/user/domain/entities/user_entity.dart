/// User role in the system.
enum UserRole {
  /// Student - can join courses, view content, do attendance
  student,
  /// Teacher/Professor - can create courses, add content, manage students
  teacher,
  /// Admin - full access
  admin,
}

/// User entity representing the core user data.
/// This is the domain model used throughout the application.
class UserEntity {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? email;
  final String? studentId;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? city;
  final int followers;
  final int following;
  final double rating;
  final int level;
  final int profileCompletion;
  final int completedSteps;
  final int totalSteps;
  final bool isFollowing;
  final UserRole role;
  final bool isSVC;

  const UserEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.email,
    this.studentId,
    this.gender,
    this.dateOfBirth,
    this.city,
    this.followers = 0,
    this.following = 0,
    this.rating = 0.0,
    this.level = 0,
    this.profileCompletion = 0,
    this.completedSteps = 0,
    this.totalSteps = 12,
    this.isFollowing = false,
    this.role = UserRole.student,
    this.isSVC = false,
  });

  String get fullName => '$firstName $lastName';

  String get displayUsername => username.startsWith('@') ? username : '@$username';

  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  
  /// Check if user is a teacher/professor
  bool get isTeacher => role == UserRole.teacher || role == UserRole.admin;
  
  /// Check if user is a student
  bool get isStudent => role == UserRole.student;

  UserEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? email,
    String? studentId,
    String? gender,
    DateTime? dateOfBirth,
    String? city,
    int? followers,
    int? following,
    double? rating,
    int? level,
    int? profileCompletion,
    int? completedSteps,
    int? totalSteps,
    bool? isFollowing,
    UserRole? role,
    bool? isSVC,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      city: city ?? this.city,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      rating: rating ?? this.rating,
      level: level ?? this.level,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      completedSteps: completedSteps ?? this.completedSteps,
      totalSteps: totalSteps ?? this.totalSteps,
      isFollowing: isFollowing ?? this.isFollowing,
      role: role ?? this.role,
      isSVC: isSVC ?? this.isSVC,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserEntity) return false;
    return id == other.id &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        username == other.username &&
        avatarUrl == other.avatarUrl &&
        bio == other.bio &&
        phone == other.phone &&
        email == other.email &&
        studentId == other.studentId &&
        gender == other.gender &&
        dateOfBirth == other.dateOfBirth &&
        city == other.city &&
        followers == other.followers &&
        following == other.following &&
        rating == other.rating &&
        level == other.level &&
        profileCompletion == other.profileCompletion &&
        completedSteps == other.completedSteps &&
        totalSteps == other.totalSteps &&
        isFollowing == other.isFollowing &&
        role == other.role &&
        isSVC == other.isSVC;
  }

  @override
  int get hashCode => Object.hash(
        id,
        firstName,
        lastName,
        username,
        avatarUrl,
        bio,
        phone,
        email,
        studentId,
        gender,
        dateOfBirth,
        city,
        followers,
        following,
        rating,
        level,
        // Nest trailing fields to stay within Object.hash's 20-arg limit.
        Object.hash(
          profileCompletion,
          completedSteps,
          totalSteps,
          isFollowing,
          role,
          isSVC,
        ),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'phone': phone,
    'email': email,
    'studentId': studentId,
    'gender': gender,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'city': city,
    'followers': followers,
    'following': following,
    'rating': rating,
    'level': level,
    'profileCompletion': profileCompletion,
    'completedSteps': completedSteps,
    'totalSteps': totalSteps,
    'isFollowing': isFollowing,
    'role': role.name,
    'isSVC': isSVC,
  };

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      studentId: json['studentId'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      city: json['city'] as String?,
      followers: json['followers'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] as int? ?? 0,
      profileCompletion: json['profileCompletion'] as int? ?? 0,
      completedSteps: json['completedSteps'] as int? ?? 0,
      totalSteps: json['totalSteps'] as int? ?? 12,
      isFollowing: json['isFollowing'] as bool? ?? false,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      isSVC: json['isSVC'] as bool? ?? false,
    );
  }
}
