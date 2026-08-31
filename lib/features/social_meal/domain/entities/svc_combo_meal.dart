/// Represents a combo meal in the Social Meal Program.
///
/// Each combo contains multiple items (e.g., soup + main dish + drink)
/// and a total price. Replaces individual [SVCMealItem] for a more
/// realistic university cafeteria experience.
class SVCComboMeal {
  /// Unique identifier for this combo.
  final String id;

  /// Display name (e.g., "Combo A — Standard").
  final String name;

  /// Category: 'breakfast' or 'lunch'.
  final String category;

  /// Ordered list of items included in this combo.
  final List<String> items;

  /// Total price for the combo in ₸.
  final double totalPrice;

  /// Optional short description displayed on the card.
  final String description;

  const SVCComboMeal({
    required this.id,
    required this.name,
    required this.category,
    required this.items,
    required this.totalPrice,
    this.description = '',
  });

  SVCComboMeal copyWith({
    String? id,
    String? name,
    String? category,
    List<String>? items,
    double? totalPrice,
    String? description,
  }) {
    return SVCComboMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'items': items,
      'totalPrice': totalPrice,
      'description': description,
    };
  }

  factory SVCComboMeal.fromJson(Map<String, dynamic> json) {
    return SVCComboMeal(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      items: List<String>.from(json['items'] as List),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }
}
