/// Entity representing a skill
class SkillEntity {
  final String id;
  final String name;

  const SkillEntity({
    required this.id,
    required this.name,
  });

  SkillEntity copyWith({
    String? id,
    String? name,
  }) {
    return SkillEntity(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  factory SkillEntity.fromJson(Map<String, dynamic> json) {
    return SkillEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillEntity &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;

  static const List<SkillEntity> suggestions = [
    SkillEntity(id: '1', name: 'UI/UX дизайнер'),
    SkillEntity(id: '2', name: 'Дизайн презентации'),
    SkillEntity(id: '3', name: 'Брендинг'),
    SkillEntity(id: '4', name: 'Дизайн продуктов'),
    SkillEntity(id: '5', name: 'Графический дизайн'),
    SkillEntity(id: '6', name: 'Лого дизайн'),
    SkillEntity(id: '7', name: 'Product Designer'),
    SkillEntity(id: '8', name: 'Копирайтинг'),
    SkillEntity(id: '9', name: 'UI-Дизайн'),
    SkillEntity(id: '10', name: 'UX-Дизайн'),
    SkillEntity(id: '11', name: 'Photoshop'),
    SkillEntity(id: '12', name: 'Figma'),
    SkillEntity(id: '13', name: 'Blender'),
    SkillEntity(id: '14', name: 'Cinema 4D'),
    SkillEntity(id: '15', name: 'After Effects'),
  ];

  static List<SkillEntity> get mockUserSkills => [
    const SkillEntity(id: '12', name: 'Figma'),
    const SkillEntity(id: '1', name: 'UI/UX дизайнер'),
    const SkillEntity(id: '7', name: 'Product Designer'),
    const SkillEntity(id: '11', name: 'Photoshop'),
    const SkillEntity(id: '15', name: 'After Effects'),
    const SkillEntity(id: '5', name: 'Графический дизайн'),
    const SkillEntity(id: '3', name: 'Брендинг'),
    const SkillEntity(id: '13', name: 'Blender'),
  ];
}
