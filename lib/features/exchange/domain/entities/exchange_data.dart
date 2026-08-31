class ExchangeData {
  const ExchangeData({
    required this.usdToKzt,
    required this.eurToKzt,
    this.rubToKzt,
    this.lastUpdated,
  });

  final double usdToKzt;
  final double eurToKzt;
  final double? rubToKzt;
  final DateTime? lastUpdated;
}
