import 'meal_slot.dart';

/// Represents a single meal redemption event.
///
/// Tracks which [MealSlot] was consumed, the combo name, category, and price.
/// Used both at runtime (QR scan) and for analytics/reporting.
class MealTransaction {
  final String id;
  final String userId;
  final DateTime redeemedAt;
  final String qrCode;

  /// Which time slot this meal was redeemed in.
  final MealSlot slot;

  /// Name of the combo served (e.g. "Комбо A — Стандарт / Combo A — Standard").
  final String comboName;

  /// Category string for backwards compatibility ('breakfast', 'lunch', 'dinner').
  final String category;

  /// Price of the combo in ₸.
  final double price;

  const MealTransaction({
    required this.id,
    required this.userId,
    required this.redeemedAt,
    required this.qrCode,
    required this.slot,
    required this.comboName,
    required this.category,
    required this.price,
  });

  MealTransaction copyWith({
    String? id,
    String? userId,
    DateTime? redeemedAt,
    String? qrCode,
    MealSlot? slot,
    String? comboName,
    String? category,
    double? price,
  }) {
    return MealTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      qrCode: qrCode ?? this.qrCode,
      slot: slot ?? this.slot,
      comboName: comboName ?? this.comboName,
      category: category ?? this.category,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'redeemedAt': redeemedAt.toIso8601String(),
      'qrCode': qrCode,
      'slot': slot.key,
      'comboName': comboName,
      'category': category,
      'price': price,
    };
  }

  factory MealTransaction.fromJson(Map<String, dynamic> json) {
    return MealTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      redeemedAt: DateTime.parse(json['redeemedAt'] as String),
      qrCode: json['qrCode'] as String,
      slot: MealSlot.fromKey(json['slot'] as String? ?? 'lunch'),
      comboName: json['comboName'] as String? ?? '',
      category: json['category'] as String? ?? 'lunch',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
