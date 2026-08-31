/// Represents an available meal that students can order.
class SVCMealItem {
  final String id;
  final String name;
  final String category; // 'breakfast' or 'lunch'
  final double price;
  final String description;

  const SVCMealItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
  });

  SVCMealItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
  }) {
    return SVCMealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
    };
  }

  factory SVCMealItem.fromJson(Map<String, dynamic> json) {
    return SVCMealItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }
}
