// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Jas Wallet';

  @override
  String get common_continue => 'Продолжить';

  @override
  String get common_back => 'Назад';

  @override
  String get common_skip => 'Пропустить';

  @override
  String get common_start => 'Начать';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_keep => 'Оставить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_edit => 'Редактировать';

  @override
  String get common_showPassword => 'Показать пароль';

  @override
  String get common_hidePassword => 'Скрыть пароль';

  @override
  String get common_useBiometric =>
      'Использовать биометрическую аутентификацию';

  @override
  String get common_done => 'Готово';

  @override
  String get common_next => 'Далее';

  @override
  String get common_confirm => 'Подтвердить';

  @override
  String get common_yes => 'Да';

  @override
  String get common_no => 'Нет';

  @override
  String get common_ok => 'ОК';

  @override
  String get common_error => 'Ошибка';

  @override
  String get common_success => 'Успешно';

  @override
  String get common_loading => 'Загрузка...';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_saved => 'Сохранено';

  @override
  String get common_earlier => 'Ранее';

  @override
  String get common_userNotFound => 'Пользователь не найден';

  @override
  String get common_search => 'Поиск';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_close => 'Закрыть';

  @override
  String get common_hide => 'Скрыть';

  @override
  String get common_all => 'Все';

  @override
  String get common_viewAll => 'Все';

  @override
  String get common_notSpecified => 'Не указан';

  @override
  String get common_deleteProfile => 'Удалить профиль';

  @override
  String get common_deleteAccountConfirm =>
      'Вы действительно хотите удалить учетную запись?';

  @override
  String common_minutesAgo(Object count) {
    return '$count мин. назад';
  }

  @override
  String common_hoursAgo(Object count) {
    return '$count ч. назад';
  }

  @override
  String common_daysAgo(Object count) {
    return '$count дн. назад';
  }

  @override
  String get splash_selectLanguage => 'Выберите язык';

  @override
  String get splash_welcomeMessage => 'Добро пожаловать в Jas Wallet';

  @override
  String get splash_russian => 'Русский';

  @override
  String get splash_english => 'Английский';

  @override
  String get splash_kazakh => 'Казахский';

  @override
  String get welcome_title => 'Добро пожаловать в Jas Wallet';

  @override
  String get welcome_login => 'Войти';

  @override
  String get welcome_register => 'Зарегистрироваться';

  @override
  String get welcome_subtitle => 'Ваше путешествие начинается здесь';

  @override
  String get auth_username => 'Юзернейм';

  @override
  String get auth_usernameOrEmail => 'Username или email';

  @override
  String get auth_password => 'Пароль';

  @override
  String get auth_repeatPassword => 'Повторите пароль';

  @override
  String get auth_phone => 'Номер телефона';

  @override
  String get auth_email => 'Электронная почта';

  @override
  String get auth_firstName => 'Имя';

  @override
  String get auth_lastName => 'Фамилия';

  @override
  String get auth_forgotPassword => 'Забыли пароль?';

  @override
  String get auth_noAccount => 'Нет аккаунта?';

  @override
  String get auth_hasAccount => 'Уже есть аккаунт?';

  @override
  String get auth_signUp => 'Зарегистрироваться';

  @override
  String get auth_signIn => 'Войти';

  @override
  String get auth_createAccount => 'Создать аккаунт';

  @override
  String get auth_agreeTerms =>
      'Я согласен с Условиями использования и Политикой конфиденциальности';

  @override
  String get auth_consentDataCollection =>
      'Даю согласие на обработку персональных данных';

  @override
  String get auth_registration => 'Регистрация';

  @override
  String get auth_registrationDesc =>
      'Используйте ваш адрес @nu.edu.kz для регистрации';

  @override
  String get auth_register => 'Зарегистрироваться';

  @override
  String get auth_login => 'Вход';

  @override
  String get auth_loginDesc =>
      'Заполните краткую информацию и войдите в аккаунт';

  @override
  String get auth_rememberMe => 'Запомнить';

  @override
  String get auth_createProfile => 'Создание профиля';

  @override
  String get auth_createProfileDesc =>
      'Чтобы продолжить регистрацию заполните краткую информацию';

  @override
  String get auth_fullName => 'Имя Фамилия';

  @override
  String get auth_thinkUsername => 'Придумайте юзернейм';

  @override
  String get auth_createPassword => 'Создайте пароль';

  @override
  String get biometric_verificationTitle => 'Биометрическая верификация';

  @override
  String get biometric_verificationDesc =>
      'Для завершения регистрации необходимо пройти биометрическую верификацию';

  @override
  String get biometric_verificationError => 'Ошибка верификации';

  @override
  String get biometric_verificationSuccess => 'Верификация успешно завершена';

  @override
  String get biometric_startVerification => 'Начать верификацию';

  @override
  String get biometric_processing => 'Обработка...';

  @override
  String get biometric_requestingPermissions => 'Запрос разрешений...';

  @override
  String get biometric_permissionsDescription =>
      'Пожалуйста, разрешите доступ к камере и микрофону';

  @override
  String get biometric_permissionsDeniedPermanently =>
      'Доступ к камере и микрофону необходим для верификации. Пожалуйста, разрешите доступ в настройках приложения.';

  @override
  String get biometric_permissionsDenied =>
      'Доступ к камере и микрофону не предоставлен. Пожалуйста, разрешите доступ и попробуйте снова.';

  @override
  String get biometric_permissionsError => 'Ошибка запроса разрешений';

  @override
  String get biometric_openSettings => 'Открыть настройки';

  @override
  String get verification_title => 'Код подтверждения';

  @override
  String get verification_enterCode => 'Введите код подтверждения';

  @override
  String verification_codeSent(String destination) {
    return 'Код отправлен на $destination';
  }

  @override
  String get verification_resend => 'Отправить заново';

  @override
  String verification_resendIn(int seconds) {
    return 'Повторная отправка через $secondsс';
  }

  @override
  String get forgotPassword_title => 'Восстановление пароля';

  @override
  String get forgotPassword_selectMethod => 'Выберите способ восстановления';

  @override
  String get forgotPassword_viaPhone => 'По номеру телефона';

  @override
  String get forgotPassword_viaEmail => 'По E-mail';

  @override
  String get forgotPassword_enterPhone =>
      'Введите номер телефона для получения кода подтверждения';

  @override
  String get forgotPassword_enterEmail =>
      'Введите email для получения кода подтверждения';

  @override
  String get forgotPassword_newPassword => 'Новый пароль';

  @override
  String get forgotPassword_resetDesc =>
      'Придумайте новый пароль для вашего аккаунта';

  @override
  String get forgotPassword_confirmPassword => 'Подтвердите новый пароль';

  @override
  String get forgotPassword_reset => 'Сбросить пароль';

  @override
  String get forgotPassword_success => 'Пароль успешно изменен';

  @override
  String get forgotPassword_successDesc =>
      'Ваш пароль был обновлен. Теперь вы можете войти с новым паролем.';

  @override
  String get common_contactUs => 'Связаться с нами';

  @override
  String get home_title => 'Главная';

  @override
  String get stories_yourStory => 'Ваша история';

  @override
  String get stories_addStory => 'Добавить историю';

  @override
  String get stories_publishAs => 'Опубликовать как';

  @override
  String get stories_chooseMedia => 'Выберите медиа';

  @override
  String get stories_mediaPhoto => 'Фото';

  @override
  String get stories_mediaVideo => 'Видео';

  @override
  String get stories_publishFailed =>
      'Не удалось опубликовать историю. Попробуйте снова.';

  @override
  String get stories_publishForbidden =>
      'У вас нет прав публиковать истории от имени этой организации.';

  @override
  String get stories_processingVideo => 'Подготовка видео...';

  @override
  String get stories_videoReadFailed =>
      'Не удалось подготовить выбранное видео. Выберите другое видео.';

  @override
  String get stories_videoProcessFailed =>
      'Не удалось обработать выбранное видео. Выберите другое видео.';

  @override
  String get stories_deleteFailed =>
      'Не удалось удалить историю. Попробуйте снова.';

  @override
  String get stories_deleteForbidden => 'У вас нет прав удалять эту историю.';

  @override
  String get stories_notFound =>
      'История не найдена. Возможно, она уже истекла или была удалена.';

  @override
  String get stories_mediaUnsupported =>
      'Неподдерживаемый формат медиа для истории. Выберите поддерживаемое фото или видео.';

  @override
  String get stories_mediaTooLarge =>
      'Файл истории слишком большой. Выберите файл меньшего размера.';

  @override
  String get stories_videoTooLong =>
      'Видео слишком длинное. Выберите видео длительностью до 20 секунд.';

  @override
  String get stories_uploading => 'Загрузка истории...';

  @override
  String get stories_videoLoadFailed => 'Не удалось загрузить это видео.';

  @override
  String get stories_deleteTitle => 'Удалить историю';

  @override
  String get stories_deleteMessage =>
      'Вы уверены, что хотите удалить эту историю?';

  @override
  String get stories_renderFailed =>
      'Не удалось подготовить историю к загрузке. Попробуйте снова.';

  @override
  String get stories_discardTitle => 'Отменить историю?';

  @override
  String get stories_discardMessage =>
      'Вы уверены, что хотите закрыть редактор? Изменения будут потеряны.';

  @override
  String get stories_discardConfirm => 'Удалить';

  @override
  String get stories_keepEditing => 'Продолжить редактирование';

  @override
  String get stories_share => 'Поделиться историей';

  @override
  String get stories_videoPreview => 'Предпросмотр видео';

  @override
  String get stories_textHint => 'Введите текст...';

  @override
  String get stories_replyHint => 'Написать сообщение';

  @override
  String get stories_trimFailed =>
      'Не удалось обрезать видео. Попробуйте ещё раз.';

  @override
  String get widgets_title => 'Виджеты';

  @override
  String get widgets_description =>
      'Выберите виджеты для отображения на главном экране';

  @override
  String get hub_title => 'Хаб';

  @override
  String get hub_searchPlaceholder => 'Поиск услуг, вакансий, курсов...';

  @override
  String get hub_mainServices => 'Основные сервисы';

  @override
  String get hub_comingSoon => 'Скоро!';

  @override
  String get hub_stories => 'Истории';

  @override
  String get hub_saltoCard => 'Студенческий ID';

  @override
  String get hub_events => 'События';

  @override
  String get hub_weather => 'Погода';

  @override
  String get hub_exchange => 'Курс валют';

  @override
  String get weather_title => 'Погода';

  @override
  String get weather_astana => 'Астана';

  @override
  String weather_feelsLike(Object temp) {
    return 'Ощущается как $temp°';
  }

  @override
  String get weather_forecast7day => 'Прогноз на 7 дней';

  @override
  String get weather_wind => 'Ветер';

  @override
  String get weather_humidity => 'Влажность';

  @override
  String get weather_pressure => 'Давление';

  @override
  String get weather_uvIndex => 'УФ-индекс';

  @override
  String get weather_precipitation => 'Осадки';

  @override
  String get weather_sunrise => 'Восход';

  @override
  String get weather_sunset => 'Закат';

  @override
  String get weather_today => 'Сегодня';

  @override
  String get weather_noData => 'Нет данных';

  @override
  String get weather_uvLow => 'Низкий';

  @override
  String get weather_uvModerate => 'Умеренный';

  @override
  String get weather_uvHigh => 'Высокий';

  @override
  String get weather_uvVeryHigh => 'Очень высокий';

  @override
  String get weather_uvExtreme => 'Экстремальный';

  @override
  String get exchange_title => 'Курс валют';

  @override
  String get exchange_label => 'Валюта';

  @override
  String get exchange_noData => 'Нет данных';

  @override
  String get exchange_usDollar => 'Доллар США';

  @override
  String get exchange_euro => 'Евро';

  @override
  String get exchange_russianRuble => 'Российский рубль';

  @override
  String exchange_updated(Object date) {
    return 'Обновлено $date';
  }

  @override
  String get hub_jobFinder => 'Job Finder';

  @override
  String get hub_actualJobs => 'Актуальные вакансии';

  @override
  String get hub_fintech => 'FinTech';

  @override
  String get hub_courses => 'Курсы';

  @override
  String get hub_studentClubs => 'Студенческие клубы';

  @override
  String get hub_gym => 'Спортзал';

  @override
  String get courses_openAcademy => 'Открыть Академию';

  @override
  String get hub_aiChat => 'AI-Chat';

  @override
  String get hub_habits => 'Привычки';

  @override
  String get hub_library => 'Библиотека';

  @override
  String get hub_market => 'Маркет';

  @override
  String get hub_blogNews => 'Блог и Новости';

  @override
  String get hub_social => 'Социальные';

  @override
  String get hub_rent => 'Аренда';

  @override
  String get hub_documents => 'Документы';

  @override
  String get hub_forum => 'Форум';

  @override
  String get hub_widgetsDescription => 'Порядок расположения сервисов';

  @override
  String get profile_title => 'Профиль';

  @override
  String get profile_share => 'Поделиться профилем';

  @override
  String get profile_shareVia => 'Поделиться через...';

  @override
  String get profile_copyLink => 'Копировать ссылку';

  @override
  String get profile_linkCopied => 'Ссылка скопирована в буфер обмена';

  @override
  String get profile_followers => 'Подписчики';

  @override
  String get profile_following => 'Подписки';

  @override
  String get profile_rating => 'Рейтинг';

  @override
  String get profile_bio => 'О себе';

  @override
  String get profile_editProfile => 'Редактировать профиль';

  @override
  String get profile_workExperience => 'Опыт работы';

  @override
  String get profile_skills => 'Навыки';

  @override
  String get profile_education => 'Образование';

  @override
  String get profile_activities => 'Деятельность';

  @override
  String get profile_school => 'Школа';

  @override
  String get profile_university => 'Университет';

  @override
  String get profile_volunteering => 'Волонтерство';

  @override
  String get editProfile_accountData => 'Данные аккаунта';

  @override
  String get editProfile_personalData => 'Персональные данные';

  @override
  String get editProfile_phoneNumber => 'Номер телефона';

  @override
  String get editProfile_email => 'Почта';

  @override
  String get editProfile_dateOfBirth => 'Дата рождения';

  @override
  String get editProfile_gender => 'Пол';

  @override
  String get editProfile_deleteAccount => 'Удалить аккаунт';

  @override
  String get editProfile_deleteAccountDesc =>
      'Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить.';

  @override
  String get editProfile_male => 'Мужской';

  @override
  String get editProfile_female => 'Женский';

  @override
  String get editProfile_other => 'Другой';

  @override
  String get editProfile_changePhoto => 'Изменить фото';

  @override
  String get editProfile_takePhoto => 'Сделать фото';

  @override
  String get editProfile_chooseFromGallery => 'Выбрать из галереи';

  @override
  String get editProfile_avatarTemplates => 'Шаблоны аватаров';

  @override
  String get editProfile_profilePhoto => 'Фотография профиля';

  @override
  String get editProfile_avatars => 'Аватарки';

  @override
  String get editProfile_additionalPhone => 'Дополнительный номер';

  @override
  String get editProfile_addBioHint => 'Добавьте информацию о себе';

  @override
  String get editProfile_description => 'Описание';

  @override
  String get editProfile_descriptionHint => 'Расскажите о себе...';

  @override
  String get editProfile_addTag => 'Добавить тег';

  @override
  String get editProfile_tagHint => 'Введите название тега';

  @override
  String get profile_fillProfile => 'Заполните профиль';

  @override
  String profile_completedSteps(int completed, int total) {
    return '$completed/$total Завершено';
  }

  @override
  String get days_mon => 'Пн';

  @override
  String get days_tue => 'Вт';

  @override
  String get days_wed => 'Ср';

  @override
  String get days_thu => 'Чт';

  @override
  String get days_fri => 'Пт';

  @override
  String get days_sat => 'Сб';

  @override
  String get days_sun => 'Вс';

  @override
  String get auth_firstNameHint => 'Введите ваше имя';

  @override
  String get auth_lastNameHint => 'Введите вашу фамилию';

  @override
  String get auth_usernameHint => 'Введите ваш юзернейм';

  @override
  String get auth_usernameTaken =>
      'Пользователь с таким username уже существует';

  @override
  String get auth_studentIdTaken =>
      'Этот student ID уже зарегистрирован в приложении. Если вы уверены, что это ошибка, напишите нам: support@jasaim.kz';

  @override
  String get auth_usernameAvailable => 'Username свободен';

  @override
  String get auth_usernameInvalidFormat =>
      '3–30 символов: строчные буквы, цифры, нижнее подчёркивание';

  @override
  String get auth_passwordRule => 'Минимум 8 символов, включая букву и цифру';

  @override
  String get auth_passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get auth_nameAutoFilled => 'Имя и фамилия заполнены автоматически.';

  @override
  String get auth_sendCode => 'Отправить код';

  @override
  String get auth_enterVerificationCode =>
      'Введите код подтверждения, отправленный на';

  @override
  String get auth_resendCode => 'Отправить код повторно';

  @override
  String get auth_phoneOptional => 'Номер телефона (необязательно)';

  @override
  String get auth_studentIdHint => 'Студенческий ID';

  @override
  String get auth_invalidEmailFormat => 'Неверный формат email';

  @override
  String get auth_onlyNuEmailAllowed => 'Допускаются только email @nu.edu.kz';

  @override
  String get auth_alreadyRegistered =>
      'Вы уже зарегистрированы. Войдите в аккаунт, чтобы продолжить.';

  @override
  String get auth_biometricLoginTitle => 'Включить биометрический вход?';

  @override
  String get auth_biometricLoginDesc =>
      'Используйте отпечаток пальца или распознавание лица для более быстрого и безопасного входа.';

  @override
  String get auth_biometricEnable => 'Включить';

  @override
  String get auth_biometricMaybeLater => 'Позже';

  @override
  String get auth_personalDataConsent =>
      'Согласие на обработку персональных данных';

  @override
  String get auth_personalDataConsentBody =>
      'Согласие на обработку персональных данных\n\nОтмечая галочку, вы даёте согласие на обработку ваших персональных данных в соответствии с законодательством Республики Казахстан.\n\nЦель обработки данных:\n- Идентификация и аутентификация пользователей;\n- Предоставление услуг приложения;\n- Улучшение качества обслуживания;\n- Выполнение требований законодательства.\n\nСобираемые данные:\n- Имя и фамилия;\n- Адрес электронной почты (университетский домен);\n- Номер телефона (при предоставлении);\n- Данные аутентификации.\n\nВаши данные будут храниться в защищённом виде и не будут переданы третьим лицам без вашего явного согласия, за исключением случаев, предусмотренных законом.\n\nВы имеете право отозвать своё согласие в любое время, обратившись в службу поддержки. Отзыв согласия не влияет на законность обработки данных до момента его отзыва.\n\nПо вопросам обработки персональных данных обращайтесь: support@nu.edu.kz';

  @override
  String get notifications_title => 'Уведомления';

  @override
  String get notifications_all => 'Все';

  @override
  String get notifications_important => 'Важные';

  @override
  String get notifications_unread => 'Непрочитанные';

  @override
  String get notifications_markAllRead => 'Прочитать все';

  @override
  String get notifications_empty => 'Пока нет уведомлений';

  @override
  String get notifications_settings => 'Настройки уведомлений';

  @override
  String get notifications_push => 'Push-уведомления';

  @override
  String get notifications_personalChats => 'Личные сообщения';

  @override
  String get notifications_news => 'Новости и акции';

  @override
  String get notifications_fintech => 'Финтех';

  @override
  String get notifications_jobFinder => 'Поиск работы';

  @override
  String get notifications_courses => 'Курсы';

  @override
  String get notifications_today => 'Сегодня';

  @override
  String get notifications_yesterday => 'Вчера';

  @override
  String get notifications_enablePush => 'Включить все push-уведомления';

  @override
  String get notifications_categories => 'Категории уведомлений';

  @override
  String get notifications_chatsSubtitle => 'Уведомления о новых сообщениях';

  @override
  String get notifications_newsSubtitle => 'Новости и специальные предложения';

  @override
  String get notifications_fintechSubtitle => 'Платежи и транзакции';

  @override
  String get notifications_jobsSubtitle => 'Новые вакансии по вашему профилю';

  @override
  String get notifications_coursesSubtitle =>
      'Обновления и напоминания о курсах';

  @override
  String get security_title => 'Безопасность';

  @override
  String get security_changePassword => 'Изменить пароль';

  @override
  String get security_faceId => 'Face ID';

  @override
  String get security_pinCode => 'PIN-код';

  @override
  String get security_biometric => 'Биометрия';

  @override
  String get security_rememberMe => 'Запомнить меня';

  @override
  String get security_currentPassword => 'Текущий пароль';

  @override
  String get security_newPassword => 'Новый пароль';

  @override
  String get security_oldPassword => 'Старый пароль';

  @override
  String get security_confirmPassword => 'Подтвердите пароль';

  @override
  String get security_passwordChangedSuccess => 'Пароль успешно изменён';

  @override
  String get security_currentPasswordIncorrect => 'Текущий пароль неверен';

  @override
  String get security_passwordMinLength =>
      'Пароль должен содержать минимум 8 символов';

  @override
  String get security_passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get security_changePasswordFailed =>
      'Не удалось изменить пароль. Попробуйте ещё раз.';

  @override
  String get security_changePin => 'Изменить PIN-код';

  @override
  String get security_enterOldPin => 'Введите текущий PIN';

  @override
  String get security_enterNewPin => 'Введите новый PIN';

  @override
  String get security_confirmNewPin => 'Подтвердите новый PIN';

  @override
  String get security_pinChanged => 'PIN-код успешно изменён';

  @override
  String get help_title => 'Помощь';

  @override
  String get help_onlineChat => 'Онлайн чат';

  @override
  String get help_onlineChatDesc => 'Написать в поддержку';

  @override
  String get help_call => 'Позвонить';

  @override
  String get help_callDesc => 'Позвонить в поддержку';

  @override
  String get help_email => 'Email';

  @override
  String get help_emailDesc => 'Отправить письмо';

  @override
  String get help_supportPhone => '+7 (700) 123-4567';

  @override
  String get help_supportEmail => 'support@jasaim.kz';

  @override
  String get about_title => 'О приложении';

  @override
  String get about_rateApp => 'Оценить в Play Store';

  @override
  String get about_inviteFriends => 'Пригласить друзей';

  @override
  String get about_inviteFriendsMessage =>
      'Проверьте это удивительное приложение!';

  @override
  String get about_version => 'Версия';

  @override
  String get settings_selectCity => 'Выберите город';

  @override
  String get settings_searchCity => 'Поиск города...';

  @override
  String get deleteAccount_title => 'Удаление аккаунта';

  @override
  String get deleteAccount_warning =>
      'Это действие нельзя отменить. Все ваши данные будут безвозвратно удалены.';

  @override
  String get deleteAccount_confirm => 'Вы уверены, что хотите удалить аккаунт?';

  @override
  String get deleteAccount_button => 'Удалить мой аккаунт';

  @override
  String get bottomNav_home => 'Главная';

  @override
  String get bottomNav_hub => 'Хаб';

  @override
  String get bottomNav_access => 'Вход';

  @override
  String get bottomNav_profile => 'Профиль';

  @override
  String get bottomNav_settings => 'Настройки';

  @override
  String get saltoAccess_title => 'Вход';

  @override
  String get saltoAccess_ready => 'Готов к открытию';

  @override
  String get saltoAccess_open => 'Открыть';

  @override
  String get saltoAccess_scanning => 'Поиск...';

  @override
  String get saltoAccess_connecting => 'Подключение...';

  @override
  String get saltoAccess_granted => 'Доступ разрешён';

  @override
  String get saltoAccess_rejected => 'Доступ запрещён';

  @override
  String get saltoAccess_hint => 'Подойдите к турникету и нажмите кнопку ниже';

  @override
  String get saltoAccess_hintBluetooth =>
      'Убедитесь, что Bluetooth включён — он нужен для связи с турникетом';

  @override
  String get saltoAccess_noKey => 'Ключ недоступен';

  @override
  String get saltoAccess_notConfigured =>
      'SALTO не настроен. Обратитесь в поддержку.';

  @override
  String get profileMenu_settings => 'Настройки';

  @override
  String get profileMenu_myLevel => 'Мой уровень';

  @override
  String get profileMenu_showId => 'Показать ID';

  @override
  String get profileMenu_saved => 'Сохраненное';

  @override
  String get profileMenu_statistics => 'Статистика';

  @override
  String get profileMenu_findFriends => 'Найти друзей';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_basic => 'Основное';

  @override
  String get settings_myProfile => 'Мой профиль';

  @override
  String get settings_verification => 'Верификация';

  @override
  String get settings_notifications => 'Уведомление';

  @override
  String get settings_security => 'Безопасность';

  @override
  String get settings_info => 'Информация';

  @override
  String get settings_city => 'Город';

  @override
  String get settings_appLanguage => 'Язык приложения';

  @override
  String get settings_interfaceMode => 'Режим интерфейса';

  @override
  String get settings_aboutApp => 'О приложении';

  @override
  String get settings_help => 'Помощь';

  @override
  String get settings_logout => 'Выйти из профиля';

  @override
  String get settings_logoutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get settings_light => 'Светлый';

  @override
  String get settings_dark => 'Темный';

  @override
  String get profile_aboutMe => 'О себе';

  @override
  String get profile_addAboutMe => 'Добавьте информацию о себе';

  @override
  String get profile_add => 'Добавить';

  @override
  String get profile_academy => 'Академия';

  @override
  String get profile_activity => 'Активность';

  @override
  String get profile_expand => 'Развернуть';

  @override
  String get profile_collapse => 'Свернуть';

  @override
  String get profile_completionTitle => 'Заполненность профиля';

  @override
  String profile_completionSubtitle(int completed, int total) {
    return '$completed из $total полей заполнено';
  }

  @override
  String get profile_completed => 'Завершено';

  @override
  String get profile_message => 'Сообщение';

  @override
  String get profile_actions => 'Действия';

  @override
  String get profile_bonuses => 'Бонусы';

  @override
  String get profile_tokens => 'Токены';

  @override
  String get profile_tasks => 'Задания';

  @override
  String get profile_activityPoints => 'Активность';

  @override
  String get profile_rewards => 'Награды';

  @override
  String get profile_motivation => 'Мотивация';

  @override
  String get profile_statistics => 'Статистика';

  @override
  String get profile_profileViews => 'Просмотр профиля';

  @override
  String get profile_numbers => 'Числа';

  @override
  String get profile_watched => 'Смотрели';

  @override
  String get profile_searched => 'Искали';

  @override
  String get profile_savedItems => 'Сохранили';

  @override
  String get profile_subscriptions => 'Подписок';

  @override
  String get profile_subscribers => 'Подписчиков';

  @override
  String get profile_achievements => 'Награды';

  @override
  String get profile_allAchievements => 'Все награды';

  @override
  String get statistics_summary => 'Сводка';

  @override
  String get statistics_totalViews => 'Всего просмотров';

  @override
  String get statistics_interactions => 'Взаимодействия';

  @override
  String get statistics_messagesSent => 'Отправлено сообщений';

  @override
  String get statistics_contentShares => 'Поделились';

  @override
  String get resume_workExperience => 'Опыт работы';

  @override
  String get resume_addWorkExperience => 'Добавьте информацию об опыте работы';

  @override
  String get resume_companyName => 'Название компании';

  @override
  String get resume_position => 'Должность';

  @override
  String get resume_startDate => 'Дата начала';

  @override
  String get resume_endDate => 'Дата окончания';

  @override
  String get resume_present => 'По настоящее время';

  @override
  String get resume_description => 'Описание';

  @override
  String get resume_skills => 'Навыки';

  @override
  String get resume_addSkills => 'Добавьте информацию о навыках';

  @override
  String get resume_education => 'Образование';

  @override
  String get resume_addEducation => 'Добавьте информацию об образовании';

  @override
  String get resume_universityName => 'Название университета';

  @override
  String get resume_facultyName => 'Название факультета';

  @override
  String get resume_degree => 'Степень';

  @override
  String get resume_degreeBachelor => 'Бакалавриат';

  @override
  String get resume_degreeMaster => 'Магистратура';

  @override
  String get resume_degreeDoctoral => 'Докторантура / PhD';

  @override
  String get resume_degreeAssociate => 'Ассоциированная степень';

  @override
  String get resume_degreeCertificate => 'Сертификат';

  @override
  String get resume_degreeOther => 'Другое';

  @override
  String get resume_degreeOtherSpecify => 'Укажите степень';

  @override
  String get resume_academySkillsNote =>
      'Навыки задаются в разделе «Навыки» профиля — они общие для всего профиля.';

  @override
  String get resume_educationLoadFailed =>
      'Не удалось загрузить образование. Проверьте подключение и попробуйте снова.';

  @override
  String get resume_educationSaveFailed =>
      'Не удалось сохранить образование. Попробуйте снова.';

  @override
  String get resume_educationDeleteFailed =>
      'Не удалось удалить запись. Попробуйте снова.';

  @override
  String get profile_errorNetwork =>
      'Проверьте подключение к интернету и попробуйте снова.';

  @override
  String get profile_errorSession =>
      'Войдите в аккаунт снова и повторите попытку.';

  @override
  String get profile_errorGeneric => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get profile_activityPhotoTooLarge =>
      'Фото слишком большое. Максимум 5 МБ.';

  @override
  String get profile_activityMaxPhotos =>
      'Не больше 5 фото на одну активность.';

  @override
  String get profile_activityPhotoRead =>
      'Не удалось прочитать фото. Выберите другое изображение.';

  @override
  String get profile_activitySaveFailed =>
      'Не удалось сохранить активность. Попробуйте снова.';

  @override
  String get profile_activityDeleteFailed =>
      'Не удалось удалить активность. Попробуйте снова.';

  @override
  String get profile_skillsSaveFailed =>
      'Не удалось сохранить навыки. Попробуйте снова.';

  @override
  String get profile_skillsLoadFailed =>
      'Не удалось загрузить навыки. Проверьте подключение.';

  @override
  String get profile_experienceSaveFailed =>
      'Не удалось сохранить опыт работы. Попробуйте снова.';

  @override
  String get profile_experienceDeleteFailed =>
      'Не удалось удалить запись. Попробуйте снова.';

  @override
  String get profile_experienceLoadFailed =>
      'Не удалось загрузить опыт работы. Проверьте подключение.';

  @override
  String get profile_aboutMeSaveFailed =>
      'Не удалось сохранить. Попробуйте снова.';

  @override
  String get resume_gpa => 'GPA';

  @override
  String get resume_activities => 'Деятельность';

  @override
  String get resume_addActivities => 'Добавьте информацию о деятельности';

  @override
  String get resume_title => 'Резюме';

  @override
  String get resume_academyTab => 'Академия';

  @override
  String get resume_activityTab => 'Активность';

  @override
  String get resume_noWorkExperience => 'Опыт работы пока не добавлен';

  @override
  String get resume_noEducation => 'Образование пока не добавлено';

  @override
  String get resume_noSkills => 'Навыки пока не добавлены';

  @override
  String get resume_noActivity => 'Пока нет активности';

  @override
  String get common_add => 'Добавить';

  @override
  String get common_suggestions => 'Рекомендации';

  @override
  String get jobFinder_title => 'Поиск работы';

  @override
  String get jobFinder_findDreamJob => 'Найдите работу мечты';

  @override
  String get jobFinder_home => 'Главная';

  @override
  String get jobFinder_applications => 'Отклики';

  @override
  String get jobFinder_noApplications => 'Откликов пока нет';

  @override
  String get jobFinder_profileComingSoon => 'Профиль скоро появится';

  @override
  String get jobFinder_recentSearches => 'Вы прежде искали';

  @override
  String get jobFinder_noJobsFound => 'Вакансии не найдены';

  @override
  String get jobFinder_jobDetail => 'Описание вакансии';

  @override
  String get jobFinder_jobDetails => 'Описание';

  @override
  String get jobFinder_aboutCompany => 'О компании';

  @override
  String get jobFinder_description => 'Описание';

  @override
  String get jobFinder_apply => 'Откликнуться';

  @override
  String get jobFinder_applicationSent => 'Отклик успешно отправлен!';

  @override
  String get jobFinder_filters => 'Фильтры';

  @override
  String get jobFinder_clearAll => 'Сбросить все';

  @override
  String get jobFinder_location => 'Локация';

  @override
  String get jobFinder_enterLocation => 'Введите локацию';

  @override
  String get jobFinder_jobType => 'Тип работы';

  @override
  String get jobFinder_salaryRange => 'Диапазон зарплаты';

  @override
  String get jobFinder_experienceLevel => 'Уровень опыта';

  @override
  String get jobFinder_applyFilters => 'Применить фильтры';

  @override
  String jobFinder_jobsCount(int count) {
    return '$count работ';
  }

  @override
  String get jobFinder_explore => 'Обзор';

  @override
  String get jobFinder_saved => 'Сохранённые';

  @override
  String get jobFinder_noSavedJobs => 'Нет сохранённых вакансий';

  @override
  String get jobFinder_savedSubtitle => 'Сохранённые вакансии появятся здесь';

  @override
  String get jobFinder_featuredJobs => 'Рекомендуемые';

  @override
  String get jobFinder_promotedJobs => 'Продвигаемые';

  @override
  String get jobFinder_allCategories => 'Все категории';

  @override
  String get jobFinder_all => 'Все';

  @override
  String get jobFinder_inProcess => 'В процессе';

  @override
  String get jobFinder_accepted => 'Принято';

  @override
  String get jobFinder_declined => 'Отклонено';

  @override
  String jobFinder_appliedOn(String date) {
    return 'Подано $date';
  }

  @override
  String get jobFinder_alreadyApplied => 'Уже подано';

  @override
  String get fintech_title => 'Финтех';

  @override
  String get fintech_home => 'Главная';

  @override
  String get fintech_payments => 'Платежи';

  @override
  String get fintech_wallet => 'Кошелек';

  @override
  String get fintech_actions => 'Быстрые действия';

  @override
  String get fintech_services => 'Сервисы';

  @override
  String get fintech_viewAll => 'Все';

  @override
  String get fintech_finance => 'Финансы';

  @override
  String get fintech_tokens => 'Токены';

  @override
  String get fintech_nft => 'NFT';

  @override
  String get fintech_discounts => 'Скидки';

  @override
  String get fintech_customization => 'Настройка';

  @override
  String get fintech_bonuses => 'Бонусы';

  @override
  String get fintech_analytics => 'Аналитика';

  @override
  String get fintech_noCards => 'Карт пока нет';

  @override
  String get fintech_noTokens => 'Токенов пока нет';

  @override
  String get fintech_noNfts => 'NFT пока нет';

  @override
  String get fintech_noDiscounts => 'Скидки недоступны';

  @override
  String get fintech_totalBalance => 'Общий баланс';

  @override
  String get fintech_preview => 'Предпросмотр';

  @override
  String get fintech_selectColor => 'Выберите цвет карты';

  @override
  String get fintech_colorSaved => 'Цвет карты сохранен!';

  @override
  String get fintech_expiringSoon => 'Скоро истекает';

  @override
  String get fintech_transfer => 'Перевод';

  @override
  String get fintech_request => 'Запрос';

  @override
  String get fintech_inOut => 'Ввод/Вывод';

  @override
  String get fintech_cards => 'Карты';

  @override
  String get fintech_investing => 'Инвестиции';

  @override
  String get fintech_main => 'Главная';

  @override
  String get fintech_addCard => 'Добавить карту';

  @override
  String get fintech_freezeCard => 'Заморозить';

  @override
  String get fintech_unfreezeCard => 'Разморозить';

  @override
  String get fintech_showDetails => 'Показать детали';

  @override
  String get fintech_cardSettings => 'Настройки';

  @override
  String get fintech_transaction => 'Операция';

  @override
  String get fintech_amount => 'Сумма';

  @override
  String get fintech_completed => 'Завершено';

  @override
  String get fintech_seeAll => 'Все';

  @override
  String get fintech_getHelp => 'Помощь по карте';

  @override
  String get fintech_cardFrozen => 'Карта заморожена';

  @override
  String get fintech_cardUnfrozen => 'Карта разморожена';

  @override
  String get fintech_labelCard => 'Название карты';

  @override
  String get fintech_cardLabel => 'Название карты';

  @override
  String get fintech_unblockCvv => 'Разблокировать CVV';

  @override
  String get fintech_unblockCvvDesc => 'Используйте после 3 попыток';

  @override
  String get fintech_terminateCard => 'Закрыть карту';

  @override
  String get fintech_terminateConfirmTitle => 'Закрыть карту?';

  @override
  String get fintech_terminateConfirmDesc =>
      'Это действие необратимо. Карта будет навсегда закрыта и не может быть восстановлена.';

  @override
  String get fintech_terminate => 'Закрыть';

  @override
  String get fintech_cancel => 'Отмена';

  @override
  String get fintech_customise => 'Настройка';

  @override
  String get fintech_cvv => 'CVV';

  @override
  String get fintech_cvvUnblocked => 'CVV разблокирован';

  @override
  String get fintech_authRequired => 'Требуется аутентификация';

  @override
  String get fintech_labelSaved => 'Название карты сохранено';

  @override
  String get fintech_cardDesign => 'Дизайн карты';

  @override
  String get fintech_designSaved => 'Дизайн карты сохранён';

  @override
  String get fintech_cardTerminated => 'Карта закрыта';

  @override
  String get fintech_cardLabelHint => 'Введите название карты';

  @override
  String get fintech_noTransactions => 'Нет операций';

  @override
  String get fintech_yourCards => 'Ваши Карты';

  @override
  String get fintech_spendThisMonth => 'Расходы за месяц';

  @override
  String get fintech_totalWealth => 'Общее состояние';

  @override
  String get fintech_savingsGoals => 'Цели накоплений';

  @override
  String get fintech_upcomingPayments => 'Предстоящие платежи';

  @override
  String get fintech_recentPayees => 'Недавние получатели';

  @override
  String get fintech_transactionHistory => 'История операций';

  @override
  String get fintech_ofBudget => 'от бюджета';

  @override
  String get fintech_today => 'Сегодня';

  @override
  String get fintech_tomorrow => 'Завтра';

  @override
  String fintech_inDays(int days) {
    return 'Через $days дней';
  }

  @override
  String get fintech_cardDetails => 'Реквизиты карты';

  @override
  String get fintech_accountDetails => 'Данные счёта';

  @override
  String get fintech_cardholderName => 'Имя держателя';

  @override
  String get fintech_cardNumber => 'Номер карты';

  @override
  String get fintech_expiryDate => 'Срок действия';

  @override
  String get fintech_cardType => 'Тип карты';

  @override
  String get fintech_currency => 'Валюта';

  @override
  String get fintech_copied => 'Скопировано';

  @override
  String get fintech_share => 'Поделиться';

  @override
  String get fintech_topUp => 'Пополнить';

  @override
  String get fintech_balance => 'Баланс';

  @override
  String get fintech_cardInfo => 'Информация о карте';

  @override
  String get fintech_limits => 'Лимиты карты';

  @override
  String get fintech_limitsDesc => 'Дневные и месячные лимиты';

  @override
  String get fintech_changePin => 'Сменить PIN';

  @override
  String get fintech_changePinDesc => 'Установить новый PIN-код';

  @override
  String get fintech_reissueCard => 'Перевыпустить карту';

  @override
  String get fintech_reissueCardDesc => 'Заказать замену карты';

  @override
  String get fintech_closeCard => 'Закрыть карту';

  @override
  String get fintech_closeCardDesc => 'Навсегда закрыть эту карту';

  @override
  String get fintech_blockCard => 'Заблокировать карту';

  @override
  String get fintech_cardBlocked => 'Карта заблокирована';

  @override
  String get fintech_cardActive => 'Карта активна';

  @override
  String get fintech_securitySettings => 'Безопасность и настройки';

  @override
  String get fintech_recentTransactions => 'Последние транзакции';

  @override
  String get fintech_stocks => 'Акции';

  @override
  String get fintech_crypto => 'Крипто';

  @override
  String get fintech_portfolio => 'Портфель';

  @override
  String get fintech_totalValue => 'Общая стоимость';

  @override
  String get fintech_totalGain => 'Общая прибыль';

  @override
  String get fintech_holdings => 'Активы';

  @override
  String get fintech_popular => 'Популярные';

  @override
  String get fintech_marketCap => 'Капитализация';

  @override
  String get fintech_noStocks => 'Акции недоступны';

  @override
  String get fintech_noCrypto => 'Криптовалюты недоступны';

  @override
  String get fintech_buy => 'Купить';

  @override
  String get fintech_sell => 'Продать';

  @override
  String get fintech_avg => 'Сред.';

  @override
  String get fintech_qty => 'Кол-во';

  @override
  String get fintech_closeCardConfirmTitle => 'Закрыть карту?';

  @override
  String get fintech_closeCardConfirmDesc =>
      'Карта будет закрыта навсегда. Оставшиеся средства будут переведены на основной счёт.';

  @override
  String get fintech_close => 'Закрыть';

  @override
  String get fintech_cashback => 'Кэшбэк';

  @override
  String get fintech_cashbackDesc => 'До 3% за покупки';

  @override
  String get fintech_addMoney => 'Пополнить';

  @override
  String get fintech_exchange => 'Обмен';

  @override
  String get fintech_details => 'Детали';

  @override
  String get fintech_more => 'Ещё';

  @override
  String get fintech_accounts => 'Счета';

  @override
  String get fintech_searchHint => 'Поиск';

  @override
  String get fintech_inviteFriends => 'Пригласить друзей';

  @override
  String get fintech_inviteDesc => 'Получите бонус за каждого друга';

  @override
  String get fintech_widgetsSection => 'Виджеты';

  @override
  String get fintech_savings => 'Накопления';

  @override
  String get fintech_insurance => 'Страховка';

  @override
  String get fintech_budget => 'Бюджет';

  @override
  String get fintech_remaining => 'Осталось';

  @override
  String get fintech_categoryBreakdown => 'По категориям';

  @override
  String get fintech_payNow => 'Оплатить';

  @override
  String get fintech_schedule => 'Запланировать';

  @override
  String get fintech_paid => 'Оплачено';

  @override
  String get fintech_unpaid => 'Не оплачено';

  @override
  String get fintech_sendMoney => 'Отправить деньги';

  @override
  String get fintech_enterAmount => 'Введите сумму';

  @override
  String get fintech_send => 'Отправить';

  @override
  String get fintech_lastTransfer => 'Последний перевод';

  @override
  String get fintech_income => 'Доход';

  @override
  String get fintech_expense => 'Расход';

  @override
  String get fintech_repeat => 'Повторить';

  @override
  String get fintech_wealthBreakdown => 'По счетам';

  @override
  String get fintech_manage => 'Управление';

  @override
  String get fintech_history => 'История';

  @override
  String get fintech_status => 'Статус';

  @override
  String get fintech_date => 'Дата';

  @override
  String get fintech_category => 'Категория';

  @override
  String get fintech_trade => 'Торговать';

  @override
  String get fintech_withdraw => 'Вывести';

  @override
  String get fintech_tradingNews => 'Новости торговли';

  @override
  String get fintech_topMovers => 'Лидеры движения';

  @override
  String get fintech_marketOverview => 'Обзор рынка';

  @override
  String get fintech_readMore => 'Подробнее';

  @override
  String get fintech_bullish => 'Рост';

  @override
  String get fintech_bearish => 'Падение';

  @override
  String get fintech_neutral => 'Нейтрально';

  @override
  String get fintech_yourPortfolio => 'Ваш портфель';

  @override
  String get gamification_myLevel => 'Мой уровень';

  @override
  String get gamification_level => 'Уровень';

  @override
  String get gamification_levelUp => '🎉 Новый уровень!';

  @override
  String get gamification_toNextLevel => 'до следующего уровня';

  @override
  String get gamification_points => 'Баллы';

  @override
  String get gamification_ranking => 'Рейтинг';

  @override
  String get gamification_tasks => 'Задания';

  @override
  String get gamification_activity => 'Активность';

  @override
  String get gamification_achievements => 'Награды';

  @override
  String get gamification_motivation => 'Мотивация';

  @override
  String get gamification_of => 'из';

  @override
  String get gamification_participants => 'участников';

  @override
  String get gamification_taskCount => 'Количество заданий';

  @override
  String get gamification_noTasks => 'Заданий пока нет';

  @override
  String get gamification_noPointsHistory => 'История баллов пуста';

  @override
  String get gamification_today => 'Сегодня';

  @override
  String get gamification_yesterday => 'Вчера';

  @override
  String get gamification_earlier => 'Ранее';

  @override
  String get gamification_achievementsEarned => 'наград получено';

  @override
  String get gamification_noAchievements => 'Наград пока нет';

  @override
  String get gamification_goalsCompleted => 'целей выполнено';

  @override
  String get gamification_yourGoals => 'Ваши цели';

  @override
  String get gamification_seeAll => 'Все';

  @override
  String get gamification_noGoals => 'Целей пока нет';

  @override
  String get gamification_noGoalsDesc =>
      'Создайте свою первую цель и начните следить за своим прогрессом';

  @override
  String get gamification_noActivity => 'Активности пока нет';

  @override
  String get gamification_week => 'Неделя';

  @override
  String get gamification_month => 'Месяц';

  @override
  String get gamification_year => 'Год';

  @override
  String get gamification_expand => 'Развернуть';

  @override
  String get gamification_collapse => 'Свернуть';

  @override
  String get gamification_addActivity => 'Добавить активность';

  @override
  String get gamification_activityName => 'Название';

  @override
  String get gamification_date => 'Дата';

  @override
  String get gamification_description => 'Описание';

  @override
  String get gamification_attachPhoto => 'Прикрепить фотографию';

  @override
  String get gamification_activityPhoto => 'Фотография активности';

  @override
  String get gamification_awards => 'Награды';

  @override
  String get gamification_totalAwards => 'Всего наград';

  @override
  String get gamification_collected => 'Собрано';

  @override
  String get gamification_collection => 'Коллекция';

  @override
  String get gamification_totalAchievements => 'Всего наград';

  @override
  String get gamification_averageLevel => 'Средний уровень';

  @override
  String get gamification_goals => 'Цель';

  @override
  String get gamification_encouragement => 'Поощрение';

  @override
  String get gamification_addGoal => 'Добавить цель';

  @override
  String get motivation_goalTitle => 'Название цели';

  @override
  String get motivation_goalDescription => 'Описание цели';

  @override
  String get motivation_targetValue => 'Целевое значение';

  @override
  String get motivation_unit => 'Единица (уроки, баллы, дни и т. д.)';

  @override
  String get gamification_actions => 'Действия';

  @override
  String get gamification_bonuses => 'Бонусы';

  @override
  String get gamification_tokens => 'Токены';

  @override
  String get gamification_history => 'История';

  @override
  String get gamification_bonusesInfo =>
      'Бонусы — это баллы, которые вы получаете за выполнение заданий и достижений. Их можно использовать для разблокировки новых функций и наград.';

  @override
  String get gamification_tokensInfo =>
      'Токены — это цифровая валюта, которую вы получаете за участие в мероприятиях. Их можно обменять на призы и специальные предложения.';

  @override
  String get gamification_filterAll => 'Все';

  @override
  String get gamification_filterDaily => 'Ежедневные';

  @override
  String get gamification_filterWeekly => 'Еженедельные';

  @override
  String get gamification_filterAchievements => 'Достижения';

  @override
  String get gamification_typeDaily => 'Дневное';

  @override
  String get gamification_typeWeekly => 'Недельное';

  @override
  String get gamification_typeAchievement => 'Достижение';

  @override
  String get gamification_typeSpecial => 'Особое';

  @override
  String get gamification_typeBonus => 'Бонус';

  @override
  String get gamification_typeToken => 'Токен';

  @override
  String get gamification_allTasksCompleted => 'Все задания выполнены! 🎉';

  @override
  String get gamification_errorLoadingTasks => 'Ошибка загрузки заданий';

  @override
  String get gamification_completeTasksToEarn =>
      'Выполняйте задания, чтобы получить награды!';

  @override
  String get gamification_allAchievements => 'Все награды';

  @override
  String get social_followers => 'Подписчики';

  @override
  String get social_following => 'Подписки';

  @override
  String get social_follow => 'Подписаться';

  @override
  String get social_unfollow => 'Отписаться';

  @override
  String get social_message => 'Сообщение';

  @override
  String get social_rating => 'Рейтинг';

  @override
  String get social_searchFollowers => 'Поиск подписчиков...';

  @override
  String get social_searchFollowing => 'Поиск подписок...';

  @override
  String get social_noFollowers => 'Пока нет подписчиков';

  @override
  String get social_noFollowing => 'Вы пока ни на кого не подписаны';

  @override
  String get social_nothingFound => 'Ничего не найдено';

  @override
  String get social_findUsers => 'Найдите интересных пользователей';

  @override
  String get social_unfollowConfirmTitle => 'Отписаться?';

  @override
  String social_unfollowConfirmMessage(Object userName) {
    return 'Вы уверены, что хотите отписаться от $userName?';
  }

  @override
  String get social_cancel => 'Отмена';

  @override
  String get social_userNotFound => 'Пользователь не найден';

  @override
  String get social_back => 'Назад';

  @override
  String get social_aboutMe => 'О себе';

  @override
  String get social_workExperience => 'Опыт работы';

  @override
  String get social_skills => 'Навыки';

  @override
  String get social_academy => 'Академия';

  @override
  String get social_shareProfile => 'Поделиться профилем';

  @override
  String get social_copyLink => 'Скопировать ссылку';

  @override
  String get social_block => 'Заблокировать';

  @override
  String get social_messages => 'Сообщения';

  @override
  String get social_noMessages => 'Нет сообщений';

  @override
  String get social_startConversation => 'Начните разговор';

  @override
  String get social_sendFirstMessage => 'Отправьте первое сообщение';

  @override
  String get social_messageHint => 'Сообщение...';

  @override
  String get social_today => 'Сегодня';

  @override
  String get social_yesterday => 'Вчера';

  @override
  String get social_online => 'В сети';

  @override
  String get social_openProfile => 'Открыть профиль';

  @override
  String get social_searchInChat => 'Поиск в чате';

  @override
  String get social_muteNotifications => 'Отключить уведомления';

  @override
  String get social_deleteChat => 'Удалить чат';

  @override
  String get social_searchUsers => 'Поиск пользователей';

  @override
  String get social_enterNameOrUsername => 'Введите имя или username...';

  @override
  String get social_findUsersTitle => 'Найдите пользователей';

  @override
  String get social_tryAnotherQuery => 'Попробуйте другой запрос';

  @override
  String get social_subscriptions => 'Подписки';

  @override
  String get social_present => 'н.в.';

  @override
  String get web_loading => 'Загрузка...';

  @override
  String get web_error_title => 'Не удалось загрузить страницу';

  @override
  String get web_error_subtitle =>
      'Проверьте подключение к интернету и попробуйте снова';

  @override
  String get web_retry => 'Повторить';

  @override
  String get web_external_link_title => 'Открыть внешнюю ссылку?';

  @override
  String get web_external_link_message => 'Эта ссылка откроется в браузере';

  @override
  String get web_external_link_open => 'Открыть';

  @override
  String get web_external_link_cancel => 'Отмена';

  @override
  String get resume_currentlyWorkingHere => 'Я сейчас работаю здесь';

  @override
  String get resume_currentlyStudying => 'Я сейчас учусь';

  @override
  String get resume_selectDate => 'Выбрать дату';

  @override
  String get resume_attachPhoto => 'Прикрепить фотографию';

  @override
  String get resume_activityTitle => 'Активность';

  @override
  String get resume_activityName => 'Название';

  @override
  String get resume_activityDate => 'Дата';

  @override
  String get resume_institution => 'Учебное заведение';

  @override
  String get resume_degreeWithExample => 'Степень (Бакалавр и т.д.)';

  @override
  String get resume_specialization => 'Специализация';

  @override
  String get resume_gpaScore => 'Средний балл (GPA)';

  @override
  String get resume_recommended => 'Рекомендованные';

  @override
  String get points_bonuses => 'Бонусы';

  @override
  String get points_tokens => 'Токены';

  @override
  String get points_bonusesInfo =>
      'Бонусы - для чего они ваше нужны как ими пользоваться и чем есть';

  @override
  String get points_bonusesExchange =>
      'Бонусы можно обменять на токены по курсу\n100 Бонусов = 1 токен';

  @override
  String get points_tokensInfo =>
      'Токены - для чего они ваше нужны как ими пользоваться и чем есть';

  @override
  String get points_tokensExchange =>
      'Токены можно обменять на деньги или потратить внутри приложения списывается по курсу 1 токен = 100 тенге';

  @override
  String get points_filterBonuses => 'Бонусы';

  @override
  String get points_filterTokens => 'Токены';

  @override
  String get salto_mobileAccess => 'Мобильный доступ';

  @override
  String get salto_mobileAccessAlreadyEnabled =>
      'Мобильный проход уже активирован';

  @override
  String get salto_enableAccessInApp => 'Включить проход через приложение';

  @override
  String get salto_mobileKeyAlreadyIssued =>
      'Для этого аккаунта уже выпущен мобильный ключ. Продолжите настройку приложения.';

  @override
  String get salto_switchToMobileKeyDescription =>
      'После подтверждения аккаунт будет переключен с физической карты на мобильный ключ SALTO для прохода через турникет.';

  @override
  String get salto_physicalCardWarning =>
      'Важно: после активации физическая карта перестанет работать для прохода через турникет.';

  @override
  String get salto_activateInApp => 'Активировать в приложении';

  @override
  String get salto_skipForNow => 'Пока пропустить';

  @override
  String get salto_switchAccessConfirmTitle => 'Переключить доступ на телефон?';

  @override
  String get salto_switchAccessConfirmDescription =>
      'Физическая карта будет отключена для прохода через турникет. После этого доступ будет работать только через приложение.';

  @override
  String get salto_yesSwitch => 'Да, переключить';

  @override
  String get editProfile_avatarUpdated => 'Фото профиля обновлено';

  @override
  String get editProfile_usernameFormatHint =>
      'Username: 3-30 символов, только строчные буквы, цифры и _';

  @override
  String get editProfile_avatarUpdateFailed =>
      'Не удалось обновить фото профиля';

  @override
  String get hub_attendance => 'Посещаемость';

  @override
  String get hub_attendanceStudent => 'Студент';

  @override
  String get hub_attendanceTeacher => 'Профессор';

  @override
  String get hub_classroom => 'Classroom';

  @override
  String get tasks_special => 'Специальные';

  @override
  String get tasks_daily => 'Ежедневные задания';

  @override
  String get tasks_weekly => 'Еженедельные задания';

  @override
  String get tasks_achievements => 'Награды';

  @override
  String get tasks_claim => 'Получить';

  @override
  String get tasks_inProgress => 'В процессе';

  @override
  String get tasks_completed => 'Выполнено';

  @override
  String get tasks_toNextLevel => 'до следующего уровня';

  @override
  String get cancel => 'Отмена';

  @override
  String get pin_createTitle => 'Создайте PIN-код';

  @override
  String get pin_confirmTitle => 'Подтвердите PIN-код';

  @override
  String get pin_createSubtitle =>
      'Придумайте 4-значный PIN для быстрого доступа';

  @override
  String get pin_confirmSubtitle => 'Введите PIN-код повторно';

  @override
  String get pin_mismatchError => 'PIN-коды не совпадают';

  @override
  String get pin_enterTitle => 'Введите PIN-код';

  @override
  String get pin_enterSubtitle => 'Введите ваш PIN для продолжения';

  @override
  String get pin_biometricReason => 'Подтвердите свою личность';

  @override
  String pin_lockedMessage(int seconds) {
    return 'Слишком много попыток. Повторите через $seconds сек';
  }

  @override
  String get pin_incorrectError => 'Неверный PIN-код';

  @override
  String get pin_switchAccount => 'Сменить аккаунт';

  @override
  String get pin_biometricUnavailable =>
      'Биометрия недоступна. Пожалуйста, включите её в настройках устройства.';

  @override
  String get pin_sessionRefreshFailed =>
      'Не удалось обновить сессию. Проверьте интернет и попробуйте снова.';

  @override
  String get pin_sessionExpired =>
      'Сессия истекла. Войдите снова через логин и пароль.';

  @override
  String get pin_signingIn => 'Вход...';

  @override
  String get biometric_setupTitle => 'Быстрый доступ';

  @override
  String get biometric_setupDescription =>
      'Включите Face ID или отпечаток пальца для быстрого входа без ввода PIN-кода';

  @override
  String get biometric_setupReason =>
      'Подтвердите свою личность для включения биометрии';

  @override
  String get biometric_setupEnable => 'Включить';

  @override
  String get biometric_setupSkip => 'Пропустить';

  @override
  String get svc_title => 'Meal Pass';

  @override
  String get svc_weeklyProgress => 'Недельный прогресс';

  @override
  String get svc_mealsUsed => 'приёмов использовано';

  @override
  String get svc_remaining => 'осталось';

  @override
  String get svc_todayUsage => 'Сегодня';

  @override
  String get svc_todayMenu => 'Меню на сегодня';

  @override
  String get svc_scanQr => 'Сканировать QR для получения питания';

  @override
  String get svc_limitReached => 'Лимит исчерпан';

  @override
  String get svc_statusActive => 'Активно';

  @override
  String get svc_accessDenied => 'Доступ запрещён';

  @override
  String get svc_accessDeniedHint =>
      'У вас нет доступа к Meal Pass. Обратитесь в администрацию.';

  @override
  String get svc_mealRedeemed => 'Питание успешно получено!';

  @override
  String get svc_pointCamera => 'Наведите камеру на QR-код';

  @override
  String get svc_cameraPermissionDenied =>
      'Для сканирования QR-кодов необходим доступ к камере';

  @override
  String get svc_daysUsed => 'Дней использовано';

  @override
  String get svc_analyticsTitle => 'Аналитика Meal Pass';

  @override
  String get svc_totalRegistered => 'Зарегистрированные студенты';

  @override
  String get svc_totalActiveUsers => 'Активные пользователи';

  @override
  String get svc_totalMeals => 'Всего приёмов';

  @override
  String get svc_totalSpent => 'Общая сумма';

  @override
  String get svc_mealsBreakdown => 'Разбивка по блюдам';

  @override
  String get svc_spendingOverTime => 'Расходы по дням';

  @override
  String get svc_transactions => 'Транзакции';

  @override
  String get svc_student => 'Студент';

  @override
  String get svc_meal => 'Блюдо';

  @override
  String get svc_category => 'Категория';

  @override
  String get svc_price => 'Цена';

  @override
  String get svc_date => 'Дата';

  @override
  String get svc_breakfast => 'Завтрак';

  @override
  String get svc_lunch => 'Обед';

  @override
  String get svc_dinner => 'Ужин';

  @override
  String get svc_dailyCheck => 'Дневной чек';

  @override
  String get svc_mealSlots => 'Слоты питания';

  @override
  String get svc_skippedReminder => 'Пропущено';

  @override
  String get svc_noActiveSlot => 'Нет активного слота';

  @override
  String get svc_slotAlreadyRedeemed => 'Слот уже использован';

  @override
  String get svc_fixedMenu => 'Фиксированное меню';

  @override
  String get svc_availableMeals => 'Доступные блюда';

  @override
  String get svc_selectMeal => 'Выбрать блюдо';

  @override
  String get svc_categoryDistribution => 'Распределение по категориям';

  @override
  String get svc_exportPdf => 'Экспорт PDF';

  @override
  String get svc_avgPerStudent => 'Среднее на студента';

  @override
  String get svc_participationRate => 'Уровень участия';

  @override
  String get svc_analyticsReport => 'Отчёт аналитики Meal Pass';

  @override
  String get svc_dailySpending => 'Ежедневные расходы';

  @override
  String get svc_spendingPerStudent => 'Расходы на студента';

  @override
  String get svc_participation => 'Участие';

  @override
  String get svc_studentId => 'ID студента';

  @override
  String get svc_inactive => 'Неактивен';

  @override
  String get svc_meals => 'приём.';

  @override
  String get svc_avg => 'сред.';

  @override
  String get svc_total => 'Итого';

  @override
  String get svc_showMore => 'Показать ещё';

  @override
  String get svc_allTransactionsShown => 'Все транзакции показаны';

  @override
  String get svc_mealReceipt => 'Чек питания';

  @override
  String get svc_time => 'Время';

  @override
  String get svc_close => 'Закрыть';

  @override
  String get svc_name => 'Имя';

  @override
  String get svc_combo => 'Комбо';

  @override
  String get svc_mon => 'Пн';

  @override
  String get svc_tue => 'Вт';

  @override
  String get svc_wed => 'Ср';

  @override
  String get svc_thu => 'Чт';

  @override
  String get svc_fri => 'Пт';

  @override
  String get svc_sat => 'Сб';

  @override
  String get svc_sun => 'Вс';

  @override
  String get svc_faq => 'Вопросы и ответы';

  @override
  String get svc_faqHowToUse => 'Как пользоваться Meal Pass?';

  @override
  String get svc_faqHowToUseContent =>
      '1. Идите в столовую в часы приёма пищи\n2. Откройте приложение и нажмите \"Сканировать QR\"\n3. Наведите камеру на QR-код\n4. Дождитесь подтверждения\n5. Приятного аппетита!';

  @override
  String get svc_faqTimeSlots => 'Время приёма пищи';

  @override
  String get svc_faqTimeSlotsContent =>
      'Завтрак: 08:00 – 12:00\nОбед: 12:00 – 17:00\nУжин: 17:00 – 00:00';

  @override
  String get svc_mealReminders => 'Напоминания о приёме пищи';

  @override
  String get svc_reminderDescription =>
      'Получайте уведомления перед каждым приёмом пищи';

  @override
  String get svc_reminderBreakfast => 'Напоминание о завтраке';

  @override
  String get svc_reminderLunch => 'Напоминание об обеде';

  @override
  String get svc_reminderDinner => 'Напоминание об ужине';

  @override
  String svc_meal_reminder_open(String mealName) {
    return '$mealName уже доступен — не забудьте его получить!';
  }

  @override
  String svc_meal_reminder_closing(String mealName) {
    return 'Осталось всего 30 минут, чтобы получить $mealName — не пропустите!';
  }

  @override
  String get svc_successTitle => 'Приём пищи получен!';

  @override
  String get svc_successSubtitle =>
      'Ваш приём пищи успешно получен. Приятного аппетита!';

  @override
  String get svc_backToDashboard => 'На главную';

  @override
  String get svc_weeklyUsage => 'Использование питания за неделю';

  @override
  String get svc_weeklyLimitWarning =>
      'Недельный лимит достигнут. Нельзя подтвердить дополнительное питание.';

  @override
  String get svc_tomorrowConfirmation => 'Подтверждение питания на завтра';

  @override
  String get svc_confirmationCutoff => 'Подтверждение до 23:59 сегодня';

  @override
  String get svc_confirmationDeadlinePassed =>
      'Срок подтверждения истёк — форма закрыта после 20:00';

  @override
  String get svc_confirmSubmit => 'Сохранить выбор';

  @override
  String get svc_confirmSaved => 'Выбор питания сохранён!';

  @override
  String get svc_confirmSavedBadge => 'Сохранено';

  @override
  String get svc_missedMealComp => 'Компенсация пропущенного питания';

  @override
  String get svc_missedMealCompSubtitle =>
      'Подайте медицинскую справку за пропущенный приём пищи из-за болезни';

  @override
  String get svc_examMealComp => 'Компенсация питания за экзамен';

  @override
  String get svc_examMealCompSubtitle =>
      'Подайте подтверждение экзамена за пропущенный приём пищи. Вместо обеда — дополнительный ужин.';

  @override
  String get svc_submitRequest => 'Подать';

  @override
  String get svc_submitCompRequest => 'Подать заявку на компенсацию';

  @override
  String get svc_mealDate => 'Дата пропущенного приёма пищи';

  @override
  String get svc_mealType => 'Тип питания';

  @override
  String get svc_examDate => 'Дата экзамена';

  @override
  String get svc_missedMeal => 'Пропущенный приём пищи';

  @override
  String get svc_uploadDocument => 'Загрузить документ';

  @override
  String get svc_documentAttached => 'Документ прикреплён';

  @override
  String get svc_requestSubmitted => 'Заявка успешно подана';

  @override
  String get svc_requestHistory => 'Мои заявки';

  @override
  String get svc_noRequestsYet => 'Заявки ещё не поданы';

  @override
  String get svc_statusPending => 'На рассмотрении';

  @override
  String get svc_statusApproved => 'Одобрено';

  @override
  String get svc_statusRejected => 'Отклонено';

  @override
  String get svc_reqTypeMedical => 'Болезнь';

  @override
  String get svc_reqTypeExam => 'Экзамен';

  @override
  String get svc_tomorrowStats => 'Статистика питания на завтра';

  @override
  String get svc_compensationRequests => 'Заявки на компенсацию';

  @override
  String get svc_noCompRequests => 'Нет заявок на компенсацию';

  @override
  String get svc_approve => 'Одобрить';

  @override
  String get svc_reject => 'Отклонить';

  @override
  String get svc_approveSuccess => 'Заявка одобрена';

  @override
  String get svc_rejectSuccess => 'Заявка отклонена';

  @override
  String get tutorials_title => 'Обучение';

  @override
  String get tutorials_empty => 'Нет доступных обучений';

  @override
  String get tutorials_steps => 'шагов';

  @override
  String get tutorials_stepsHeader => 'Шаги';

  @override
  String get tutorials_guide => 'Руководство';

  @override
  String get settings_tutorials => 'Обучение';

  @override
  String get svc_faqHowToApply => 'Как подать заявку?';

  @override
  String get svc_faqHowToApplyContent =>
      '1. Нажмите на соответствующую кнопку запроса компенсации.\n2. Выберите дату и тип приема пищи.\n3. Обязательно прикрепите необходимый документ (медицинскую справку или расписание экзаменов).\n4. Дождитесь одобрения от администрации.';

  @override
  String get svc_faqHowToChange => 'Могу ли я изменить заявку?';

  @override
  String get svc_faqHowToChangeContent =>
      'В настоящее время заявки нельзя изменить после отправки. Пожалуйста, внимательно проверьте дату, тип приема пищи и прикрепленные документы перед отправкой. Если вы ошиблись, обратитесь в службу поддержки.';

  @override
  String get svc_notifyBefore => 'Напомнить до';

  @override
  String get svc_time15m => '15 мин';

  @override
  String get svc_time30m => '30 мин';

  @override
  String get svc_time45m => '45 мин';

  @override
  String get svc_time60m => '1 час';

  @override
  String get svc_debugEnableQr => 'ОТЛАДКА: Включить QR (Обход времени)';

  @override
  String get svc_debugEnableQrDesc =>
      'Разрешить сканирование вне часов приема пищи';

  @override
  String get svc_debugCloseMode => 'ОТЛАДКА: Режим закрытия';

  @override
  String get svc_debugCloseModeDesc => 'Имитировать закрытие в 20:00';

  @override
  String get svc_goGetMeal => 'Идите получать еду!';

  @override
  String get svc_noConfirmations => 'Нет подтверждений на завтра';

  @override
  String get svc_mealsConfirmed => 'Подтвержденные приемы пищи';

  @override
  String get svc_mealsConfirmedStatus => 'Статус';

  @override
  String get svc_none => 'Нет';

  @override
  String get svc_monthlyUsage => 'Месячная квота';

  @override
  String get svc_mealsPerMonth => 'приемов пищи/месяц';

  @override
  String get svc_quota => 'Квота';

  @override
  String get svc_monthlyLimitReached => 'Месячная квота исчерпана';

  @override
  String get svc_monthInfo => 'Информация о месяце';

  @override
  String get svc_currentMonth => 'Текущий месяц';

  @override
  String get svc_daysElapsed => 'Прошедшие дни';

  @override
  String get svc_avgPerDay => 'В среднем в день';

  @override
  String get svc_used => 'Использовано';

  @override
  String get svc_redeemedMeals => 'Выкупленные приемы пищи';

  @override
  String get svc_tomorrowConfirmationInfo =>
      'Подтвердите завтрашние приемы пищи в столовой';

  @override
  String get gamification_goalCreated => 'Цель успешно создана!';

  @override
  String get sos_title => 'SOS';

  @override
  String get sos_subtitle => 'Экстренные контакты';

  @override
  String get sos_emergencyActions => 'Экстренные звонки';

  @override
  String get sos_callPolice => 'Полиция';

  @override
  String get sos_callAmbulance => 'Скорая помощь';

  @override
  String get sos_callFire => 'Пожарная служба';

  @override
  String get sos_callEmergency => 'Экстренная помощь';

  @override
  String get sos_dialerUnavailable => 'Приложение телефона недоступно';

  @override
  String get hub_sos => 'SOS';

  @override
  String get bottomNav_notifications => 'Уведомления';

  @override
  String get settings_privacyPolicy => 'Политика конфиденциальности';

  @override
  String get social_chat => 'Чат';

  @override
  String get editPhone_description =>
      'Введите ваш казахстанский номер телефона';

  @override
  String get editPhone_invalidFormat => 'Неверный формат номера телефона';

  @override
  String get notifications_filterAll => 'Все';

  @override
  String get notifications_filterUnread => 'Непрочитанные';

  @override
  String get notifications_allCaughtUp => 'Всё прочитано!';

  @override
  String get notifications_noUnread => 'Нет непрочитанных уведомлений';

  @override
  String get notifications_openScreen => 'Открыть';

  @override
  String get notifications_pushPaused => 'Push-уведомления приостановлены';

  @override
  String get notifications_sectionMeals => 'Уведомления о питании';

  @override
  String get notifications_svcNotMember =>
      'Вы не являетесь участником Meal Pass';

  @override
  String get notifications_svcSubtitle => 'Баланс питания и обновления меню';

  @override
  String get notifications_settingsFootnote =>
      'Настройки уведомлений применяются к push-уведомлениям. Вы можете изменить их в любое время.';

  @override
  String get notif_action_viewClub => 'Открыть клуб';

  @override
  String get notif_action_showQr => 'Показать QR';

  @override
  String get notif_action_openWorkout => 'Открыть тренировку';

  @override
  String get notif_action_openChat => 'Открыть чат';

  @override
  String get notif_action_openWallet => 'Открыть кошелёк';

  @override
  String get notif_action_viewSchedule => 'Расписание';

  @override
  String get notif_action_findJob => 'Найти работу';

  @override
  String get notif_action_openAccess => 'Открыть доступ';

  @override
  String get notif_action_readMore => 'Читать далее';

  @override
  String get tasks_gettingStarted => 'Начало работы';

  @override
  String get tasks_yourProgress => 'Ваш прогресс';

  @override
  String get tasks_allDone => 'Все задачи выполнены!';

  @override
  String get tasks_allDoneDesc =>
      'Вы выполнили все доступные задачи. Отличная работа!';

  @override
  String get svc_greetingMorning => 'Доброе утро';

  @override
  String get svc_greetingAfternoon => 'Добрый день';

  @override
  String get svc_greetingEvening => 'Добрый вечер';

  @override
  String get svc_greetingSubtitle => 'Ваш план питания на сегодня';

  @override
  String get svc_mealDashboard => 'Питание';

  @override
  String get svc_mealLeaderboard => 'Рейтинг питания';

  @override
  String get svc_viewLeaderboard => 'Смотреть рейтинг';

  @override
  String get svc_mealHistory => 'История питания';

  @override
  String get svc_viewHistory => 'Посмотреть историю';

  @override
  String get svc_today => 'Сегодня';

  @override
  String get svc_yesterday => 'Вчера';

  @override
  String get svc_noMealsOnDay => 'Нет запланированных приёмов пищи';

  @override
  String get svc_skip => 'Пропустить';

  @override
  String get svc_going => 'Иду';

  @override
  String get svc_calendarTitle => 'Календарь питания';

  @override
  String get svc_todayMeals => 'Сегодняшние блюда';

  @override
  String get svc_statusLegend => 'Обозначения статусов';

  @override
  String get svc_statusScheduled => 'Запланировано';

  @override
  String get svc_statusScheduledDesc => 'Приём пищи забронирован на этот день';

  @override
  String get svc_statusReceived => 'Получено';

  @override
  String get svc_statusReceivedDesc => 'Приём пищи был получен';

  @override
  String get svc_statusCancelled => 'Отменено';

  @override
  String get svc_statusSkippedDesc => 'Приём пищи отменён или пропущен';

  @override
  String get svc_statusNoShow => 'Неявка';

  @override
  String get svc_statusNoShowDesc => 'Приём пищи не был получен';

  @override
  String get svc_mealStreak => 'Серия питания';

  @override
  String get svc_mealPass => 'Пропуск питания';

  @override
  String get svc_currentStreak => 'Текущая серия';

  @override
  String get svc_bestStreak => 'Лучшая серия';

  @override
  String get svc_noStreakYet => 'Серии ещё нет';

  @override
  String get svc_startStreak => 'Начните серию, получая питание каждый день!';

  @override
  String svc_streakDays(Object count) {
    return '$count дней';
  }

  @override
  String svc_nextMilestone(Object days) {
    return 'Ещё $days дней до следующего значка';
  }

  @override
  String get svc_badges => 'Значки';

  @override
  String svc_streakRequired(Object days) {
    return 'Нужна серия $days дней';
  }

  @override
  String get svc_totalReceived => 'Всего получено';

  @override
  String get svc_totalCancelled => 'Всего отменено';

  @override
  String get svc_noShows => 'Неявки';

  @override
  String get svc_goToMealPass => 'Перейти к пропуску питания';

  @override
  String get svc_noShowInfo =>
      'Пропуск приёма пищи без отмены считается неявкой и может повлиять на ваш статус';

  @override
  String get svc_faqCancelQ => 'Как отменить приём пищи?';

  @override
  String get svc_faqCancelA =>
      'Откройте календарь питания, нажмите на запланированный приём пищи и выберите «Отменить». Отменить можно за 2 часа до времени приёма пищи.';

  @override
  String get svc_faqNoShowQ => 'Что будет, если я не приду?';

  @override
  String get svc_faqNoShowA =>
      'Если вы пропустите приём пищи без отмены, он будет отмечен как неявка. Частые неявки могут повлиять на доступ к программе питания.';

  @override
  String get svc_faqStreakQ => 'Что такое серия питания?';

  @override
  String get svc_faqStreakA =>
      'Серия — это количество consecutive дней, когда вы получали питание. Более длинные серии открывают значки и награды.';

  @override
  String get svc_faqQrQ => 'Как использовать QR-код?';

  @override
  String get svc_faqQrA =>
      'Откройте приложение и нажмите «Сканировать QR», затем наведите камеру на QR-код в столовой. Дождитесь экрана подтверждения — питание будет отмечено автоматически.';

  @override
  String get svc_faqDeadlineQ => 'Каков срок отмены?';

  @override
  String get svc_faqDeadlineA =>
      'Вы можете отменить питание за 2 часа до запланированного времени. После этого отмена недоступна.';

  @override
  String get svc_faqUndoQ => 'Можно ли отменить отмену?';

  @override
  String get svc_faqUndoA =>
      'Да! Если окно отмены ещё не закрылось, вы можете отменить отмену через календарь питания.';

  @override
  String get svc_cancelMeal => 'Отменить приём пищи';

  @override
  String get svc_keepMeal => 'Оставить';

  @override
  String get svc_cancelConfirm => 'Подтвердить отмену';

  @override
  String get svc_cancelMealDescription =>
      'Отмена приёма пищи освободит место. Вы можете отменить это до истечения срока.';

  @override
  String get svc_cancelDeadlineLabel => 'Срок отмены';

  @override
  String get svc_honestCancelInfo =>
      'Честная отмена помогает другим получить питание';

  @override
  String get svc_cancelWindowClosed => 'Отмена недоступна';

  @override
  String get svc_cancelWindowClosedDesc =>
      'Окно отмены для этого приёма пищи закрыто. Пожалуйста, придите или это будет отмечено как неявка.';

  @override
  String get svc_cancelSuccess => 'Приём пищи успешно отменён';

  @override
  String get svc_undoCancellation => 'Отменить отмену';

  @override
  String get svc_undoCancelSuccess => 'Отмена отменена';

  @override
  String get svc_scanToReceive => 'Сканируйте, чтобы получить питание';

  @override
  String get svc_pointCameraAtQr => 'Наведите камеру на QR-код';

  @override
  String get svc_processing => 'Обработка...';

  @override
  String get svc_invalidQr => 'Неверный QR-код';

  @override
  String get svc_qrScanGenericError =>
      'Не удалось сканировать QR-код. Попробуйте ещё раз.';

  @override
  String get svc_scanAgain => 'Сканировать снова';

  @override
  String get svc_openSettings => 'Открыть настройки';

  @override
  String get svc_remainingTodayLabel => 'Осталось сегодня';

  @override
  String get svc_visitLabel => 'Визит';

  @override
  String get svc_studentLabel => 'Студент';

  @override
  String get svc_yourRank => 'Ваш рейтинг';

  @override
  String get svc_you => 'Вы';

  @override
  String get svc_leaderboardEmpty => 'Данных рейтинга пока нет';

  @override
  String get svc_couldNotLoad => 'Не удалось загрузить данные';

  @override
  String get svc_noHistoryYet => 'Истории питания пока нет';

  @override
  String get svc_historyEmpty =>
      'Начните получать питание, чтобы увидеть историю здесь';

  @override
  String get svc_historyComplete => 'Вы достигли конца';

  @override
  String get svc_loadingMore => 'Загрузка...';

  @override
  String get wordle_title => 'Wordle';

  @override
  String get wordle_subtitle => 'Угадайте слово из 5 букв';

  @override
  String get wordle_play => 'Играть';

  @override
  String get wordle_youWon => 'Великолепно!';

  @override
  String get wordle_youLost => 'Удачи завтра!';

  @override
  String get wordle_playAgainTomorrow =>
      'Возвращайтесь завтра за новой загадкой.';

  @override
  String get wordle_invalidWord => 'Слово не найдено в списке';

  @override
  String get wordle_tooShort => 'Недостаточно букв';

  @override
  String get wordle_networkError => 'Не удалось загрузить. Попробуйте позже.';

  @override
  String get wordle_streak => 'Серия';

  @override
  String get wordle_bestStreak => 'Рекорд';

  @override
  String get wordle_totalGames => 'Игр';

  @override
  String get wordle_winRate => 'Победы';

  @override
  String get wordle_statistics => 'Статистика';

  @override
  String get wordle_history => 'История';

  @override
  String get wordle_noHistory => 'Игр ещё нет';

  @override
  String get wordle_failed => 'Не угадано';

  @override
  String get wordle_reminderTitle => 'Ежедневное напоминание';

  @override
  String get wordle_reminderSubtitle => 'Уведомление о новой игре';

  @override
  String get wordle_reminderTime => 'Время напоминания';

  @override
  String get wordle_reminderInfo =>
      'Напоминание появится при открытии приложения после заданного времени.';

  @override
  String get wordle_reminderEnabled => 'Включено';

  @override
  String get wordle_notifTitle => 'Wordle готов!';

  @override
  String get wordle_notifBody => 'Сегодняшняя загадка ждёт вас.';

  @override
  String get wordle_viewStats => 'Статистика';

  @override
  String get wordle_alreadyPlayed => 'Сегодня уже сыграно';

  @override
  String wordle_solvedIn(Object attempts) {
    return 'Угадано за $attempts попыт(ок)';
  }

  @override
  String get settings_community => 'Сообщество';

  @override
  String get settings_shareJasWallet => 'Поделиться Jas Wallet';

  @override
  String get settings_inviteEarn => 'Реферал';

  @override
  String get settings_rateJasWallet => 'Оценить Jas Wallet';

  @override
  String get share_title => 'Поделиться Jas Wallet';

  @override
  String get share_subtitle => 'Расскажите друзьям о Jas Wallet';

  @override
  String get share_shareApp => 'Поделиться приложением';

  @override
  String get share_shareAppSubtitle =>
      'Отправить через WhatsApp, Telegram и другие социальные сети';

  @override
  String get share_copyLink => 'Скопировать ссылку';

  @override
  String get share_copyLinkSubtitle => 'Скопировать ссылку для скачивания';

  @override
  String get share_openStore => 'Открыть страницу в магазине';

  @override
  String get share_openStoreSubtitle =>
      'Просмотреть Jas Wallet в App Store или Play Store';

  @override
  String get share_linkCopied => 'Ссылка скопирована!';

  @override
  String get share_storeUnavailable => 'Страница магазина пока недоступна';

  @override
  String get referral_title => 'Реферал';

  @override
  String get referral_subtitle => 'Приглашайте друзей и открывайте достижения';

  @override
  String get referral_yourCode => 'Ваш реферальный код';

  @override
  String get referral_invitedFriends => 'Приглашённые друзья';

  @override
  String get referral_badgesEarned => 'Получено значков';

  @override
  String get referral_copyCode => 'Скопировать код';

  @override
  String get referral_shareInvite => 'Поделиться';

  @override
  String get referral_codeCopied => 'Реферальный код скопирован!';

  @override
  String get referral_yourProgress => 'Ваш прогресс';

  @override
  String referral_currentLevel(String name) {
    return 'Уровень: $name';
  }

  @override
  String get referral_noLevelYet =>
      'Пригласите первого друга, чтобы разблокировать значок';

  @override
  String get referral_invites => 'приглашение(й)';

  @override
  String referral_nextMilestone(String name, int count) {
    return 'Следующий: $name ($count приглашений)';
  }

  @override
  String referral_invitesNeeded(int count) {
    return 'Ещё $count приглашение(й)';
  }

  @override
  String get referral_rewardRoadmap => 'Дорожная карта достижений';

  @override
  String get referral_leaderboardTitle => 'Топ рефереров';

  @override
  String get rateApp_thanks => 'Спасибо! Ваш отзыв помогает нам улучшаться.';

  @override
  String get rateApp_error => 'Не удалось открыть диалог оценки';

  @override
  String get appUpdate_title => 'Доступно обновление';

  @override
  String get appUpdate_optionalMessage =>
      'Доступна новая версия Jas Wallet с новыми функциями и улучшениями.';

  @override
  String get appUpdate_requiredTitle => 'Требуется обновление';

  @override
  String get appUpdate_requiredMessage =>
      'Пожалуйста, обновите Jas Wallet, чтобы продолжить. Эта версия больше не поддерживается.';

  @override
  String get appUpdate_updateButton => 'Обновить';

  @override
  String get appUpdate_laterButton => 'Позже';

  @override
  String get events_nuTitle => 'События NU';

  @override
  String get events_aboutSection => 'О мероприятии';

  @override
  String get events_organizerSection => 'Организатор';

  @override
  String get events_openInBrowser => 'Открыть в браузере';

  @override
  String get widgets_alwaysVisible => 'Всегда виден';

  @override
  String get security_fingerprintSubtitle =>
      'Используйте отпечаток пальца для разблокировки';

  @override
  String get security_faceIdSubtitle => 'Используйте Face ID для разблокировки';

  @override
  String get security_authenticationSection => 'Аутентификация';

  @override
  String get help_subtitle => 'Как мы можем помочь вам сегодня?';

  @override
  String get help_telegramTitle => 'Telegram группа';

  @override
  String get help_telegramSubtitle => 'Задайте вопрос в группе';

  @override
  String get help_telegramOpenFailed => 'Не удалось открыть ссылку Telegram';

  @override
  String get help_emailSubject => 'Поддержка Jas Wallet';

  @override
  String help_emailSendFailed(String email) {
    return 'Не удалось отправить email на $email';
  }

  @override
  String get help_chatGreeting => 'Здравствуйте! Чем мы можем помочь?';

  @override
  String get help_chatMessageHint => 'Введите сообщение...';

  @override
  String get help_chatAutoReply =>
      'Спасибо за сообщение! Наша команда поддержки скоро ответит.';

  @override
  String tasks_progressCompleted(int completed, int total) {
    return '$completed из $total заданий выполнено';
  }

  @override
  String tasks_progressAvailable(int count) {
    return 'Доступно заданий: $count';
  }

  @override
  String get gamification_rewardsCollected => 'наград получено';

  @override
  String gamification_percentComplete(int percent) {
    return '$percent% завершено';
  }

  @override
  String get common_now => 'сейчас';

  @override
  String common_routeNotFound(String route) {
    return 'Маршрут не найден: $route';
  }

  @override
  String get notifications_silentModeDesc =>
      'Уведомления сохраняются без баннеров';

  @override
  String get notifications_categoryDisabled =>
      'Эта категория отключена в настройках уведомлений.';

  @override
  String get settings_privacyPolicyOpenFailed =>
      'Не удалось открыть политику конфиденциальности';

  @override
  String get about_storeOpenFailed => 'Не удалось открыть магазин приложений';

  @override
  String get about_developedBy => 'Разработано командой JASAIM';

  @override
  String get about_supportedBy => 'При поддержке NU Impact Foundation';

  @override
  String get editProfile_dateFormatInvalid =>
      'Введите дату в формате ДД.ММ.ГГГГ';

  @override
  String get editProfile_dateFormatHint => 'ДД.ММ.ГГГГ';

  @override
  String get editProfile_phoneHint => '+7 XXX XXX XX XX';

  @override
  String get auth_emailExample => 'example@nu.edu.kz';

  @override
  String get motivation_goalTitleHint => 'например, Пройти 50 уроков';

  @override
  String get motivation_goalDescriptionHint => 'Какая у вас цель?';

  @override
  String get motivation_unitHint => 'например, уроки, баллы, дни';

  @override
  String get motivation_goalDone => 'Готово! ✓';

  @override
  String hub_noSearchResults(String query) {
    return 'Нет результатов по запросу «$query»';
  }

  @override
  String get sos_callButton => 'ПОЗВОНИТЬ';

  @override
  String get svc_mealDateLabel => 'Дата питания:';

  @override
  String get svc_mealTypeLabel => 'Тип:';

  @override
  String get language_nameKazakh => 'Қазақша';

  @override
  String get language_nameRussian => 'Русский';

  @override
  String get language_nameEnglish => 'English';

  @override
  String get referral_enterCodeTitle => 'Есть реферальный код?';

  @override
  String get referral_enterCodeDesc =>
      'Введите реферальный код друга. Они получат вознаграждение, когда вы присоединитесь — это совершенно необязательно.';

  @override
  String get referral_codeFieldHint => 'Введите реферальный код';

  @override
  String get referral_applyCode => 'Применить код';

  @override
  String get referral_skipStep => 'Пропустить';

  @override
  String get referral_codeApplied => 'Реферальный код сохранён!';

  @override
  String get referral_invalidCodeFormat =>
      'Код должен содержать 3–10 букв или цифр';

  @override
  String get tutorial_svcMeal_slide1_title => 'Питание оплачено';

  @override
  String get tutorial_svcMeal_slide1_body =>
      'NU Impact Foundation зачисляет средства на ваш счёт. Наслаждайтесь едой в кампусе — полностью или частично за счёт фонда.';

  @override
  String get tutorial_svcMeal_slide2_title => 'Сканируйте и платите';

  @override
  String get tutorial_svcMeal_slide2_body =>
      'Покажите QR-код на кассе кафетерия для оплаты. Быстро, бесконтактно, без наличных.';

  @override
  String get tutorial_svcMeal_slide3_title => 'Стройте серию';

  @override
  String get tutorial_svcMeal_slide3_body =>
      'Питайтесь каждый день и поднимайтесь в таблице лидеров. Зарабатывайте значки, огненные серии и соревнуйтесь с кампусом.';

  @override
  String get tutorial_salto_slide1_title => 'Забудьте о пластиковых картах';

  @override
  String get tutorial_salto_slide1_body =>
      'Больше не нужно искать карту доступа. Ваш смартфон заменяет все пластиковые карты на кампусе.';

  @override
  String get tutorial_salto_slide2_title => 'Нажмите для открытия';

  @override
  String get tutorial_salto_slide2_body =>
      'Поднесите телефон к любому замку Salto. Одно касание по Bluetooth — и вы внутри.';

  @override
  String get tutorial_salto_slide3_title => 'Сделайте её своей';

  @override
  String get tutorial_salto_slide3_body =>
      'Выберите из нескольких дизайнов студенческой карты. Персонализируйте свой цифровой ID под свой стиль.';

  @override
  String get tutorial_referral_slide1_title => 'Пригласите друзей';

  @override
  String get tutorial_referral_slide1_body =>
      'Поделитесь уникальным реферальным кодом с одногруппниками. Вы оба получите награды при регистрации.';

  @override
  String get tutorial_referral_slide2_title => 'Поделитесь кодом';

  @override
  String get tutorial_referral_slide2_body =>
      'Скопируйте реферальную ссылку и отправьте её друзьям через любое приложение. Они регистрируются — вы оба получаете награду.';

  @override
  String get tutorial_referral_slide3_title => 'Рейтинг приглашений';

  @override
  String get tutorial_referral_slide3_body =>
      'Соревнуйтесь с другими пригласившими. Займите первое место и покажите свою сеть контактов.';

  @override
  String get tutorial_profile_slide1_title => 'Ваша цифровая идентичность';

  @override
  String get tutorial_profile_slide1_body =>
      'Одна карта объединяет всю кампусную жизнь — питание, доступ к зданиям, реферальная программа и многое другое в одном профиле.';

  @override
  String get tutorial_profile_slide2_title => 'Представьте себя';

  @override
  String get tutorial_profile_slide2_body =>
      'Создайте своё присутствие в кампусе — достижения, активность и студенческая жизнь в одном месте.';

  @override
  String get tutorial_profile_slide3_title => 'Заполните профиль';

  @override
  String get tutorial_profile_slide3_body =>
      'Чем больше вы заполняете, тем больше открываете. Полный профиль — полный доступ ко всем возможностям Jas Wallet.';

  @override
  String get contest_title => 'Конкурс';

  @override
  String get referral_contestDeadline => 'До 10 сентября 2026 года';

  @override
  String get contest_headline => 'Выиграй до\n₸100 000';

  @override
  String get contest_intro =>
      'Три конкурса. Один дедлайн. Реальные призы — победители объявляются командой BFLAB 10 сентября 2026 года.';

  @override
  String get contest_card1Title => 'Топ-3 по рефералам';

  @override
  String get contest_card1Desc => 'Приведи больше всего друзей в Jas Wallet.';

  @override
  String get contest_card2Title => 'Лучший рилс в Instagram';

  @override
  String get contest_card2Desc =>
      'Сними рилс о Jas Wallet или интересных хайлайтах студенческой жизни. Отметь @blockchain.fintech.lab и @nu_impact_foundation в публикации.';

  @override
  String get contest_card3Title => 'Самый креативный профиль';

  @override
  String get contest_card3Desc =>
      'Создай самый креативный профиль в Jas Wallet — сделай айди заметным и полностью заполни профиль. Важен весь профиль, а не только айди.';

  @override
  String get contest_card3Note =>
      'Отправь профиль в директ @blockchain.fintech.lab в Instagram.';

  @override
  String get contest_mandatoryLabel => 'Обязательно для всех конкурсов';

  @override
  String get contest_mandatoryDesc =>
      'Обязательное условие для всех конкурсов — отметить аккаунты @blockchain.fintech.lab и @nu_impact_foundation. Заявки без отметки не рассматриваются.';

  @override
  String get contest_announcement =>
      'Объявление победителей\n10 сентября 2026 года.';

  @override
  String get contest_legalPrefix =>
      'Принимая участие в этом конкурсе, вы автоматически соглашаетесь с ';

  @override
  String get contest_legalLink => 'правилами конкурса и положением';

  @override
  String get referral_inviteFriends => 'Пригласить друзей';

  @override
  String get referral_howItWorksTitle => 'Как это работает';

  @override
  String get referral_step1Title => 'Поделитесь кодом';

  @override
  String get referral_step1Desc =>
      'Скопируйте уникальный код или отправьте его напрямую друзьям.';

  @override
  String get referral_step2Title => 'Друг регистрируется';

  @override
  String get referral_step2Desc =>
      'Ваш друг скачивает Jas Wallet и регистрируется с вашим кодом.';

  @override
  String get referral_step3Title => 'Оба получают награды';

  @override
  String get referral_step3Desc =>
      'Достигайте вех, чтобы разблокировать эксклюзивные бейджи и подняться в рейтинге.';

  @override
  String get referral_promoTitle =>
      'Чем больше делишься,\nтем больше зарабатываешь';

  @override
  String get referral_promoDesc =>
      'Каждый приглашённый друг приближает тебя к следующему уровню наград.';

  @override
  String get referral_faqTitle => 'Частые вопросы';

  @override
  String get referral_faq1Q => 'Кто может участвовать в реферальной программе?';

  @override
  String get referral_faq1A =>
      'Любой зарегистрированный пользователь Jas Wallet с подтверждённым аккаунтом может приглашать друзей и получать награды.';

  @override
  String get referral_faq2Q => 'Когда я получу вознаграждение?';

  @override
  String get referral_faq2A =>
      'Вознаграждение начисляется после того, как ваш друг завершит регистрацию и подтвердит аккаунт.';

  @override
  String get referral_faq3Q => 'Есть ли ограничение на количество приглашений?';

  @override
  String get referral_faq3A =>
      'Без ограничений — приглашайте сколько угодно друзей и открывайте новые уровни.';

  @override
  String get referral_faq4Q => 'Что если у моего друга уже есть аккаунт?';

  @override
  String get referral_faq4A =>
      'Реферальный код работает только для новых пользователей, которые регистрируются впервые.';

  @override
  String get referral_detailsTitle => 'Дополнительно';

  @override
  String get referral_termsLink => 'Условия реферальной программы';

  @override
  String get referral_historyLink => 'История рефералов';

  @override
  String get referral_supportLink => 'Поддержка';

  @override
  String get contest_prizePool => 'Призовой фонд';

  @override
  String get contest_condSectionTitle => 'Правила конкурса';

  @override
  String get contest_cond1Title => 'Кто может участвовать';

  @override
  String get contest_cond1Desc =>
      'Любой студент с зарегистрированным аккаунтом Jas Wallet.';

  @override
  String get contest_cond3Title => 'Срок конкурса';

  @override
  String get contest_cond4Title => 'Выбор победителей';

  @override
  String get contest_cond4Desc =>
      'Рефералы: топ-3 по количеству приглашений. Reels и профиль: оцениваются командой @blockchain.fintech.lab.';

  @override
  String get contest_cond5Title => 'Объявление победителей';

  @override
  String get contest_faq1Q => 'Как выбираются победители?';

  @override
  String get contest_faq1A =>
      'Топ-3 рефереров по числу приглашений. Победители в Reels и Профиле выбираются командой @blockchain.fintech.lab.';

  @override
  String get contest_faq2Q => 'Можно ли участвовать во всех трёх конкурсах?';

  @override
  String get contest_faq2A =>
      'Да! Вы можете участвовать во всех трёх одновременно и победить в нескольких категориях.';

  @override
  String get contest_faq3Q => 'Когда будут вручены призы?';

  @override
  String get contest_faq3A =>
      'Победители будут объявлены, а призы вручены 10 сентября 2026 года.';

  @override
  String get contest_faq4Q => 'Есть вопросы?';

  @override
  String get contest_faq4A =>
      'Напишите в Direct @blockchain.fintech.lab в Instagram.';

  @override
  String get notifications_sectionEvents => 'События';

  @override
  String get notifications_eventsSubtitle =>
      'Уведомления на отслеживаемые мероприятия. Нажмите колокольчик на событии, чтобы подписаться.';

  @override
  String get events_followTooltip => 'Отслеживать это мероприятие';

  @override
  String get events_unfollowTooltip => 'Не отслеживать это мероприятие';

  @override
  String get events_followedToast =>
      'Вы будете получать напоминания об этом мероприятии';

  @override
  String get events_unfollowedToast =>
      'Напоминания об этом мероприятии выключены';

  @override
  String get events_reminderTitle => 'Скоро мероприятие';

  @override
  String events_reminderBody(String time, String title) {
    return 'Завтра в $time — $title';
  }

  @override
  String events_reminderBodyAllDay(String title) {
    return 'Завтра — $title';
  }

  @override
  String events_reminderBody12h(String time, String title) {
    return 'Через 12 часов в $time — $title';
  }

  @override
  String events_reminderBody1h(String time, String title) {
    return 'Через час, в $time — $title';
  }

  @override
  String get orientation_week_title => 'Club Fair';

  @override
  String get orientation_hub_banner_subtitle =>
      'Выполняйте задания, исследуйте кампус, выигрывайте призы';

  @override
  String orientation_day_of(Object day, Object total) {
    return 'День $day из $total';
  }

  @override
  String get orientation_tokens_label => 'Токены';

  @override
  String get orientation_continue_journey => 'Продолжить путь';

  @override
  String get orientation_networking_bingo => 'Бинго кампуса';

  @override
  String get orientation_photo_quests => 'Фото-квесты';

  @override
  String get orientation_leaderboard => 'Рейтинг';

  @override
  String get orientation_rewards => 'Призы';

  @override
  String get orientation_mini_games => 'Мини-игры';

  @override
  String orientation_min_short(Object minutes) {
    return '$minutes мин';
  }

  @override
  String orientation_xp_short(Object xp) {
    return '+$xp XP';
  }

  @override
  String get orientation_error_title => 'Что-то пошло не так';

  @override
  String get orientation_error_message =>
      'Не удалось загрузить Orientation Quest. Попробуйте еще раз.';

  @override
  String get orientation_offline_title => 'Вы не в сети';

  @override
  String get orientation_offline_message =>
      'Подключитесь к интернету, чтобы загрузить Orientation Quest.';

  @override
  String get orientation_bingo_title => 'Бинго кампуса';

  @override
  String get orientation_bingo_subtitle =>
      'Исследуйте кампус, чтобы закрыть каждую клетку';

  @override
  String orientation_cells_completed(Object count, Object total) {
    return '$count/$total клеток';
  }

  @override
  String get orientation_foundation_year => 'Foundation Year';

  @override
  String orientation_day_n(Object day) {
    return 'День $day';
  }

  @override
  String get orientation_profile_title => 'Мой профиль Orientation';

  @override
  String orientation_level_n(Object level) {
    return 'Уровень $level';
  }

  @override
  String get orientation_friends_met => 'Открыто мест';

  @override
  String get orientation_locations_visited => 'Локаций посещено';

  @override
  String get orientation_badges => 'Значки';

  @override
  String get orientation_photo_status_not_started => 'Не начато';

  @override
  String get orientation_photo_status_pending => 'На модерации';

  @override
  String get orientation_photo_status_approved => 'Одобрено';

  @override
  String get orientation_photo_status_rejected =>
      'Отклонено — попробуйте снова';

  @override
  String get orientation_redeem => 'Обменять';

  @override
  String get orientation_insufficient_tokens => 'Недостаточно токенов';

  @override
  String get orientation_awarded_automatically => 'Начисляется по рейтингу';

  @override
  String get orientation_completed_label => 'Выполнено';

  @override
  String get orientation_submit_answer => 'Ответить';

  @override
  String get orientation_true_or_myth_statement =>
      'Библиотека NU — первое здание, построенное на кампусе.';

  @override
  String get orientation_location_library => 'Библиотека';

  @override
  String get orientation_location_registrar => 'Registrar';

  @override
  String get orientation_location_sports_complex => 'Спорткомплекс';

  @override
  String get orientation_location_cafe => 'Кампус-кафе';

  @override
  String get orientation_leaderboard_weekly => 'Неделя';

  @override
  String get orientation_leaderboard_friends => 'Кампус';

  @override
  String get orientation_leaderboard_global => 'Все';

  @override
  String get orientation_photo_submitted_message =>
      'Фото отправлено на проверку!';

  @override
  String get orientation_progress_title => 'Прогресс';

  @override
  String get orientation_statistics => 'Статистика';

  @override
  String get orientation_tokens_earned => 'Заработано токенов';

  @override
  String get orientation_bingo_completion => 'Прогресс Bingo';

  @override
  String get orientation_achievements => 'Достижения';

  @override
  String get orientation_take_photo => 'Сделать фото';

  @override
  String get orientation_choose_from_gallery => 'Галерея';

  @override
  String get orientation_submit_photo => 'Отправить фото';

  @override
  String get orientation_available => 'Доступно';

  @override
  String get orientation_start => 'Начать';

  @override
  String orientation_plus_n(Object n) {
    return '+$n';
  }

  @override
  String get orientation_interests => 'Интересы';

  @override
  String get orientation_you_will_earn => 'Вы получите';

  @override
  String get orientation_foundation_year_short => 'Первый курс';

  @override
  String get orientation_leaderboard_school => 'Школа';

  @override
  String get orientation_bingo_line_hint => 'Закройте линию, чтобы получить';

  @override
  String get orientation_bingo_start_hint =>
      'Закройте ещё одну, чтобы получить';

  @override
  String get orientation_your_rank => 'Ваш ранг';

  @override
  String get orientation_todays_highlights => 'Главное сегодня';

  @override
  String orientation_highlight_bingo_subtitle(Object completed, Object total) {
    return 'Прогресс $completed/$total';
  }

  @override
  String orientation_highlight_photo_quest_subtitle(Object count) {
    return 'Осталось локаций: $count';
  }

  @override
  String get orientation_highlight_rewards_subtitle => 'Доступны новые призы';

  @override
  String orientation_day_n_of_total(Object day, Object total) {
    return 'День $day из $total';
  }

  @override
  String orientation_keep_going_name(Object name) {
    return 'Продолжайте, $name!';
  }

  @override
  String get orientation_keep_going => 'Продолжайте!';

  @override
  String get orientation_friends_added => 'Места';

  @override
  String get orientation_locations_visited_label => 'Локации';

  @override
  String get orientation_how_it_works => 'Как это работает';

  @override
  String get orientation_how_it_works_body =>
      'Сделайте фото в указанном месте и отправьте на проверку. После одобрения токены начислятся автоматически. Каждую локацию можно закрыть только один раз.';

  @override
  String get orientation_status_label => 'Статус';

  @override
  String get orientation_reward_label => 'Награда';

  @override
  String get orientation_campus_rewards => 'Призы кампуса';

  @override
  String get orientation_nav_home => 'Главная';

  @override
  String get orientation_nav_bingo => 'Бинго';

  @override
  String get orientation_nav_quests => 'Задания';

  @override
  String get orientation_nav_leaderboard => 'Рейтинг';

  @override
  String get orientation_nav_rewards => 'Призы';

  @override
  String get orientation_bingo_bonus_label => 'Бонус';

  @override
  String orientation_bingo_bonus_lines(Object count) {
    return '$count линий';
  }

  @override
  String get orientation_mission_reward => 'Награда за миссию';

  @override
  String get orientation_line_completion_reward => 'Награда за линию';

  @override
  String get orientation_board_completion_reward => 'Награда за поле';

  @override
  String get orientation_completed_missions => 'Выполненные миссии';

  @override
  String get orientation_your_journey => 'Ваш путь';

  @override
  String get orientation_you => 'Вы';

  @override
  String get orientation_leaderboard_rankings => 'Рейтинг';

  @override
  String get orientation_your_position => 'Ваша позиция';

  @override
  String orientation_tokens_to_rank(Object tokens, Object rank) {
    return '$tokens токенов до места №$rank';
  }

  @override
  String get orientation_top_of_leaderboard => 'Вы на вершине!';

  @override
  String get orientation_student_profile_title => 'Студент';

  @override
  String get orientation_orientation_explorer_badge =>
      'Исследователь ориентации';

  @override
  String orientation_streak_days_n(Object count) {
    return '$count дней подряд';
  }

  @override
  String get orientation_streak_active_subtitle =>
      'Вы выполняли задания каждый день.';

  @override
  String get orientation_streak_inactive_subtitle =>
      'Начните новую серию сегодня.';

  @override
  String get orientation_next_milestone => 'Далее';

  @override
  String get orientation_recently_unlocked => 'Недавно открыто';

  @override
  String get orientation_activity_breakdown => 'Разбивка активности';

  @override
  String orientation_days_remaining(Object days) {
    return 'Осталось $days дней';
  }

  @override
  String get orientation_orientation_complete => 'Ориентация завершена';

  @override
  String get orientation_milestone_started => 'Ориентация началась';

  @override
  String get orientation_milestone_first_friend => 'Первое открытое место';

  @override
  String get orientation_milestone_first_reward => 'Первая награда';

  @override
  String get orientation_milestone_halfway => 'Половина пути';

  @override
  String get orientation_milestone_campus_explorer => 'Исследователь кампуса';

  @override
  String get orientation_milestone_complete => 'Ориентация завершена';

  @override
  String get orientation_category_orientation => 'Ориентация';

  @override
  String get orientation_category_networking => 'Открытия';

  @override
  String get orientation_category_exploration => 'Исследование';

  @override
  String get orientation_category_participation => 'Участие';

  @override
  String get orientation_category_community => 'Сообщество';

  @override
  String get orientation_category_special => 'Особые';

  @override
  String orientation_achievements_unlocked_of_total(
    Object unlocked,
    Object total,
  ) {
    return '$unlocked / $total открыто';
  }

  @override
  String get orientation_featured_achievement => 'Главное достижение';

  @override
  String get orientation_view_details => 'Подробнее';

  @override
  String get orientation_hero_subtitle_1 => 'Ваш путь начинается здесь.';

  @override
  String get orientation_hero_subtitle_2 =>
      'Выполняйте задания, зарабатывайте токены и открывайте призы.';

  @override
  String orientation_activities_completed(Object completed, Object total) {
    return '$completed / $total заданий выполнено';
  }

  @override
  String get orientation_your_progress_title => 'Ваш прогресс';

  @override
  String orientation_tokens_of_level(Object tokens, Object total) {
    return '$tokens / $total токенов';
  }

  @override
  String orientation_tokens_to_next_level(Object tokens) {
    return '$tokens токенов до следующего уровня';
  }

  @override
  String get orientation_featured_reward_title => 'Главный приз';

  @override
  String get orientation_recent_achievement_title => 'Недавнее достижение';

  @override
  String get orientation_continue_your_journey => 'Продолжить путь';

  @override
  String get orientation_tab_overview => 'Главная';

  @override
  String get orientation_tab_challenges => 'Задания';

  @override
  String get orientation_schedule => 'Расписание';

  @override
  String get orientation_schedule_label => 'ОРИЕНТАЦИОННАЯ НЕДЕЛЯ';

  @override
  String get orientation_schedule_full => 'Всё расписание';

  @override
  String get orientation_schedule_empty_title => 'Ничего не запланировано';

  @override
  String get orientation_schedule_empty_body =>
      'В этот день нет сессий для вашей программы.';

  @override
  String get orientation_schedule_today => 'Сегодня';

  @override
  String get orientation_schedule_mandatory => 'Обязательно';

  @override
  String get orientation_schedule_recommended => 'Рекомендуется';

  @override
  String orientation_schedule_sessions(Object count) {
    return 'Сессий: $count';
  }

  @override
  String orientation_schedule_mandatory_count(Object count) {
    return 'обязательных: $count';
  }

  @override
  String get orientation_track_question => 'На какой вы программе?';

  @override
  String get orientation_track_body =>
      'На неделе идут два параллельных расписания. Выберите своё — и мы покажем только то, что касается вас.';

  @override
  String get orientation_track_ug => 'Бакалавриат';

  @override
  String get orientation_track_gr => 'Магистратура';

  @override
  String get orientation_track_change => 'Сменить программу';

  @override
  String get orientation_my_qr => 'Мой QR-код';

  @override
  String get orientation_my_qr_body =>
      'Покажите его другому студенту, чтобы он вас отсканировал. Код не меняется всю неделю.';

  @override
  String get orientation_qr_scan_someone => 'Отсканировать';

  @override
  String get orientation_school_pending => 'Определяем вашу школу…';

  @override
  String get orientation_school_pending_body =>
      'Мы определяем это автоматически по вашему студенческому ID. Это займёт всего момент.';

  @override
  String get orientation_school_unresolved_title =>
      'Не удалось определить школу';

  @override
  String get orientation_school_unresolved_body =>
      'В вашей студенческой записи пока нет данных о школе. Если это не решится само, свяжитесь с ADSL.';

  @override
  String get orientation_school_retry => 'Повторить';

  @override
  String get orientation_school_scan_blocked =>
      'Мы всё ещё проверяем вашу школу. Попробуйте снова через момент.';

  @override
  String get orientation_scan_not_ours => 'Это не код Ориентации';

  @override
  String get orientation_scan_not_ours_body =>
      'Попросите открыть Ориентационную неделю и показать свой QR-код.';

  @override
  String get orientation_scan_self => 'Это ваш собственный код';

  @override
  String get orientation_scan_self_body =>
      'Найдите другого студента и отсканируйте его код.';

  @override
  String get orientation_scan_duplicate => 'Уже отсканировано';

  @override
  String orientation_scan_duplicate_body(Object name) {
    return '$name уже засчитан для этого задания.';
  }

  @override
  String get orientation_scan_accepted => 'Засчитано';

  @override
  String get orientation_challenges_title => 'Задания';

  @override
  String get orientation_challenges_subtitle =>
      'Задания, где нужен ответ, скан или пост.';

  @override
  String get orientation_ch_progress_title => 'Прогресс заданий';

  @override
  String get orientation_ch_progress_subtitle =>
      'Отвечайте, сканируйте и делитесь на протяжении недели';

  @override
  String orientation_ch_completed(Object done, Object total) {
    return 'Выполнено $done / $total заданий';
  }

  @override
  String get orientation_ch_tokens_earned => 'Заработано токенов';

  @override
  String get orientation_challenge_save => 'Сохранить ответ';

  @override
  String get orientation_challenge_edit => 'Изменить ответ';

  @override
  String get orientation_challenge_clear => 'Удалить ответ';

  @override
  String get orientation_challenge_your_answer => 'Ваш ответ';

  @override
  String get orientation_challenge_open_referral => 'Открыть рефералку';

  @override
  String get orientation_challenge_done => 'Готово';

  @override
  String orientation_challenge_progress(Object done, Object total) {
    return 'Выполнено $done из $total';
  }

  @override
  String get orientation_tab_bingo => 'Бинго';

  @override
  String get orientation_tab_photo_quest => 'Фотоквест';

  @override
  String get orientation_tab_rewards => 'Призы';

  @override
  String get orientation_next_bingo_mission => 'Следующая миссия';

  @override
  String orientation_visit_location(Object location) {
    return 'Посетите $location';
  }

  @override
  String get orientation_redeem_a_reward => 'Получить приз';

  @override
  String get orientation_days_remaining_label => 'Осталось дней';

  @override
  String get orientation_total_tokens => 'Всего токенов';

  @override
  String get orientation_welcome_title =>
      'Добро пожаловать на Неделю ориентации! 🎉';

  @override
  String get orientation_welcome_subtitle =>
      'Участвуйте в активностях, исследуйте кампус и получайте награды.';

  @override
  String get orientation_overall_progress => 'Общий прогресс';

  @override
  String orientation_missions_progress(Object completed, Object total) {
    return 'Вы выполнили $completed из $total миссий';
  }

  @override
  String get orientation_complete_label => 'Выполнено';

  @override
  String get orientation_missions_completed_label => 'миссий выполнено';

  @override
  String get orientation_quick_access => 'Быстрый доступ';

  @override
  String get orientation_qr_scanner => 'QR-сканер';

  @override
  String get orientation_qa_bingo => 'Бинго';

  @override
  String get orientation_qa_photos => 'Фото';

  @override
  String get orientation_qa_scan => 'Скан QR';

  @override
  String get orientation_qa_challenges => 'Задания';

  @override
  String get orientation_earn_rewards_title => 'Получайте награды';

  @override
  String get orientation_earn_rewards_subtitle =>
      'Выполняйте миссии, собирайте токены и открывайте эксклюзивные награды Недели ориентации.';

  @override
  String get orientation_view_rewards => 'Смотреть награды';

  @override
  String get orientation_bingo_hero_title => 'Выполняй. Отмечай. Побеждай.';

  @override
  String get orientation_bingo_hero_subtitle =>
      'Выполняйте задания и собирайте бинго, чтобы заработать больше токенов!';

  @override
  String get orientation_bingo_progress_title => 'Прогресс бинго';

  @override
  String orientation_bingo_progress_subtitle(Object target) {
    return 'Соберите $target линий и получите крупный бонус!';
  }

  @override
  String orientation_bingo_lines_completed(Object completed, Object total) {
    return '$completed / $total линий собрано';
  }

  @override
  String get orientation_bingo_bonus_tokens => 'Бонусных токенов';

  @override
  String get orientation_bingo_free_space => 'СВОБОДНАЯ КЛЕТКА';

  @override
  String get orientation_bingo_cta_title => 'Больше заданий — больше наград';

  @override
  String get orientation_bingo_cta_subtitle =>
      'Продолжайте играть и открывайте новые награды!';

  @override
  String get orientation_bingo_mark_complete => 'Выполнить';

  @override
  String get orientation_bingo_completed_label => 'Выполнено';

  @override
  String orientation_bingo_squares_completed(Object completed, Object total) {
    return '$completed из $total клеток';
  }

  @override
  String get orientation_bingo_line_complete_toast => 'Линия собрана!';

  @override
  String get orientation_bingo_board_complete_toast =>
      'Бинго! Карточка собрана';

  @override
  String get orientation_pq_hero_title => 'Снимай. Делись. Зарабатывай.';

  @override
  String get orientation_pq_hero_subtitle =>
      'Выполняйте фотомиссии по кампусу и получайте награды!';

  @override
  String get orientation_pq_progress_title => 'Прогресс фотоквеста';

  @override
  String get orientation_pq_progress_subtitle =>
      'Выполняйте миссии и получайте токены!';

  @override
  String orientation_pq_missions_completed(Object completed, Object total) {
    return '$completed / $total миссий выполнено';
  }

  @override
  String get orientation_pq_complete_all => 'Выполните все, чтобы получить';

  @override
  String get orientation_pq_all_missions => 'Все миссии';

  @override
  String get orientation_pq_easy => 'Лёгкие';

  @override
  String get orientation_pq_medium => 'Средние';

  @override
  String get orientation_pq_hard => 'Сложные';

  @override
  String get orientation_pq_cta_title => 'Выполняйте больше фотомиссий!';

  @override
  String get orientation_pq_cta_subtitle =>
      'Завершите все миссии и получите бонусные токены и эксклюзивные награды.';

  @override
  String get orientation_pq_completed => 'Выполнено';

  @override
  String get orientation_pq_requirements => 'Что должно быть на фото';

  @override
  String get orientation_pq_where => 'Где снимать';

  @override
  String get orientation_pq_reward => 'Награда';

  @override
  String get orientation_pq_difficulty => 'Сложность';

  @override
  String get orientation_pq_take_photo => 'Сделать фото';

  @override
  String get orientation_pq_from_gallery => 'Выбрать из галереи';

  @override
  String get orientation_pq_retake => 'Переснять';

  @override
  String get orientation_pq_submit => 'Отправить фото';

  @override
  String get orientation_pq_submission_title => 'Отправка фото';

  @override
  String get orientation_pq_status_pending => 'На проверке';

  @override
  String get orientation_pq_status_rejected => 'Нужно фото получше';

  @override
  String get orientation_pq_status_locked => 'Заблокировано';

  @override
  String get orientation_pq_status_expired => 'Истекло';

  @override
  String get orientation_pq_notify_approved_title => 'Фотоквест засчитан';

  @override
  String orientation_pq_notify_approved_body(String mission, int tokens) {
    return '«$mission» проверено — вы получили $tokens токенов.';
  }

  @override
  String get orientation_pq_notify_declined_title => 'Нужно переснять фото';

  @override
  String orientation_pq_notify_declined_body(String mission) {
    return '«$mission» не принято. Сделайте новый снимок и попробуйте ещё раз.';
  }

  @override
  String get orientation_pq_empty_filter => 'Пока нет миссий этой сложности.';

  @override
  String get orientation_pq_bonus_unlocked => 'Фотоквест пройден!';

  @override
  String get orientation_rw_hero_title_1 => 'Твои усилия.';

  @override
  String get orientation_rw_hero_title_2a => 'Отличные ';

  @override
  String get orientation_rw_hero_title_2b => 'награды.';

  @override
  String get orientation_rw_hero_subtitle =>
      'Обменивайте токены на классные награды и впечатления.';

  @override
  String get orientation_rw_browse_category => 'Категории';

  @override
  String get orientation_rw_token_rewards => 'Награды за токены';

  @override
  String get orientation_rw_cat_all => 'Все';

  @override
  String get orientation_rw_cat_merch => 'Мерч';

  @override
  String get orientation_rw_cat_gift_cards => 'Карты';

  @override
  String get orientation_rw_cat_experiences => 'События';

  @override
  String get orientation_rw_cat_other => 'Другое';

  @override
  String orientation_rw_tokens_suffix(Object count) {
    return '$count токенов';
  }

  @override
  String get orientation_rw_hot => 'Хит';

  @override
  String get orientation_rw_unlimited => 'Без лимита';

  @override
  String orientation_rw_limited(Object count) {
    return 'Осталось: $count';
  }

  @override
  String get orientation_rw_out_of_stock => 'Нет в наличии';

  @override
  String get orientation_rw_coming_soon => 'Скоро';

  @override
  String get orientation_rw_expired => 'Истекло';

  @override
  String get orientation_rw_redeem => 'Обменять';

  @override
  String get orientation_rw_redeemed => 'Обменяно';

  @override
  String orientation_rw_need_more(Object count) {
    return 'Нужно ещё $count токенов';
  }

  @override
  String get orientation_rw_earn_more => 'Заработать';

  @override
  String get orientation_rw_details => 'О награде';

  @override
  String get orientation_rw_terms => 'Условия';

  @override
  String get orientation_rw_how_to_redeem => 'Как получить';

  @override
  String get orientation_rw_availability => 'Наличие';

  @override
  String get orientation_rw_remaining => 'Осталось';

  @override
  String get orientation_rw_confirm_title => 'Подтвердите обмен';

  @override
  String get orientation_rw_confirm_balance => 'Текущий баланс';

  @override
  String get orientation_rw_confirm_cost => 'Стоимость';

  @override
  String get orientation_rw_confirm_after => 'Баланс после';

  @override
  String get orientation_rw_cancel => 'Отмена';

  @override
  String get orientation_rw_success_title => 'Награда получена!';

  @override
  String get orientation_rw_success_body =>
      'Наслаждайтесь наградой. Проверьте историю, чтобы забрать её.';

  @override
  String get orientation_rw_view_history => 'История';

  @override
  String get orientation_rw_done => 'Готово';

  @override
  String get orientation_rw_history_title => 'История обменов';

  @override
  String get orientation_rw_exclusive_claimed_title =>
      'Эксклюзивный приз получен';

  @override
  String get orientation_rw_exclusive_claimed_body =>
      'Ты уже забрал один из топ-призов — новые обмены недоступны.';

  @override
  String get orientation_rw_history_empty =>
      'Вы ещё не обменяли ни одной награды.';

  @override
  String get orientation_rw_collected => 'Получено';

  @override
  String get orientation_rw_to_collect => 'Готово к выдаче';

  @override
  String get orientation_rw_milestones_title => 'Этапы';

  @override
  String get orientation_rw_keep_collecting => 'Продолжайте копить!';

  @override
  String get orientation_rw_milestone_subtitle =>
      'Достигайте новых этапов, чтобы открывать награды получше.';

  @override
  String get orientation_rw_view_milestones => 'Этапы';

  @override
  String get orientation_rw_next_milestone => 'Следующий этап';

  @override
  String get orientation_rw_unlocked => 'Открыто';

  @override
  String get orientation_rw_locked => 'Закрыто';

  @override
  String get orientation_rw_empty_category =>
      'В этой категории пока нет наград.';

  @override
  String get orientation_bingo_scan_qr => 'Сканировать QR';

  @override
  String get orientation_bingo_scan_hint =>
      'Попросите супервайзера показать QR-код, чтобы подтвердить задание.';

  @override
  String get orientation_bingo_auto_title => 'Отслеживается автоматически';

  @override
  String get orientation_bingo_auto_hint =>
      'Приложение само отметит это, когда вы выполните задание.';

  @override
  String get orientation_bingo_open_task => 'Выполнить задание';

  @override
  String get orientation_bingo_photo_hint =>
      'Эта клетка — фотозадание. Сделай снимок во вкладке Photo Quest.';

  @override
  String get orientation_challenge_wrong_answer =>
      'Неверный ответ — проверь и попробуй ещё раз.';

  @override
  String get orientation_challenge_invalid_student_id =>
      'Введи корректный Student ID — номер с карты NU.';

  @override
  String get orientation_challenge_senior_not_found =>
      'Такой Student ID не найден в справочнике университета. Проверь номер и попробуй ещё раз.';

  @override
  String get orientation_challenge_senior_too_recent =>
      'Этот человек в NU меньше трёх лет. Найди кого-нибудь постарше!';

  @override
  String get orientation_challenge_own_student_id =>
      'Это твой собственный Student ID — совет должен дать кто-то другой!';

  @override
  String get orientation_bingo_scan_instruction =>
      'Наведите камеру на QR клуба';

  @override
  String get orientation_bingo_scan_failed =>
      'Код не распознан. Попробуйте ещё раз.';

  @override
  String get orientation_rw_total_spent => 'Всего потрачено';

  @override
  String orientation_rw_redeemed_count(Object count) {
    return 'Обменяно: $count';
  }

  @override
  String get orientation_about_title => 'Что такое Club Fair?';

  @override
  String get orientation_about_body =>
      'Клубы NU в Атриуме - ходите по стендам, сканируйте QR клубов, выполняйте задания и тратьте токены на призы.';

  @override
  String get orientation_about_point_explore_title => 'Знакомство с клубами';

  @override
  String get orientation_about_point_explore_body =>
      'Все стенды в NU Atrium, в двух блоках: 11:00–14:00 и 15:00–18:00.';

  @override
  String get orientation_about_point_connect_title => 'Скан и бинго';

  @override
  String get orientation_about_point_connect_body =>
      'Сканируйте QR клубов за токены. Бинго - случайные 16 клубов из всего списка.';

  @override
  String get orientation_about_point_earn_title => 'Токены и призы';

  @override
  String get orientation_about_point_earn_body =>
      'Обменивайте токены во вкладке «Призы».';

  @override
  String get orientation_about_hide => 'Понятно, скрыть';

  @override
  String get orientation_partner_title => 'Совместно с ADSL';

  @override
  String get orientation_partner_body =>
      'ADSL (Ассоциация развития студенческой жизни) — студенческая некоммерческая организация NU, которая поддерживает инициативы, лидерство и активное студенческое сообщество.';

  @override
  String get orientation_partner_instagram_cta => 'Открыть Instagram';

  @override
  String get orientation_challenge_open_link => 'Открыть';

  @override
  String get orientation_rw_claim_title => 'Как получить приз';

  @override
  String get orientation_rw_claim_intro =>
      'Награды обмениваются в приложении, и выдаются лично.';

  @override
  String get orientation_rw_claim_step1 => 'Обменяйте награду в приложении.';

  @override
  String orientation_rw_claim_step2(String number) {
    return 'Напишите в WhatsApp на номер $number и укажите, какую награду вы обменяли.';
  }

  @override
  String get orientation_rw_claim_step3 =>
      'Заберите приз лично. Перед выдачей проводится дополнительная проверка на месте.';

  @override
  String get orientation_rw_claim_cta => 'Написать в WhatsApp';

  @override
  String get orientation_closed_title => 'Club Fair завершен';

  @override
  String get orientation_closed_body =>
      'Club Fair этого года окончен. Спасибо за участие — до встречи в следующем году!';

  @override
  String get orientation_freshmen_title => 'Только для первокурсников';

  @override
  String get orientation_freshmen_body =>
      'Неделя ориентации — мероприятие только для первокурсников: NUFYP, 1 курс бакалавриата и 1 курс магистратуры/докторантуры. Если вы не первокурсник, пожалуйста, не выполняйте задания — приз всё равно не будет вам начислен. Если вы всё же заберёте приз, получить его вы не сможете, а это создаст проблемы для первокурсников. Пожалуйста, отнеситесь с пониманием.';

  @override
  String get orientation_freshmen_acknowledge => 'Я ознакомлен';

  @override
  String get orientation_freshmen_card_title => 'Кто может участвовать';

  @override
  String get orientation_rw_view_details => 'Подробнее';

  @override
  String get orientation_rw_redemption_details => 'Детали обмена';

  @override
  String get orientation_rw_redeemed_on => 'Дата обмена';

  @override
  String get orientation_rw_tokens_spent => 'Потрачено токенов';

  @override
  String get orientation_rw_redeemed_by => 'Кто обменял';

  @override
  String get orientation_rw_field_name => 'Имя';

  @override
  String get orientation_rw_field_student_id => 'Student ID';

  @override
  String get orientation_rw_field_email => 'Email';

  @override
  String get orientation_rw_field_unset => 'Не указано';

  @override
  String get orientation_journey_title => 'Ваш 7-дневный путь';

  @override
  String orientation_journey_subtitle(Object current, Object total) {
    return 'День $current из $total';
  }

  @override
  String orientation_journey_day(Object n) {
    return 'День $n';
  }

  @override
  String get orientation_view_leaderboard => 'Таблица лидеров';

  @override
  String get orientation_leaderboard_cta_subtitle =>
      'Посмотрите своё место среди других студентов';

  @override
  String get orientation_faq_title => 'Частые вопросы';

  @override
  String get orientation_faq_q1 => 'Кто может участвовать?';

  @override
  String get orientation_faq_a1 =>
      'Любой студент NU. Club Fair для всего кампуса!';

  @override
  String get orientation_faq_q2 => 'Когда и где?';

  @override
  String get orientation_faq_a2 =>
      'С 23 по 27 августа 2026 в NU Atrium. Стенды клубов - пн–чт, 11:00–14:00 и 15:00–18:00 (в четверг только утром).';

  @override
  String get orientation_faq_q3 => 'Как работает скан QR клуба?';

  @override
  String get orientation_faq_a3 =>
      'Представитель клуба показывает QR (меняется каждые 20 секунд). Сканируйте его и получайте токены, которые начисляются один раз на клуб.';

  @override
  String get orientation_faq_q4 => 'Как работают токены?';

  @override
  String get orientation_faq_a4 =>
      'Дневных лимитов нет. Токены дают сканы клубов, выполнение заданий и линии бинго. Собирайте, а затем тратьте их во вкладке «Призы».';

  @override
  String get orientation_faq_q5 => 'Как работает бинго?';

  @override
  String get orientation_faq_a5 =>
      'Карточка - случайные 16 клубов в сетке 4×4. Скан клуба закрывает клетку. Линия даёт +50, четыре линии - +200 один раз.';

  @override
  String get orientation_faq_q6 => 'Как получить приз?';

  @override
  String get orientation_faq_a6 =>
      'Обменивайте во вкладке «Призы», затем напишите в WhatsApp на указанный номер. Приз выдают лично после проверки. Если возникают технические вопросы по приложению и работе квеста - просим обращаться по указанной кнопке в наш Telegram канал.';

  @override
  String get orientation_club_scan_title => 'QR клуба';

  @override
  String get orientation_club_scan_cta => 'Сканировать QR клуба';

  @override
  String orientation_club_scan_progress(Object scanned, Object total) {
    return '$scanned из $total клубов';
  }

  @override
  String orientation_club_scan_tokens(Object tokens) {
    return '$tokens токенов за сканы';
  }

  @override
  String get orientation_club_scan_already => 'Этот клуб вы уже сканировали.';

  @override
  String get orientation_club_scan_wrong => 'Это не QR стенда Club Fair.';

  @override
  String get orientation_club_scan_expired =>
      'QR истёк - попросите показать свежий.';

  @override
  String get orientation_club_scan_own => 'Нельзя сканировать QR своего клуба.';

  @override
  String get orientation_club_scan_outside =>
      'Этот клуб сейчас не представлен на Club Fair. Проверьте время и расписание.';

  @override
  String get orientation_club_scan_closed => 'Club Fair ещё не открыт.';

  @override
  String get orientation_tasks_group_all => 'Все';

  @override
  String get orientation_tasks_group_general => 'Общие';

  @override
  String get orientation_tasks_group_today => 'Сегодня';

  @override
  String get orientation_tasks_group_clubs => 'Клубы';

  @override
  String get orientation_tasks_group_photos => 'Фото-задания';

  @override
  String get orientation_tasks_group_qr => 'QR';

  @override
  String get orientation_schedule_morning => '11:00–14:00';

  @override
  String get orientation_schedule_afternoon => '15:00–18:00';

  @override
  String get orientation_schedule_always => 'Всю неделю';

  @override
  String get orientation_schedule_atrium => 'NU Atrium';

  @override
  String get orientation_schedule_in_quest => 'Квест';

  @override
  String get orientation_rw_tech_cta => 'Технические вопросы';

  @override
  String get orientation_rw_tech_body =>
      'Если у вас возникли технические проблемы или вопросы, просим обращаться в наш Telegram канал!';

  @override
  String get orientation_rw_tech_open => 'Открыть Telegram';

  @override
  String get orientation_qa_rewards => 'Призы';

  @override
  String get orientation_club_stand_qr_cta => 'Показать QR стенда';

  @override
  String get orientation_club_stand_qr_title => 'QR стенда';

  @override
  String orientation_club_stand_qr_body(int seconds) {
    return 'Покажите этот код студентам у стенда. Он меняется каждые $seconds секунд — фото из чата не сработает.';
  }

  @override
  String orientation_club_stand_qr_refresh(int seconds) {
    return 'Обновится через $seconds с';
  }

  @override
  String get orientation_club_stand_qr_live => 'Сейчас';

  @override
  String get orientation_club_stand_qr_waiting => 'Стенд закрыт';

  @override
  String get orientation_club_stand_qr_waiting_body =>
      'Живой код появляется только в слот вашего клуба на Club Fair.';

  @override
  String orientation_club_stand_qr_window(String window) {
    return 'Показывайте QR $window.';
  }

  @override
  String get orientation_club_stand_qr_all_week => 'в любое время Club Fair';

  @override
  String get orientation_club_stand_qr_not_rep =>
      'Этот аккаунт не указан как представитель клуба.';

  @override
  String get orientation_club_ranking_cta => 'Рейтинг Club Fair';

  @override
  String get orientation_club_ranking_cta_subtitle =>
      'Какие клубы студенты сканируют чаще';

  @override
  String get orientation_club_ranking_title => 'Рейтинг Club Fair';

  @override
  String get orientation_club_ranking_list => 'Все клубы';

  @override
  String orientation_club_ranking_scans(int count) {
    return '$count сканов';
  }

  @override
  String orientation_club_ranking_total(int scans, int clubs) {
    return '$scans сканов · $clubs клубов';
  }
}
