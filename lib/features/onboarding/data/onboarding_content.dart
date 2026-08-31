/// Data model for onboarding page content
class OnboardingPage {
  final int pageIndex;
  final String title;
  final String description;
  final String imageUrl;
  final String? fallbackAsset;

  const OnboardingPage({
    required this.pageIndex,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.fallbackAsset,
  });
}

/// Onboarding content in English
class OnboardingContentEn {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      pageIndex: 0,
      title: 'Everything. One Hub.',
      description: 'From opportunities to campus services — access the ecosystem that moves your student life forward.',
      imageUrl: 'assets/onboarding_assets/1.webp',
      fallbackAsset: 'assets/onboarding_assets/1.webp',
    ),
    OnboardingPage(
      pageIndex: 1,
      title: 'Campus Meals, Covered',
      description: 'Check today\'s menu, track your meal balance, and never miss a hot meal on campus.',
      imageUrl: 'assets/onboarding_assets/2.webp',
      fallbackAsset: 'assets/onboarding_assets/2.webp',
    ),
    OnboardingPage(
      pageIndex: 2,
      title: 'Stay in the Loop',
      description: 'University news, events, and announcements — delivered straight to your feed, always up to date.',
      imageUrl: 'assets/onboarding_assets/3.webp',
      fallbackAsset: 'assets/onboarding_assets/3.webp',
    ),
    OnboardingPage(
      pageIndex: 3,
      title: 'Learn. Earn. Repeat.',
      description: 'Grow your skills while unlocking value. Education and rewards — built into one journey.',
      imageUrl: 'assets/onboarding_assets/4.webp',
      fallbackAsset: 'assets/onboarding_assets/4.webp',
    ),
    OnboardingPage(
      pageIndex: 4,
      title: 'Opportunities, Unlocked',
      description: 'Discover jobs, projects, and career paths — all waiting inside your ecosystem.',
      imageUrl: 'assets/onboarding_assets/5.webp',
      fallbackAsset: 'assets/onboarding_assets/5.webp',
    ),
    OnboardingPage(
      pageIndex: 5,
      title: 'And There\'s More Ahead',
      description: 'New features. New access. New advantages — already on the horizon.',
      imageUrl: 'assets/onboarding_assets/6.webp',
      fallbackAsset: 'assets/onboarding_assets/6.webp',
    ),
  ];
}

/// Onboarding content in Russian
class OnboardingContentRu {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      pageIndex: 0,
      title: 'Всё в одном месте',
      description: 'От возможностей до сервисов кампуса — доступ к экосистеме, которая двигает вашу студенческую жизнь вперёд.',
      imageUrl: 'assets/onboarding_assets/1.webp',
      fallbackAsset: 'assets/onboarding_assets/1.webp',
    ),
    OnboardingPage(
      pageIndex: 1,
      title: 'Питание в кампусе',
      description: 'Смотрите меню дня, следите за балансом питания и не пропускайте горячие блюда.',
      imageUrl: 'assets/onboarding_assets/2.webp',
      fallbackAsset: 'assets/onboarding_assets/2.webp',
    ),
    OnboardingPage(
      pageIndex: 2,
      title: 'Будьте в курсе',
      description: 'Новости университета, мероприятия и объявления — прямо в ленте, всегда актуально.',
      imageUrl: 'assets/onboarding_assets/3.webp',
      fallbackAsset: 'assets/onboarding_assets/3.webp',
    ),
    OnboardingPage(
      pageIndex: 3,
      title: 'Учись. Зарабатывай. Повторяй.',
      description: 'Развивайте навыки и получайте ценность. Образование и награды — интегрированы в один путь.',
      imageUrl: 'assets/onboarding_assets/4.webp',
      fallbackAsset: 'assets/onboarding_assets/4.webp',
    ),
    OnboardingPage(
      pageIndex: 4,
      title: 'Возможности открыты',
      description: 'Откройте вакансии, проекты и карьерные пути — всё ждёт вас внутри экосистемы.',
      imageUrl: 'assets/onboarding_assets/5.webp',
      fallbackAsset: 'assets/onboarding_assets/5.webp',
    ),
    OnboardingPage(
      pageIndex: 5,
      title: 'Впереди ещё больше',
      description: 'Новые функции. Новый доступ. Новые преимущества — уже на горизонте.',
      imageUrl: 'assets/onboarding_assets/6.webp',
      fallbackAsset: 'assets/onboarding_assets/6.webp',
    ),
  ];
}

/// Onboarding content in Kazakh
class OnboardingContentKk {
  static const List<OnboardingPage> pages = [
    OnboardingPage(
      pageIndex: 0,
      title: 'Барлығы бір жерде',
      description: 'Мүмкіндіктерден кампус сервисіне дейін — студент өміріңізді ілгерілететін экосистемаға қол жеткіңіз.',
      imageUrl: 'assets/onboarding_assets/1.webp',
      fallbackAsset: 'assets/onboarding_assets/1.webp',
    ),
    OnboardingPage(
      pageIndex: 1,
      title: 'Кампуста тамақ',
      description: 'Бүгінгі мәзірді қараңыз, тамақ балансыңызды бақылаңыз және ыстық тамақты жіберіп алмаңыз.',
      imageUrl: 'assets/onboarding_assets/2.webp',
      fallbackAsset: 'assets/onboarding_assets/2.webp',
    ),
    OnboardingPage(
      pageIndex: 2,
      title: 'Жаңалықтан хабардар болыңыз',
      description: 'Университет жаңалықтары, іс-шаралар және хабарландырулар — тікелей лентаңызға, әрқашан өзекті.',
      imageUrl: 'assets/onboarding_assets/3.webp',
      fallbackAsset: 'assets/onboarding_assets/3.webp',
    ),
    OnboardingPage(
      pageIndex: 3,
      title: 'Сыбайлас. Табу. Қайталаңыз.',
      description: 'Дағдыларды дамытыңыз және құнды ашыңыз. Білім және марапаттар — бір жолға біріктірілген.',
      imageUrl: 'assets/onboarding_assets/4.webp',
      fallbackAsset: 'assets/onboarding_assets/4.webp',
    ),
    OnboardingPage(
      pageIndex: 4,
      title: 'Мүмкіндіктер ашылды',
      description: 'Жұмыс орындарын, жобаларды және мансаптық жолдарды табыңыз — барлығы экосистемада.',
      imageUrl: 'assets/onboarding_assets/5.webp',
      fallbackAsset: 'assets/onboarding_assets/5.webp',
    ),
    OnboardingPage(
      pageIndex: 5,
      title: 'Алда да көп',
      description: 'Жаңа мүмкіндіктер. Жаңа қол жеткізу. Жаңа артықшылықтар — горизонтқа жақын.',
      imageUrl: 'assets/onboarding_assets/6.webp',
      fallbackAsset: 'assets/onboarding_assets/6.webp',
    ),
  ];
}
