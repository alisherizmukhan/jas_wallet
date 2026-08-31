// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jas Wallet';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_back => 'Back';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_start => 'Start';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_keep => 'Keep';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_showPassword => 'Show password';

  @override
  String get common_hidePassword => 'Hide password';

  @override
  String get common_useBiometric => 'Use biometric authentication';

  @override
  String get common_done => 'Done';

  @override
  String get common_next => 'Next';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_saved => 'Saved';

  @override
  String get common_earlier => 'Earlier';

  @override
  String get common_userNotFound => 'User not found';

  @override
  String get common_search => 'Search';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_close => 'Close';

  @override
  String get common_hide => 'Hide';

  @override
  String get common_all => 'All';

  @override
  String get common_viewAll => 'View All';

  @override
  String get common_notSpecified => 'Not specified';

  @override
  String get common_deleteProfile => 'Delete profile';

  @override
  String get common_deleteAccountConfirm =>
      'Are you sure you want to delete your account?';

  @override
  String common_minutesAgo(Object count) {
    return '${count}m ago';
  }

  @override
  String common_hoursAgo(Object count) {
    return '${count}h ago';
  }

  @override
  String common_daysAgo(Object count) {
    return '${count}d ago';
  }

  @override
  String get splash_selectLanguage => 'Select Language';

  @override
  String get splash_welcomeMessage => 'Welcome to Jas Wallet';

  @override
  String get splash_russian => 'Russian';

  @override
  String get splash_english => 'English';

  @override
  String get splash_kazakh => 'Kazakh';

  @override
  String get welcome_title => 'Welcome to Jas Wallet';

  @override
  String get welcome_login => 'Login';

  @override
  String get welcome_register => 'Register';

  @override
  String get welcome_subtitle => 'Your journey starts here';

  @override
  String get auth_username => 'Username';

  @override
  String get auth_usernameOrEmail => 'Username or email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_repeatPassword => 'Repeat Password';

  @override
  String get auth_phone => 'Phone Number';

  @override
  String get auth_email => 'Email';

  @override
  String get auth_firstName => 'First Name';

  @override
  String get auth_lastName => 'Last Name';

  @override
  String get auth_forgotPassword => 'Forgot Password?';

  @override
  String get auth_noAccount => 'Don\'t have an account?';

  @override
  String get auth_hasAccount => 'Already have an account?';

  @override
  String get auth_signUp => 'Sign Up';

  @override
  String get auth_signIn => 'Sign In';

  @override
  String get auth_createAccount => 'Create Account';

  @override
  String get auth_agreeTerms =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get auth_consentDataCollection =>
      'I consent to data collection for service improvement';

  @override
  String get auth_registration => 'Registration';

  @override
  String get auth_registrationDesc => 'Use your @nu.edu.kz address to register';

  @override
  String get auth_register => 'Register';

  @override
  String get auth_login => 'Login';

  @override
  String get auth_loginDesc =>
      'Fill in brief information and log into your account';

  @override
  String get auth_rememberMe => 'Remember me';

  @override
  String get auth_createProfile => 'Create profile';

  @override
  String get auth_createProfileDesc =>
      'To continue registration, fill in brief information';

  @override
  String get auth_fullName => 'Full Name';

  @override
  String get auth_thinkUsername => 'Think of a username';

  @override
  String get auth_createPassword => 'Create password';

  @override
  String get biometric_verificationTitle => 'Biometric Verification';

  @override
  String get biometric_verificationDesc =>
      'To complete registration, you need to pass biometric verification';

  @override
  String get biometric_verificationError => 'Verification Error';

  @override
  String get biometric_verificationSuccess =>
      'Verification completed successfully';

  @override
  String get biometric_startVerification => 'Start Verification';

  @override
  String get biometric_processing => 'Processing...';

  @override
  String get biometric_requestingPermissions => 'Requesting Permissions...';

  @override
  String get biometric_permissionsDescription =>
      'Please allow access to camera and microphone';

  @override
  String get biometric_permissionsDeniedPermanently =>
      'Camera and microphone access is required for verification. Please allow access in app settings.';

  @override
  String get biometric_permissionsDenied =>
      'Camera and microphone access not granted. Please allow access and try again.';

  @override
  String get biometric_permissionsError => 'Error requesting permissions';

  @override
  String get biometric_openSettings => 'Open Settings';

  @override
  String get verification_title => 'Verification Code';

  @override
  String get verification_enterCode => 'Enter verification code';

  @override
  String verification_codeSent(String destination) {
    return 'Code sent to $destination';
  }

  @override
  String get verification_resend => 'Resend';

  @override
  String verification_resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgotPassword_title => 'Forgot Password';

  @override
  String get forgotPassword_selectMethod => 'Select recovery method';

  @override
  String get forgotPassword_viaPhone => 'Via Phone Number';

  @override
  String get forgotPassword_viaEmail => 'Via E-mail';

  @override
  String get forgotPassword_enterPhone =>
      'Enter your phone number to receive a verification code';

  @override
  String get forgotPassword_enterEmail =>
      'Enter your email to receive a verification code';

  @override
  String get forgotPassword_newPassword => 'New Password';

  @override
  String get forgotPassword_resetDesc =>
      'Create a new password for your account';

  @override
  String get forgotPassword_confirmPassword => 'Confirm New Password';

  @override
  String get forgotPassword_reset => 'Reset Password';

  @override
  String get forgotPassword_success => 'Password Changed Successfully';

  @override
  String get forgotPassword_successDesc =>
      'Your password has been updated. You can now log in with your new password.';

  @override
  String get common_contactUs => 'Contact Us';

  @override
  String get home_title => 'Home';

  @override
  String get stories_yourStory => 'Your Story';

  @override
  String get stories_addStory => 'Add Story';

  @override
  String get stories_publishAs => 'Publish as';

  @override
  String get stories_chooseMedia => 'Choose media';

  @override
  String get stories_mediaPhoto => 'Photo';

  @override
  String get stories_mediaVideo => 'Video';

  @override
  String get stories_publishFailed =>
      'Could not publish story. Please try again.';

  @override
  String get stories_publishForbidden =>
      'You do not have permission to publish stories for this organization.';

  @override
  String get stories_processingVideo => 'Preparing video...';

  @override
  String get stories_videoReadFailed =>
      'Could not prepare the selected video. Please choose another video.';

  @override
  String get stories_videoProcessFailed =>
      'Could not process the selected video. Please choose another video.';

  @override
  String get stories_deleteFailed =>
      'Could not delete story. Please try again.';

  @override
  String get stories_deleteForbidden =>
      'You do not have permission to delete this story.';

  @override
  String get stories_notFound =>
      'This story was not found. It may have already expired or been deleted.';

  @override
  String get stories_mediaUnsupported =>
      'Unsupported story media format. Please choose a supported photo or video.';

  @override
  String get stories_mediaTooLarge =>
      'Story file is too large. Please choose a smaller file.';

  @override
  String get stories_videoTooLong =>
      'Video is too long. Please choose a video up to 20 seconds.';

  @override
  String get stories_uploading => 'Uploading story...';

  @override
  String get stories_videoLoadFailed => 'Could not load this video.';

  @override
  String get stories_deleteTitle => 'Delete Story';

  @override
  String get stories_deleteMessage =>
      'Are you sure you want to delete this story?';

  @override
  String get stories_renderFailed =>
      'Could not prepare story for upload. Please try again.';

  @override
  String get stories_discardTitle => 'Discard Story?';

  @override
  String get stories_discardMessage =>
      'Are you sure you want to close? Your changes will be lost.';

  @override
  String get stories_discardConfirm => 'Discard';

  @override
  String get stories_keepEditing => 'Keep Editing';

  @override
  String get stories_share => 'Share Story';

  @override
  String get stories_videoPreview => 'Video Preview';

  @override
  String get stories_textHint => 'Type here...';

  @override
  String get stories_replyHint => 'Send message';

  @override
  String get stories_trimFailed =>
      'Could not trim the video. Please try again.';

  @override
  String get widgets_title => 'Widgets';

  @override
  String get widgets_description =>
      'Choose which widgets to display on your home screen';

  @override
  String get hub_title => 'Hub';

  @override
  String get hub_searchPlaceholder => 'Search services, jobs, courses...';

  @override
  String get hub_mainServices => 'Main Services';

  @override
  String get hub_comingSoon => 'Coming Soon!';

  @override
  String get hub_stories => 'Stories';

  @override
  String get hub_saltoCard => 'Student ID';

  @override
  String get hub_events => 'Events';

  @override
  String get hub_weather => 'Weather';

  @override
  String get hub_exchange => 'Exchange Rates';

  @override
  String get weather_title => 'Weather';

  @override
  String get weather_astana => 'Astana';

  @override
  String weather_feelsLike(Object temp) {
    return 'Feels like $temp°';
  }

  @override
  String get weather_forecast7day => '7-Day Forecast';

  @override
  String get weather_wind => 'Wind';

  @override
  String get weather_humidity => 'Humidity';

  @override
  String get weather_pressure => 'Pressure';

  @override
  String get weather_uvIndex => 'UV Index';

  @override
  String get weather_precipitation => 'Precipitation';

  @override
  String get weather_sunrise => 'Sunrise';

  @override
  String get weather_sunset => 'Sunset';

  @override
  String get weather_today => 'Today';

  @override
  String get weather_noData => 'No data';

  @override
  String get weather_uvLow => 'Low';

  @override
  String get weather_uvModerate => 'Moderate';

  @override
  String get weather_uvHigh => 'High';

  @override
  String get weather_uvVeryHigh => 'Very High';

  @override
  String get weather_uvExtreme => 'Extreme';

  @override
  String get exchange_title => 'Exchange Rates';

  @override
  String get exchange_label => 'Exchange';

  @override
  String get exchange_noData => 'No data';

  @override
  String get exchange_usDollar => 'US Dollar';

  @override
  String get exchange_euro => 'Euro';

  @override
  String get exchange_russianRuble => 'Russian Ruble';

  @override
  String exchange_updated(Object date) {
    return 'Updated $date';
  }

  @override
  String get hub_jobFinder => 'Job Finder';

  @override
  String get hub_actualJobs => 'Actual Jobs';

  @override
  String get hub_fintech => 'FinTech';

  @override
  String get hub_courses => 'Courses';

  @override
  String get hub_studentClubs => 'Student Clubs';

  @override
  String get hub_gym => 'Gym';

  @override
  String get courses_openAcademy => 'Open Academy';

  @override
  String get hub_aiChat => 'AI-Chat';

  @override
  String get hub_habits => 'Habits';

  @override
  String get hub_library => 'Library';

  @override
  String get hub_market => 'Market';

  @override
  String get hub_blogNews => 'Blog & News';

  @override
  String get hub_social => 'Social';

  @override
  String get hub_rent => 'Rent';

  @override
  String get hub_documents => 'Documents';

  @override
  String get hub_forum => 'Forum';

  @override
  String get hub_widgetsDescription => 'Порядок расположения сервисов';

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_share => 'Share Profile';

  @override
  String get profile_shareVia => 'Share via...';

  @override
  String get profile_copyLink => 'Copy Link';

  @override
  String get profile_linkCopied => 'Link copied to clipboard';

  @override
  String get profile_followers => 'Followers';

  @override
  String get profile_following => 'Following';

  @override
  String get profile_rating => 'Rating';

  @override
  String get profile_bio => 'Bio';

  @override
  String get profile_editProfile => 'Edit Profile';

  @override
  String get profile_workExperience => 'Work Experience';

  @override
  String get profile_skills => 'Skills';

  @override
  String get profile_education => 'Education';

  @override
  String get profile_activities => 'Activities';

  @override
  String get profile_school => 'School';

  @override
  String get profile_university => 'University';

  @override
  String get profile_volunteering => 'Volunteering';

  @override
  String get editProfile_accountData => 'Account data';

  @override
  String get editProfile_personalData => 'Personal data';

  @override
  String get editProfile_phoneNumber => 'Phone number';

  @override
  String get editProfile_email => 'E-mail';

  @override
  String get editProfile_dateOfBirth => 'Date of birth';

  @override
  String get editProfile_gender => 'Gender';

  @override
  String get editProfile_deleteAccount => 'Delete account';

  @override
  String get editProfile_deleteAccountDesc =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get editProfile_male => 'Male';

  @override
  String get editProfile_female => 'Female';

  @override
  String get editProfile_other => 'Other';

  @override
  String get editProfile_changePhoto => 'Change photo';

  @override
  String get editProfile_takePhoto => 'Take photo';

  @override
  String get editProfile_chooseFromGallery => 'Choose from gallery';

  @override
  String get editProfile_avatarTemplates => 'Avatar templates';

  @override
  String get editProfile_profilePhoto => 'Profile photo';

  @override
  String get editProfile_avatars => 'Avatars';

  @override
  String get editProfile_additionalPhone => 'Additional phone';

  @override
  String get editProfile_addBioHint => 'Add information about yourself';

  @override
  String get editProfile_description => 'Description';

  @override
  String get editProfile_descriptionHint => 'Tell us about yourself...';

  @override
  String get editProfile_addTag => 'Add tag';

  @override
  String get editProfile_tagHint => 'Enter tag name';

  @override
  String get profile_fillProfile => 'Fill your profile';

  @override
  String profile_completedSteps(int completed, int total) {
    return '$completed/$total Completed';
  }

  @override
  String get days_mon => 'Mon';

  @override
  String get days_tue => 'Tue';

  @override
  String get days_wed => 'Wed';

  @override
  String get days_thu => 'Thu';

  @override
  String get days_fri => 'Fri';

  @override
  String get days_sat => 'Sat';

  @override
  String get days_sun => 'Sun';

  @override
  String get auth_firstNameHint => 'Enter your first name';

  @override
  String get auth_lastNameHint => 'Enter your last name';

  @override
  String get auth_usernameHint => 'Enter your username';

  @override
  String get auth_usernameTaken => 'This username is already taken';

  @override
  String get auth_studentIdTaken =>
      'This student ID is already registered in the app. If you believe this is a mistake, contact us at support@jasaim.kz';

  @override
  String get auth_usernameAvailable => 'Username is available';

  @override
  String get auth_usernameInvalidFormat =>
      '3–30 characters: lowercase letters, digits, underscore';

  @override
  String get auth_passwordRule =>
      'At least 8 characters, including a letter and a number';

  @override
  String get auth_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get auth_nameAutoFilled =>
      'First and last name were filled automatically.';

  @override
  String get auth_sendCode => 'Send code';

  @override
  String get auth_enterVerificationCode =>
      'Enter the verification code sent to';

  @override
  String get auth_resendCode => 'Resend code';

  @override
  String get auth_phoneOptional => 'Phone number (optional)';

  @override
  String get auth_studentIdHint => 'Student ID';

  @override
  String get auth_invalidEmailFormat => 'Invalid email format';

  @override
  String get auth_onlyNuEmailAllowed => 'Only @nu.edu.kz emails are allowed';

  @override
  String get auth_alreadyRegistered =>
      'You are already registered. Please log in to continue.';

  @override
  String get auth_biometricLoginTitle => 'Enable Biometric Login?';

  @override
  String get auth_biometricLoginDesc =>
      'Use fingerprint or face recognition for faster and more secure login next time.';

  @override
  String get auth_biometricEnable => 'Enable';

  @override
  String get auth_biometricMaybeLater => 'Maybe later';

  @override
  String get auth_personalDataConsent => 'Personal Data Consent';

  @override
  String get auth_personalDataConsentBody =>
      'Personal Data Processing Consent\n\nBy checking the box, you give your consent to the processing of your personal data in accordance with the legislation of the Republic of Kazakhstan.\n\nPurpose of data processing:\n- Identification and authentication of users;\n- Provision of application services;\n- Improvement of service quality;\n- Compliance with legal requirements.\n\nData collected:\n- First name and last name;\n- Email address (university domain);\n- Phone number (if provided);\n- Authentication credentials.\n\nYour data will be stored securely and will not be shared with third parties without your explicit consent, except as required by law.\n\nYou have the right to withdraw your consent at any time by contacting support. Withdrawal of consent does not affect the lawfulness of processing based on consent before its withdrawal.\n\nFor questions regarding personal data processing, please contact: support@nu.edu.kz';

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_all => 'All';

  @override
  String get notifications_important => 'Important';

  @override
  String get notifications_unread => 'Unread';

  @override
  String get notifications_markAllRead => 'Mark all as read';

  @override
  String get notifications_empty => 'No notifications yet';

  @override
  String get notifications_settings => 'Notification Settings';

  @override
  String get notifications_push => 'Push Notifications';

  @override
  String get notifications_personalChats => 'Personal Chats';

  @override
  String get notifications_news => 'News & Promotions';

  @override
  String get notifications_fintech => 'Fintech';

  @override
  String get notifications_jobFinder => 'Job Finder';

  @override
  String get notifications_courses => 'Courses';

  @override
  String get notifications_today => 'Today';

  @override
  String get notifications_yesterday => 'Yesterday';

  @override
  String get notifications_enablePush => 'Enable all push notifications';

  @override
  String get notifications_categories => 'Notification Categories';

  @override
  String get notifications_chatsSubtitle => 'Get notified about new messages';

  @override
  String get notifications_newsSubtitle => 'Stay updated with news and offers';

  @override
  String get notifications_fintechSubtitle => 'Payments and transactions';

  @override
  String get notifications_jobsSubtitle => 'New jobs matching your profile';

  @override
  String get notifications_coursesSubtitle => 'Course updates and reminders';

  @override
  String get security_title => 'Security';

  @override
  String get security_changePassword => 'Change Password';

  @override
  String get security_faceId => 'Face ID';

  @override
  String get security_pinCode => 'PIN Code';

  @override
  String get security_biometric => 'Biometric ID';

  @override
  String get security_rememberMe => 'Remember Me';

  @override
  String get security_currentPassword => 'Current Password';

  @override
  String get security_newPassword => 'New Password';

  @override
  String get security_oldPassword => 'Old Password';

  @override
  String get security_confirmPassword => 'Confirm Password';

  @override
  String get security_passwordChangedSuccess => 'Password changed successfully';

  @override
  String get security_currentPasswordIncorrect =>
      'Current password is incorrect';

  @override
  String get security_passwordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get security_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get security_changePasswordFailed =>
      'Could not change password. Please try again.';

  @override
  String get security_changePin => 'Change PIN Code';

  @override
  String get security_enterOldPin => 'Enter current PIN';

  @override
  String get security_enterNewPin => 'Enter new PIN';

  @override
  String get security_confirmNewPin => 'Confirm new PIN';

  @override
  String get security_pinChanged => 'PIN changed successfully';

  @override
  String get help_title => 'Help';

  @override
  String get help_onlineChat => 'Online Chat';

  @override
  String get help_onlineChatDesc => 'Chat with our support team';

  @override
  String get help_call => 'Call';

  @override
  String get help_callDesc => 'Call our support line';

  @override
  String get help_email => 'Email';

  @override
  String get help_emailDesc => 'Send us an email';

  @override
  String get help_supportPhone => '+7 (700) 123-4567';

  @override
  String get help_supportEmail => 'support@jasaim.kz';

  @override
  String get about_title => 'About App';

  @override
  String get about_rateApp => 'Rate in Play Store';

  @override
  String get about_inviteFriends => 'Invite Friends';

  @override
  String get about_inviteFriendsMessage => 'Check out this amazing app!';

  @override
  String get about_version => 'Version';

  @override
  String get settings_selectCity => 'Select City';

  @override
  String get settings_searchCity => 'Search city...';

  @override
  String get deleteAccount_title => 'Delete Account';

  @override
  String get deleteAccount_warning =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get deleteAccount_confirm =>
      'Are you sure you want to delete your account?';

  @override
  String get deleteAccount_button => 'Delete My Account';

  @override
  String get bottomNav_home => 'Home';

  @override
  String get bottomNav_hub => 'Hub';

  @override
  String get bottomNav_access => 'Access';

  @override
  String get bottomNav_profile => 'Profile';

  @override
  String get bottomNav_settings => 'Settings';

  @override
  String get saltoAccess_title => 'Access';

  @override
  String get saltoAccess_ready => 'Ready to open';

  @override
  String get saltoAccess_open => 'Open';

  @override
  String get saltoAccess_scanning => 'Searching...';

  @override
  String get saltoAccess_connecting => 'Connecting...';

  @override
  String get saltoAccess_granted => 'Access granted';

  @override
  String get saltoAccess_rejected => 'Access denied';

  @override
  String get saltoAccess_hint =>
      'Approach the turnstile and tap the button below';

  @override
  String get saltoAccess_hintBluetooth =>
      'Make sure Bluetooth is enabled — it\'s required to connect to the turnstile';

  @override
  String get saltoAccess_noKey => 'Key not available';

  @override
  String get saltoAccess_notConfigured =>
      'SALTO access not configured. Contact support.';

  @override
  String get profileMenu_settings => 'Settings';

  @override
  String get profileMenu_myLevel => 'My Level';

  @override
  String get profileMenu_showId => 'Show ID';

  @override
  String get profileMenu_saved => 'Saved';

  @override
  String get profileMenu_statistics => 'Statistics';

  @override
  String get profileMenu_findFriends => 'Find Friends';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_basic => 'Basic';

  @override
  String get settings_myProfile => 'My Profile';

  @override
  String get settings_verification => 'Verification';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_security => 'Security';

  @override
  String get settings_info => 'Information';

  @override
  String get settings_city => 'City';

  @override
  String get settings_appLanguage => 'Application Language';

  @override
  String get settings_interfaceMode => 'Interface Mode';

  @override
  String get settings_aboutApp => 'About App';

  @override
  String get settings_help => 'Help';

  @override
  String get settings_logout => 'Logout';

  @override
  String get settings_logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get settings_light => 'Light';

  @override
  String get settings_dark => 'Dark';

  @override
  String get profile_aboutMe => 'About me';

  @override
  String get profile_addAboutMe => 'Add information about yourself';

  @override
  String get profile_add => 'Add';

  @override
  String get profile_academy => 'Academy';

  @override
  String get profile_activity => 'Activity';

  @override
  String get profile_expand => 'Expand';

  @override
  String get profile_collapse => 'Collapse';

  @override
  String get profile_completionTitle => 'Profile completion';

  @override
  String profile_completionSubtitle(int completed, int total) {
    return '$completed of $total fields completed';
  }

  @override
  String get profile_completed => 'Completed';

  @override
  String get profile_message => 'Message';

  @override
  String get profile_actions => 'Actions';

  @override
  String get profile_bonuses => 'Bonuses';

  @override
  String get profile_tokens => 'Tokens';

  @override
  String get profile_tasks => 'Tasks';

  @override
  String get profile_activityPoints => 'Activity';

  @override
  String get profile_rewards => 'Rewards';

  @override
  String get profile_motivation => 'Motivation';

  @override
  String get profile_statistics => 'Statistics';

  @override
  String get profile_profileViews => 'Profile views';

  @override
  String get profile_numbers => 'Numbers';

  @override
  String get profile_watched => 'Watched';

  @override
  String get profile_searched => 'Searched';

  @override
  String get profile_savedItems => 'Saved';

  @override
  String get profile_subscriptions => 'Subscriptions';

  @override
  String get profile_subscribers => 'Subscribers';

  @override
  String get profile_achievements => 'Rewards';

  @override
  String get profile_allAchievements => 'All rewards';

  @override
  String get statistics_summary => 'Summary';

  @override
  String get statistics_totalViews => 'Total views';

  @override
  String get statistics_interactions => 'Interactions';

  @override
  String get statistics_messagesSent => 'Messages sent';

  @override
  String get statistics_contentShares => 'Content shares';

  @override
  String get resume_workExperience => 'Work Experience';

  @override
  String get resume_addWorkExperience =>
      'Add information about work experience';

  @override
  String get resume_companyName => 'Company name';

  @override
  String get resume_position => 'Position';

  @override
  String get resume_startDate => 'Start date';

  @override
  String get resume_endDate => 'End date';

  @override
  String get resume_present => 'Present';

  @override
  String get resume_description => 'Description';

  @override
  String get resume_skills => 'Skills';

  @override
  String get resume_addSkills => 'Add information about skills';

  @override
  String get resume_education => 'Education';

  @override
  String get resume_addEducation => 'Add education information';

  @override
  String get resume_universityName => 'University name';

  @override
  String get resume_facultyName => 'Faculty name';

  @override
  String get resume_degree => 'Degree';

  @override
  String get resume_degreeBachelor => 'Bachelor\'s degree';

  @override
  String get resume_degreeMaster => 'Master\'s degree';

  @override
  String get resume_degreeDoctoral => 'Doctoral / PhD';

  @override
  String get resume_degreeAssociate => 'Associate degree';

  @override
  String get resume_degreeCertificate => 'Certificate';

  @override
  String get resume_degreeOther => 'Other';

  @override
  String get resume_degreeOtherSpecify => 'Specify degree';

  @override
  String get resume_academySkillsNote =>
      'Skills are listed in the Skills section of your profile — they are shared for your whole profile.';

  @override
  String get resume_educationLoadFailed =>
      'Could not load your education. Check your connection and try again.';

  @override
  String get resume_educationSaveFailed =>
      'Could not save your education. Please try again.';

  @override
  String get resume_educationDeleteFailed =>
      'Could not delete this entry. Please try again.';

  @override
  String get profile_errorNetwork =>
      'Check your internet connection and try again.';

  @override
  String get profile_errorSession => 'Please sign in again to continue.';

  @override
  String get profile_errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get profile_activityPhotoTooLarge =>
      'This photo is too large. Maximum size is 5 MB.';

  @override
  String get profile_activityMaxPhotos =>
      'You can add at most 5 photos per activity.';

  @override
  String get profile_activityPhotoRead =>
      'Could not read the selected photo. Try another image.';

  @override
  String get profile_activitySaveFailed =>
      'Could not save your activity. Please try again.';

  @override
  String get profile_activityDeleteFailed =>
      'Could not delete this activity. Please try again.';

  @override
  String get profile_skillsSaveFailed =>
      'Could not save skills. Please try again.';

  @override
  String get profile_skillsLoadFailed =>
      'Could not load skills. Check your connection and try again.';

  @override
  String get profile_experienceSaveFailed =>
      'Could not save work experience. Please try again.';

  @override
  String get profile_experienceDeleteFailed =>
      'Could not delete this entry. Please try again.';

  @override
  String get profile_experienceLoadFailed =>
      'Could not load work experience. Check your connection and try again.';

  @override
  String get profile_aboutMeSaveFailed => 'Could not save. Please try again.';

  @override
  String get resume_gpa => 'GPA';

  @override
  String get resume_activities => 'Activities';

  @override
  String get resume_addActivities => 'Add information about activities';

  @override
  String get resume_title => 'Resume';

  @override
  String get resume_academyTab => 'Academy';

  @override
  String get resume_activityTab => 'Activity';

  @override
  String get resume_noWorkExperience => 'No work experience added yet';

  @override
  String get resume_noEducation => 'No education added yet';

  @override
  String get resume_noSkills => 'No skills added yet';

  @override
  String get resume_noActivity => 'No activity yet';

  @override
  String get common_add => 'Add';

  @override
  String get common_suggestions => 'Suggestions';

  @override
  String get jobFinder_title => 'Job Finder';

  @override
  String get jobFinder_findDreamJob => 'Find your dream job';

  @override
  String get jobFinder_home => 'Home';

  @override
  String get jobFinder_applications => 'Applications';

  @override
  String get jobFinder_noApplications => 'No applications yet';

  @override
  String get jobFinder_profileComingSoon => 'Profile coming soon';

  @override
  String get jobFinder_recentSearches => 'You previously searched';

  @override
  String get jobFinder_noJobsFound => 'No jobs found';

  @override
  String get jobFinder_jobDetail => 'Job Detail';

  @override
  String get jobFinder_jobDetails => 'Job details';

  @override
  String get jobFinder_aboutCompany => 'About company';

  @override
  String get jobFinder_description => 'Description';

  @override
  String get jobFinder_apply => 'Apply';

  @override
  String get jobFinder_applicationSent => 'Application sent successfully!';

  @override
  String get jobFinder_filters => 'Filters';

  @override
  String get jobFinder_clearAll => 'Clear all';

  @override
  String get jobFinder_location => 'Location';

  @override
  String get jobFinder_enterLocation => 'Enter location';

  @override
  String get jobFinder_jobType => 'Job type';

  @override
  String get jobFinder_salaryRange => 'Salary range';

  @override
  String get jobFinder_experienceLevel => 'Experience level';

  @override
  String get jobFinder_applyFilters => 'Apply filters';

  @override
  String jobFinder_jobsCount(int count) {
    return '$count jobs';
  }

  @override
  String get jobFinder_explore => 'Explore';

  @override
  String get jobFinder_saved => 'Saved';

  @override
  String get jobFinder_noSavedJobs => 'No saved jobs yet';

  @override
  String get jobFinder_savedSubtitle => 'Jobs you save will appear here';

  @override
  String get jobFinder_featuredJobs => 'Featured Jobs';

  @override
  String get jobFinder_promotedJobs => 'Promoted';

  @override
  String get jobFinder_allCategories => 'All Categories';

  @override
  String get jobFinder_all => 'All';

  @override
  String get jobFinder_inProcess => 'In Process';

  @override
  String get jobFinder_accepted => 'Accepted';

  @override
  String get jobFinder_declined => 'Declined';

  @override
  String jobFinder_appliedOn(String date) {
    return 'Applied on $date';
  }

  @override
  String get jobFinder_alreadyApplied => 'Already applied';

  @override
  String get fintech_title => 'Fintech';

  @override
  String get fintech_home => 'Home';

  @override
  String get fintech_payments => 'Payments';

  @override
  String get fintech_wallet => 'Wallet';

  @override
  String get fintech_actions => 'Quick Actions';

  @override
  String get fintech_services => 'Services';

  @override
  String get fintech_viewAll => 'View all';

  @override
  String get fintech_finance => 'Finance';

  @override
  String get fintech_tokens => 'Tokens';

  @override
  String get fintech_nft => 'NFT';

  @override
  String get fintech_discounts => 'Discounts';

  @override
  String get fintech_customization => 'Customization';

  @override
  String get fintech_bonuses => 'Bonuses';

  @override
  String get fintech_analytics => 'Analytics';

  @override
  String get fintech_noCards => 'No cards yet';

  @override
  String get fintech_noTokens => 'No tokens yet';

  @override
  String get fintech_noNfts => 'No NFTs yet';

  @override
  String get fintech_noDiscounts => 'No discounts available';

  @override
  String get fintech_totalBalance => 'Total Balance';

  @override
  String get fintech_preview => 'Preview';

  @override
  String get fintech_selectColor => 'Select Card Color';

  @override
  String get fintech_colorSaved => 'Card color saved!';

  @override
  String get fintech_expiringSoon => 'Expiring soon';

  @override
  String get fintech_transfer => 'Transfer';

  @override
  String get fintech_request => 'Request';

  @override
  String get fintech_inOut => 'In & Out';

  @override
  String get fintech_cards => 'Cards';

  @override
  String get fintech_investing => 'Investing';

  @override
  String get fintech_main => 'Main';

  @override
  String get fintech_addCard => 'Add card';

  @override
  String get fintech_freezeCard => 'Freeze';

  @override
  String get fintech_unfreezeCard => 'Unfreeze';

  @override
  String get fintech_showDetails => 'Show details';

  @override
  String get fintech_cardSettings => 'Settings';

  @override
  String get fintech_transaction => 'Transaction';

  @override
  String get fintech_amount => 'Amount';

  @override
  String get fintech_completed => 'Completed';

  @override
  String get fintech_seeAll => 'See all';

  @override
  String get fintech_getHelp => 'Get help with the card';

  @override
  String get fintech_cardFrozen => 'Card frozen';

  @override
  String get fintech_cardUnfrozen => 'Card unfrozen';

  @override
  String get fintech_labelCard => 'Label card';

  @override
  String get fintech_cardLabel => 'Card label';

  @override
  String get fintech_unblockCvv => 'Unblock CVV';

  @override
  String get fintech_unblockCvvDesc => 'Use after exceeding 3 tries';

  @override
  String get fintech_terminateCard => 'Terminate card';

  @override
  String get fintech_terminateConfirmTitle => 'Terminate card?';

  @override
  String get fintech_terminateConfirmDesc =>
      'This action is irreversible. The card will be permanently terminated and cannot be restored.';

  @override
  String get fintech_terminate => 'Terminate';

  @override
  String get fintech_cancel => 'Cancel';

  @override
  String get fintech_customise => 'Customise';

  @override
  String get fintech_cvv => 'CVV';

  @override
  String get fintech_cvvUnblocked => 'CVV unblocked';

  @override
  String get fintech_authRequired => 'Authentication required';

  @override
  String get fintech_labelSaved => 'Card label saved';

  @override
  String get fintech_cardDesign => 'Card design';

  @override
  String get fintech_designSaved => 'Card design saved';

  @override
  String get fintech_cardTerminated => 'Card terminated';

  @override
  String get fintech_cardLabelHint => 'Enter card label';

  @override
  String get fintech_noTransactions => 'No transactions yet';

  @override
  String get fintech_yourCards => 'Your Cards';

  @override
  String get fintech_spendThisMonth => 'Spend this month';

  @override
  String get fintech_totalWealth => 'Total Wealth';

  @override
  String get fintech_savingsGoals => 'Savings Goals';

  @override
  String get fintech_upcomingPayments => 'Upcoming Payments';

  @override
  String get fintech_recentPayees => 'Recent Payees';

  @override
  String get fintech_transactionHistory => 'Transaction History';

  @override
  String get fintech_ofBudget => 'of budget';

  @override
  String get fintech_today => 'Today';

  @override
  String get fintech_tomorrow => 'Tomorrow';

  @override
  String fintech_inDays(int days) {
    return 'In $days days';
  }

  @override
  String get fintech_cardDetails => 'Card Details';

  @override
  String get fintech_accountDetails => 'Account Details';

  @override
  String get fintech_cardholderName => 'Cardholder Name';

  @override
  String get fintech_cardNumber => 'Card Number';

  @override
  String get fintech_expiryDate => 'Expiry Date';

  @override
  String get fintech_cardType => 'Card Type';

  @override
  String get fintech_currency => 'Currency';

  @override
  String get fintech_copied => 'Copied';

  @override
  String get fintech_share => 'Share';

  @override
  String get fintech_topUp => 'Top up';

  @override
  String get fintech_balance => 'Balance';

  @override
  String get fintech_cardInfo => 'Card Info';

  @override
  String get fintech_limits => 'Card Limits';

  @override
  String get fintech_limitsDesc => 'Daily & monthly spending limits';

  @override
  String get fintech_changePin => 'Change PIN';

  @override
  String get fintech_changePinDesc => 'Set a new PIN code';

  @override
  String get fintech_reissueCard => 'Reissue Card';

  @override
  String get fintech_reissueCardDesc => 'Order a replacement card';

  @override
  String get fintech_closeCard => 'Close Card';

  @override
  String get fintech_closeCardDesc => 'Permanently close this card';

  @override
  String get fintech_blockCard => 'Block Card';

  @override
  String get fintech_cardBlocked => 'Card is blocked';

  @override
  String get fintech_cardActive => 'Card is active';

  @override
  String get fintech_securitySettings => 'Security & Settings';

  @override
  String get fintech_recentTransactions => 'Recent Transactions';

  @override
  String get fintech_stocks => 'Stocks';

  @override
  String get fintech_crypto => 'Crypto';

  @override
  String get fintech_portfolio => 'Portfolio';

  @override
  String get fintech_totalValue => 'Total Value';

  @override
  String get fintech_totalGain => 'Total Gain';

  @override
  String get fintech_holdings => 'Holdings';

  @override
  String get fintech_popular => 'Popular';

  @override
  String get fintech_marketCap => 'Market Cap';

  @override
  String get fintech_noStocks => 'No stocks available';

  @override
  String get fintech_noCrypto => 'No crypto available';

  @override
  String get fintech_buy => 'Buy';

  @override
  String get fintech_sell => 'Sell';

  @override
  String get fintech_avg => 'Avg';

  @override
  String get fintech_qty => 'Qty';

  @override
  String get fintech_closeCardConfirmTitle => 'Close card?';

  @override
  String get fintech_closeCardConfirmDesc =>
      'This card will be permanently closed. Any remaining balance will be transferred to your main account.';

  @override
  String get fintech_close => 'Close';

  @override
  String get fintech_cashback => 'Cashback';

  @override
  String get fintech_cashbackDesc => 'Up to 3% on purchases';

  @override
  String get fintech_addMoney => 'Add money';

  @override
  String get fintech_exchange => 'Exchange';

  @override
  String get fintech_details => 'Details';

  @override
  String get fintech_more => 'More';

  @override
  String get fintech_accounts => 'Accounts';

  @override
  String get fintech_searchHint => 'Search';

  @override
  String get fintech_inviteFriends => 'Invite friends';

  @override
  String get fintech_inviteDesc => 'Get bonus for each friend';

  @override
  String get fintech_widgetsSection => 'Widgets';

  @override
  String get fintech_savings => 'Savings';

  @override
  String get fintech_insurance => 'Insurance';

  @override
  String get fintech_budget => 'Budget';

  @override
  String get fintech_remaining => 'Remaining';

  @override
  String get fintech_categoryBreakdown => 'Category Breakdown';

  @override
  String get fintech_payNow => 'Pay now';

  @override
  String get fintech_schedule => 'Schedule';

  @override
  String get fintech_paid => 'Paid';

  @override
  String get fintech_unpaid => 'Unpaid';

  @override
  String get fintech_sendMoney => 'Send money';

  @override
  String get fintech_enterAmount => 'Enter amount';

  @override
  String get fintech_send => 'Send';

  @override
  String get fintech_lastTransfer => 'Last transfer';

  @override
  String get fintech_income => 'Income';

  @override
  String get fintech_expense => 'Expense';

  @override
  String get fintech_repeat => 'Repeat';

  @override
  String get fintech_wealthBreakdown => 'Account breakdown';

  @override
  String get fintech_manage => 'Manage';

  @override
  String get fintech_history => 'History';

  @override
  String get fintech_status => 'Status';

  @override
  String get fintech_date => 'Date';

  @override
  String get fintech_category => 'Category';

  @override
  String get fintech_trade => 'Trade';

  @override
  String get fintech_withdraw => 'Withdraw';

  @override
  String get fintech_tradingNews => 'Trading News';

  @override
  String get fintech_topMovers => 'Top Movers';

  @override
  String get fintech_marketOverview => 'Market Overview';

  @override
  String get fintech_readMore => 'Read more';

  @override
  String get fintech_bullish => 'Bullish';

  @override
  String get fintech_bearish => 'Bearish';

  @override
  String get fintech_neutral => 'Neutral';

  @override
  String get fintech_yourPortfolio => 'Your Portfolio';

  @override
  String get gamification_myLevel => 'My Level';

  @override
  String get gamification_level => 'Level';

  @override
  String get gamification_levelUp => '🎉 Level Up!';

  @override
  String get gamification_toNextLevel => 'to next level';

  @override
  String get gamification_points => 'Points';

  @override
  String get gamification_ranking => 'Ranking';

  @override
  String get gamification_tasks => 'Tasks';

  @override
  String get gamification_activity => 'Activity';

  @override
  String get gamification_achievements => 'Rewards';

  @override
  String get gamification_motivation => 'Motivation';

  @override
  String get gamification_of => 'of';

  @override
  String get gamification_participants => 'participants';

  @override
  String get gamification_taskCount => 'Task count';

  @override
  String get gamification_noTasks => 'No tasks yet';

  @override
  String get gamification_noPointsHistory => 'No points history';

  @override
  String get gamification_today => 'Today';

  @override
  String get gamification_yesterday => 'Yesterday';

  @override
  String get gamification_earlier => 'Earlier';

  @override
  String get gamification_achievementsEarned => 'rewards earned';

  @override
  String get gamification_noAchievements => 'No rewards yet';

  @override
  String get gamification_goalsCompleted => 'goals completed';

  @override
  String get gamification_yourGoals => 'Your Goals';

  @override
  String get gamification_seeAll => 'See all';

  @override
  String get gamification_noGoals => 'No goals yet';

  @override
  String get gamification_noGoalsDesc =>
      'Create your first goal and start tracking your progress';

  @override
  String get gamification_noActivity => 'No activity yet';

  @override
  String get gamification_week => 'Week';

  @override
  String get gamification_month => 'Month';

  @override
  String get gamification_year => 'Year';

  @override
  String get gamification_expand => 'Expand';

  @override
  String get gamification_collapse => 'Collapse';

  @override
  String get gamification_addActivity => 'Add Activity';

  @override
  String get gamification_activityName => 'Activity name';

  @override
  String get gamification_date => 'Date';

  @override
  String get gamification_description => 'Description';

  @override
  String get gamification_attachPhoto => 'Attach photo';

  @override
  String get gamification_activityPhoto => 'Activity photo';

  @override
  String get gamification_awards => 'Rewards';

  @override
  String get gamification_totalAwards => 'Total Rewards';

  @override
  String get gamification_collected => 'Collected';

  @override
  String get gamification_collection => 'Collection';

  @override
  String get gamification_totalAchievements => 'Total Rewards';

  @override
  String get gamification_averageLevel => 'Average Level';

  @override
  String get gamification_goals => 'Goals';

  @override
  String get gamification_encouragement => 'Encouragement';

  @override
  String get gamification_addGoal => 'Add Goal';

  @override
  String get motivation_goalTitle => 'Goal Title';

  @override
  String get motivation_goalDescription => 'Goal Description';

  @override
  String get motivation_targetValue => 'Target Value';

  @override
  String get motivation_unit => 'Unit (lessons, points, days, etc.)';

  @override
  String get gamification_actions => 'Actions';

  @override
  String get gamification_bonuses => 'Bonuses';

  @override
  String get gamification_tokens => 'Tokens';

  @override
  String get gamification_history => 'History';

  @override
  String get gamification_bonusesInfo =>
      'Bonuses are points that you earn for completing tasks and achievements. They can be used to unlock new features and rewards.';

  @override
  String get gamification_tokensInfo =>
      'Tokens are digital currency that you earn for participating in activities. They can be exchanged for prizes and special offers.';

  @override
  String get gamification_filterAll => 'All';

  @override
  String get gamification_filterDaily => 'Daily';

  @override
  String get gamification_filterWeekly => 'Weekly';

  @override
  String get gamification_filterAchievements => 'Achievements';

  @override
  String get gamification_typeDaily => 'Daily';

  @override
  String get gamification_typeWeekly => 'Weekly';

  @override
  String get gamification_typeAchievement => 'Achievement';

  @override
  String get gamification_typeSpecial => 'Special';

  @override
  String get gamification_typeBonus => 'Bonus';

  @override
  String get gamification_typeToken => 'Token';

  @override
  String get gamification_allTasksCompleted => 'All tasks completed! 🎉';

  @override
  String get gamification_errorLoadingTasks => 'Error loading tasks';

  @override
  String get gamification_completeTasksToEarn =>
      'Complete tasks to earn rewards!';

  @override
  String get gamification_allAchievements => 'All Rewards';

  @override
  String get social_followers => 'Followers';

  @override
  String get social_following => 'Following';

  @override
  String get social_follow => 'Follow';

  @override
  String get social_unfollow => 'Unfollow';

  @override
  String get social_message => 'Message';

  @override
  String get social_rating => 'Rating';

  @override
  String get social_searchFollowers => 'Search followers...';

  @override
  String get social_searchFollowing => 'Search following...';

  @override
  String get social_noFollowers => 'No followers yet';

  @override
  String get social_noFollowing => 'Not following anyone';

  @override
  String get social_nothingFound => 'Nothing found';

  @override
  String get social_findUsers => 'Find interesting users';

  @override
  String get social_unfollowConfirmTitle => 'Unfollow?';

  @override
  String social_unfollowConfirmMessage(Object userName) {
    return 'Are you sure you want to unfollow $userName?';
  }

  @override
  String get social_cancel => 'Cancel';

  @override
  String get social_userNotFound => 'User not found';

  @override
  String get social_back => 'Back';

  @override
  String get social_aboutMe => 'About Me';

  @override
  String get social_workExperience => 'Work Experience';

  @override
  String get social_skills => 'Skills';

  @override
  String get social_academy => 'Academy';

  @override
  String get social_shareProfile => 'Share profile';

  @override
  String get social_copyLink => 'Copy link';

  @override
  String get social_block => 'Block';

  @override
  String get social_messages => 'Messages';

  @override
  String get social_noMessages => 'No messages';

  @override
  String get social_startConversation => 'Start a conversation';

  @override
  String get social_sendFirstMessage => 'Send the first message';

  @override
  String get social_messageHint => 'Message...';

  @override
  String get social_today => 'Today';

  @override
  String get social_yesterday => 'Yesterday';

  @override
  String get social_online => 'Online';

  @override
  String get social_openProfile => 'Open profile';

  @override
  String get social_searchInChat => 'Search in chat';

  @override
  String get social_muteNotifications => 'Mute notifications';

  @override
  String get social_deleteChat => 'Delete chat';

  @override
  String get social_searchUsers => 'Search users';

  @override
  String get social_enterNameOrUsername => 'Enter name or username...';

  @override
  String get social_findUsersTitle => 'Find users';

  @override
  String get social_tryAnotherQuery => 'Try another query';

  @override
  String get social_subscriptions => 'Subscriptions';

  @override
  String get social_present => 'Present';

  @override
  String get web_loading => 'Loading...';

  @override
  String get web_error_title => 'Unable to load page';

  @override
  String get web_error_subtitle =>
      'Please check your internet connection and try again';

  @override
  String get web_retry => 'Retry';

  @override
  String get web_external_link_title => 'Open External Link?';

  @override
  String get web_external_link_message => 'This link will open in your browser';

  @override
  String get web_external_link_open => 'Open';

  @override
  String get web_external_link_cancel => 'Cancel';

  @override
  String get resume_currentlyWorkingHere => 'I am currently working here';

  @override
  String get resume_currentlyStudying => 'I am currently studying';

  @override
  String get resume_selectDate => 'Select date';

  @override
  String get resume_attachPhoto => 'Attach photo';

  @override
  String get resume_activityTitle => 'Activity';

  @override
  String get resume_activityName => 'Name';

  @override
  String get resume_activityDate => 'Date';

  @override
  String get resume_institution => 'Institution';

  @override
  String get resume_degreeWithExample => 'Degree (Bachelor, etc.)';

  @override
  String get resume_specialization => 'Specialization';

  @override
  String get resume_gpaScore => 'GPA Score';

  @override
  String get resume_recommended => 'Recommended';

  @override
  String get points_bonuses => 'Bonuses';

  @override
  String get points_tokens => 'Tokens';

  @override
  String get points_bonusesInfo =>
      'Bonuses - what they are for, how to use them and what you can do with them';

  @override
  String get points_bonusesExchange =>
      'Bonuses can be exchanged for tokens at the rate of 100 Bonuses = 1 token';

  @override
  String get points_tokensInfo =>
      'Tokens - what they are for, how to use them and what you can do with them';

  @override
  String get points_tokensExchange =>
      'Tokens can be exchanged for money or spent inside the app at the rate of 1 token = 100 tenge';

  @override
  String get points_filterBonuses => 'Bonuses';

  @override
  String get points_filterTokens => 'Tokens';

  @override
  String get salto_mobileAccess => 'Mobile Access';

  @override
  String get salto_mobileAccessAlreadyEnabled =>
      'Mobile access is already enabled';

  @override
  String get salto_enableAccessInApp => 'Enable access in the app';

  @override
  String get salto_mobileKeyAlreadyIssued =>
      'A mobile SALTO key has already been issued for this account. Continue setting up the app.';

  @override
  String get salto_switchToMobileKeyDescription =>
      'After confirmation, this account will be switched from the physical card to a mobile SALTO key for turnstile access.';

  @override
  String get salto_physicalCardWarning =>
      'Important: after activation, the physical card will stop working for turnstile access.';

  @override
  String get salto_activateInApp => 'Activate in the app';

  @override
  String get salto_skipForNow => 'Skip for now';

  @override
  String get salto_switchAccessConfirmTitle => 'Switch access to the phone?';

  @override
  String get salto_switchAccessConfirmDescription =>
      'The physical card will be disabled for turnstile access. After that, access will work only through the app.';

  @override
  String get salto_yesSwitch => 'Yes, switch';

  @override
  String get editProfile_avatarUpdated => 'Profile photo updated';

  @override
  String get editProfile_usernameFormatHint =>
      'Username must be 3-30 chars and use only lowercase letters, digits, and _';

  @override
  String get editProfile_avatarUpdateFailed => 'Failed to update profile photo';

  @override
  String get hub_attendance => 'Attendance';

  @override
  String get hub_attendanceStudent => 'Student';

  @override
  String get hub_attendanceTeacher => 'Teacher';

  @override
  String get hub_classroom => 'Classroom';

  @override
  String get tasks_special => 'Special';

  @override
  String get tasks_daily => 'Daily Tasks';

  @override
  String get tasks_weekly => 'Weekly Tasks';

  @override
  String get tasks_achievements => 'Rewards';

  @override
  String get tasks_claim => 'Claim';

  @override
  String get tasks_inProgress => 'In Progress';

  @override
  String get tasks_completed => 'Completed';

  @override
  String get tasks_toNextLevel => 'to next level';

  @override
  String get cancel => 'Cancel';

  @override
  String get pin_createTitle => 'Create PIN code';

  @override
  String get pin_confirmTitle => 'Confirm PIN code';

  @override
  String get pin_createSubtitle => 'Create a 4-digit PIN for quick access';

  @override
  String get pin_confirmSubtitle => 'Re-enter the PIN code';

  @override
  String get pin_mismatchError => 'PIN codes do not match';

  @override
  String get pin_enterTitle => 'Enter PIN code';

  @override
  String get pin_enterSubtitle => 'Enter your PIN to continue';

  @override
  String get pin_biometricReason => 'Verify your identity';

  @override
  String pin_lockedMessage(int seconds) {
    return 'Too many attempts. Try again in $seconds sec';
  }

  @override
  String get pin_incorrectError => 'Incorrect PIN';

  @override
  String get pin_switchAccount => 'Switch account';

  @override
  String get pin_biometricUnavailable =>
      'Biometric is unavailable. Please enable it in your device settings.';

  @override
  String get pin_sessionRefreshFailed =>
      'Could not refresh your session. Check your internet and try again.';

  @override
  String get pin_sessionExpired =>
      'Session expired. Please sign in again with your credentials.';

  @override
  String get pin_signingIn => 'Signing in...';

  @override
  String get biometric_setupTitle => 'Quick access';

  @override
  String get biometric_setupDescription =>
      'Enable Face ID or Fingerprint for faster login without entering a PIN code';

  @override
  String get biometric_setupReason =>
      'Verify your identity to enable biometric login';

  @override
  String get biometric_setupEnable => 'Enable';

  @override
  String get biometric_setupSkip => 'Skip';

  @override
  String get svc_title => 'Meal Pass';

  @override
  String get svc_weeklyProgress => 'Weekly Progress';

  @override
  String get svc_mealsUsed => 'meals used';

  @override
  String get svc_remaining => 'remaining';

  @override
  String get svc_todayUsage => 'Today\'s Usage';

  @override
  String get svc_todayMenu => 'Today\'s Menu';

  @override
  String get svc_scanQr => 'Scan QR to Get Meal';

  @override
  String get svc_limitReached => 'Limit Reached';

  @override
  String get svc_statusActive => 'Active';

  @override
  String get svc_accessDenied => 'Access Denied';

  @override
  String get svc_accessDeniedHint =>
      'You don\'t have access to Meal Pass. Contact administration for details.';

  @override
  String get svc_mealRedeemed => 'Meal redeemed successfully!';

  @override
  String get svc_pointCamera => 'Point camera at QR code';

  @override
  String get svc_cameraPermissionDenied =>
      'Camera permission is required to scan QR codes';

  @override
  String get svc_daysUsed => 'Days used';

  @override
  String get svc_analyticsTitle => 'Meal Pass Analytics';

  @override
  String get svc_totalRegistered => 'Registered Students';

  @override
  String get svc_totalActiveUsers => 'Active Users';

  @override
  String get svc_totalMeals => 'Total Meals';

  @override
  String get svc_totalSpent => 'Total Spent';

  @override
  String get svc_mealsBreakdown => 'Meals Breakdown';

  @override
  String get svc_spendingOverTime => 'Spending Over Time';

  @override
  String get svc_transactions => 'Transactions';

  @override
  String get svc_student => 'Student';

  @override
  String get svc_meal => 'Meal';

  @override
  String get svc_category => 'Category';

  @override
  String get svc_price => 'Price';

  @override
  String get svc_date => 'Date';

  @override
  String get svc_breakfast => 'Breakfast';

  @override
  String get svc_lunch => 'Lunch';

  @override
  String get svc_dinner => 'Dinner';

  @override
  String get svc_dailyCheck => 'Daily check';

  @override
  String get svc_mealSlots => 'Meal Slots';

  @override
  String get svc_skippedReminder => 'Skipped';

  @override
  String get svc_noActiveSlot => 'No Active Slot';

  @override
  String get svc_slotAlreadyRedeemed => 'Slot Already Redeemed';

  @override
  String get svc_fixedMenu => 'Fixed Menu';

  @override
  String get svc_availableMeals => 'Available Meals';

  @override
  String get svc_selectMeal => 'Select Meal';

  @override
  String get svc_categoryDistribution => 'Category Distribution';

  @override
  String get svc_exportPdf => 'Export PDF';

  @override
  String get svc_avgPerStudent => 'Avg per Student';

  @override
  String get svc_participationRate => 'Participation Rate';

  @override
  String get svc_analyticsReport => 'Meal Pass Analytics Report';

  @override
  String get svc_dailySpending => 'Daily Spending';

  @override
  String get svc_spendingPerStudent => 'Spending per Student';

  @override
  String get svc_participation => 'Participation';

  @override
  String get svc_studentId => 'Student ID';

  @override
  String get svc_inactive => 'Inactive';

  @override
  String get svc_meals => 'meals';

  @override
  String get svc_avg => 'avg';

  @override
  String get svc_total => 'Total';

  @override
  String get svc_showMore => 'Show More';

  @override
  String get svc_allTransactionsShown => 'All transactions shown';

  @override
  String get svc_mealReceipt => 'Meal Receipt';

  @override
  String get svc_time => 'Time';

  @override
  String get svc_close => 'Close';

  @override
  String get svc_name => 'Name';

  @override
  String get svc_combo => 'Combo';

  @override
  String get svc_mon => 'Mon';

  @override
  String get svc_tue => 'Tue';

  @override
  String get svc_wed => 'Wed';

  @override
  String get svc_thu => 'Thu';

  @override
  String get svc_fri => 'Fri';

  @override
  String get svc_sat => 'Sat';

  @override
  String get svc_sun => 'Sun';

  @override
  String get svc_faq => 'FAQ';

  @override
  String get svc_faqHowToUse => 'How to use Meal Pass?';

  @override
  String get svc_faqHowToUseContent =>
      '1. Go to the dining hall during meal hours\n2. Open the app and tap \"Scan QR\"\n3. Point your camera at the QR code\n4. Wait for confirmation\n5. Enjoy your meal!';

  @override
  String get svc_faqTimeSlots => 'Meal time slots';

  @override
  String get svc_faqTimeSlotsContent =>
      'Breakfast: 08:00 – 12:00\nLunch: 12:00 – 17:00\nDinner: 17:00 – 00:00';

  @override
  String get svc_mealReminders => 'Meal Reminders';

  @override
  String get svc_reminderDescription =>
      'Get notified before each meal so you don\'t forget';

  @override
  String get svc_reminderBreakfast => 'Breakfast reminder';

  @override
  String get svc_reminderLunch => 'Lunch reminder';

  @override
  String get svc_reminderDinner => 'Dinner reminder';

  @override
  String svc_meal_reminder_open(String mealName) {
    return '$mealName is ready — don\'t forget to grab it!';
  }

  @override
  String svc_meal_reminder_closing(String mealName) {
    return 'Only 30 minutes left to get your $mealName — don\'t miss it!';
  }

  @override
  String get svc_successTitle => 'Meal Redeemed!';

  @override
  String get svc_successSubtitle =>
      'Your meal has been successfully redeemed. Enjoy!';

  @override
  String get svc_backToDashboard => 'Back to Dashboard';

  @override
  String get svc_weeklyUsage => 'Weekly Meal Usage';

  @override
  String get svc_weeklyLimitWarning =>
      'Weekly limit reached. No more meals can be confirmed.';

  @override
  String get svc_tomorrowConfirmation => 'Meal Confirmation for Tomorrow';

  @override
  String get svc_confirmationCutoff => 'Confirmation closes at 23:59 today';

  @override
  String get svc_confirmationDeadlinePassed =>
      'Deadline passed — confirmation closed after 23:59';

  @override
  String get svc_confirmSubmit => 'Save Confirmation';

  @override
  String get svc_confirmSaved => 'Meal confirmation saved!';

  @override
  String get svc_confirmSavedBadge => 'Saved';

  @override
  String get svc_missedMealComp => 'Missed Meal Compensation';

  @override
  String get svc_missedMealCompSubtitle =>
      'Submit a medical certificate for meals missed due to illness';

  @override
  String get svc_examMealComp => 'Exam Meal Compensation';

  @override
  String get svc_examMealCompSubtitle =>
      'Submit exam proof for meals missed during exams. Receive extra dinner instead.';

  @override
  String get svc_submitRequest => 'Submit';

  @override
  String get svc_submitCompRequest => 'Submit Compensation Request';

  @override
  String get svc_mealDate => 'Date of missed meal';

  @override
  String get svc_mealType => 'Meal type';

  @override
  String get svc_examDate => 'Exam date';

  @override
  String get svc_missedMeal => 'Missed meal';

  @override
  String get svc_uploadDocument => 'Upload Document';

  @override
  String get svc_documentAttached => 'Document attached';

  @override
  String get svc_requestSubmitted => 'Request submitted successfully';

  @override
  String get svc_requestHistory => 'My Requests';

  @override
  String get svc_noRequestsYet => 'No requests submitted yet';

  @override
  String get svc_statusPending => 'Pending';

  @override
  String get svc_statusApproved => 'Approved';

  @override
  String get svc_statusRejected => 'Rejected';

  @override
  String get svc_reqTypeMedical => 'Medical Absence';

  @override
  String get svc_reqTypeExam => 'Exam Conflict';

  @override
  String get svc_tomorrowStats => 'Tomorrow Meal Statistics';

  @override
  String get svc_compensationRequests => 'Compensation Requests';

  @override
  String get svc_noCompRequests => 'No compensation requests';

  @override
  String get svc_approve => 'Approve';

  @override
  String get svc_reject => 'Reject';

  @override
  String get svc_approveSuccess => 'Request approved';

  @override
  String get svc_rejectSuccess => 'Request rejected';

  @override
  String get tutorials_title => 'Tutorials';

  @override
  String get tutorials_empty => 'No tutorials available';

  @override
  String get tutorials_steps => 'steps';

  @override
  String get tutorials_stepsHeader => 'Steps';

  @override
  String get tutorials_guide => 'Guide';

  @override
  String get settings_tutorials => 'Tutorials';

  @override
  String get svc_faqHowToApply => 'How to make applications?';

  @override
  String get svc_faqHowToApplyContent =>
      '1. Click on the appropriate compensation request button.\n2. Select the meal date and type.\n3. Make sure to attach the necessary document (medical certificate or exam schedule).\n4. Wait for approval from the administration.';

  @override
  String get svc_faqHowToChange => 'Can I change my request?';

  @override
  String get svc_faqHowToChangeContent =>
      'Currently, applications cannot be changed after submission. Please carefully review the date, meal type, and attached documents before submitting. If you made a mistake, please contact support.';

  @override
  String get svc_notifyBefore => 'Notify before meal';

  @override
  String get svc_time15m => '15 min';

  @override
  String get svc_time30m => '30 min';

  @override
  String get svc_time45m => '45 min';

  @override
  String get svc_time60m => '1 hour';

  @override
  String get svc_debugEnableQr => 'DEBUG: Enable QR (Bypass Slot)';

  @override
  String get svc_debugEnableQrDesc => 'Allow scanning outside meal hours';

  @override
  String get svc_debugCloseMode => 'DEBUG: Close Mode';

  @override
  String get svc_debugCloseModeDesc => 'Simulate the 20:00 cutoff';

  @override
  String get svc_goGetMeal => 'Go get your meal!';

  @override
  String get svc_noConfirmations => 'No confirmations for tomorrow';

  @override
  String get svc_mealsConfirmed => 'Meals Confirmed';

  @override
  String get svc_mealsConfirmedStatus => 'Status';

  @override
  String get svc_none => 'None';

  @override
  String get svc_monthlyUsage => 'Monthly Quota';

  @override
  String get svc_mealsPerMonth => 'meals/month';

  @override
  String get svc_quota => 'Quota';

  @override
  String get svc_monthlyLimitReached => 'Monthly quota reached';

  @override
  String get svc_monthInfo => 'Month Information';

  @override
  String get svc_currentMonth => 'Current Month';

  @override
  String get svc_daysElapsed => 'Days Elapsed';

  @override
  String get svc_avgPerDay => 'Avg per Day';

  @override
  String get svc_used => 'Used';

  @override
  String get svc_redeemedMeals => 'Redeemed Meals';

  @override
  String get svc_tomorrowConfirmationInfo =>
      'Confirm the meals you want tomorrow from the canteen';

  @override
  String get gamification_goalCreated => 'Goal created successfully!';

  @override
  String get sos_title => 'SOS';

  @override
  String get sos_subtitle => 'Emergency Contacts';

  @override
  String get sos_emergencyActions => 'Emergency Calls';

  @override
  String get sos_callPolice => 'Police';

  @override
  String get sos_callAmbulance => 'Ambulance';

  @override
  String get sos_callFire => 'Fire Service';

  @override
  String get sos_callEmergency => 'Emergency';

  @override
  String get sos_dialerUnavailable => 'No phone app found';

  @override
  String get hub_sos => 'SOS';

  @override
  String get bottomNav_notifications => 'Notifications';

  @override
  String get settings_privacyPolicy => 'Privacy Policy';

  @override
  String get social_chat => 'Chat';

  @override
  String get editPhone_description => 'Enter your Kazakhstan phone number';

  @override
  String get editPhone_invalidFormat => 'Invalid phone number format';

  @override
  String get notifications_filterAll => 'All';

  @override
  String get notifications_filterUnread => 'Unread';

  @override
  String get notifications_allCaughtUp => 'You\'re all caught up!';

  @override
  String get notifications_noUnread => 'No unread notifications';

  @override
  String get notifications_openScreen => 'Open';

  @override
  String get notifications_pushPaused => 'Push notifications are paused';

  @override
  String get notifications_sectionMeals => 'Meal Notifications';

  @override
  String get notifications_svcNotMember => 'You are not a member of Meal Pass';

  @override
  String get notifications_svcSubtitle => 'Meal balance and menu updates';

  @override
  String get notifications_settingsFootnote =>
      'Notification settings apply to push notifications. You can change these at any time.';

  @override
  String get notif_action_viewClub => 'View Club';

  @override
  String get notif_action_showQr => 'Show QR';

  @override
  String get notif_action_openWorkout => 'Open Workout';

  @override
  String get notif_action_openChat => 'Open Chat';

  @override
  String get notif_action_openWallet => 'Open Wallet';

  @override
  String get notif_action_viewSchedule => 'View Schedule';

  @override
  String get notif_action_findJob => 'Find Job';

  @override
  String get notif_action_openAccess => 'Open Access';

  @override
  String get notif_action_readMore => 'Read More';

  @override
  String get tasks_gettingStarted => 'Getting Started';

  @override
  String get tasks_yourProgress => 'Your Progress';

  @override
  String get tasks_allDone => 'All Tasks Done!';

  @override
  String get tasks_allDoneDesc =>
      'You\'ve completed all available tasks. Keep up the great work!';

  @override
  String get svc_greetingMorning => 'Good morning';

  @override
  String get svc_greetingAfternoon => 'Good afternoon';

  @override
  String get svc_greetingEvening => 'Good evening';

  @override
  String get svc_greetingSubtitle => 'Here\'s your meal plan for today';

  @override
  String get svc_mealDashboard => 'Meal Dashboard';

  @override
  String get svc_mealLeaderboard => 'Meal Leaderboard';

  @override
  String get svc_viewLeaderboard => 'View all rankings';

  @override
  String get svc_mealHistory => 'Meal History';

  @override
  String get svc_viewHistory => 'View your past meals';

  @override
  String get svc_today => 'Today';

  @override
  String get svc_yesterday => 'Yesterday';

  @override
  String get svc_noMealsOnDay => 'No meals scheduled';

  @override
  String get svc_skip => 'Skip';

  @override
  String get svc_going => 'Going';

  @override
  String get svc_calendarTitle => 'Meal Calendar';

  @override
  String get svc_todayMeals => 'Today\'s Meals';

  @override
  String get svc_statusLegend => 'Status Legend';

  @override
  String get svc_statusScheduled => 'Scheduled';

  @override
  String get svc_statusScheduledDesc => 'Meal is booked for this day';

  @override
  String get svc_statusReceived => 'Received';

  @override
  String get svc_statusReceivedDesc => 'Meal was collected';

  @override
  String get svc_statusCancelled => 'Cancelled';

  @override
  String get svc_statusSkippedDesc => 'Meal was cancelled or skipped';

  @override
  String get svc_statusNoShow => 'No Show';

  @override
  String get svc_statusNoShowDesc => 'Meal was not collected';

  @override
  String get svc_mealStreak => 'Meal Streak';

  @override
  String get svc_mealPass => 'Meal Pass';

  @override
  String get svc_currentStreak => 'Current Streak';

  @override
  String get svc_bestStreak => 'Best Streak';

  @override
  String get svc_noStreakYet => 'No streak yet';

  @override
  String get svc_startStreak =>
      'Start your streak by collecting meals every day!';

  @override
  String svc_streakDays(Object count) {
    return '$count days';
  }

  @override
  String svc_nextMilestone(Object days) {
    return '$days more days to next badge';
  }

  @override
  String get svc_badges => 'Badges';

  @override
  String svc_streakRequired(Object days) {
    return '$days-day streak required';
  }

  @override
  String get svc_totalReceived => 'Total Received';

  @override
  String get svc_totalCancelled => 'Total Cancelled';

  @override
  String get svc_noShows => 'No Shows';

  @override
  String get svc_goToMealPass => 'Go to Meal Pass';

  @override
  String get svc_noShowInfo =>
      'Missing meals without cancelling counts as a no-show and may affect your standing';

  @override
  String get svc_faqCancelQ => 'How do I cancel a meal?';

  @override
  String get svc_faqCancelA =>
      'Open the meal calendar, tap on a scheduled meal, and choose Cancel. You can cancel up to 2 hours before the meal time.';

  @override
  String get svc_faqNoShowQ => 'What happens if I don\'t show up?';

  @override
  String get svc_faqNoShowA =>
      'If you miss a meal without cancelling it will be marked as a no-show. Frequent no-shows may affect your meal program access.';

  @override
  String get svc_faqStreakQ => 'What is a meal streak?';

  @override
  String get svc_faqStreakA =>
      'A streak is the number of consecutive days you collected your meal. Longer streaks unlock badges and rewards.';

  @override
  String get svc_faqQrQ => 'How do I use the QR code?';

  @override
  String get svc_faqQrA =>
      'Open the app and tap \"Scan QR\", then point your camera at the QR code displayed at the canteen. Wait for the confirmation screen — your meal will be recorded automatically.';

  @override
  String get svc_faqDeadlineQ => 'What is the cancellation deadline?';

  @override
  String get svc_faqDeadlineA =>
      'You can cancel your meal up to 2 hours before the scheduled meal time. After that, cancellation is locked.';

  @override
  String get svc_faqUndoQ => 'Can I undo a cancellation?';

  @override
  String get svc_faqUndoA =>
      'Yes! If the cancellation window hasn\'t closed yet, you can undo your cancellation from the meal calendar.';

  @override
  String get svc_cancelMeal => 'Cancel Meal';

  @override
  String get svc_keepMeal => 'Keep Meal';

  @override
  String get svc_cancelConfirm => 'Confirm Cancellation';

  @override
  String get svc_cancelMealDescription =>
      'Cancelling your meal will free up the slot. You can undo this before the deadline.';

  @override
  String get svc_cancelDeadlineLabel => 'Cancellation Deadline';

  @override
  String get svc_honestCancelInfo =>
      'Cancelling honestly helps others get meals';

  @override
  String get svc_cancelWindowClosed => 'Cancellation Unavailable';

  @override
  String get svc_cancelWindowClosedDesc =>
      'The cancellation window for this meal has closed. Please show up or it will be recorded as a no-show.';

  @override
  String get svc_cancelSuccess => 'Meal cancelled successfully';

  @override
  String get svc_undoCancellation => 'Undo Cancellation';

  @override
  String get svc_undoCancelSuccess => 'Cancellation undone';

  @override
  String get svc_scanToReceive => 'Scan to Receive Your Meal';

  @override
  String get svc_pointCameraAtQr => 'Point camera at QR code';

  @override
  String get svc_processing => 'Processing...';

  @override
  String get svc_invalidQr => 'Invalid QR code';

  @override
  String get svc_qrScanGenericError =>
      'Failed to scan QR code. Please try again.';

  @override
  String get svc_scanAgain => 'Scan Again';

  @override
  String get svc_openSettings => 'Open Settings';

  @override
  String get svc_remainingTodayLabel => 'Remaining Today';

  @override
  String get svc_visitLabel => 'Visit';

  @override
  String get svc_studentLabel => 'Student';

  @override
  String get svc_yourRank => 'Your Rank';

  @override
  String get svc_you => 'You';

  @override
  String get svc_leaderboardEmpty => 'No leaderboard data yet';

  @override
  String get svc_couldNotLoad => 'Could not load data';

  @override
  String get svc_noHistoryYet => 'No meal history yet';

  @override
  String get svc_historyEmpty =>
      'Start collecting meals to see your history here';

  @override
  String get svc_historyComplete => 'You\'ve reached the end';

  @override
  String get svc_loadingMore => 'Loading more...';

  @override
  String get wordle_title => 'Wordle';

  @override
  String get wordle_subtitle => 'Guess today\'s 5-letter word';

  @override
  String get wordle_play => 'Play';

  @override
  String get wordle_youWon => 'Brilliant!';

  @override
  String get wordle_youLost => 'Better luck tomorrow!';

  @override
  String get wordle_playAgainTomorrow => 'Come back tomorrow for a new puzzle.';

  @override
  String get wordle_invalidWord => 'Not in word list';

  @override
  String get wordle_tooShort => 'Not enough letters';

  @override
  String get wordle_networkError => 'Unable to load. Try again later.';

  @override
  String get wordle_streak => 'Streak';

  @override
  String get wordle_bestStreak => 'Best';

  @override
  String get wordle_totalGames => 'Played';

  @override
  String get wordle_winRate => 'Win %';

  @override
  String get wordle_statistics => 'Statistics';

  @override
  String get wordle_history => 'History';

  @override
  String get wordle_noHistory => 'No games played yet';

  @override
  String get wordle_failed => 'Not solved';

  @override
  String get wordle_reminderTitle => 'Daily Reminder';

  @override
  String get wordle_reminderSubtitle => 'Get notified when puzzle is ready';

  @override
  String get wordle_reminderTime => 'Reminder Time';

  @override
  String get wordle_reminderInfo =>
      'The reminder appears when you open the app after the set time.';

  @override
  String get wordle_reminderEnabled => 'Enabled';

  @override
  String get wordle_notifTitle => 'Wordle is ready!';

  @override
  String get wordle_notifBody => 'Today\'s puzzle is waiting for you.';

  @override
  String get wordle_viewStats => 'Statistics';

  @override
  String get wordle_alreadyPlayed => 'Already played today';

  @override
  String wordle_solvedIn(Object attempts) {
    return 'Solved in $attempts attempt(s)';
  }

  @override
  String get settings_community => 'Community';

  @override
  String get settings_shareJasWallet => 'Share Jas Wallet';

  @override
  String get settings_inviteEarn => 'Referral';

  @override
  String get settings_rateJasWallet => 'Rate Jas Wallet';

  @override
  String get share_title => 'Share Jas Wallet';

  @override
  String get share_subtitle => 'Help your friends discover Jas Wallet';

  @override
  String get share_shareApp => 'Share App';

  @override
  String get share_shareAppSubtitle =>
      'Send via WhatsApp, Telegram, and other social media';

  @override
  String get share_copyLink => 'Copy App Link';

  @override
  String get share_copyLinkSubtitle => 'Copy the download link to clipboard';

  @override
  String get share_openStore => 'Open Store Page';

  @override
  String get share_openStoreSubtitle =>
      'View Jas Wallet on the App Store or Play Store';

  @override
  String get share_linkCopied => 'Link copied!';

  @override
  String get share_storeUnavailable => 'Store page is not yet available';

  @override
  String get referral_title => 'Referral';

  @override
  String get referral_subtitle => 'Invite friends and unlock achievements';

  @override
  String get referral_yourCode => 'Your Referral Code';

  @override
  String get referral_invitedFriends => 'Invited Friends';

  @override
  String get referral_badgesEarned => 'Badges Earned';

  @override
  String get referral_copyCode => 'Copy Code';

  @override
  String get referral_shareInvite => 'Share';

  @override
  String get referral_codeCopied => 'Referral code copied!';

  @override
  String get referral_yourProgress => 'Your Progress';

  @override
  String referral_currentLevel(String name) {
    return 'Level: $name';
  }

  @override
  String get referral_noLevelYet =>
      'Invite your first friend to unlock a badge';

  @override
  String get referral_invites => 'invite(s)';

  @override
  String referral_nextMilestone(String name, int count) {
    return 'Next: $name ($count invites)';
  }

  @override
  String referral_invitesNeeded(int count) {
    return '$count more invite(s) to go';
  }

  @override
  String get referral_rewardRoadmap => 'Achievement Roadmap';

  @override
  String get referral_leaderboardTitle => 'Top Referrers';

  @override
  String get rateApp_thanks => 'Thanks! Your feedback helps us improve.';

  @override
  String get rateApp_error => 'Could not open review dialog';

  @override
  String get appUpdate_title => 'Update Available';

  @override
  String get appUpdate_optionalMessage =>
      'A new version of Jas Wallet is available with new features and improvements.';

  @override
  String get appUpdate_requiredTitle => 'Update Required';

  @override
  String get appUpdate_requiredMessage =>
      'Please update Jas Wallet to continue. This version is no longer supported.';

  @override
  String get appUpdate_updateButton => 'Update';

  @override
  String get appUpdate_laterButton => 'Later';

  @override
  String get events_nuTitle => 'NU Events';

  @override
  String get events_aboutSection => 'About the event';

  @override
  String get events_organizerSection => 'Organizer';

  @override
  String get events_openInBrowser => 'Open in browser';

  @override
  String get widgets_alwaysVisible => 'Always visible';

  @override
  String get security_fingerprintSubtitle => 'Use your fingerprint to unlock';

  @override
  String get security_faceIdSubtitle => 'Use Face ID to unlock';

  @override
  String get security_authenticationSection => 'Authentication';

  @override
  String get help_subtitle => 'How can we help you today?';

  @override
  String get help_telegramTitle => 'Telegram Group';

  @override
  String get help_telegramSubtitle => 'Write your question in the group';

  @override
  String get help_telegramOpenFailed => 'Could not open Telegram link';

  @override
  String get help_emailSubject => 'Jas Wallet Support';

  @override
  String help_emailSendFailed(String email) {
    return 'Could not send email to $email';
  }

  @override
  String get help_chatGreeting => 'Hello! How can we help you today?';

  @override
  String get help_chatMessageHint => 'Type your message...';

  @override
  String get help_chatAutoReply =>
      'Thank you for your message! Our support team will respond shortly.';

  @override
  String tasks_progressCompleted(int completed, int total) {
    return '$completed of $total tasks completed';
  }

  @override
  String tasks_progressAvailable(int count) {
    return '$count tasks available';
  }

  @override
  String get gamification_rewardsCollected => 'rewards collected';

  @override
  String gamification_percentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get common_now => 'now';

  @override
  String common_routeNotFound(String route) {
    return 'Route not found: $route';
  }

  @override
  String get notifications_silentModeDesc =>
      'Notifications saved silently (no banners)';

  @override
  String get notifications_categoryDisabled =>
      'This category is disabled in notification settings.';

  @override
  String get settings_privacyPolicyOpenFailed =>
      'Could not open privacy policy';

  @override
  String get about_storeOpenFailed => 'Could not open store';

  @override
  String get about_developedBy => 'Developed by the JASAIM team';

  @override
  String get about_supportedBy => 'Supported by NU Impact Foundation';

  @override
  String get editProfile_dateFormatInvalid => 'Enter date as DD.MM.YYYY';

  @override
  String get editProfile_dateFormatHint => 'DD.MM.YYYY';

  @override
  String get editProfile_phoneHint => '+7 XXX XXX XX XX';

  @override
  String get auth_emailExample => 'example@nu.edu.kz';

  @override
  String get motivation_goalTitleHint => 'e.g., Complete 50 lessons';

  @override
  String get motivation_goalDescriptionHint => 'What is your goal?';

  @override
  String get motivation_unitHint => 'e.g., lessons, points, days';

  @override
  String get motivation_goalDone => 'Done! ✓';

  @override
  String hub_noSearchResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get sos_callButton => 'CALL';

  @override
  String get svc_mealDateLabel => 'Meal Date:';

  @override
  String get svc_mealTypeLabel => 'Type:';

  @override
  String get language_nameKazakh => 'Қазақша';

  @override
  String get language_nameRussian => 'Русский';

  @override
  String get language_nameEnglish => 'English';

  @override
  String get referral_enterCodeTitle => 'Have a Referral Code?';

  @override
  String get referral_enterCodeDesc =>
      'Enter a friend\'s referral code. They\'ll earn rewards when you join — completely optional.';

  @override
  String get referral_codeFieldHint => 'Enter referral code';

  @override
  String get referral_applyCode => 'Apply Code';

  @override
  String get referral_skipStep => 'Skip';

  @override
  String get referral_codeApplied => 'Referral code saved!';

  @override
  String get referral_invalidCodeFormat =>
      'Code must be 3–10 letters or digits';

  @override
  String get tutorial_svcMeal_slide1_title => 'Your Meals, Covered';

  @override
  String get tutorial_svcMeal_slide1_body =>
      'NU Impact Foundation credits your account with meal allowances. Enjoy campus food — fully or partially covered.';

  @override
  String get tutorial_svcMeal_slide2_title => 'Scan and Pay';

  @override
  String get tutorial_svcMeal_slide2_body =>
      'Show your QR code at the cafeteria counter to redeem your meal allowance. Fast, contactless, cashless.';

  @override
  String get tutorial_svcMeal_slide3_title => 'Build Your Streak';

  @override
  String get tutorial_svcMeal_slide3_body =>
      'Eat consistently every day and climb the leaderboard. Earn badges, fire streaks, and compete with the whole campus.';

  @override
  String get tutorial_salto_slide1_title => 'Say Goodbye to Physical Cards';

  @override
  String get tutorial_salto_slide1_body =>
      'No more digging for your access card. Your smartphone replaces every plastic campus card.';

  @override
  String get tutorial_salto_slide2_title => 'Tap to Unlock';

  @override
  String get tutorial_salto_slide2_body =>
      'Hold your phone near any Salto lock. One tap over Bluetooth — and you\'re in.';

  @override
  String get tutorial_salto_slide3_title => 'Make It Yours';

  @override
  String get tutorial_salto_slide3_body =>
      'Choose from multiple student card designs. Personalize your digital ID to match your style.';

  @override
  String get tutorial_referral_slide1_title => 'Invite Friends';

  @override
  String get tutorial_referral_slide1_body =>
      'Share your unique referral code with classmates. You both earn rewards when they join Jas Wallet.';

  @override
  String get tutorial_referral_slide2_title => 'Share Your Code';

  @override
  String get tutorial_referral_slide2_body =>
      'Copy your referral link and send it to friends via any app. They sign up, you both get rewarded instantly.';

  @override
  String get tutorial_referral_slide3_title => 'Climb the Leaderboard';

  @override
  String get tutorial_referral_slide3_body =>
      'See how you rank against other inviters. Compete for the top spot and show off your network.';

  @override
  String get tutorial_profile_slide1_title => 'Your Digital Identity';

  @override
  String get tutorial_profile_slide1_body =>
      'One card connects your campus life — meals, building access, referrals, and more, all in a single digital profile.';

  @override
  String get tutorial_profile_slide2_title => 'Showcase Yourself';

  @override
  String get tutorial_profile_slide2_body =>
      'Build your campus presence with a profile that shows your achievements, activity, and student life highlights.';

  @override
  String get tutorial_profile_slide3_title => 'Complete Your Profile';

  @override
  String get tutorial_profile_slide3_body =>
      'The more you fill in, the more you unlock. A complete profile gives you full access to everything Jas Wallet offers.';

  @override
  String get contest_title => 'Contest';

  @override
  String get referral_contestDeadline => 'Contest ends September 10, 2026';

  @override
  String get contest_headline => 'Win Up to\n₸100,000';

  @override
  String get contest_intro =>
      'Three competitions. One deadline. Real prizes — winners announced by the BFLAB team on September 10, 2026.';

  @override
  String get contest_card1Title => 'Top 3 Referrers';

  @override
  String get contest_card1Desc => 'Invite the most friends to Jas Wallet.';

  @override
  String get contest_card2Title => 'Best Instagram Reel';

  @override
  String get contest_card2Desc =>
      'Create a Reel about Jas Wallet or your campus life highlights. Tag @blockchain.fintech.lab and @nu_impact_foundation when you post.';

  @override
  String get contest_card3Title => 'Most Creative Profile';

  @override
  String get contest_card3Desc =>
      'Design the most creative profile on Jas Wallet — make your ID stand out and fill your profile completely. The whole profile matters, not just the ID.';

  @override
  String get contest_card3Note =>
      'Submit your profile in a DM to @blockchain.fintech.lab on Instagram.';

  @override
  String get contest_mandatoryLabel => 'Required for all contests';

  @override
  String get contest_mandatoryDesc =>
      'Every entry must tag @blockchain.fintech.lab and @nu_impact_foundation. Entries without the tag will not be considered.';

  @override
  String get contest_announcement => 'Winners announced\nSeptember 10, 2026.';

  @override
  String get contest_legalPrefix =>
      'By participating in this contest, you automatically agree to the ';

  @override
  String get contest_legalLink => 'Contest Rules and Terms';

  @override
  String get referral_inviteFriends => 'Invite Friends';

  @override
  String get referral_howItWorksTitle => 'How It Works';

  @override
  String get referral_step1Title => 'Share Your Code';

  @override
  String get referral_step1Desc =>
      'Copy your unique code or share it directly with friends.';

  @override
  String get referral_step2Title => 'Friend Signs Up';

  @override
  String get referral_step2Desc =>
      'Your friend downloads Jas Wallet and registers using your code.';

  @override
  String get referral_step3Title => 'Both Earn Rewards';

  @override
  String get referral_step3Desc =>
      'Reach milestones to unlock exclusive badges and climb the leaderboard.';

  @override
  String get referral_promoTitle => 'The more you share,\nthe more you earn';

  @override
  String get referral_promoDesc =>
      'Every friend you invite brings you closer to the next reward tier.';

  @override
  String get referral_faqTitle => 'FAQ';

  @override
  String get referral_faq1Q => 'Who can join the referral program?';

  @override
  String get referral_faq1A =>
      'Any registered Jas Wallet user with a verified account can invite friends and earn rewards.';

  @override
  String get referral_faq2Q => 'When do I get my reward?';

  @override
  String get referral_faq2A =>
      'Rewards are credited once your friend completes registration and verifies their account.';

  @override
  String get referral_faq3Q => 'Is there a limit on invites?';

  @override
  String get referral_faq3A =>
      'No limit — invite as many friends as you want and keep unlocking higher tiers.';

  @override
  String get referral_faq4Q => 'What if my friend already has an account?';

  @override
  String get referral_faq4A =>
      'The referral code only works for new users signing up for the first time.';

  @override
  String get referral_detailsTitle => 'More';

  @override
  String get referral_termsLink => 'Referral Terms';

  @override
  String get referral_historyLink => 'Referral History';

  @override
  String get referral_supportLink => 'Support';

  @override
  String get contest_prizePool => 'Prize Pool';

  @override
  String get contest_condSectionTitle => 'Contest Rules';

  @override
  String get contest_cond1Title => 'Who can participate';

  @override
  String get contest_cond1Desc =>
      'Any student with a registered Jas Wallet account.';

  @override
  String get contest_cond3Title => 'Contest deadline';

  @override
  String get contest_cond4Title => 'Winner selection';

  @override
  String get contest_cond4Desc =>
      'Referrals: top 3 by invite count. Reel and Profile: judged by the @blockchain.fintech.lab team.';

  @override
  String get contest_cond5Title => 'Prize announcement';

  @override
  String get contest_faq1Q => 'How are winners selected?';

  @override
  String get contest_faq1A =>
      'Top 3 referrers by invite count. Reel and Profile winners are chosen by the @blockchain.fintech.lab team.';

  @override
  String get contest_faq2Q => 'Can I enter all three contests?';

  @override
  String get contest_faq2A =>
      'Yes! You can participate in all three simultaneously and win in multiple categories.';

  @override
  String get contest_faq3Q => 'When will prizes be awarded?';

  @override
  String get contest_faq3A =>
      'Winners will be announced and prizes awarded on September 10, 2026.';

  @override
  String get contest_faq4Q => 'Have questions?';

  @override
  String get contest_faq4A =>
      'DM @blockchain.fintech.lab on Instagram with any questions.';

  @override
  String get notifications_sectionEvents => 'Events';

  @override
  String get notifications_eventsSubtitle =>
      'Reminders for events you follow. Tap the bell on an event to subscribe.';

  @override
  String get events_followTooltip => 'Follow this event';

  @override
  String get events_unfollowTooltip => 'Unfollow this event';

  @override
  String get events_followedToast => 'You\'ll get reminders for this event';

  @override
  String get events_unfollowedToast => 'Reminders for this event are off';

  @override
  String get events_reminderTitle => 'Upcoming Event';

  @override
  String events_reminderBody(String time, String title) {
    return 'Tomorrow at $time — $title';
  }

  @override
  String events_reminderBodyAllDay(String title) {
    return 'Tomorrow — $title';
  }

  @override
  String events_reminderBody12h(String time, String title) {
    return 'In 12 hours at $time — $title';
  }

  @override
  String events_reminderBody1h(String time, String title) {
    return 'In 1 hour at $time — $title';
  }

  @override
  String get orientation_week_title => 'Club Fair';

  @override
  String get orientation_hub_banner_subtitle =>
      'Complete quests, explore campus, win prizes';

  @override
  String orientation_day_of(Object day, Object total) {
    return 'Day $day of $total';
  }

  @override
  String get orientation_tokens_label => 'Tokens';

  @override
  String get orientation_continue_journey => 'Continue Journey';

  @override
  String get orientation_networking_bingo => 'Campus Bingo';

  @override
  String get orientation_photo_quests => 'Photo Quests';

  @override
  String get orientation_leaderboard => 'Leaderboard';

  @override
  String get orientation_rewards => 'Rewards';

  @override
  String get orientation_mini_games => 'Mini Games';

  @override
  String orientation_min_short(Object minutes) {
    return '$minutes min';
  }

  @override
  String orientation_xp_short(Object xp) {
    return '+$xp XP';
  }

  @override
  String get orientation_error_title => 'Something went wrong';

  @override
  String get orientation_error_message =>
      'We couldn\'t load Orientation Quest. Please try again.';

  @override
  String get orientation_offline_title => 'You\'re offline';

  @override
  String get orientation_offline_message =>
      'Connect to the internet to load Orientation Quest.';

  @override
  String get orientation_bingo_title => 'Campus Bingo';

  @override
  String get orientation_bingo_subtitle =>
      'Explore campus to close each square';

  @override
  String orientation_cells_completed(Object count, Object total) {
    return '$count/$total cells';
  }

  @override
  String get orientation_foundation_year => 'Foundation Year';

  @override
  String orientation_day_n(Object day) {
    return 'Day $day';
  }

  @override
  String get orientation_profile_title => 'My Orientation Profile';

  @override
  String orientation_level_n(Object level) {
    return 'Level $level';
  }

  @override
  String get orientation_friends_met => 'Places Discovered';

  @override
  String get orientation_locations_visited => 'Locations Visited';

  @override
  String get orientation_badges => 'Badges';

  @override
  String get orientation_photo_status_not_started => 'Not started';

  @override
  String get orientation_photo_status_pending => 'Pending review';

  @override
  String get orientation_photo_status_approved => 'Approved';

  @override
  String get orientation_photo_status_rejected => 'Rejected — try again';

  @override
  String get orientation_redeem => 'Redeem';

  @override
  String get orientation_insufficient_tokens => 'Not enough tokens';

  @override
  String get orientation_awarded_automatically => 'Awarded from leaderboard';

  @override
  String get orientation_completed_label => 'Completed';

  @override
  String get orientation_submit_answer => 'Submit';

  @override
  String get orientation_true_or_myth_statement =>
      'NU\'s library was the first building completed on campus.';

  @override
  String get orientation_location_library => 'Library';

  @override
  String get orientation_location_registrar => 'Registrar';

  @override
  String get orientation_location_sports_complex => 'Sports Complex';

  @override
  String get orientation_location_cafe => 'Campus Café';

  @override
  String get orientation_leaderboard_weekly => 'Weekly';

  @override
  String get orientation_leaderboard_friends => 'Campus';

  @override
  String get orientation_leaderboard_global => 'Global';

  @override
  String get orientation_photo_submitted_message =>
      'Photo submitted for review!';

  @override
  String get orientation_progress_title => 'Progress';

  @override
  String get orientation_statistics => 'Statistics';

  @override
  String get orientation_tokens_earned => 'Tokens Earned';

  @override
  String get orientation_bingo_completion => 'Bingo Completion';

  @override
  String get orientation_achievements => 'Achievements';

  @override
  String get orientation_take_photo => 'Take Photo';

  @override
  String get orientation_choose_from_gallery => 'Gallery';

  @override
  String get orientation_submit_photo => 'Submit Photo';

  @override
  String get orientation_available => 'Available';

  @override
  String get orientation_start => 'Start';

  @override
  String orientation_plus_n(Object n) {
    return '+$n';
  }

  @override
  String get orientation_interests => 'Interests';

  @override
  String get orientation_you_will_earn => 'You will earn';

  @override
  String get orientation_foundation_year_short => 'First Year';

  @override
  String get orientation_leaderboard_school => 'School';

  @override
  String get orientation_bingo_line_hint => 'Complete a line to earn';

  @override
  String get orientation_bingo_start_hint => 'Complete one more to earn';

  @override
  String get orientation_your_rank => 'Your Rank';

  @override
  String get orientation_todays_highlights => 'Today\'s Highlights';

  @override
  String orientation_highlight_bingo_subtitle(Object completed, Object total) {
    return 'Progress $completed/$total';
  }

  @override
  String orientation_highlight_photo_quest_subtitle(Object count) {
    return '$count locations left';
  }

  @override
  String get orientation_highlight_rewards_subtitle => 'New rewards available';

  @override
  String orientation_day_n_of_total(Object day, Object total) {
    return 'Day $day of $total';
  }

  @override
  String orientation_keep_going_name(Object name) {
    return 'Keep going, $name!';
  }

  @override
  String get orientation_keep_going => 'Keep going!';

  @override
  String get orientation_friends_added => 'Places';

  @override
  String get orientation_locations_visited_label => 'Locations';

  @override
  String get orientation_how_it_works => 'How it works';

  @override
  String get orientation_how_it_works_body =>
      'Take a photo at the location shown, then submit it for review. Once approved, your tokens are added automatically. Each location can only be completed once.';

  @override
  String get orientation_status_label => 'Status';

  @override
  String get orientation_reward_label => 'Reward';

  @override
  String get orientation_campus_rewards => 'Campus Rewards';

  @override
  String get orientation_nav_home => 'Home';

  @override
  String get orientation_nav_bingo => 'Bingo';

  @override
  String get orientation_nav_quests => 'Quests';

  @override
  String get orientation_nav_leaderboard => 'Leaderboard';

  @override
  String get orientation_nav_rewards => 'Rewards';

  @override
  String get orientation_bingo_bonus_label => 'Bonus';

  @override
  String orientation_bingo_bonus_lines(Object count) {
    return '$count Lines';
  }

  @override
  String get orientation_mission_reward => 'Mission Reward';

  @override
  String get orientation_line_completion_reward => 'Line Completion Reward';

  @override
  String get orientation_board_completion_reward => 'Board Completion Reward';

  @override
  String get orientation_completed_missions => 'Completed Missions';

  @override
  String get orientation_your_journey => 'Your Journey';

  @override
  String get orientation_you => 'You';

  @override
  String get orientation_leaderboard_rankings => 'Rankings';

  @override
  String get orientation_your_position => 'Your Position';

  @override
  String orientation_tokens_to_rank(Object tokens, Object rank) {
    return '$tokens tokens to rank #$rank';
  }

  @override
  String get orientation_top_of_leaderboard => 'You\'re at the top!';

  @override
  String get orientation_student_profile_title => 'Student';

  @override
  String get orientation_orientation_explorer_badge => 'Orientation Explorer';

  @override
  String orientation_streak_days_n(Object count) {
    return '$count Day Streak';
  }

  @override
  String get orientation_streak_active_subtitle =>
      'You\'ve completed challenges every day.';

  @override
  String get orientation_streak_inactive_subtitle =>
      'Start a new streak today.';

  @override
  String get orientation_next_milestone => 'Up Next';

  @override
  String get orientation_recently_unlocked => 'Recently Unlocked';

  @override
  String get orientation_activity_breakdown => 'Activity Breakdown';

  @override
  String orientation_days_remaining(Object days) {
    return '$days Days Remaining';
  }

  @override
  String get orientation_orientation_complete => 'Orientation Complete';

  @override
  String get orientation_milestone_started => 'Orientation Started';

  @override
  String get orientation_milestone_first_friend => 'First Place Discovered';

  @override
  String get orientation_milestone_first_reward => 'First Reward Earned';

  @override
  String get orientation_milestone_halfway => 'Halfway Complete';

  @override
  String get orientation_milestone_campus_explorer => 'Campus Explorer';

  @override
  String get orientation_milestone_complete => 'Orientation Complete';

  @override
  String get orientation_category_orientation => 'Orientation';

  @override
  String get orientation_category_networking => 'Discovery';

  @override
  String get orientation_category_exploration => 'Exploration';

  @override
  String get orientation_category_participation => 'Participation';

  @override
  String get orientation_category_community => 'Community';

  @override
  String get orientation_category_special => 'Special';

  @override
  String orientation_achievements_unlocked_of_total(
    Object unlocked,
    Object total,
  ) {
    return '$unlocked / $total unlocked';
  }

  @override
  String get orientation_featured_achievement => 'Featured Achievement';

  @override
  String get orientation_view_details => 'View Details';

  @override
  String get orientation_hero_subtitle_1 => 'Your journey starts here.';

  @override
  String get orientation_hero_subtitle_2 =>
      'Complete challenges, earn tokens, and unlock rewards.';

  @override
  String orientation_activities_completed(Object completed, Object total) {
    return '$completed / $total Activities Completed';
  }

  @override
  String get orientation_your_progress_title => 'Your Progress';

  @override
  String orientation_tokens_of_level(Object tokens, Object total) {
    return '$tokens / $total Tokens';
  }

  @override
  String orientation_tokens_to_next_level(Object tokens) {
    return '$tokens Tokens to next level';
  }

  @override
  String get orientation_featured_reward_title => 'Featured Reward';

  @override
  String get orientation_recent_achievement_title => 'Recent Achievement';

  @override
  String get orientation_continue_your_journey => 'Continue Your Journey';

  @override
  String get orientation_tab_overview => 'Home';

  @override
  String get orientation_tab_challenges => 'Tasks';

  @override
  String get orientation_schedule => 'Schedule';

  @override
  String get orientation_schedule_label => 'ORIENTATION WEEK';

  @override
  String get orientation_schedule_full => 'Full schedule';

  @override
  String get orientation_schedule_empty_title => 'Nothing scheduled';

  @override
  String get orientation_schedule_empty_body =>
      'No sessions on this day for your programme.';

  @override
  String get orientation_schedule_today => 'Today';

  @override
  String get orientation_schedule_mandatory => 'Mandatory';

  @override
  String get orientation_schedule_recommended => 'Recommended';

  @override
  String orientation_schedule_sessions(Object count) {
    return '$count sessions';
  }

  @override
  String orientation_schedule_mandatory_count(Object count) {
    return '$count mandatory';
  }

  @override
  String get orientation_track_question => 'Which programme are you on?';

  @override
  String get orientation_track_body =>
      'The week runs two parallel timetables. Pick yours and the schedule will only show sessions that apply to you.';

  @override
  String get orientation_track_ug => 'Undergraduate';

  @override
  String get orientation_track_gr => 'Graduate';

  @override
  String get orientation_track_change => 'Change programme';

  @override
  String get orientation_my_qr => 'My QR code';

  @override
  String get orientation_my_qr_body =>
      'Show this to another student so they can scan you. Yours stays the same all week.';

  @override
  String get orientation_qr_scan_someone => 'Scan someone';

  @override
  String get orientation_school_pending => 'Detecting your school…';

  @override
  String get orientation_school_pending_body =>
      'We match this automatically from your student ID. This only takes a moment.';

  @override
  String get orientation_school_unresolved_title =>
      'Couldn\'t detect your school';

  @override
  String get orientation_school_unresolved_body =>
      'Your student record doesn\'t have a school on file yet. Contact ADSL if this doesn\'t resolve on its own.';

  @override
  String get orientation_school_retry => 'Try again';

  @override
  String get orientation_school_scan_blocked =>
      'We\'re still verifying your school. Try again in a moment.';

  @override
  String get orientation_scan_not_ours => 'That is not an Orientation code';

  @override
  String get orientation_scan_not_ours_body =>
      'Ask them to open Orientation Week and show their own QR code.';

  @override
  String get orientation_scan_self => 'That is your own code';

  @override
  String get orientation_scan_self_body =>
      'Find another student and scan theirs.';

  @override
  String get orientation_scan_duplicate => 'Already scanned';

  @override
  String orientation_scan_duplicate_body(Object name) {
    return 'You have already counted $name for this task.';
  }

  @override
  String get orientation_scan_accepted => 'Counted';

  @override
  String get orientation_challenges_title => 'Challenges';

  @override
  String get orientation_challenges_subtitle =>
      'Tasks that need an answer, a scan or a post.';

  @override
  String get orientation_ch_progress_title => 'Challenges Progress';

  @override
  String get orientation_ch_progress_subtitle =>
      'Answer, scan and share your way through the week';

  @override
  String orientation_ch_completed(Object done, Object total) {
    return '$done / $total challenges completed';
  }

  @override
  String get orientation_ch_tokens_earned => 'Tokens Earned';

  @override
  String get orientation_challenge_save => 'Save answer';

  @override
  String get orientation_challenge_edit => 'Edit answer';

  @override
  String get orientation_challenge_clear => 'Clear answer';

  @override
  String get orientation_challenge_your_answer => 'Your answer';

  @override
  String get orientation_challenge_open_referral => 'Open referral';

  @override
  String get orientation_challenge_done => 'Done';

  @override
  String orientation_challenge_progress(Object done, Object total) {
    return '$done of $total done';
  }

  @override
  String get orientation_tab_bingo => 'Bingo';

  @override
  String get orientation_tab_photo_quest => 'Photo Quest';

  @override
  String get orientation_tab_rewards => 'Rewards';

  @override
  String get orientation_next_bingo_mission => 'Next Mission';

  @override
  String orientation_visit_location(Object location) {
    return 'Visit the $location';
  }

  @override
  String get orientation_redeem_a_reward => 'Redeem a Reward';

  @override
  String get orientation_days_remaining_label => 'Days Remaining';

  @override
  String get orientation_total_tokens => 'Total Tokens';

  @override
  String get orientation_welcome_title => 'Welcome to Orientation Week! 🎉';

  @override
  String get orientation_welcome_subtitle =>
      'Take part in exciting activities, explore the campus and earn rewards.';

  @override
  String get orientation_overall_progress => 'Overall Progress';

  @override
  String orientation_missions_progress(Object completed, Object total) {
    return 'You\'ve completed $completed of $total missions';
  }

  @override
  String get orientation_complete_label => 'Complete';

  @override
  String get orientation_missions_completed_label => 'missions completed';

  @override
  String get orientation_quick_access => 'Quick Access';

  @override
  String get orientation_qr_scanner => 'QR Scanner';

  @override
  String get orientation_qa_bingo => 'Bingo';

  @override
  String get orientation_qa_photos => 'Photos';

  @override
  String get orientation_qa_scan => 'Scan QR';

  @override
  String get orientation_qa_challenges => 'Challenges';

  @override
  String get orientation_earn_rewards_title => 'Earn Amazing Rewards';

  @override
  String get orientation_earn_rewards_subtitle =>
      'Complete missions, collect tokens and unlock exclusive Orientation Week rewards.';

  @override
  String get orientation_view_rewards => 'View Rewards';

  @override
  String get orientation_bingo_hero_title => 'Complete. Mark. Win.';

  @override
  String get orientation_bingo_hero_subtitle =>
      'Complete activities and get Bingo to earn more tokens!';

  @override
  String get orientation_bingo_progress_title => 'Bingo Progress';

  @override
  String orientation_bingo_progress_subtitle(Object target) {
    return 'Complete $target lines to win big!';
  }

  @override
  String orientation_bingo_lines_completed(Object completed, Object total) {
    return '$completed / $total lines completed';
  }

  @override
  String get orientation_bingo_bonus_tokens => 'Bonus Tokens';

  @override
  String get orientation_bingo_free_space => 'FREE SPACE';

  @override
  String get orientation_bingo_cta_title => 'Complete more, win more';

  @override
  String get orientation_bingo_cta_subtitle =>
      'Keep playing and unlock amazing rewards!';

  @override
  String get orientation_bingo_mark_complete => 'Complete';

  @override
  String get orientation_bingo_completed_label => 'Completed';

  @override
  String orientation_bingo_squares_completed(Object completed, Object total) {
    return '$completed of $total squares';
  }

  @override
  String get orientation_bingo_line_complete_toast => 'Line complete!';

  @override
  String get orientation_bingo_board_complete_toast => 'Bingo! Board complete';

  @override
  String get orientation_pq_hero_title => 'Capture. Share. Earn.';

  @override
  String get orientation_pq_hero_subtitle =>
      'Complete photo missions around campus and earn amazing rewards!';

  @override
  String get orientation_pq_progress_title => 'Photo Quest Progress';

  @override
  String get orientation_pq_progress_subtitle =>
      'Complete missions to earn tokens!';

  @override
  String orientation_pq_missions_completed(Object completed, Object total) {
    return '$completed / $total missions completed';
  }

  @override
  String get orientation_pq_complete_all => 'Complete all to earn';

  @override
  String get orientation_pq_all_missions => 'All Missions';

  @override
  String get orientation_pq_easy => 'Easy';

  @override
  String get orientation_pq_medium => 'Medium';

  @override
  String get orientation_pq_hard => 'Hard';

  @override
  String get orientation_pq_cta_title => 'Complete more photo quests!';

  @override
  String get orientation_pq_cta_subtitle =>
      'Finish all missions to earn bonus tokens and exclusive rewards.';

  @override
  String get orientation_pq_completed => 'Completed';

  @override
  String get orientation_pq_requirements => 'What your photo must show';

  @override
  String get orientation_pq_where => 'Where to take it';

  @override
  String get orientation_pq_reward => 'Reward';

  @override
  String get orientation_pq_difficulty => 'Difficulty';

  @override
  String get orientation_pq_take_photo => 'Take Photo';

  @override
  String get orientation_pq_from_gallery => 'Choose from Gallery';

  @override
  String get orientation_pq_retake => 'Retake';

  @override
  String get orientation_pq_submit => 'Submit Photo';

  @override
  String get orientation_pq_submission_title => 'Submit your photo';

  @override
  String get orientation_pq_status_pending => 'Pending review';

  @override
  String get orientation_pq_status_rejected => 'Needs a better photo';

  @override
  String get orientation_pq_status_locked => 'Locked';

  @override
  String get orientation_pq_status_expired => 'Expired';

  @override
  String get orientation_pq_notify_approved_title => 'Photo Quest approved';

  @override
  String orientation_pq_notify_approved_body(String mission, int tokens) {
    return '$mission was verified — you earned $tokens tokens.';
  }

  @override
  String get orientation_pq_notify_declined_title => 'Photo needs a retake';

  @override
  String orientation_pq_notify_declined_body(String mission) {
    return '$mission was not accepted. Take a new photo to try again.';
  }

  @override
  String get orientation_pq_empty_filter =>
      'No missions at this difficulty yet.';

  @override
  String get orientation_pq_bonus_unlocked => 'Photo Quest complete!';

  @override
  String get orientation_rw_hero_title_1 => 'Your effort.';

  @override
  String get orientation_rw_hero_title_2a => 'Great ';

  @override
  String get orientation_rw_hero_title_2b => 'rewards.';

  @override
  String get orientation_rw_hero_subtitle =>
      'Redeem your tokens for amazing rewards and experiences.';

  @override
  String get orientation_rw_browse_category => 'Browse by Category';

  @override
  String get orientation_rw_token_rewards => 'Token Rewards';

  @override
  String get orientation_rw_cat_all => 'All';

  @override
  String get orientation_rw_cat_merch => 'Merch';

  @override
  String get orientation_rw_cat_gift_cards => 'Gift Cards';

  @override
  String get orientation_rw_cat_experiences => 'Experiences';

  @override
  String get orientation_rw_cat_other => 'Other';

  @override
  String orientation_rw_tokens_suffix(Object count) {
    return '$count tokens';
  }

  @override
  String get orientation_rw_hot => 'Hot';

  @override
  String get orientation_rw_unlimited => 'Unlimited';

  @override
  String orientation_rw_limited(Object count) {
    return 'Limited: $count left';
  }

  @override
  String get orientation_rw_out_of_stock => 'Out of stock';

  @override
  String get orientation_rw_coming_soon => 'Coming soon';

  @override
  String get orientation_rw_expired => 'Expired';

  @override
  String get orientation_rw_redeem => 'Redeem';

  @override
  String get orientation_rw_redeemed => 'Redeemed';

  @override
  String orientation_rw_need_more(Object count) {
    return 'You need $count more tokens';
  }

  @override
  String get orientation_rw_earn_more => 'Earn more';

  @override
  String get orientation_rw_details => 'Reward Details';

  @override
  String get orientation_rw_terms => 'Terms';

  @override
  String get orientation_rw_how_to_redeem => 'How to redeem';

  @override
  String get orientation_rw_availability => 'Availability';

  @override
  String get orientation_rw_remaining => 'Remaining';

  @override
  String get orientation_rw_confirm_title => 'Confirm redemption';

  @override
  String get orientation_rw_confirm_balance => 'Current balance';

  @override
  String get orientation_rw_confirm_cost => 'Reward cost';

  @override
  String get orientation_rw_confirm_after => 'Balance after';

  @override
  String get orientation_rw_cancel => 'Cancel';

  @override
  String get orientation_rw_success_title => 'Reward redeemed!';

  @override
  String get orientation_rw_success_body =>
      'Enjoy your reward. Check your history to collect it.';

  @override
  String get orientation_rw_view_history => 'View History';

  @override
  String get orientation_rw_done => 'Done';

  @override
  String get orientation_rw_history_title => 'Redemption History';

  @override
  String get orientation_rw_exclusive_claimed_title =>
      'Exclusive prize claimed';

  @override
  String get orientation_rw_exclusive_claimed_body =>
      'You already claimed one of the top prizes — further redeems are locked.';

  @override
  String get orientation_rw_history_empty =>
      'You have not redeemed any rewards yet.';

  @override
  String get orientation_rw_collected => 'Collected';

  @override
  String get orientation_rw_to_collect => 'Ready to collect';

  @override
  String get orientation_rw_milestones_title => 'Milestones';

  @override
  String get orientation_rw_keep_collecting => 'Keep collecting!';

  @override
  String get orientation_rw_milestone_subtitle =>
      'Reach new milestones to unlock even better rewards.';

  @override
  String get orientation_rw_view_milestones => 'View Milestones';

  @override
  String get orientation_rw_next_milestone => 'Next milestone';

  @override
  String get orientation_rw_unlocked => 'Unlocked';

  @override
  String get orientation_rw_locked => 'Locked';

  @override
  String get orientation_rw_empty_category =>
      'No rewards in this category yet.';

  @override
  String get orientation_bingo_scan_qr => 'Scan QR Code';

  @override
  String get orientation_bingo_scan_hint =>
      'Ask a supervisor to show their QR code to confirm this task.';

  @override
  String get orientation_bingo_auto_title => 'Tracked automatically';

  @override
  String get orientation_bingo_auto_hint =>
      'The app marks this done for you when you complete it.';

  @override
  String get orientation_bingo_open_task => 'Complete task';

  @override
  String get orientation_bingo_photo_hint =>
      'This square is a Photo Quest — take the photo in the Photo Quest tab.';

  @override
  String get orientation_challenge_wrong_answer =>
      'That\'s not the right answer — check it and try again.';

  @override
  String get orientation_challenge_invalid_student_id =>
      'Enter a valid Student ID — the number on their NU card.';

  @override
  String get orientation_challenge_senior_not_found =>
      'This Student ID was not found in the university directory. Check the number and try again.';

  @override
  String get orientation_challenge_senior_too_recent =>
      'This person has been at NU for less than three years. Find someone more senior!';

  @override
  String get orientation_challenge_own_student_id =>
      'That\'s your own Student ID — the advice has to come from someone else!';

  @override
  String get orientation_bingo_scan_instruction =>
      'Point your camera at the club\'s QR';

  @override
  String get orientation_bingo_scan_failed =>
      'That code was not recognised. Try again.';

  @override
  String get orientation_rw_total_spent => 'Total spent';

  @override
  String orientation_rw_redeemed_count(Object count) {
    return '$count redeemed';
  }

  @override
  String get orientation_about_title => 'What is Club Fair?';

  @override
  String get orientation_about_body =>
      'NU clubs in the Atrium - walk the stands, scan club QRs, complete tasks, and spend tokens on prizes.';

  @override
  String get orientation_about_point_explore_title =>
      'Getting to know the clubs';

  @override
  String get orientation_about_point_explore_body =>
      'All booths are in the NU Atrium, in two time blocks: 11:00–14:00 and 15:00–18:00.';

  @override
  String get orientation_about_point_connect_title => 'Scan and bingo';

  @override
  String get orientation_about_point_connect_body =>
      'Scan club QRs for tokens. Bingo is 16 random clubs from the full list.';

  @override
  String get orientation_about_point_earn_title => 'Tokens and prizes';

  @override
  String get orientation_about_point_earn_body =>
      'Redeem tokens in the Rewards tab.';

  @override
  String get orientation_about_hide => 'Got it, hide';

  @override
  String get orientation_partner_title => 'Together with ADSL';

  @override
  String get orientation_partner_body =>
      'ADSL (Association for the Development of Student Life) is NU\'s student nonprofit that supports initiatives, leadership, and an active student community.';

  @override
  String get orientation_partner_instagram_cta => 'Open Instagram';

  @override
  String get orientation_challenge_open_link => 'Open';

  @override
  String get orientation_rw_claim_title => 'How to get your prize';

  @override
  String get orientation_rw_claim_intro =>
      'Rewards are redeemed in the app, and handed over in person.';

  @override
  String get orientation_rw_claim_step1 => 'Redeem the reward in the app.';

  @override
  String orientation_rw_claim_step2(String number) {
    return 'Message $number on WhatsApp and say which reward you redeemed.';
  }

  @override
  String get orientation_rw_claim_step3 =>
      'Collect it in person. There is an additional check on site before the prize is handed over.';

  @override
  String get orientation_rw_claim_cta => 'Message on WhatsApp';

  @override
  String get orientation_closed_title => 'Club Fair has ended';

  @override
  String get orientation_closed_body =>
      'This year\'s Club Fair is over. Thank you for taking part — see you next year!';

  @override
  String get orientation_freshmen_title => 'For freshmen only';

  @override
  String get orientation_freshmen_body =>
      'Orientation Week is only for first-year students — NUFYP, first-year undergraduates, and first-year graduate students. If you\'re not a freshman, please don\'t complete the tasks — you won\'t receive the prizes anyway. If you claim a prize regardless, you won\'t be able to collect it, and it will cause problems for the freshmen who are eligible. Please be considerate.';

  @override
  String get orientation_freshmen_acknowledge => 'I understand';

  @override
  String get orientation_freshmen_card_title => 'Who can participate';

  @override
  String get orientation_rw_view_details => 'Details';

  @override
  String get orientation_rw_redemption_details => 'Redemption details';

  @override
  String get orientation_rw_redeemed_on => 'Redeemed on';

  @override
  String get orientation_rw_tokens_spent => 'Tokens spent';

  @override
  String get orientation_rw_redeemed_by => 'Redeemed by';

  @override
  String get orientation_rw_field_name => 'Name';

  @override
  String get orientation_rw_field_student_id => 'Student ID';

  @override
  String get orientation_rw_field_email => 'Email';

  @override
  String get orientation_rw_field_unset => 'Not set';

  @override
  String get orientation_journey_title => 'Your 7-Day Journey';

  @override
  String orientation_journey_subtitle(Object current, Object total) {
    return 'Day $current of $total';
  }

  @override
  String orientation_journey_day(Object n) {
    return 'Day $n';
  }

  @override
  String get orientation_view_leaderboard => 'View Leaderboard';

  @override
  String get orientation_leaderboard_cta_subtitle =>
      'See how you rank against other students';

  @override
  String get orientation_faq_title => 'FAQ';

  @override
  String get orientation_faq_q1 => 'Who can take part?';

  @override
  String get orientation_faq_a1 =>
      'Any NU student. Club Fair is for the whole campus!';

  @override
  String get orientation_faq_q2 => 'When and where is it?';

  @override
  String get orientation_faq_a2 =>
      'From 23 to 27 August 2026 at NU Atrium. Club stands - Mon–Thu, 11:00–14:00 and 15:00–18:00 (Thursday morning only).';

  @override
  String get orientation_faq_q3 => 'How do club QR scans work?';

  @override
  String get orientation_faq_a3 =>
      'The club representative shows a QR (it changes every 20 seconds). Scan it and get tokens, awarded once per club.';

  @override
  String get orientation_faq_q4 => 'How do tokens work?';

  @override
  String get orientation_faq_a4 =>
      'There is no daily or weekly earn cap. You earn tokens from club scans, tasks, photo missions, venue QRs, bingo lines (+50) and grand bingo (+200). Spend them in the Rewards tab.';

  @override
  String get orientation_faq_q5 => 'How does bingo work?';

  @override
  String get orientation_faq_a5 =>
      'The card is 16 random clubs on a 4×4 grid. Scanning a club closes that square. A line gives +50, four lines - +200 once.';

  @override
  String get orientation_faq_q6 => 'How do I collect a prize?';

  @override
  String get orientation_faq_a6 =>
      'Redeem in the Rewards tab, then message the listed number on WhatsApp. The prize is handed over in person after a check. If you have technical questions about the app or the quest, please use the button provided to reach our Telegram channel.';

  @override
  String get orientation_club_scan_title => 'Club QR';

  @override
  String get orientation_club_scan_cta => 'Scan club QR';

  @override
  String orientation_club_scan_progress(Object scanned, Object total) {
    return '$scanned of $total clubs';
  }

  @override
  String orientation_club_scan_tokens(Object tokens) {
    return '$tokens tokens from scans';
  }

  @override
  String get orientation_club_scan_already => 'You already scanned this club.';

  @override
  String get orientation_club_scan_wrong => 'That is not a Club Fair stand QR.';

  @override
  String get orientation_club_scan_expired =>
      'QR expired - ask them to show a fresh one.';

  @override
  String get orientation_club_scan_own => 'You cannot scan your own club QR.';

  @override
  String get orientation_club_scan_outside =>
      'This club is not at Club Fair right now. Check the time and schedule.';

  @override
  String get orientation_club_scan_closed => 'Club Fair is not open yet.';

  @override
  String get orientation_tasks_group_all => 'All';

  @override
  String get orientation_tasks_group_general => 'General';

  @override
  String get orientation_tasks_group_today => 'Today';

  @override
  String get orientation_tasks_group_clubs => 'Clubs';

  @override
  String get orientation_tasks_group_photos => 'Photo tasks';

  @override
  String get orientation_tasks_group_qr => 'QR';

  @override
  String get orientation_schedule_morning => '11:00–14:00';

  @override
  String get orientation_schedule_afternoon => '15:00–18:00';

  @override
  String get orientation_schedule_always => 'All week';

  @override
  String get orientation_schedule_atrium => 'NU Atrium';

  @override
  String get orientation_schedule_in_quest => 'Quest';

  @override
  String get orientation_rw_tech_cta => 'Technical questions';

  @override
  String get orientation_rw_tech_body =>
      'If you have technical problems or questions, please reach out in our Telegram channel!';

  @override
  String get orientation_rw_tech_open => 'Open Telegram';

  @override
  String get orientation_qa_rewards => 'Rewards';

  @override
  String get orientation_club_stand_qr_cta => 'Show stand QR';

  @override
  String get orientation_club_stand_qr_title => 'Stand QR';

  @override
  String orientation_club_stand_qr_body(int seconds) {
    return 'Hold this up at your booth. The code changes every $seconds seconds so a photo from the chat will not work.';
  }

  @override
  String orientation_club_stand_qr_refresh(int seconds) {
    return 'Refreshes in ${seconds}s';
  }

  @override
  String get orientation_club_stand_qr_live => 'Live';

  @override
  String get orientation_club_stand_qr_waiting => 'Stand closed';

  @override
  String get orientation_club_stand_qr_waiting_body =>
      'The live code appears only during your Club Fair slot.';

  @override
  String orientation_club_stand_qr_window(String window) {
    return 'Show this QR $window.';
  }

  @override
  String get orientation_club_stand_qr_all_week => 'any time during Club Fair';

  @override
  String get orientation_club_stand_qr_not_rep =>
      'This account is not listed as a club representative.';

  @override
  String get orientation_club_ranking_cta => 'Club Fair ranking';

  @override
  String get orientation_club_ranking_cta_subtitle =>
      'See which clubs students visited most';

  @override
  String get orientation_club_ranking_title => 'Club Fair ranking';

  @override
  String get orientation_club_ranking_list => 'All clubs';

  @override
  String orientation_club_ranking_scans(int count) {
    return '$count scans';
  }

  @override
  String orientation_club_ranking_total(int scans, int clubs) {
    return '$scans scans · $clubs clubs';
  }
}
