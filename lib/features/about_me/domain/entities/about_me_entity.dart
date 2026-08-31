/// Entity representing "About Me" user data
class AboutMeEntity {
  final String id;
  final String userId;
  final String content;
  final DateTime? updatedAt;

  const AboutMeEntity({
    required this.id,
    required this.userId,
    required this.content,
    this.updatedAt,
  });

  AboutMeEntity copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? updatedAt,
  }) {
    return AboutMeEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'content': content,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory AboutMeEntity.fromJson(Map<String, dynamic> json) {
    return AboutMeEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static const AboutMeEntity empty = AboutMeEntity(
    id: '',
    userId: '',
    content: '',
  );

  static const AboutMeEntity mock = AboutMeEntity(
    id: '1',
    userId: '1',
    content: 'Ключевые моменты вашей карьеры, достижения - Ваши самые сильные навыки, компетенции имеющие отношение к желаемой должности. Опытный UX/UI дизайнер с более чем 5-летним опытом работы в сфере цифрового дизайна. Специализируюсь на создании удобных и красивых интерфейсов для мобильных приложений и веб-сервисов. Увлечен исследованиями пользовательского опыта и постоянно стремлюсь к совершенствованию своих навыков.',
  );
}
