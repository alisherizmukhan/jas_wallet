/// Entity representing a user activity for profile display
class UserActivityEntity {
  final String id;
  final String userId;
  final String name;
  final DateTime date;
  final String? description;
  final List<String> imageUrls;
  final DateTime? createdAt;

  const UserActivityEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.description,
    this.imageUrls = const [],
    this.createdAt,
  });

  UserActivityEntity copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? date,
    String? description,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return UserActivityEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'date': date.toIso8601String(),
    'description': description,
    'imageUrls': imageUrls,
    'createdAt': createdAt?.toIso8601String(),
  };

  /// Create from JSON — uses null-safe casts so a single bad cached
  /// entry never silently nukes the entire activity list.
  factory UserActivityEntity.fromJson(Map<String, dynamic> json) {
    return UserActivityEntity(
      id: (json['id'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  static UserActivityEntity get empty => UserActivityEntity(
    id: '',
    userId: '',
    name: '',
    date: DateTime.now(),
  );
}
