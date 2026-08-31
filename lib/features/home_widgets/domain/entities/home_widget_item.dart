/// Represents a widget that can be shown/hidden on the home page
class HomeWidgetItem {
  const HomeWidgetItem({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.order,
  });

  final String id;
  final String name;
  final bool isVisible;
  final int order;

  HomeWidgetItem copyWith({
    String? id,
    String? name,
    bool? isVisible,
    int? order,
  }) {
    return HomeWidgetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }
}

/// Widget IDs for home page sections
class HomeWidgetIds {
  static const String stories = 'stories';
  static const String saltoCard = 'salto_card';
  static const String events = 'events';
  static const String weather = 'weather';
  static const String exchange = 'exchange';
  static const String fintech = 'fintech';
  static const String jobFinder = 'job_finder';
  static const String aiChat = 'ai_chat';
  static const String habits = 'habits';
  static const String library = 'library';
  static const String market = 'market';
  static const String blogNews = 'blog_news';
  static const String social = 'social';
  static const String rent = 'rent';
  static const String documents = 'documents';
  static const String forum = 'forum';
  static const String course = 'course';

  // Fintech sub-widgets (only visible when parent fintech is ON)
  static const String fintechCards = 'fintech_cards';
  static const String fintechSpend = 'fintech_spend';
  static const String fintechWealth = 'fintech_wealth';
  static const String fintechPayments = 'fintech_payments';
  static const String fintechPayees = 'fintech_payees';
  static const String fintechHistory = 'fintech_history';

  // Trading sub-widgets (only visible when parent fintech is ON)
  static const String tradingStocks = 'trading_stocks';
  static const String tradingCrypto = 'trading_crypto';
  static const String tradingPortfolio = 'trading_portfolio';
  static const String tradingNews = 'trading_news';
  static const String tradingMarket = 'trading_market';

  /// All fintech sub-widget IDs for grouping in management sheet.
  static const List<String> fintechSubWidgets = [
    fintechCards,
    fintechSpend,
    fintechWealth,
    fintechPayments,
    fintechPayees,
    fintechHistory,
  ];

  /// All trading sub-widget IDs for grouping in management sheet.
  static const List<String> tradingSubWidgets = [
    tradingStocks,
    tradingCrypto,
    tradingPortfolio,
    tradingNews,
    tradingMarket,
  ];

  /// Whether the given ID is a fintech sub-widget.
  static bool isFintechSubWidget(String id) =>
      fintechSubWidgets.contains(id);

  /// Whether the given ID is a trading sub-widget.
  static bool isTradingSubWidget(String id) =>
      tradingSubWidgets.contains(id);

  /// Whether the given ID is any fintech-related sub-widget (fintech or trading).
  static bool isAnyFintechSubWidget(String id) =>
      isFintechSubWidget(id) || isTradingSubWidget(id);
}
