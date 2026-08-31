import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Jas Wallet'**
  String get appName;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get common_start;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get common_keep;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get common_showPassword;

  /// No description provided for @common_hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get common_hidePassword;

  /// No description provided for @common_useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometric authentication'**
  String get common_useBiometric;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get common_success;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get common_saved;

  /// No description provided for @common_earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get common_earlier;

  /// No description provided for @common_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get common_userNotFound;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get common_hide;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get common_viewAll;

  /// No description provided for @common_notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get common_notSpecified;

  /// No description provided for @common_deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get common_deleteProfile;

  /// No description provided for @common_deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get common_deleteAccountConfirm;

  /// No description provided for @common_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String common_minutesAgo(Object count);

  /// No description provided for @common_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String common_hoursAgo(Object count);

  /// No description provided for @common_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String common_daysAgo(Object count);

  /// No description provided for @splash_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get splash_selectLanguage;

  /// No description provided for @splash_welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jas Wallet'**
  String get splash_welcomeMessage;

  /// No description provided for @splash_russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get splash_russian;

  /// No description provided for @splash_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get splash_english;

  /// No description provided for @splash_kazakh.
  ///
  /// In en, this message translates to:
  /// **'Kazakh'**
  String get splash_kazakh;

  /// No description provided for @welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jas Wallet'**
  String get welcome_title;

  /// No description provided for @welcome_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get welcome_login;

  /// No description provided for @welcome_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get welcome_register;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here'**
  String get welcome_subtitle;

  /// No description provided for @auth_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get auth_username;

  /// No description provided for @auth_usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get auth_usernameOrEmail;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat Password'**
  String get auth_repeatPassword;

  /// No description provided for @auth_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get auth_phone;

  /// No description provided for @auth_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_email;

  /// No description provided for @auth_firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get auth_firstName;

  /// No description provided for @auth_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get auth_lastName;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_noAccount;

  /// No description provided for @auth_hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_hasAccount;

  /// No description provided for @auth_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signUp;

  /// No description provided for @auth_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_signIn;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get auth_createAccount;

  /// No description provided for @auth_agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get auth_agreeTerms;

  /// No description provided for @auth_consentDataCollection.
  ///
  /// In en, this message translates to:
  /// **'I consent to data collection for service improvement'**
  String get auth_consentDataCollection;

  /// No description provided for @auth_registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get auth_registration;

  /// No description provided for @auth_registrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your @nu.edu.kz address to register'**
  String get auth_registrationDesc;

  /// No description provided for @auth_register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get auth_register;

  /// No description provided for @auth_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get auth_login;

  /// No description provided for @auth_loginDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill in brief information and log into your account'**
  String get auth_loginDesc;

  /// No description provided for @auth_rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get auth_rememberMe;

  /// No description provided for @auth_createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get auth_createProfile;

  /// No description provided for @auth_createProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'To continue registration, fill in brief information'**
  String get auth_createProfileDesc;

  /// No description provided for @auth_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get auth_fullName;

  /// No description provided for @auth_thinkUsername.
  ///
  /// In en, this message translates to:
  /// **'Think of a username'**
  String get auth_thinkUsername;

  /// No description provided for @auth_createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create password'**
  String get auth_createPassword;

  /// No description provided for @biometric_verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Verification'**
  String get biometric_verificationTitle;

  /// No description provided for @biometric_verificationDesc.
  ///
  /// In en, this message translates to:
  /// **'To complete registration, you need to pass biometric verification'**
  String get biometric_verificationDesc;

  /// No description provided for @biometric_verificationError.
  ///
  /// In en, this message translates to:
  /// **'Verification Error'**
  String get biometric_verificationError;

  /// No description provided for @biometric_verificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification completed successfully'**
  String get biometric_verificationSuccess;

  /// No description provided for @biometric_startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get biometric_startVerification;

  /// No description provided for @biometric_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get biometric_processing;

  /// No description provided for @biometric_requestingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Requesting Permissions...'**
  String get biometric_requestingPermissions;

  /// No description provided for @biometric_permissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please allow access to camera and microphone'**
  String get biometric_permissionsDescription;

  /// No description provided for @biometric_permissionsDeniedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone access is required for verification. Please allow access in app settings.'**
  String get biometric_permissionsDeniedPermanently;

  /// No description provided for @biometric_permissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone access not granted. Please allow access and try again.'**
  String get biometric_permissionsDenied;

  /// No description provided for @biometric_permissionsError.
  ///
  /// In en, this message translates to:
  /// **'Error requesting permissions'**
  String get biometric_permissionsError;

  /// No description provided for @biometric_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get biometric_openSettings;

  /// No description provided for @verification_title.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verification_title;

  /// No description provided for @verification_enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get verification_enterCode;

  /// No description provided for @verification_codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {destination}'**
  String verification_codeSent(String destination);

  /// No description provided for @verification_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get verification_resend;

  /// No description provided for @verification_resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String verification_resendIn(int seconds);

  /// No description provided for @forgotPassword_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword_title;

  /// No description provided for @forgotPassword_selectMethod.
  ///
  /// In en, this message translates to:
  /// **'Select recovery method'**
  String get forgotPassword_selectMethod;

  /// No description provided for @forgotPassword_viaPhone.
  ///
  /// In en, this message translates to:
  /// **'Via Phone Number'**
  String get forgotPassword_viaPhone;

  /// No description provided for @forgotPassword_viaEmail.
  ///
  /// In en, this message translates to:
  /// **'Via E-mail'**
  String get forgotPassword_viaEmail;

  /// No description provided for @forgotPassword_enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code'**
  String get forgotPassword_enterPhone;

  /// No description provided for @forgotPassword_enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a verification code'**
  String get forgotPassword_enterEmail;

  /// No description provided for @forgotPassword_newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get forgotPassword_newPassword;

  /// No description provided for @forgotPassword_resetDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account'**
  String get forgotPassword_resetDesc;

  /// No description provided for @forgotPassword_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get forgotPassword_confirmPassword;

  /// No description provided for @forgotPassword_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPassword_reset;

  /// No description provided for @forgotPassword_success.
  ///
  /// In en, this message translates to:
  /// **'Password Changed Successfully'**
  String get forgotPassword_success;

  /// No description provided for @forgotPassword_successDesc.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated. You can now log in with your new password.'**
  String get forgotPassword_successDesc;

  /// No description provided for @common_contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get common_contactUs;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @stories_yourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get stories_yourStory;

  /// No description provided for @stories_addStory.
  ///
  /// In en, this message translates to:
  /// **'Add Story'**
  String get stories_addStory;

  /// No description provided for @stories_publishAs.
  ///
  /// In en, this message translates to:
  /// **'Publish as'**
  String get stories_publishAs;

  /// No description provided for @stories_chooseMedia.
  ///
  /// In en, this message translates to:
  /// **'Choose media'**
  String get stories_chooseMedia;

  /// No description provided for @stories_mediaPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get stories_mediaPhoto;

  /// No description provided for @stories_mediaVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get stories_mediaVideo;

  /// No description provided for @stories_publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish story. Please try again.'**
  String get stories_publishFailed;

  /// No description provided for @stories_publishForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to publish stories for this organization.'**
  String get stories_publishForbidden;

  /// No description provided for @stories_processingVideo.
  ///
  /// In en, this message translates to:
  /// **'Preparing video...'**
  String get stories_processingVideo;

  /// No description provided for @stories_videoReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare the selected video. Please choose another video.'**
  String get stories_videoReadFailed;

  /// No description provided for @stories_videoProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not process the selected video. Please choose another video.'**
  String get stories_videoProcessFailed;

  /// No description provided for @stories_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete story. Please try again.'**
  String get stories_deleteFailed;

  /// No description provided for @stories_deleteForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete this story.'**
  String get stories_deleteForbidden;

  /// No description provided for @stories_notFound.
  ///
  /// In en, this message translates to:
  /// **'This story was not found. It may have already expired or been deleted.'**
  String get stories_notFound;

  /// No description provided for @stories_mediaUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported story media format. Please choose a supported photo or video.'**
  String get stories_mediaUnsupported;

  /// No description provided for @stories_mediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Story file is too large. Please choose a smaller file.'**
  String get stories_mediaTooLarge;

  /// No description provided for @stories_videoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video is too long. Please choose a video up to 20 seconds.'**
  String get stories_videoTooLong;

  /// No description provided for @stories_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading story...'**
  String get stories_uploading;

  /// No description provided for @stories_videoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this video.'**
  String get stories_videoLoadFailed;

  /// No description provided for @stories_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Story'**
  String get stories_deleteTitle;

  /// No description provided for @stories_deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this story?'**
  String get stories_deleteMessage;

  /// No description provided for @stories_renderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not prepare story for upload. Please try again.'**
  String get stories_renderFailed;

  /// No description provided for @stories_discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Story?'**
  String get stories_discardTitle;

  /// No description provided for @stories_discardMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close? Your changes will be lost.'**
  String get stories_discardMessage;

  /// No description provided for @stories_discardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get stories_discardConfirm;

  /// No description provided for @stories_keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get stories_keepEditing;

  /// No description provided for @stories_share.
  ///
  /// In en, this message translates to:
  /// **'Share Story'**
  String get stories_share;

  /// No description provided for @stories_videoPreview.
  ///
  /// In en, this message translates to:
  /// **'Video Preview'**
  String get stories_videoPreview;

  /// No description provided for @stories_textHint.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get stories_textHint;

  /// No description provided for @stories_replyHint.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get stories_replyHint;

  /// No description provided for @stories_trimFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not trim the video. Please try again.'**
  String get stories_trimFailed;

  /// No description provided for @widgets_title.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get widgets_title;

  /// No description provided for @widgets_description.
  ///
  /// In en, this message translates to:
  /// **'Choose which widgets to display on your home screen'**
  String get widgets_description;

  /// No description provided for @hub_title.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get hub_title;

  /// No description provided for @hub_searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search services, jobs, courses...'**
  String get hub_searchPlaceholder;

  /// No description provided for @hub_mainServices.
  ///
  /// In en, this message translates to:
  /// **'Main Services'**
  String get hub_mainServices;

  /// No description provided for @hub_comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get hub_comingSoon;

  /// No description provided for @hub_stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get hub_stories;

  /// No description provided for @hub_saltoCard.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get hub_saltoCard;

  /// No description provided for @hub_events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get hub_events;

  /// No description provided for @hub_weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get hub_weather;

  /// No description provided for @hub_exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get hub_exchange;

  /// No description provided for @weather_title.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather_title;

  /// No description provided for @weather_astana.
  ///
  /// In en, this message translates to:
  /// **'Astana'**
  String get weather_astana;

  /// No description provided for @weather_feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°'**
  String weather_feelsLike(Object temp);

  /// No description provided for @weather_forecast7day.
  ///
  /// In en, this message translates to:
  /// **'7-Day Forecast'**
  String get weather_forecast7day;

  /// No description provided for @weather_wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weather_wind;

  /// No description provided for @weather_humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weather_humidity;

  /// No description provided for @weather_pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get weather_pressure;

  /// No description provided for @weather_uvIndex.
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get weather_uvIndex;

  /// No description provided for @weather_precipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weather_precipitation;

  /// No description provided for @weather_sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get weather_sunrise;

  /// No description provided for @weather_sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get weather_sunset;

  /// No description provided for @weather_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weather_today;

  /// No description provided for @weather_noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get weather_noData;

  /// No description provided for @weather_uvLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get weather_uvLow;

  /// No description provided for @weather_uvModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get weather_uvModerate;

  /// No description provided for @weather_uvHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get weather_uvHigh;

  /// No description provided for @weather_uvVeryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get weather_uvVeryHigh;

  /// No description provided for @weather_uvExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get weather_uvExtreme;

  /// No description provided for @exchange_title.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rates'**
  String get exchange_title;

  /// No description provided for @exchange_label.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange_label;

  /// No description provided for @exchange_noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get exchange_noData;

  /// No description provided for @exchange_usDollar.
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get exchange_usDollar;

  /// No description provided for @exchange_euro.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get exchange_euro;

  /// No description provided for @exchange_russianRuble.
  ///
  /// In en, this message translates to:
  /// **'Russian Ruble'**
  String get exchange_russianRuble;

  /// No description provided for @exchange_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String exchange_updated(Object date);

  /// No description provided for @hub_jobFinder.
  ///
  /// In en, this message translates to:
  /// **'Job Finder'**
  String get hub_jobFinder;

  /// No description provided for @hub_actualJobs.
  ///
  /// In en, this message translates to:
  /// **'Actual Jobs'**
  String get hub_actualJobs;

  /// No description provided for @hub_fintech.
  ///
  /// In en, this message translates to:
  /// **'FinTech'**
  String get hub_fintech;

  /// No description provided for @hub_courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get hub_courses;

  /// No description provided for @hub_studentClubs.
  ///
  /// In en, this message translates to:
  /// **'Student Clubs'**
  String get hub_studentClubs;

  /// No description provided for @hub_gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get hub_gym;

  /// No description provided for @courses_openAcademy.
  ///
  /// In en, this message translates to:
  /// **'Open Academy'**
  String get courses_openAcademy;

  /// No description provided for @hub_aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI-Chat'**
  String get hub_aiChat;

  /// No description provided for @hub_habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get hub_habits;

  /// No description provided for @hub_library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get hub_library;

  /// No description provided for @hub_market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get hub_market;

  /// No description provided for @hub_blogNews.
  ///
  /// In en, this message translates to:
  /// **'Blog & News'**
  String get hub_blogNews;

  /// No description provided for @hub_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get hub_social;

  /// No description provided for @hub_rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get hub_rent;

  /// No description provided for @hub_documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get hub_documents;

  /// No description provided for @hub_forum.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get hub_forum;

  /// No description provided for @hub_widgetsDescription.
  ///
  /// In en, this message translates to:
  /// **'Порядок расположения сервисов'**
  String get hub_widgetsDescription;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @profile_share.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get profile_share;

  /// No description provided for @profile_shareVia.
  ///
  /// In en, this message translates to:
  /// **'Share via...'**
  String get profile_shareVia;

  /// No description provided for @profile_copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get profile_copyLink;

  /// No description provided for @profile_linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get profile_linkCopied;

  /// No description provided for @profile_followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get profile_followers;

  /// No description provided for @profile_following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get profile_following;

  /// No description provided for @profile_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get profile_rating;

  /// No description provided for @profile_bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profile_bio;

  /// No description provided for @profile_editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profile_editProfile;

  /// No description provided for @profile_workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get profile_workExperience;

  /// No description provided for @profile_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get profile_skills;

  /// No description provided for @profile_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profile_education;

  /// No description provided for @profile_activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get profile_activities;

  /// No description provided for @profile_school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get profile_school;

  /// No description provided for @profile_university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get profile_university;

  /// No description provided for @profile_volunteering.
  ///
  /// In en, this message translates to:
  /// **'Volunteering'**
  String get profile_volunteering;

  /// No description provided for @editProfile_accountData.
  ///
  /// In en, this message translates to:
  /// **'Account data'**
  String get editProfile_accountData;

  /// No description provided for @editProfile_personalData.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get editProfile_personalData;

  /// No description provided for @editProfile_phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get editProfile_phoneNumber;

  /// No description provided for @editProfile_email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get editProfile_email;

  /// No description provided for @editProfile_dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get editProfile_dateOfBirth;

  /// No description provided for @editProfile_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get editProfile_gender;

  /// No description provided for @editProfile_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get editProfile_deleteAccount;

  /// No description provided for @editProfile_deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get editProfile_deleteAccountDesc;

  /// No description provided for @editProfile_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get editProfile_male;

  /// No description provided for @editProfile_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get editProfile_female;

  /// No description provided for @editProfile_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get editProfile_other;

  /// No description provided for @editProfile_changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfile_changePhoto;

  /// No description provided for @editProfile_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get editProfile_takePhoto;

  /// No description provided for @editProfile_chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get editProfile_chooseFromGallery;

  /// No description provided for @editProfile_avatarTemplates.
  ///
  /// In en, this message translates to:
  /// **'Avatar templates'**
  String get editProfile_avatarTemplates;

  /// No description provided for @editProfile_profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get editProfile_profilePhoto;

  /// No description provided for @editProfile_avatars.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get editProfile_avatars;

  /// No description provided for @editProfile_additionalPhone.
  ///
  /// In en, this message translates to:
  /// **'Additional phone'**
  String get editProfile_additionalPhone;

  /// No description provided for @editProfile_addBioHint.
  ///
  /// In en, this message translates to:
  /// **'Add information about yourself'**
  String get editProfile_addBioHint;

  /// No description provided for @editProfile_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get editProfile_description;

  /// No description provided for @editProfile_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get editProfile_descriptionHint;

  /// No description provided for @editProfile_addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get editProfile_addTag;

  /// No description provided for @editProfile_tagHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name'**
  String get editProfile_tagHint;

  /// No description provided for @profile_fillProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill your profile'**
  String get profile_fillProfile;

  /// No description provided for @profile_completedSteps.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} Completed'**
  String profile_completedSteps(int completed, int total);

  /// No description provided for @days_mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get days_mon;

  /// No description provided for @days_tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get days_tue;

  /// No description provided for @days_wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get days_wed;

  /// No description provided for @days_thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get days_thu;

  /// No description provided for @days_fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get days_fri;

  /// No description provided for @days_sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get days_sat;

  /// No description provided for @days_sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get days_sun;

  /// No description provided for @auth_firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get auth_firstNameHint;

  /// No description provided for @auth_lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get auth_lastNameHint;

  /// No description provided for @auth_usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get auth_usernameHint;

  /// No description provided for @auth_usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get auth_usernameTaken;

  /// No description provided for @auth_studentIdTaken.
  ///
  /// In en, this message translates to:
  /// **'This student ID is already registered in the app. If you believe this is a mistake, contact us at support@jasaim.kz'**
  String get auth_studentIdTaken;

  /// No description provided for @auth_usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username is available'**
  String get auth_usernameAvailable;

  /// No description provided for @auth_usernameInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'3–30 characters: lowercase letters, digits, underscore'**
  String get auth_usernameInvalidFormat;

  /// No description provided for @auth_passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, including a letter and a number'**
  String get auth_passwordRule;

  /// No description provided for @auth_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_passwordsDoNotMatch;

  /// No description provided for @auth_nameAutoFilled.
  ///
  /// In en, this message translates to:
  /// **'First and last name were filled automatically.'**
  String get auth_nameAutoFilled;

  /// No description provided for @auth_sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get auth_sendCode;

  /// No description provided for @auth_enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to'**
  String get auth_enterVerificationCode;

  /// No description provided for @auth_resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get auth_resendCode;

  /// No description provided for @auth_phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone number (optional)'**
  String get auth_phoneOptional;

  /// No description provided for @auth_studentIdHint.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get auth_studentIdHint;

  /// No description provided for @auth_invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get auth_invalidEmailFormat;

  /// No description provided for @auth_onlyNuEmailAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only @nu.edu.kz emails are allowed'**
  String get auth_onlyNuEmailAllowed;

  /// No description provided for @auth_alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'You are already registered. Please log in to continue.'**
  String get auth_alreadyRegistered;

  /// No description provided for @auth_biometricLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login?'**
  String get auth_biometricLoginTitle;

  /// No description provided for @auth_biometricLoginDesc.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition for faster and more secure login next time.'**
  String get auth_biometricLoginDesc;

  /// No description provided for @auth_biometricEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get auth_biometricEnable;

  /// No description provided for @auth_biometricMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get auth_biometricMaybeLater;

  /// No description provided for @auth_personalDataConsent.
  ///
  /// In en, this message translates to:
  /// **'Personal Data Consent'**
  String get auth_personalDataConsent;

  /// No description provided for @auth_personalDataConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Personal Data Processing Consent\n\nBy checking the box, you give your consent to the processing of your personal data in accordance with the legislation of the Republic of Kazakhstan.\n\nPurpose of data processing:\n- Identification and authentication of users;\n- Provision of application services;\n- Improvement of service quality;\n- Compliance with legal requirements.\n\nData collected:\n- First name and last name;\n- Email address (university domain);\n- Phone number (if provided);\n- Authentication credentials.\n\nYour data will be stored securely and will not be shared with third parties without your explicit consent, except as required by law.\n\nYou have the right to withdraw your consent at any time by contacting support. Withdrawal of consent does not affect the lawfulness of processing based on consent before its withdrawal.\n\nFor questions regarding personal data processing, please contact: support@nu.edu.kz'**
  String get auth_personalDataConsentBody;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifications_all;

  /// No description provided for @notifications_important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get notifications_important;

  /// No description provided for @notifications_unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifications_unread;

  /// No description provided for @notifications_markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifications_markAllRead;

  /// No description provided for @notifications_empty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifications_empty;

  /// No description provided for @notifications_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notifications_settings;

  /// No description provided for @notifications_push.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notifications_push;

  /// No description provided for @notifications_personalChats.
  ///
  /// In en, this message translates to:
  /// **'Personal Chats'**
  String get notifications_personalChats;

  /// No description provided for @notifications_news.
  ///
  /// In en, this message translates to:
  /// **'News & Promotions'**
  String get notifications_news;

  /// No description provided for @notifications_fintech.
  ///
  /// In en, this message translates to:
  /// **'Fintech'**
  String get notifications_fintech;

  /// No description provided for @notifications_jobFinder.
  ///
  /// In en, this message translates to:
  /// **'Job Finder'**
  String get notifications_jobFinder;

  /// No description provided for @notifications_courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get notifications_courses;

  /// No description provided for @notifications_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifications_today;

  /// No description provided for @notifications_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifications_yesterday;

  /// No description provided for @notifications_enablePush.
  ///
  /// In en, this message translates to:
  /// **'Enable all push notifications'**
  String get notifications_enablePush;

  /// No description provided for @notifications_categories.
  ///
  /// In en, this message translates to:
  /// **'Notification Categories'**
  String get notifications_categories;

  /// No description provided for @notifications_chatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new messages'**
  String get notifications_chatsSubtitle;

  /// No description provided for @notifications_newsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with news and offers'**
  String get notifications_newsSubtitle;

  /// No description provided for @notifications_fintechSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payments and transactions'**
  String get notifications_fintechSubtitle;

  /// No description provided for @notifications_jobsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New jobs matching your profile'**
  String get notifications_jobsSubtitle;

  /// No description provided for @notifications_coursesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Course updates and reminders'**
  String get notifications_coursesSubtitle;

  /// No description provided for @security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security_title;

  /// No description provided for @security_changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get security_changePassword;

  /// No description provided for @security_faceId.
  ///
  /// In en, this message translates to:
  /// **'Face ID'**
  String get security_faceId;

  /// No description provided for @security_pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get security_pinCode;

  /// No description provided for @security_biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric ID'**
  String get security_biometric;

  /// No description provided for @security_rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get security_rememberMe;

  /// No description provided for @security_currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get security_currentPassword;

  /// No description provided for @security_newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get security_newPassword;

  /// No description provided for @security_oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get security_oldPassword;

  /// No description provided for @security_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get security_confirmPassword;

  /// No description provided for @security_passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get security_passwordChangedSuccess;

  /// No description provided for @security_currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get security_currentPasswordIncorrect;

  /// No description provided for @security_passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get security_passwordMinLength;

  /// No description provided for @security_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get security_passwordsDoNotMatch;

  /// No description provided for @security_changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change password. Please try again.'**
  String get security_changePasswordFailed;

  /// No description provided for @security_changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN Code'**
  String get security_changePin;

  /// No description provided for @security_enterOldPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get security_enterOldPin;

  /// No description provided for @security_enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get security_enterNewPin;

  /// No description provided for @security_confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get security_confirmNewPin;

  /// No description provided for @security_pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get security_pinChanged;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_title;

  /// No description provided for @help_onlineChat.
  ///
  /// In en, this message translates to:
  /// **'Online Chat'**
  String get help_onlineChat;

  /// No description provided for @help_onlineChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support team'**
  String get help_onlineChatDesc;

  /// No description provided for @help_call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get help_call;

  /// No description provided for @help_callDesc.
  ///
  /// In en, this message translates to:
  /// **'Call our support line'**
  String get help_callDesc;

  /// No description provided for @help_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get help_email;

  /// No description provided for @help_emailDesc.
  ///
  /// In en, this message translates to:
  /// **'Send us an email'**
  String get help_emailDesc;

  /// No description provided for @help_supportPhone.
  ///
  /// In en, this message translates to:
  /// **'+7 (700) 123-4567'**
  String get help_supportPhone;

  /// No description provided for @help_supportEmail.
  ///
  /// In en, this message translates to:
  /// **'support@jasaim.kz'**
  String get help_supportEmail;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get about_title;

  /// No description provided for @about_rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate in Play Store'**
  String get about_rateApp;

  /// No description provided for @about_inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get about_inviteFriends;

  /// No description provided for @about_inviteFriendsMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out this amazing app!'**
  String get about_inviteFriendsMessage;

  /// No description provided for @about_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get about_version;

  /// No description provided for @settings_selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get settings_selectCity;

  /// No description provided for @settings_searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city...'**
  String get settings_searchCity;

  /// No description provided for @deleteAccount_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount_title;

  /// No description provided for @deleteAccount_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccount_warning;

  /// No description provided for @deleteAccount_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccount_confirm;

  /// No description provided for @deleteAccount_button.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccount_button;

  /// No description provided for @bottomNav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNav_home;

  /// No description provided for @bottomNav_hub.
  ///
  /// In en, this message translates to:
  /// **'Hub'**
  String get bottomNav_hub;

  /// No description provided for @bottomNav_access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get bottomNav_access;

  /// No description provided for @bottomNav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get bottomNav_profile;

  /// No description provided for @bottomNav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottomNav_settings;

  /// No description provided for @saltoAccess_title.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get saltoAccess_title;

  /// No description provided for @saltoAccess_ready.
  ///
  /// In en, this message translates to:
  /// **'Ready to open'**
  String get saltoAccess_ready;

  /// No description provided for @saltoAccess_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get saltoAccess_open;

  /// No description provided for @saltoAccess_scanning.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get saltoAccess_scanning;

  /// No description provided for @saltoAccess_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get saltoAccess_connecting;

  /// No description provided for @saltoAccess_granted.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get saltoAccess_granted;

  /// No description provided for @saltoAccess_rejected.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get saltoAccess_rejected;

  /// No description provided for @saltoAccess_hint.
  ///
  /// In en, this message translates to:
  /// **'Approach the turnstile and tap the button below'**
  String get saltoAccess_hint;

  /// No description provided for @saltoAccess_hintBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Make sure Bluetooth is enabled — it\'s required to connect to the turnstile'**
  String get saltoAccess_hintBluetooth;

  /// No description provided for @saltoAccess_noKey.
  ///
  /// In en, this message translates to:
  /// **'Key not available'**
  String get saltoAccess_noKey;

  /// No description provided for @saltoAccess_notConfigured.
  ///
  /// In en, this message translates to:
  /// **'SALTO access not configured. Contact support.'**
  String get saltoAccess_notConfigured;

  /// No description provided for @profileMenu_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileMenu_settings;

  /// No description provided for @profileMenu_myLevel.
  ///
  /// In en, this message translates to:
  /// **'My Level'**
  String get profileMenu_myLevel;

  /// No description provided for @profileMenu_showId.
  ///
  /// In en, this message translates to:
  /// **'Show ID'**
  String get profileMenu_showId;

  /// No description provided for @profileMenu_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileMenu_saved;

  /// No description provided for @profileMenu_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileMenu_statistics;

  /// No description provided for @profileMenu_findFriends.
  ///
  /// In en, this message translates to:
  /// **'Find Friends'**
  String get profileMenu_findFriends;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get settings_basic;

  /// No description provided for @settings_myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get settings_myProfile;

  /// No description provided for @settings_verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get settings_verification;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settings_info;

  /// No description provided for @settings_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get settings_city;

  /// No description provided for @settings_appLanguage.
  ///
  /// In en, this message translates to:
  /// **'Application Language'**
  String get settings_appLanguage;

  /// No description provided for @settings_interfaceMode.
  ///
  /// In en, this message translates to:
  /// **'Interface Mode'**
  String get settings_interfaceMode;

  /// No description provided for @settings_aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get settings_aboutApp;

  /// No description provided for @settings_help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get settings_help;

  /// No description provided for @settings_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settings_logout;

  /// No description provided for @settings_logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get settings_logoutConfirm;

  /// No description provided for @settings_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_light;

  /// No description provided for @settings_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_dark;

  /// No description provided for @profile_aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profile_aboutMe;

  /// No description provided for @profile_addAboutMe.
  ///
  /// In en, this message translates to:
  /// **'Add information about yourself'**
  String get profile_addAboutMe;

  /// No description provided for @profile_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profile_add;

  /// No description provided for @profile_academy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get profile_academy;

  /// No description provided for @profile_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profile_activity;

  /// No description provided for @profile_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get profile_expand;

  /// No description provided for @profile_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get profile_collapse;

  /// No description provided for @profile_completionTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile completion'**
  String get profile_completionTitle;

  /// No description provided for @profile_completionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} fields completed'**
  String profile_completionSubtitle(int completed, int total);

  /// No description provided for @profile_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profile_completed;

  /// No description provided for @profile_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get profile_message;

  /// No description provided for @profile_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get profile_actions;

  /// No description provided for @profile_bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get profile_bonuses;

  /// No description provided for @profile_tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get profile_tokens;

  /// No description provided for @profile_tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get profile_tasks;

  /// No description provided for @profile_activityPoints.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get profile_activityPoints;

  /// No description provided for @profile_rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get profile_rewards;

  /// No description provided for @profile_motivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get profile_motivation;

  /// No description provided for @profile_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profile_statistics;

  /// No description provided for @profile_profileViews.
  ///
  /// In en, this message translates to:
  /// **'Profile views'**
  String get profile_profileViews;

  /// No description provided for @profile_numbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get profile_numbers;

  /// No description provided for @profile_watched.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get profile_watched;

  /// No description provided for @profile_searched.
  ///
  /// In en, this message translates to:
  /// **'Searched'**
  String get profile_searched;

  /// No description provided for @profile_savedItems.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profile_savedItems;

  /// No description provided for @profile_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get profile_subscriptions;

  /// No description provided for @profile_subscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers'**
  String get profile_subscribers;

  /// No description provided for @profile_achievements.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get profile_achievements;

  /// No description provided for @profile_allAchievements.
  ///
  /// In en, this message translates to:
  /// **'All rewards'**
  String get profile_allAchievements;

  /// No description provided for @statistics_summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get statistics_summary;

  /// No description provided for @statistics_totalViews.
  ///
  /// In en, this message translates to:
  /// **'Total views'**
  String get statistics_totalViews;

  /// No description provided for @statistics_interactions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get statistics_interactions;

  /// No description provided for @statistics_messagesSent.
  ///
  /// In en, this message translates to:
  /// **'Messages sent'**
  String get statistics_messagesSent;

  /// No description provided for @statistics_contentShares.
  ///
  /// In en, this message translates to:
  /// **'Content shares'**
  String get statistics_contentShares;

  /// No description provided for @resume_workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get resume_workExperience;

  /// No description provided for @resume_addWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'Add information about work experience'**
  String get resume_addWorkExperience;

  /// No description provided for @resume_companyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get resume_companyName;

  /// No description provided for @resume_position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get resume_position;

  /// No description provided for @resume_startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get resume_startDate;

  /// No description provided for @resume_endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get resume_endDate;

  /// No description provided for @resume_present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get resume_present;

  /// No description provided for @resume_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get resume_description;

  /// No description provided for @resume_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get resume_skills;

  /// No description provided for @resume_addSkills.
  ///
  /// In en, this message translates to:
  /// **'Add information about skills'**
  String get resume_addSkills;

  /// No description provided for @resume_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get resume_education;

  /// No description provided for @resume_addEducation.
  ///
  /// In en, this message translates to:
  /// **'Add education information'**
  String get resume_addEducation;

  /// No description provided for @resume_universityName.
  ///
  /// In en, this message translates to:
  /// **'University name'**
  String get resume_universityName;

  /// No description provided for @resume_facultyName.
  ///
  /// In en, this message translates to:
  /// **'Faculty name'**
  String get resume_facultyName;

  /// No description provided for @resume_degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get resume_degree;

  /// No description provided for @resume_degreeBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s degree'**
  String get resume_degreeBachelor;

  /// No description provided for @resume_degreeMaster.
  ///
  /// In en, this message translates to:
  /// **'Master\'s degree'**
  String get resume_degreeMaster;

  /// No description provided for @resume_degreeDoctoral.
  ///
  /// In en, this message translates to:
  /// **'Doctoral / PhD'**
  String get resume_degreeDoctoral;

  /// No description provided for @resume_degreeAssociate.
  ///
  /// In en, this message translates to:
  /// **'Associate degree'**
  String get resume_degreeAssociate;

  /// No description provided for @resume_degreeCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get resume_degreeCertificate;

  /// No description provided for @resume_degreeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get resume_degreeOther;

  /// No description provided for @resume_degreeOtherSpecify.
  ///
  /// In en, this message translates to:
  /// **'Specify degree'**
  String get resume_degreeOtherSpecify;

  /// No description provided for @resume_academySkillsNote.
  ///
  /// In en, this message translates to:
  /// **'Skills are listed in the Skills section of your profile — they are shared for your whole profile.'**
  String get resume_academySkillsNote;

  /// No description provided for @resume_educationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your education. Check your connection and try again.'**
  String get resume_educationLoadFailed;

  /// No description provided for @resume_educationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your education. Please try again.'**
  String get resume_educationSaveFailed;

  /// No description provided for @resume_educationDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this entry. Please try again.'**
  String get resume_educationDeleteFailed;

  /// No description provided for @profile_errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get profile_errorNetwork;

  /// No description provided for @profile_errorSession.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get profile_errorSession;

  /// No description provided for @profile_errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get profile_errorGeneric;

  /// No description provided for @profile_activityPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This photo is too large. Maximum size is 5 MB.'**
  String get profile_activityPhotoTooLarge;

  /// No description provided for @profile_activityMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'You can add at most 5 photos per activity.'**
  String get profile_activityMaxPhotos;

  /// No description provided for @profile_activityPhotoRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected photo. Try another image.'**
  String get profile_activityPhotoRead;

  /// No description provided for @profile_activitySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your activity. Please try again.'**
  String get profile_activitySaveFailed;

  /// No description provided for @profile_activityDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this activity. Please try again.'**
  String get profile_activityDeleteFailed;

  /// No description provided for @profile_skillsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save skills. Please try again.'**
  String get profile_skillsSaveFailed;

  /// No description provided for @profile_skillsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load skills. Check your connection and try again.'**
  String get profile_skillsLoadFailed;

  /// No description provided for @profile_experienceSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save work experience. Please try again.'**
  String get profile_experienceSaveFailed;

  /// No description provided for @profile_experienceDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this entry. Please try again.'**
  String get profile_experienceDeleteFailed;

  /// No description provided for @profile_experienceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load work experience. Check your connection and try again.'**
  String get profile_experienceLoadFailed;

  /// No description provided for @profile_aboutMeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get profile_aboutMeSaveFailed;

  /// No description provided for @resume_gpa.
  ///
  /// In en, this message translates to:
  /// **'GPA'**
  String get resume_gpa;

  /// No description provided for @resume_activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get resume_activities;

  /// No description provided for @resume_addActivities.
  ///
  /// In en, this message translates to:
  /// **'Add information about activities'**
  String get resume_addActivities;

  /// No description provided for @resume_title.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume_title;

  /// No description provided for @resume_academyTab.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get resume_academyTab;

  /// No description provided for @resume_activityTab.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get resume_activityTab;

  /// No description provided for @resume_noWorkExperience.
  ///
  /// In en, this message translates to:
  /// **'No work experience added yet'**
  String get resume_noWorkExperience;

  /// No description provided for @resume_noEducation.
  ///
  /// In en, this message translates to:
  /// **'No education added yet'**
  String get resume_noEducation;

  /// No description provided for @resume_noSkills.
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get resume_noSkills;

  /// No description provided for @resume_noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get resume_noActivity;

  /// No description provided for @common_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get common_add;

  /// No description provided for @common_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get common_suggestions;

  /// No description provided for @jobFinder_title.
  ///
  /// In en, this message translates to:
  /// **'Job Finder'**
  String get jobFinder_title;

  /// No description provided for @jobFinder_findDreamJob.
  ///
  /// In en, this message translates to:
  /// **'Find your dream job'**
  String get jobFinder_findDreamJob;

  /// No description provided for @jobFinder_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get jobFinder_home;

  /// No description provided for @jobFinder_applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get jobFinder_applications;

  /// No description provided for @jobFinder_noApplications.
  ///
  /// In en, this message translates to:
  /// **'No applications yet'**
  String get jobFinder_noApplications;

  /// No description provided for @jobFinder_profileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile coming soon'**
  String get jobFinder_profileComingSoon;

  /// No description provided for @jobFinder_recentSearches.
  ///
  /// In en, this message translates to:
  /// **'You previously searched'**
  String get jobFinder_recentSearches;

  /// No description provided for @jobFinder_noJobsFound.
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get jobFinder_noJobsFound;

  /// No description provided for @jobFinder_jobDetail.
  ///
  /// In en, this message translates to:
  /// **'Job Detail'**
  String get jobFinder_jobDetail;

  /// No description provided for @jobFinder_jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job details'**
  String get jobFinder_jobDetails;

  /// No description provided for @jobFinder_aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'About company'**
  String get jobFinder_aboutCompany;

  /// No description provided for @jobFinder_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobFinder_description;

  /// No description provided for @jobFinder_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get jobFinder_apply;

  /// No description provided for @jobFinder_applicationSent.
  ///
  /// In en, this message translates to:
  /// **'Application sent successfully!'**
  String get jobFinder_applicationSent;

  /// No description provided for @jobFinder_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get jobFinder_filters;

  /// No description provided for @jobFinder_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get jobFinder_clearAll;

  /// No description provided for @jobFinder_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get jobFinder_location;

  /// No description provided for @jobFinder_enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter location'**
  String get jobFinder_enterLocation;

  /// No description provided for @jobFinder_jobType.
  ///
  /// In en, this message translates to:
  /// **'Job type'**
  String get jobFinder_jobType;

  /// No description provided for @jobFinder_salaryRange.
  ///
  /// In en, this message translates to:
  /// **'Salary range'**
  String get jobFinder_salaryRange;

  /// No description provided for @jobFinder_experienceLevel.
  ///
  /// In en, this message translates to:
  /// **'Experience level'**
  String get jobFinder_experienceLevel;

  /// No description provided for @jobFinder_applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get jobFinder_applyFilters;

  /// No description provided for @jobFinder_jobsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs'**
  String jobFinder_jobsCount(int count);

  /// No description provided for @jobFinder_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get jobFinder_explore;

  /// No description provided for @jobFinder_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get jobFinder_saved;

  /// No description provided for @jobFinder_noSavedJobs.
  ///
  /// In en, this message translates to:
  /// **'No saved jobs yet'**
  String get jobFinder_noSavedJobs;

  /// No description provided for @jobFinder_savedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jobs you save will appear here'**
  String get jobFinder_savedSubtitle;

  /// No description provided for @jobFinder_featuredJobs.
  ///
  /// In en, this message translates to:
  /// **'Featured Jobs'**
  String get jobFinder_featuredJobs;

  /// No description provided for @jobFinder_promotedJobs.
  ///
  /// In en, this message translates to:
  /// **'Promoted'**
  String get jobFinder_promotedJobs;

  /// No description provided for @jobFinder_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get jobFinder_allCategories;

  /// No description provided for @jobFinder_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get jobFinder_all;

  /// No description provided for @jobFinder_inProcess.
  ///
  /// In en, this message translates to:
  /// **'In Process'**
  String get jobFinder_inProcess;

  /// No description provided for @jobFinder_accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get jobFinder_accepted;

  /// No description provided for @jobFinder_declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get jobFinder_declined;

  /// No description provided for @jobFinder_appliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied on {date}'**
  String jobFinder_appliedOn(String date);

  /// No description provided for @jobFinder_alreadyApplied.
  ///
  /// In en, this message translates to:
  /// **'Already applied'**
  String get jobFinder_alreadyApplied;

  /// No description provided for @fintech_title.
  ///
  /// In en, this message translates to:
  /// **'Fintech'**
  String get fintech_title;

  /// No description provided for @fintech_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get fintech_home;

  /// No description provided for @fintech_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get fintech_payments;

  /// No description provided for @fintech_wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get fintech_wallet;

  /// No description provided for @fintech_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get fintech_actions;

  /// No description provided for @fintech_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get fintech_services;

  /// No description provided for @fintech_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get fintech_viewAll;

  /// No description provided for @fintech_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get fintech_finance;

  /// No description provided for @fintech_tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get fintech_tokens;

  /// No description provided for @fintech_nft.
  ///
  /// In en, this message translates to:
  /// **'NFT'**
  String get fintech_nft;

  /// No description provided for @fintech_discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get fintech_discounts;

  /// No description provided for @fintech_customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get fintech_customization;

  /// No description provided for @fintech_bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get fintech_bonuses;

  /// No description provided for @fintech_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get fintech_analytics;

  /// No description provided for @fintech_noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards yet'**
  String get fintech_noCards;

  /// No description provided for @fintech_noTokens.
  ///
  /// In en, this message translates to:
  /// **'No tokens yet'**
  String get fintech_noTokens;

  /// No description provided for @fintech_noNfts.
  ///
  /// In en, this message translates to:
  /// **'No NFTs yet'**
  String get fintech_noNfts;

  /// No description provided for @fintech_noDiscounts.
  ///
  /// In en, this message translates to:
  /// **'No discounts available'**
  String get fintech_noDiscounts;

  /// No description provided for @fintech_totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get fintech_totalBalance;

  /// No description provided for @fintech_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get fintech_preview;

  /// No description provided for @fintech_selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Card Color'**
  String get fintech_selectColor;

  /// No description provided for @fintech_colorSaved.
  ///
  /// In en, this message translates to:
  /// **'Card color saved!'**
  String get fintech_colorSaved;

  /// No description provided for @fintech_expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get fintech_expiringSoon;

  /// No description provided for @fintech_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get fintech_transfer;

  /// No description provided for @fintech_request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get fintech_request;

  /// No description provided for @fintech_inOut.
  ///
  /// In en, this message translates to:
  /// **'In & Out'**
  String get fintech_inOut;

  /// No description provided for @fintech_cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get fintech_cards;

  /// No description provided for @fintech_investing.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get fintech_investing;

  /// No description provided for @fintech_main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get fintech_main;

  /// No description provided for @fintech_addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get fintech_addCard;

  /// No description provided for @fintech_freezeCard.
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get fintech_freezeCard;

  /// No description provided for @fintech_unfreezeCard.
  ///
  /// In en, this message translates to:
  /// **'Unfreeze'**
  String get fintech_unfreezeCard;

  /// No description provided for @fintech_showDetails.
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get fintech_showDetails;

  /// No description provided for @fintech_cardSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get fintech_cardSettings;

  /// No description provided for @fintech_transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get fintech_transaction;

  /// No description provided for @fintech_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fintech_amount;

  /// No description provided for @fintech_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get fintech_completed;

  /// No description provided for @fintech_seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get fintech_seeAll;

  /// No description provided for @fintech_getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help with the card'**
  String get fintech_getHelp;

  /// No description provided for @fintech_cardFrozen.
  ///
  /// In en, this message translates to:
  /// **'Card frozen'**
  String get fintech_cardFrozen;

  /// No description provided for @fintech_cardUnfrozen.
  ///
  /// In en, this message translates to:
  /// **'Card unfrozen'**
  String get fintech_cardUnfrozen;

  /// No description provided for @fintech_labelCard.
  ///
  /// In en, this message translates to:
  /// **'Label card'**
  String get fintech_labelCard;

  /// No description provided for @fintech_cardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card label'**
  String get fintech_cardLabel;

  /// No description provided for @fintech_unblockCvv.
  ///
  /// In en, this message translates to:
  /// **'Unblock CVV'**
  String get fintech_unblockCvv;

  /// No description provided for @fintech_unblockCvvDesc.
  ///
  /// In en, this message translates to:
  /// **'Use after exceeding 3 tries'**
  String get fintech_unblockCvvDesc;

  /// No description provided for @fintech_terminateCard.
  ///
  /// In en, this message translates to:
  /// **'Terminate card'**
  String get fintech_terminateCard;

  /// No description provided for @fintech_terminateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate card?'**
  String get fintech_terminateConfirmTitle;

  /// No description provided for @fintech_terminateConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. The card will be permanently terminated and cannot be restored.'**
  String get fintech_terminateConfirmDesc;

  /// No description provided for @fintech_terminate.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get fintech_terminate;

  /// No description provided for @fintech_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fintech_cancel;

  /// No description provided for @fintech_customise.
  ///
  /// In en, this message translates to:
  /// **'Customise'**
  String get fintech_customise;

  /// No description provided for @fintech_cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get fintech_cvv;

  /// No description provided for @fintech_cvvUnblocked.
  ///
  /// In en, this message translates to:
  /// **'CVV unblocked'**
  String get fintech_cvvUnblocked;

  /// No description provided for @fintech_authRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get fintech_authRequired;

  /// No description provided for @fintech_labelSaved.
  ///
  /// In en, this message translates to:
  /// **'Card label saved'**
  String get fintech_labelSaved;

  /// No description provided for @fintech_cardDesign.
  ///
  /// In en, this message translates to:
  /// **'Card design'**
  String get fintech_cardDesign;

  /// No description provided for @fintech_designSaved.
  ///
  /// In en, this message translates to:
  /// **'Card design saved'**
  String get fintech_designSaved;

  /// No description provided for @fintech_cardTerminated.
  ///
  /// In en, this message translates to:
  /// **'Card terminated'**
  String get fintech_cardTerminated;

  /// No description provided for @fintech_cardLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter card label'**
  String get fintech_cardLabelHint;

  /// No description provided for @fintech_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get fintech_noTransactions;

  /// No description provided for @fintech_yourCards.
  ///
  /// In en, this message translates to:
  /// **'Your Cards'**
  String get fintech_yourCards;

  /// No description provided for @fintech_spendThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spend this month'**
  String get fintech_spendThisMonth;

  /// No description provided for @fintech_totalWealth.
  ///
  /// In en, this message translates to:
  /// **'Total Wealth'**
  String get fintech_totalWealth;

  /// No description provided for @fintech_savingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get fintech_savingsGoals;

  /// No description provided for @fintech_upcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get fintech_upcomingPayments;

  /// No description provided for @fintech_recentPayees.
  ///
  /// In en, this message translates to:
  /// **'Recent Payees'**
  String get fintech_recentPayees;

  /// No description provided for @fintech_transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get fintech_transactionHistory;

  /// No description provided for @fintech_ofBudget.
  ///
  /// In en, this message translates to:
  /// **'of budget'**
  String get fintech_ofBudget;

  /// No description provided for @fintech_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get fintech_today;

  /// No description provided for @fintech_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get fintech_tomorrow;

  /// No description provided for @fintech_inDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String fintech_inDays(int days);

  /// No description provided for @fintech_cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get fintech_cardDetails;

  /// No description provided for @fintech_accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get fintech_accountDetails;

  /// No description provided for @fintech_cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get fintech_cardholderName;

  /// No description provided for @fintech_cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get fintech_cardNumber;

  /// No description provided for @fintech_expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get fintech_expiryDate;

  /// No description provided for @fintech_cardType.
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get fintech_cardType;

  /// No description provided for @fintech_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fintech_currency;

  /// No description provided for @fintech_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get fintech_copied;

  /// No description provided for @fintech_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get fintech_share;

  /// No description provided for @fintech_topUp.
  ///
  /// In en, this message translates to:
  /// **'Top up'**
  String get fintech_topUp;

  /// No description provided for @fintech_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get fintech_balance;

  /// No description provided for @fintech_cardInfo.
  ///
  /// In en, this message translates to:
  /// **'Card Info'**
  String get fintech_cardInfo;

  /// No description provided for @fintech_limits.
  ///
  /// In en, this message translates to:
  /// **'Card Limits'**
  String get fintech_limits;

  /// No description provided for @fintech_limitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily & monthly spending limits'**
  String get fintech_limitsDesc;

  /// No description provided for @fintech_changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get fintech_changePin;

  /// No description provided for @fintech_changePinDesc.
  ///
  /// In en, this message translates to:
  /// **'Set a new PIN code'**
  String get fintech_changePinDesc;

  /// No description provided for @fintech_reissueCard.
  ///
  /// In en, this message translates to:
  /// **'Reissue Card'**
  String get fintech_reissueCard;

  /// No description provided for @fintech_reissueCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Order a replacement card'**
  String get fintech_reissueCardDesc;

  /// No description provided for @fintech_closeCard.
  ///
  /// In en, this message translates to:
  /// **'Close Card'**
  String get fintech_closeCard;

  /// No description provided for @fintech_closeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently close this card'**
  String get fintech_closeCardDesc;

  /// No description provided for @fintech_blockCard.
  ///
  /// In en, this message translates to:
  /// **'Block Card'**
  String get fintech_blockCard;

  /// No description provided for @fintech_cardBlocked.
  ///
  /// In en, this message translates to:
  /// **'Card is blocked'**
  String get fintech_cardBlocked;

  /// No description provided for @fintech_cardActive.
  ///
  /// In en, this message translates to:
  /// **'Card is active'**
  String get fintech_cardActive;

  /// No description provided for @fintech_securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security & Settings'**
  String get fintech_securitySettings;

  /// No description provided for @fintech_recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get fintech_recentTransactions;

  /// No description provided for @fintech_stocks.
  ///
  /// In en, this message translates to:
  /// **'Stocks'**
  String get fintech_stocks;

  /// No description provided for @fintech_crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get fintech_crypto;

  /// No description provided for @fintech_portfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get fintech_portfolio;

  /// No description provided for @fintech_totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get fintech_totalValue;

  /// No description provided for @fintech_totalGain.
  ///
  /// In en, this message translates to:
  /// **'Total Gain'**
  String get fintech_totalGain;

  /// No description provided for @fintech_holdings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get fintech_holdings;

  /// No description provided for @fintech_popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get fintech_popular;

  /// No description provided for @fintech_marketCap.
  ///
  /// In en, this message translates to:
  /// **'Market Cap'**
  String get fintech_marketCap;

  /// No description provided for @fintech_noStocks.
  ///
  /// In en, this message translates to:
  /// **'No stocks available'**
  String get fintech_noStocks;

  /// No description provided for @fintech_noCrypto.
  ///
  /// In en, this message translates to:
  /// **'No crypto available'**
  String get fintech_noCrypto;

  /// No description provided for @fintech_buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get fintech_buy;

  /// No description provided for @fintech_sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get fintech_sell;

  /// No description provided for @fintech_avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get fintech_avg;

  /// No description provided for @fintech_qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get fintech_qty;

  /// No description provided for @fintech_closeCardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close card?'**
  String get fintech_closeCardConfirmTitle;

  /// No description provided for @fintech_closeCardConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This card will be permanently closed. Any remaining balance will be transferred to your main account.'**
  String get fintech_closeCardConfirmDesc;

  /// No description provided for @fintech_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fintech_close;

  /// No description provided for @fintech_cashback.
  ///
  /// In en, this message translates to:
  /// **'Cashback'**
  String get fintech_cashback;

  /// No description provided for @fintech_cashbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Up to 3% on purchases'**
  String get fintech_cashbackDesc;

  /// No description provided for @fintech_addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get fintech_addMoney;

  /// No description provided for @fintech_exchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get fintech_exchange;

  /// No description provided for @fintech_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fintech_details;

  /// No description provided for @fintech_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get fintech_more;

  /// No description provided for @fintech_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get fintech_accounts;

  /// No description provided for @fintech_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get fintech_searchHint;

  /// No description provided for @fintech_inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get fintech_inviteFriends;

  /// No description provided for @fintech_inviteDesc.
  ///
  /// In en, this message translates to:
  /// **'Get bonus for each friend'**
  String get fintech_inviteDesc;

  /// No description provided for @fintech_widgetsSection.
  ///
  /// In en, this message translates to:
  /// **'Widgets'**
  String get fintech_widgetsSection;

  /// No description provided for @fintech_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get fintech_savings;

  /// No description provided for @fintech_insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get fintech_insurance;

  /// No description provided for @fintech_budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get fintech_budget;

  /// No description provided for @fintech_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get fintech_remaining;

  /// No description provided for @fintech_categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get fintech_categoryBreakdown;

  /// No description provided for @fintech_payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get fintech_payNow;

  /// No description provided for @fintech_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get fintech_schedule;

  /// No description provided for @fintech_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get fintech_paid;

  /// No description provided for @fintech_unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get fintech_unpaid;

  /// No description provided for @fintech_sendMoney.
  ///
  /// In en, this message translates to:
  /// **'Send money'**
  String get fintech_sendMoney;

  /// No description provided for @fintech_enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get fintech_enterAmount;

  /// No description provided for @fintech_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get fintech_send;

  /// No description provided for @fintech_lastTransfer.
  ///
  /// In en, this message translates to:
  /// **'Last transfer'**
  String get fintech_lastTransfer;

  /// No description provided for @fintech_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get fintech_income;

  /// No description provided for @fintech_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get fintech_expense;

  /// No description provided for @fintech_repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get fintech_repeat;

  /// No description provided for @fintech_wealthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Account breakdown'**
  String get fintech_wealthBreakdown;

  /// No description provided for @fintech_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get fintech_manage;

  /// No description provided for @fintech_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get fintech_history;

  /// No description provided for @fintech_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fintech_status;

  /// No description provided for @fintech_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fintech_date;

  /// No description provided for @fintech_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fintech_category;

  /// No description provided for @fintech_trade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get fintech_trade;

  /// No description provided for @fintech_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get fintech_withdraw;

  /// No description provided for @fintech_tradingNews.
  ///
  /// In en, this message translates to:
  /// **'Trading News'**
  String get fintech_tradingNews;

  /// No description provided for @fintech_topMovers.
  ///
  /// In en, this message translates to:
  /// **'Top Movers'**
  String get fintech_topMovers;

  /// No description provided for @fintech_marketOverview.
  ///
  /// In en, this message translates to:
  /// **'Market Overview'**
  String get fintech_marketOverview;

  /// No description provided for @fintech_readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get fintech_readMore;

  /// No description provided for @fintech_bullish.
  ///
  /// In en, this message translates to:
  /// **'Bullish'**
  String get fintech_bullish;

  /// No description provided for @fintech_bearish.
  ///
  /// In en, this message translates to:
  /// **'Bearish'**
  String get fintech_bearish;

  /// No description provided for @fintech_neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get fintech_neutral;

  /// No description provided for @fintech_yourPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Your Portfolio'**
  String get fintech_yourPortfolio;

  /// No description provided for @gamification_myLevel.
  ///
  /// In en, this message translates to:
  /// **'My Level'**
  String get gamification_myLevel;

  /// No description provided for @gamification_level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get gamification_level;

  /// No description provided for @gamification_levelUp.
  ///
  /// In en, this message translates to:
  /// **'🎉 Level Up!'**
  String get gamification_levelUp;

  /// No description provided for @gamification_toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'to next level'**
  String get gamification_toNextLevel;

  /// No description provided for @gamification_points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get gamification_points;

  /// No description provided for @gamification_ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get gamification_ranking;

  /// No description provided for @gamification_tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get gamification_tasks;

  /// No description provided for @gamification_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get gamification_activity;

  /// No description provided for @gamification_achievements.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get gamification_achievements;

  /// No description provided for @gamification_motivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get gamification_motivation;

  /// No description provided for @gamification_of.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get gamification_of;

  /// No description provided for @gamification_participants.
  ///
  /// In en, this message translates to:
  /// **'participants'**
  String get gamification_participants;

  /// No description provided for @gamification_taskCount.
  ///
  /// In en, this message translates to:
  /// **'Task count'**
  String get gamification_taskCount;

  /// No description provided for @gamification_noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get gamification_noTasks;

  /// No description provided for @gamification_noPointsHistory.
  ///
  /// In en, this message translates to:
  /// **'No points history'**
  String get gamification_noPointsHistory;

  /// No description provided for @gamification_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get gamification_today;

  /// No description provided for @gamification_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get gamification_yesterday;

  /// No description provided for @gamification_earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get gamification_earlier;

  /// No description provided for @gamification_achievementsEarned.
  ///
  /// In en, this message translates to:
  /// **'rewards earned'**
  String get gamification_achievementsEarned;

  /// No description provided for @gamification_noAchievements.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet'**
  String get gamification_noAchievements;

  /// No description provided for @gamification_goalsCompleted.
  ///
  /// In en, this message translates to:
  /// **'goals completed'**
  String get gamification_goalsCompleted;

  /// No description provided for @gamification_yourGoals.
  ///
  /// In en, this message translates to:
  /// **'Your Goals'**
  String get gamification_yourGoals;

  /// No description provided for @gamification_seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get gamification_seeAll;

  /// No description provided for @gamification_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get gamification_noGoals;

  /// No description provided for @gamification_noGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first goal and start tracking your progress'**
  String get gamification_noGoalsDesc;

  /// No description provided for @gamification_noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get gamification_noActivity;

  /// No description provided for @gamification_week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get gamification_week;

  /// No description provided for @gamification_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get gamification_month;

  /// No description provided for @gamification_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get gamification_year;

  /// No description provided for @gamification_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get gamification_expand;

  /// No description provided for @gamification_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get gamification_collapse;

  /// No description provided for @gamification_addActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get gamification_addActivity;

  /// No description provided for @gamification_activityName.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get gamification_activityName;

  /// No description provided for @gamification_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get gamification_date;

  /// No description provided for @gamification_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get gamification_description;

  /// No description provided for @gamification_attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get gamification_attachPhoto;

  /// No description provided for @gamification_activityPhoto.
  ///
  /// In en, this message translates to:
  /// **'Activity photo'**
  String get gamification_activityPhoto;

  /// No description provided for @gamification_awards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get gamification_awards;

  /// No description provided for @gamification_totalAwards.
  ///
  /// In en, this message translates to:
  /// **'Total Rewards'**
  String get gamification_totalAwards;

  /// No description provided for @gamification_collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get gamification_collected;

  /// No description provided for @gamification_collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get gamification_collection;

  /// No description provided for @gamification_totalAchievements.
  ///
  /// In en, this message translates to:
  /// **'Total Rewards'**
  String get gamification_totalAchievements;

  /// No description provided for @gamification_averageLevel.
  ///
  /// In en, this message translates to:
  /// **'Average Level'**
  String get gamification_averageLevel;

  /// No description provided for @gamification_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get gamification_goals;

  /// No description provided for @gamification_encouragement.
  ///
  /// In en, this message translates to:
  /// **'Encouragement'**
  String get gamification_encouragement;

  /// No description provided for @gamification_addGoal.
  ///
  /// In en, this message translates to:
  /// **'Add Goal'**
  String get gamification_addGoal;

  /// No description provided for @motivation_goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Title'**
  String get motivation_goalTitle;

  /// No description provided for @motivation_goalDescription.
  ///
  /// In en, this message translates to:
  /// **'Goal Description'**
  String get motivation_goalDescription;

  /// No description provided for @motivation_targetValue.
  ///
  /// In en, this message translates to:
  /// **'Target Value'**
  String get motivation_targetValue;

  /// No description provided for @motivation_unit.
  ///
  /// In en, this message translates to:
  /// **'Unit (lessons, points, days, etc.)'**
  String get motivation_unit;

  /// No description provided for @gamification_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get gamification_actions;

  /// No description provided for @gamification_bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get gamification_bonuses;

  /// No description provided for @gamification_tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get gamification_tokens;

  /// No description provided for @gamification_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get gamification_history;

  /// No description provided for @gamification_bonusesInfo.
  ///
  /// In en, this message translates to:
  /// **'Bonuses are points that you earn for completing tasks and achievements. They can be used to unlock new features and rewards.'**
  String get gamification_bonusesInfo;

  /// No description provided for @gamification_tokensInfo.
  ///
  /// In en, this message translates to:
  /// **'Tokens are digital currency that you earn for participating in activities. They can be exchanged for prizes and special offers.'**
  String get gamification_tokensInfo;

  /// No description provided for @gamification_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gamification_filterAll;

  /// No description provided for @gamification_filterDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get gamification_filterDaily;

  /// No description provided for @gamification_filterWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get gamification_filterWeekly;

  /// No description provided for @gamification_filterAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get gamification_filterAchievements;

  /// No description provided for @gamification_typeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get gamification_typeDaily;

  /// No description provided for @gamification_typeWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get gamification_typeWeekly;

  /// No description provided for @gamification_typeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get gamification_typeAchievement;

  /// No description provided for @gamification_typeSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get gamification_typeSpecial;

  /// No description provided for @gamification_typeBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get gamification_typeBonus;

  /// No description provided for @gamification_typeToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get gamification_typeToken;

  /// No description provided for @gamification_allTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'All tasks completed! 🎉'**
  String get gamification_allTasksCompleted;

  /// No description provided for @gamification_errorLoadingTasks.
  ///
  /// In en, this message translates to:
  /// **'Error loading tasks'**
  String get gamification_errorLoadingTasks;

  /// No description provided for @gamification_completeTasksToEarn.
  ///
  /// In en, this message translates to:
  /// **'Complete tasks to earn rewards!'**
  String get gamification_completeTasksToEarn;

  /// No description provided for @gamification_allAchievements.
  ///
  /// In en, this message translates to:
  /// **'All Rewards'**
  String get gamification_allAchievements;

  /// No description provided for @social_followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get social_followers;

  /// No description provided for @social_following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get social_following;

  /// No description provided for @social_follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get social_follow;

  /// No description provided for @social_unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get social_unfollow;

  /// No description provided for @social_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get social_message;

  /// No description provided for @social_rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get social_rating;

  /// No description provided for @social_searchFollowers.
  ///
  /// In en, this message translates to:
  /// **'Search followers...'**
  String get social_searchFollowers;

  /// No description provided for @social_searchFollowing.
  ///
  /// In en, this message translates to:
  /// **'Search following...'**
  String get social_searchFollowing;

  /// No description provided for @social_noFollowers.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get social_noFollowers;

  /// No description provided for @social_noFollowing.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone'**
  String get social_noFollowing;

  /// No description provided for @social_nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get social_nothingFound;

  /// No description provided for @social_findUsers.
  ///
  /// In en, this message translates to:
  /// **'Find interesting users'**
  String get social_findUsers;

  /// No description provided for @social_unfollowConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfollow?'**
  String get social_unfollowConfirmTitle;

  /// No description provided for @social_unfollowConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unfollow {userName}?'**
  String social_unfollowConfirmMessage(Object userName);

  /// No description provided for @social_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get social_cancel;

  /// No description provided for @social_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get social_userNotFound;

  /// No description provided for @social_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get social_back;

  /// No description provided for @social_aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get social_aboutMe;

  /// No description provided for @social_workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get social_workExperience;

  /// No description provided for @social_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get social_skills;

  /// No description provided for @social_academy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get social_academy;

  /// No description provided for @social_shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get social_shareProfile;

  /// No description provided for @social_copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get social_copyLink;

  /// No description provided for @social_block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get social_block;

  /// No description provided for @social_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get social_messages;

  /// No description provided for @social_noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get social_noMessages;

  /// No description provided for @social_startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get social_startConversation;

  /// No description provided for @social_sendFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send the first message'**
  String get social_sendFirstMessage;

  /// No description provided for @social_messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get social_messageHint;

  /// No description provided for @social_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get social_today;

  /// No description provided for @social_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get social_yesterday;

  /// No description provided for @social_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get social_online;

  /// No description provided for @social_openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get social_openProfile;

  /// No description provided for @social_searchInChat.
  ///
  /// In en, this message translates to:
  /// **'Search in chat'**
  String get social_searchInChat;

  /// No description provided for @social_muteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get social_muteNotifications;

  /// No description provided for @social_deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get social_deleteChat;

  /// No description provided for @social_searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get social_searchUsers;

  /// No description provided for @social_enterNameOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter name or username...'**
  String get social_enterNameOrUsername;

  /// No description provided for @social_findUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Find users'**
  String get social_findUsersTitle;

  /// No description provided for @social_tryAnotherQuery.
  ///
  /// In en, this message translates to:
  /// **'Try another query'**
  String get social_tryAnotherQuery;

  /// No description provided for @social_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get social_subscriptions;

  /// No description provided for @social_present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get social_present;

  /// No description provided for @web_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get web_loading;

  /// No description provided for @web_error_title.
  ///
  /// In en, this message translates to:
  /// **'Unable to load page'**
  String get web_error_title;

  /// No description provided for @web_error_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again'**
  String get web_error_subtitle;

  /// No description provided for @web_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get web_retry;

  /// No description provided for @web_external_link_title.
  ///
  /// In en, this message translates to:
  /// **'Open External Link?'**
  String get web_external_link_title;

  /// No description provided for @web_external_link_message.
  ///
  /// In en, this message translates to:
  /// **'This link will open in your browser'**
  String get web_external_link_message;

  /// No description provided for @web_external_link_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get web_external_link_open;

  /// No description provided for @web_external_link_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get web_external_link_cancel;

  /// No description provided for @resume_currentlyWorkingHere.
  ///
  /// In en, this message translates to:
  /// **'I am currently working here'**
  String get resume_currentlyWorkingHere;

  /// No description provided for @resume_currentlyStudying.
  ///
  /// In en, this message translates to:
  /// **'I am currently studying'**
  String get resume_currentlyStudying;

  /// No description provided for @resume_selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get resume_selectDate;

  /// No description provided for @resume_attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get resume_attachPhoto;

  /// No description provided for @resume_activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get resume_activityTitle;

  /// No description provided for @resume_activityName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get resume_activityName;

  /// No description provided for @resume_activityDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get resume_activityDate;

  /// No description provided for @resume_institution.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get resume_institution;

  /// No description provided for @resume_degreeWithExample.
  ///
  /// In en, this message translates to:
  /// **'Degree (Bachelor, etc.)'**
  String get resume_degreeWithExample;

  /// No description provided for @resume_specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get resume_specialization;

  /// No description provided for @resume_gpaScore.
  ///
  /// In en, this message translates to:
  /// **'GPA Score'**
  String get resume_gpaScore;

  /// No description provided for @resume_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get resume_recommended;

  /// No description provided for @points_bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get points_bonuses;

  /// No description provided for @points_tokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get points_tokens;

  /// No description provided for @points_bonusesInfo.
  ///
  /// In en, this message translates to:
  /// **'Bonuses - what they are for, how to use them and what you can do with them'**
  String get points_bonusesInfo;

  /// No description provided for @points_bonusesExchange.
  ///
  /// In en, this message translates to:
  /// **'Bonuses can be exchanged for tokens at the rate of 100 Bonuses = 1 token'**
  String get points_bonusesExchange;

  /// No description provided for @points_tokensInfo.
  ///
  /// In en, this message translates to:
  /// **'Tokens - what they are for, how to use them and what you can do with them'**
  String get points_tokensInfo;

  /// No description provided for @points_tokensExchange.
  ///
  /// In en, this message translates to:
  /// **'Tokens can be exchanged for money or spent inside the app at the rate of 1 token = 100 tenge'**
  String get points_tokensExchange;

  /// No description provided for @points_filterBonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get points_filterBonuses;

  /// No description provided for @points_filterTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get points_filterTokens;

  /// No description provided for @salto_mobileAccess.
  ///
  /// In en, this message translates to:
  /// **'Mobile Access'**
  String get salto_mobileAccess;

  /// No description provided for @salto_mobileAccessAlreadyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Mobile access is already enabled'**
  String get salto_mobileAccessAlreadyEnabled;

  /// No description provided for @salto_enableAccessInApp.
  ///
  /// In en, this message translates to:
  /// **'Enable access in the app'**
  String get salto_enableAccessInApp;

  /// No description provided for @salto_mobileKeyAlreadyIssued.
  ///
  /// In en, this message translates to:
  /// **'A mobile SALTO key has already been issued for this account. Continue setting up the app.'**
  String get salto_mobileKeyAlreadyIssued;

  /// No description provided for @salto_switchToMobileKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'After confirmation, this account will be switched from the physical card to a mobile SALTO key for turnstile access.'**
  String get salto_switchToMobileKeyDescription;

  /// No description provided for @salto_physicalCardWarning.
  ///
  /// In en, this message translates to:
  /// **'Important: after activation, the physical card will stop working for turnstile access.'**
  String get salto_physicalCardWarning;

  /// No description provided for @salto_activateInApp.
  ///
  /// In en, this message translates to:
  /// **'Activate in the app'**
  String get salto_activateInApp;

  /// No description provided for @salto_skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get salto_skipForNow;

  /// No description provided for @salto_switchAccessConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch access to the phone?'**
  String get salto_switchAccessConfirmTitle;

  /// No description provided for @salto_switchAccessConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'The physical card will be disabled for turnstile access. After that, access will work only through the app.'**
  String get salto_switchAccessConfirmDescription;

  /// No description provided for @salto_yesSwitch.
  ///
  /// In en, this message translates to:
  /// **'Yes, switch'**
  String get salto_yesSwitch;

  /// No description provided for @editProfile_avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get editProfile_avatarUpdated;

  /// No description provided for @editProfile_usernameFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-30 chars and use only lowercase letters, digits, and _'**
  String get editProfile_usernameFormatHint;

  /// No description provided for @editProfile_avatarUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile photo'**
  String get editProfile_avatarUpdateFailed;

  /// No description provided for @hub_attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get hub_attendance;

  /// No description provided for @hub_attendanceStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get hub_attendanceStudent;

  /// No description provided for @hub_attendanceTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get hub_attendanceTeacher;

  /// No description provided for @hub_classroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get hub_classroom;

  /// No description provided for @tasks_special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get tasks_special;

  /// No description provided for @tasks_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily Tasks'**
  String get tasks_daily;

  /// No description provided for @tasks_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly Tasks'**
  String get tasks_weekly;

  /// No description provided for @tasks_achievements.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get tasks_achievements;

  /// No description provided for @tasks_claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get tasks_claim;

  /// No description provided for @tasks_inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get tasks_inProgress;

  /// No description provided for @tasks_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tasks_completed;

  /// No description provided for @tasks_toNextLevel.
  ///
  /// In en, this message translates to:
  /// **'to next level'**
  String get tasks_toNextLevel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pin_createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create PIN code'**
  String get pin_createTitle;

  /// No description provided for @pin_confirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN code'**
  String get pin_confirmTitle;

  /// No description provided for @pin_createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN for quick access'**
  String get pin_createSubtitle;

  /// No description provided for @pin_confirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter the PIN code'**
  String get pin_confirmSubtitle;

  /// No description provided for @pin_mismatchError.
  ///
  /// In en, this message translates to:
  /// **'PIN codes do not match'**
  String get pin_mismatchError;

  /// No description provided for @pin_enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN code'**
  String get pin_enterTitle;

  /// No description provided for @pin_enterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to continue'**
  String get pin_enterSubtitle;

  /// No description provided for @pin_biometricReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity'**
  String get pin_biometricReason;

  /// No description provided for @pin_lockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds} sec'**
  String pin_lockedMessage(int seconds);

  /// No description provided for @pin_incorrectError.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pin_incorrectError;

  /// No description provided for @pin_switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get pin_switchAccount;

  /// No description provided for @pin_biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric is unavailable. Please enable it in your device settings.'**
  String get pin_biometricUnavailable;

  /// No description provided for @pin_sessionRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh your session. Check your internet and try again.'**
  String get pin_sessionRefreshFailed;

  /// No description provided for @pin_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again with your credentials.'**
  String get pin_sessionExpired;

  /// No description provided for @pin_signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get pin_signingIn;

  /// No description provided for @biometric_setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get biometric_setupTitle;

  /// No description provided for @biometric_setupDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable Face ID or Fingerprint for faster login without entering a PIN code'**
  String get biometric_setupDescription;

  /// No description provided for @biometric_setupReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to enable biometric login'**
  String get biometric_setupReason;

  /// No description provided for @biometric_setupEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get biometric_setupEnable;

  /// No description provided for @biometric_setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get biometric_setupSkip;

  /// No description provided for @svc_title.
  ///
  /// In en, this message translates to:
  /// **'Meal Pass'**
  String get svc_title;

  /// No description provided for @svc_weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get svc_weeklyProgress;

  /// No description provided for @svc_mealsUsed.
  ///
  /// In en, this message translates to:
  /// **'meals used'**
  String get svc_mealsUsed;

  /// No description provided for @svc_remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get svc_remaining;

  /// No description provided for @svc_todayUsage.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Usage'**
  String get svc_todayUsage;

  /// No description provided for @svc_todayMenu.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Menu'**
  String get svc_todayMenu;

  /// No description provided for @svc_scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to Get Meal'**
  String get svc_scanQr;

  /// No description provided for @svc_limitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached'**
  String get svc_limitReached;

  /// No description provided for @svc_statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get svc_statusActive;

  /// No description provided for @svc_accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get svc_accessDenied;

  /// No description provided for @svc_accessDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to Meal Pass. Contact administration for details.'**
  String get svc_accessDeniedHint;

  /// No description provided for @svc_mealRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Meal redeemed successfully!'**
  String get svc_mealRedeemed;

  /// No description provided for @svc_pointCamera.
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code'**
  String get svc_pointCamera;

  /// No description provided for @svc_cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan QR codes'**
  String get svc_cameraPermissionDenied;

  /// No description provided for @svc_daysUsed.
  ///
  /// In en, this message translates to:
  /// **'Days used'**
  String get svc_daysUsed;

  /// No description provided for @svc_analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Pass Analytics'**
  String get svc_analyticsTitle;

  /// No description provided for @svc_totalRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered Students'**
  String get svc_totalRegistered;

  /// No description provided for @svc_totalActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get svc_totalActiveUsers;

  /// No description provided for @svc_totalMeals.
  ///
  /// In en, this message translates to:
  /// **'Total Meals'**
  String get svc_totalMeals;

  /// No description provided for @svc_totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get svc_totalSpent;

  /// No description provided for @svc_mealsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Meals Breakdown'**
  String get svc_mealsBreakdown;

  /// No description provided for @svc_spendingOverTime.
  ///
  /// In en, this message translates to:
  /// **'Spending Over Time'**
  String get svc_spendingOverTime;

  /// No description provided for @svc_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get svc_transactions;

  /// No description provided for @svc_student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get svc_student;

  /// No description provided for @svc_meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get svc_meal;

  /// No description provided for @svc_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get svc_category;

  /// No description provided for @svc_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get svc_price;

  /// No description provided for @svc_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get svc_date;

  /// No description provided for @svc_breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get svc_breakfast;

  /// No description provided for @svc_lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get svc_lunch;

  /// No description provided for @svc_dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get svc_dinner;

  /// No description provided for @svc_dailyCheck.
  ///
  /// In en, this message translates to:
  /// **'Daily check'**
  String get svc_dailyCheck;

  /// No description provided for @svc_mealSlots.
  ///
  /// In en, this message translates to:
  /// **'Meal Slots'**
  String get svc_mealSlots;

  /// No description provided for @svc_skippedReminder.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get svc_skippedReminder;

  /// No description provided for @svc_noActiveSlot.
  ///
  /// In en, this message translates to:
  /// **'No Active Slot'**
  String get svc_noActiveSlot;

  /// No description provided for @svc_slotAlreadyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Slot Already Redeemed'**
  String get svc_slotAlreadyRedeemed;

  /// No description provided for @svc_fixedMenu.
  ///
  /// In en, this message translates to:
  /// **'Fixed Menu'**
  String get svc_fixedMenu;

  /// No description provided for @svc_availableMeals.
  ///
  /// In en, this message translates to:
  /// **'Available Meals'**
  String get svc_availableMeals;

  /// No description provided for @svc_selectMeal.
  ///
  /// In en, this message translates to:
  /// **'Select Meal'**
  String get svc_selectMeal;

  /// No description provided for @svc_categoryDistribution.
  ///
  /// In en, this message translates to:
  /// **'Category Distribution'**
  String get svc_categoryDistribution;

  /// No description provided for @svc_exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get svc_exportPdf;

  /// No description provided for @svc_avgPerStudent.
  ///
  /// In en, this message translates to:
  /// **'Avg per Student'**
  String get svc_avgPerStudent;

  /// No description provided for @svc_participationRate.
  ///
  /// In en, this message translates to:
  /// **'Participation Rate'**
  String get svc_participationRate;

  /// No description provided for @svc_analyticsReport.
  ///
  /// In en, this message translates to:
  /// **'Meal Pass Analytics Report'**
  String get svc_analyticsReport;

  /// No description provided for @svc_dailySpending.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending'**
  String get svc_dailySpending;

  /// No description provided for @svc_spendingPerStudent.
  ///
  /// In en, this message translates to:
  /// **'Spending per Student'**
  String get svc_spendingPerStudent;

  /// No description provided for @svc_participation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get svc_participation;

  /// No description provided for @svc_studentId.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get svc_studentId;

  /// No description provided for @svc_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get svc_inactive;

  /// No description provided for @svc_meals.
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get svc_meals;

  /// No description provided for @svc_avg.
  ///
  /// In en, this message translates to:
  /// **'avg'**
  String get svc_avg;

  /// No description provided for @svc_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get svc_total;

  /// No description provided for @svc_showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get svc_showMore;

  /// No description provided for @svc_allTransactionsShown.
  ///
  /// In en, this message translates to:
  /// **'All transactions shown'**
  String get svc_allTransactionsShown;

  /// No description provided for @svc_mealReceipt.
  ///
  /// In en, this message translates to:
  /// **'Meal Receipt'**
  String get svc_mealReceipt;

  /// No description provided for @svc_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get svc_time;

  /// No description provided for @svc_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get svc_close;

  /// No description provided for @svc_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get svc_name;

  /// No description provided for @svc_combo.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get svc_combo;

  /// No description provided for @svc_mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get svc_mon;

  /// No description provided for @svc_tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get svc_tue;

  /// No description provided for @svc_wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get svc_wed;

  /// No description provided for @svc_thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get svc_thu;

  /// No description provided for @svc_fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get svc_fri;

  /// No description provided for @svc_sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get svc_sat;

  /// No description provided for @svc_sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get svc_sun;

  /// No description provided for @svc_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get svc_faq;

  /// No description provided for @svc_faqHowToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use Meal Pass?'**
  String get svc_faqHowToUse;

  /// No description provided for @svc_faqHowToUseContent.
  ///
  /// In en, this message translates to:
  /// **'1. Go to the dining hall during meal hours\n2. Open the app and tap \"Scan QR\"\n3. Point your camera at the QR code\n4. Wait for confirmation\n5. Enjoy your meal!'**
  String get svc_faqHowToUseContent;

  /// No description provided for @svc_faqTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Meal time slots'**
  String get svc_faqTimeSlots;

  /// No description provided for @svc_faqTimeSlotsContent.
  ///
  /// In en, this message translates to:
  /// **'Breakfast: 08:00 – 12:00\nLunch: 12:00 – 17:00\nDinner: 17:00 – 00:00'**
  String get svc_faqTimeSlotsContent;

  /// No description provided for @svc_mealReminders.
  ///
  /// In en, this message translates to:
  /// **'Meal Reminders'**
  String get svc_mealReminders;

  /// No description provided for @svc_reminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified before each meal so you don\'t forget'**
  String get svc_reminderDescription;

  /// No description provided for @svc_reminderBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast reminder'**
  String get svc_reminderBreakfast;

  /// No description provided for @svc_reminderLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch reminder'**
  String get svc_reminderLunch;

  /// No description provided for @svc_reminderDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner reminder'**
  String get svc_reminderDinner;

  /// No description provided for @svc_meal_reminder_open.
  ///
  /// In en, this message translates to:
  /// **'{mealName} is ready — don\'t forget to grab it!'**
  String svc_meal_reminder_open(String mealName);

  /// No description provided for @svc_meal_reminder_closing.
  ///
  /// In en, this message translates to:
  /// **'Only 30 minutes left to get your {mealName} — don\'t miss it!'**
  String svc_meal_reminder_closing(String mealName);

  /// No description provided for @svc_successTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Redeemed!'**
  String get svc_successTitle;

  /// No description provided for @svc_successSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your meal has been successfully redeemed. Enjoy!'**
  String get svc_successSubtitle;

  /// No description provided for @svc_backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get svc_backToDashboard;

  /// No description provided for @svc_weeklyUsage.
  ///
  /// In en, this message translates to:
  /// **'Weekly Meal Usage'**
  String get svc_weeklyUsage;

  /// No description provided for @svc_weeklyLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'Weekly limit reached. No more meals can be confirmed.'**
  String get svc_weeklyLimitWarning;

  /// No description provided for @svc_tomorrowConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Meal Confirmation for Tomorrow'**
  String get svc_tomorrowConfirmation;

  /// No description provided for @svc_confirmationCutoff.
  ///
  /// In en, this message translates to:
  /// **'Confirmation closes at 23:59 today'**
  String get svc_confirmationCutoff;

  /// No description provided for @svc_confirmationDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'Deadline passed — confirmation closed after 23:59'**
  String get svc_confirmationDeadlinePassed;

  /// No description provided for @svc_confirmSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save Confirmation'**
  String get svc_confirmSubmit;

  /// No description provided for @svc_confirmSaved.
  ///
  /// In en, this message translates to:
  /// **'Meal confirmation saved!'**
  String get svc_confirmSaved;

  /// No description provided for @svc_confirmSavedBadge.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get svc_confirmSavedBadge;

  /// No description provided for @svc_missedMealComp.
  ///
  /// In en, this message translates to:
  /// **'Missed Meal Compensation'**
  String get svc_missedMealComp;

  /// No description provided for @svc_missedMealCompSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a medical certificate for meals missed due to illness'**
  String get svc_missedMealCompSubtitle;

  /// No description provided for @svc_examMealComp.
  ///
  /// In en, this message translates to:
  /// **'Exam Meal Compensation'**
  String get svc_examMealComp;

  /// No description provided for @svc_examMealCompSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit exam proof for meals missed during exams. Receive extra dinner instead.'**
  String get svc_examMealCompSubtitle;

  /// No description provided for @svc_submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get svc_submitRequest;

  /// No description provided for @svc_submitCompRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Compensation Request'**
  String get svc_submitCompRequest;

  /// No description provided for @svc_mealDate.
  ///
  /// In en, this message translates to:
  /// **'Date of missed meal'**
  String get svc_mealDate;

  /// No description provided for @svc_mealType.
  ///
  /// In en, this message translates to:
  /// **'Meal type'**
  String get svc_mealType;

  /// No description provided for @svc_examDate.
  ///
  /// In en, this message translates to:
  /// **'Exam date'**
  String get svc_examDate;

  /// No description provided for @svc_missedMeal.
  ///
  /// In en, this message translates to:
  /// **'Missed meal'**
  String get svc_missedMeal;

  /// No description provided for @svc_uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get svc_uploadDocument;

  /// No description provided for @svc_documentAttached.
  ///
  /// In en, this message translates to:
  /// **'Document attached'**
  String get svc_documentAttached;

  /// No description provided for @svc_requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully'**
  String get svc_requestSubmitted;

  /// No description provided for @svc_requestHistory.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get svc_requestHistory;

  /// No description provided for @svc_noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests submitted yet'**
  String get svc_noRequestsYet;

  /// No description provided for @svc_statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get svc_statusPending;

  /// No description provided for @svc_statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get svc_statusApproved;

  /// No description provided for @svc_statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get svc_statusRejected;

  /// No description provided for @svc_reqTypeMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical Absence'**
  String get svc_reqTypeMedical;

  /// No description provided for @svc_reqTypeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam Conflict'**
  String get svc_reqTypeExam;

  /// No description provided for @svc_tomorrowStats.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow Meal Statistics'**
  String get svc_tomorrowStats;

  /// No description provided for @svc_compensationRequests.
  ///
  /// In en, this message translates to:
  /// **'Compensation Requests'**
  String get svc_compensationRequests;

  /// No description provided for @svc_noCompRequests.
  ///
  /// In en, this message translates to:
  /// **'No compensation requests'**
  String get svc_noCompRequests;

  /// No description provided for @svc_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get svc_approve;

  /// No description provided for @svc_reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get svc_reject;

  /// No description provided for @svc_approveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get svc_approveSuccess;

  /// No description provided for @svc_rejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get svc_rejectSuccess;

  /// No description provided for @tutorials_title.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutorials_title;

  /// No description provided for @tutorials_empty.
  ///
  /// In en, this message translates to:
  /// **'No tutorials available'**
  String get tutorials_empty;

  /// No description provided for @tutorials_steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get tutorials_steps;

  /// No description provided for @tutorials_stepsHeader.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get tutorials_stepsHeader;

  /// No description provided for @tutorials_guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get tutorials_guide;

  /// No description provided for @settings_tutorials.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get settings_tutorials;

  /// No description provided for @svc_faqHowToApply.
  ///
  /// In en, this message translates to:
  /// **'How to make applications?'**
  String get svc_faqHowToApply;

  /// No description provided for @svc_faqHowToApplyContent.
  ///
  /// In en, this message translates to:
  /// **'1. Click on the appropriate compensation request button.\n2. Select the meal date and type.\n3. Make sure to attach the necessary document (medical certificate or exam schedule).\n4. Wait for approval from the administration.'**
  String get svc_faqHowToApplyContent;

  /// No description provided for @svc_faqHowToChange.
  ///
  /// In en, this message translates to:
  /// **'Can I change my request?'**
  String get svc_faqHowToChange;

  /// No description provided for @svc_faqHowToChangeContent.
  ///
  /// In en, this message translates to:
  /// **'Currently, applications cannot be changed after submission. Please carefully review the date, meal type, and attached documents before submitting. If you made a mistake, please contact support.'**
  String get svc_faqHowToChangeContent;

  /// No description provided for @svc_notifyBefore.
  ///
  /// In en, this message translates to:
  /// **'Notify before meal'**
  String get svc_notifyBefore;

  /// No description provided for @svc_time15m.
  ///
  /// In en, this message translates to:
  /// **'15 min'**
  String get svc_time15m;

  /// No description provided for @svc_time30m.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get svc_time30m;

  /// No description provided for @svc_time45m.
  ///
  /// In en, this message translates to:
  /// **'45 min'**
  String get svc_time45m;

  /// No description provided for @svc_time60m.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get svc_time60m;

  /// No description provided for @svc_debugEnableQr.
  ///
  /// In en, this message translates to:
  /// **'DEBUG: Enable QR (Bypass Slot)'**
  String get svc_debugEnableQr;

  /// No description provided for @svc_debugEnableQrDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow scanning outside meal hours'**
  String get svc_debugEnableQrDesc;

  /// No description provided for @svc_debugCloseMode.
  ///
  /// In en, this message translates to:
  /// **'DEBUG: Close Mode'**
  String get svc_debugCloseMode;

  /// No description provided for @svc_debugCloseModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Simulate the 20:00 cutoff'**
  String get svc_debugCloseModeDesc;

  /// No description provided for @svc_goGetMeal.
  ///
  /// In en, this message translates to:
  /// **'Go get your meal!'**
  String get svc_goGetMeal;

  /// No description provided for @svc_noConfirmations.
  ///
  /// In en, this message translates to:
  /// **'No confirmations for tomorrow'**
  String get svc_noConfirmations;

  /// No description provided for @svc_mealsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Meals Confirmed'**
  String get svc_mealsConfirmed;

  /// No description provided for @svc_mealsConfirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get svc_mealsConfirmedStatus;

  /// No description provided for @svc_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get svc_none;

  /// No description provided for @svc_monthlyUsage.
  ///
  /// In en, this message translates to:
  /// **'Monthly Quota'**
  String get svc_monthlyUsage;

  /// No description provided for @svc_mealsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'meals/month'**
  String get svc_mealsPerMonth;

  /// No description provided for @svc_quota.
  ///
  /// In en, this message translates to:
  /// **'Quota'**
  String get svc_quota;

  /// No description provided for @svc_monthlyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly quota reached'**
  String get svc_monthlyLimitReached;

  /// No description provided for @svc_monthInfo.
  ///
  /// In en, this message translates to:
  /// **'Month Information'**
  String get svc_monthInfo;

  /// No description provided for @svc_currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get svc_currentMonth;

  /// No description provided for @svc_daysElapsed.
  ///
  /// In en, this message translates to:
  /// **'Days Elapsed'**
  String get svc_daysElapsed;

  /// No description provided for @svc_avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg per Day'**
  String get svc_avgPerDay;

  /// No description provided for @svc_used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get svc_used;

  /// No description provided for @svc_redeemedMeals.
  ///
  /// In en, this message translates to:
  /// **'Redeemed Meals'**
  String get svc_redeemedMeals;

  /// No description provided for @svc_tomorrowConfirmationInfo.
  ///
  /// In en, this message translates to:
  /// **'Confirm the meals you want tomorrow from the canteen'**
  String get svc_tomorrowConfirmationInfo;

  /// No description provided for @gamification_goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Goal created successfully!'**
  String get gamification_goalCreated;

  /// No description provided for @sos_title.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos_title;

  /// No description provided for @sos_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get sos_subtitle;

  /// No description provided for @sos_emergencyActions.
  ///
  /// In en, this message translates to:
  /// **'Emergency Calls'**
  String get sos_emergencyActions;

  /// No description provided for @sos_callPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get sos_callPolice;

  /// No description provided for @sos_callAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get sos_callAmbulance;

  /// No description provided for @sos_callFire.
  ///
  /// In en, this message translates to:
  /// **'Fire Service'**
  String get sos_callFire;

  /// No description provided for @sos_callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get sos_callEmergency;

  /// No description provided for @sos_dialerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No phone app found'**
  String get sos_dialerUnavailable;

  /// No description provided for @hub_sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get hub_sos;

  /// No description provided for @bottomNav_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get bottomNav_notifications;

  /// No description provided for @settings_privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacyPolicy;

  /// No description provided for @social_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get social_chat;

  /// No description provided for @editPhone_description.
  ///
  /// In en, this message translates to:
  /// **'Enter your Kazakhstan phone number'**
  String get editPhone_description;

  /// No description provided for @editPhone_invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get editPhone_invalidFormat;

  /// No description provided for @notifications_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifications_filterAll;

  /// No description provided for @notifications_filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifications_filterUnread;

  /// No description provided for @notifications_allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get notifications_allCaughtUp;

  /// No description provided for @notifications_noUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get notifications_noUnread;

  /// No description provided for @notifications_openScreen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get notifications_openScreen;

  /// No description provided for @notifications_pushPaused.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are paused'**
  String get notifications_pushPaused;

  /// No description provided for @notifications_sectionMeals.
  ///
  /// In en, this message translates to:
  /// **'Meal Notifications'**
  String get notifications_sectionMeals;

  /// No description provided for @notifications_svcNotMember.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of Meal Pass'**
  String get notifications_svcNotMember;

  /// No description provided for @notifications_svcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meal balance and menu updates'**
  String get notifications_svcSubtitle;

  /// No description provided for @notifications_settingsFootnote.
  ///
  /// In en, this message translates to:
  /// **'Notification settings apply to push notifications. You can change these at any time.'**
  String get notifications_settingsFootnote;

  /// No description provided for @notif_action_viewClub.
  ///
  /// In en, this message translates to:
  /// **'View Club'**
  String get notif_action_viewClub;

  /// No description provided for @notif_action_showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get notif_action_showQr;

  /// No description provided for @notif_action_openWorkout.
  ///
  /// In en, this message translates to:
  /// **'Open Workout'**
  String get notif_action_openWorkout;

  /// No description provided for @notif_action_openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get notif_action_openChat;

  /// No description provided for @notif_action_openWallet.
  ///
  /// In en, this message translates to:
  /// **'Open Wallet'**
  String get notif_action_openWallet;

  /// No description provided for @notif_action_viewSchedule.
  ///
  /// In en, this message translates to:
  /// **'View Schedule'**
  String get notif_action_viewSchedule;

  /// No description provided for @notif_action_findJob.
  ///
  /// In en, this message translates to:
  /// **'Find Job'**
  String get notif_action_findJob;

  /// No description provided for @notif_action_openAccess.
  ///
  /// In en, this message translates to:
  /// **'Open Access'**
  String get notif_action_openAccess;

  /// No description provided for @notif_action_readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get notif_action_readMore;

  /// No description provided for @tasks_gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get tasks_gettingStarted;

  /// No description provided for @tasks_yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get tasks_yourProgress;

  /// No description provided for @tasks_allDone.
  ///
  /// In en, this message translates to:
  /// **'All Tasks Done!'**
  String get tasks_allDone;

  /// No description provided for @tasks_allDoneDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ve completed all available tasks. Keep up the great work!'**
  String get tasks_allDoneDesc;

  /// No description provided for @svc_greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get svc_greetingMorning;

  /// No description provided for @svc_greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get svc_greetingAfternoon;

  /// No description provided for @svc_greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get svc_greetingEvening;

  /// No description provided for @svc_greetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s your meal plan for today'**
  String get svc_greetingSubtitle;

  /// No description provided for @svc_mealDashboard.
  ///
  /// In en, this message translates to:
  /// **'Meal Dashboard'**
  String get svc_mealDashboard;

  /// No description provided for @svc_mealLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Meal Leaderboard'**
  String get svc_mealLeaderboard;

  /// No description provided for @svc_viewLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'View all rankings'**
  String get svc_viewLeaderboard;

  /// No description provided for @svc_mealHistory.
  ///
  /// In en, this message translates to:
  /// **'Meal History'**
  String get svc_mealHistory;

  /// No description provided for @svc_viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View your past meals'**
  String get svc_viewHistory;

  /// No description provided for @svc_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get svc_today;

  /// No description provided for @svc_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get svc_yesterday;

  /// No description provided for @svc_noMealsOnDay.
  ///
  /// In en, this message translates to:
  /// **'No meals scheduled'**
  String get svc_noMealsOnDay;

  /// No description provided for @svc_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get svc_skip;

  /// No description provided for @svc_going.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get svc_going;

  /// No description provided for @svc_calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Calendar'**
  String get svc_calendarTitle;

  /// No description provided for @svc_todayMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get svc_todayMeals;

  /// No description provided for @svc_statusLegend.
  ///
  /// In en, this message translates to:
  /// **'Status Legend'**
  String get svc_statusLegend;

  /// No description provided for @svc_statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get svc_statusScheduled;

  /// No description provided for @svc_statusScheduledDesc.
  ///
  /// In en, this message translates to:
  /// **'Meal is booked for this day'**
  String get svc_statusScheduledDesc;

  /// No description provided for @svc_statusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get svc_statusReceived;

  /// No description provided for @svc_statusReceivedDesc.
  ///
  /// In en, this message translates to:
  /// **'Meal was collected'**
  String get svc_statusReceivedDesc;

  /// No description provided for @svc_statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get svc_statusCancelled;

  /// No description provided for @svc_statusSkippedDesc.
  ///
  /// In en, this message translates to:
  /// **'Meal was cancelled or skipped'**
  String get svc_statusSkippedDesc;

  /// No description provided for @svc_statusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get svc_statusNoShow;

  /// No description provided for @svc_statusNoShowDesc.
  ///
  /// In en, this message translates to:
  /// **'Meal was not collected'**
  String get svc_statusNoShowDesc;

  /// No description provided for @svc_mealStreak.
  ///
  /// In en, this message translates to:
  /// **'Meal Streak'**
  String get svc_mealStreak;

  /// No description provided for @svc_mealPass.
  ///
  /// In en, this message translates to:
  /// **'Meal Pass'**
  String get svc_mealPass;

  /// No description provided for @svc_currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get svc_currentStreak;

  /// No description provided for @svc_bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get svc_bestStreak;

  /// No description provided for @svc_noStreakYet.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get svc_noStreakYet;

  /// No description provided for @svc_startStreak.
  ///
  /// In en, this message translates to:
  /// **'Start your streak by collecting meals every day!'**
  String get svc_startStreak;

  /// No description provided for @svc_streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String svc_streakDays(Object count);

  /// No description provided for @svc_nextMilestone.
  ///
  /// In en, this message translates to:
  /// **'{days} more days to next badge'**
  String svc_nextMilestone(Object days);

  /// No description provided for @svc_badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get svc_badges;

  /// No description provided for @svc_streakRequired.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak required'**
  String svc_streakRequired(Object days);

  /// No description provided for @svc_totalReceived.
  ///
  /// In en, this message translates to:
  /// **'Total Received'**
  String get svc_totalReceived;

  /// No description provided for @svc_totalCancelled.
  ///
  /// In en, this message translates to:
  /// **'Total Cancelled'**
  String get svc_totalCancelled;

  /// No description provided for @svc_noShows.
  ///
  /// In en, this message translates to:
  /// **'No Shows'**
  String get svc_noShows;

  /// No description provided for @svc_goToMealPass.
  ///
  /// In en, this message translates to:
  /// **'Go to Meal Pass'**
  String get svc_goToMealPass;

  /// No description provided for @svc_noShowInfo.
  ///
  /// In en, this message translates to:
  /// **'Missing meals without cancelling counts as a no-show and may affect your standing'**
  String get svc_noShowInfo;

  /// No description provided for @svc_faqCancelQ.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel a meal?'**
  String get svc_faqCancelQ;

  /// No description provided for @svc_faqCancelA.
  ///
  /// In en, this message translates to:
  /// **'Open the meal calendar, tap on a scheduled meal, and choose Cancel. You can cancel up to 2 hours before the meal time.'**
  String get svc_faqCancelA;

  /// No description provided for @svc_faqNoShowQ.
  ///
  /// In en, this message translates to:
  /// **'What happens if I don\'t show up?'**
  String get svc_faqNoShowQ;

  /// No description provided for @svc_faqNoShowA.
  ///
  /// In en, this message translates to:
  /// **'If you miss a meal without cancelling it will be marked as a no-show. Frequent no-shows may affect your meal program access.'**
  String get svc_faqNoShowA;

  /// No description provided for @svc_faqStreakQ.
  ///
  /// In en, this message translates to:
  /// **'What is a meal streak?'**
  String get svc_faqStreakQ;

  /// No description provided for @svc_faqStreakA.
  ///
  /// In en, this message translates to:
  /// **'A streak is the number of consecutive days you collected your meal. Longer streaks unlock badges and rewards.'**
  String get svc_faqStreakA;

  /// No description provided for @svc_faqQrQ.
  ///
  /// In en, this message translates to:
  /// **'How do I use the QR code?'**
  String get svc_faqQrQ;

  /// No description provided for @svc_faqQrA.
  ///
  /// In en, this message translates to:
  /// **'Open the app and tap \"Scan QR\", then point your camera at the QR code displayed at the canteen. Wait for the confirmation screen — your meal will be recorded automatically.'**
  String get svc_faqQrA;

  /// No description provided for @svc_faqDeadlineQ.
  ///
  /// In en, this message translates to:
  /// **'What is the cancellation deadline?'**
  String get svc_faqDeadlineQ;

  /// No description provided for @svc_faqDeadlineA.
  ///
  /// In en, this message translates to:
  /// **'You can cancel your meal up to 2 hours before the scheduled meal time. After that, cancellation is locked.'**
  String get svc_faqDeadlineA;

  /// No description provided for @svc_faqUndoQ.
  ///
  /// In en, this message translates to:
  /// **'Can I undo a cancellation?'**
  String get svc_faqUndoQ;

  /// No description provided for @svc_faqUndoA.
  ///
  /// In en, this message translates to:
  /// **'Yes! If the cancellation window hasn\'t closed yet, you can undo your cancellation from the meal calendar.'**
  String get svc_faqUndoA;

  /// No description provided for @svc_cancelMeal.
  ///
  /// In en, this message translates to:
  /// **'Cancel Meal'**
  String get svc_cancelMeal;

  /// No description provided for @svc_keepMeal.
  ///
  /// In en, this message translates to:
  /// **'Keep Meal'**
  String get svc_keepMeal;

  /// No description provided for @svc_cancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get svc_cancelConfirm;

  /// No description provided for @svc_cancelMealDescription.
  ///
  /// In en, this message translates to:
  /// **'Cancelling your meal will free up the slot. You can undo this before the deadline.'**
  String get svc_cancelMealDescription;

  /// No description provided for @svc_cancelDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Deadline'**
  String get svc_cancelDeadlineLabel;

  /// No description provided for @svc_honestCancelInfo.
  ///
  /// In en, this message translates to:
  /// **'Cancelling honestly helps others get meals'**
  String get svc_honestCancelInfo;

  /// No description provided for @svc_cancelWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Unavailable'**
  String get svc_cancelWindowClosed;

  /// No description provided for @svc_cancelWindowClosedDesc.
  ///
  /// In en, this message translates to:
  /// **'The cancellation window for this meal has closed. Please show up or it will be recorded as a no-show.'**
  String get svc_cancelWindowClosedDesc;

  /// No description provided for @svc_cancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Meal cancelled successfully'**
  String get svc_cancelSuccess;

  /// No description provided for @svc_undoCancellation.
  ///
  /// In en, this message translates to:
  /// **'Undo Cancellation'**
  String get svc_undoCancellation;

  /// No description provided for @svc_undoCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cancellation undone'**
  String get svc_undoCancelSuccess;

  /// No description provided for @svc_scanToReceive.
  ///
  /// In en, this message translates to:
  /// **'Scan to Receive Your Meal'**
  String get svc_scanToReceive;

  /// No description provided for @svc_pointCameraAtQr.
  ///
  /// In en, this message translates to:
  /// **'Point camera at QR code'**
  String get svc_pointCameraAtQr;

  /// No description provided for @svc_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get svc_processing;

  /// No description provided for @svc_invalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get svc_invalidQr;

  /// No description provided for @svc_qrScanGenericError.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan QR code. Please try again.'**
  String get svc_qrScanGenericError;

  /// No description provided for @svc_scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get svc_scanAgain;

  /// No description provided for @svc_openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get svc_openSettings;

  /// No description provided for @svc_remainingTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining Today'**
  String get svc_remainingTodayLabel;

  /// No description provided for @svc_visitLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get svc_visitLabel;

  /// No description provided for @svc_studentLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get svc_studentLabel;

  /// No description provided for @svc_yourRank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get svc_yourRank;

  /// No description provided for @svc_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get svc_you;

  /// No description provided for @svc_leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data yet'**
  String get svc_leaderboardEmpty;

  /// No description provided for @svc_couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get svc_couldNotLoad;

  /// No description provided for @svc_noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No meal history yet'**
  String get svc_noHistoryYet;

  /// No description provided for @svc_historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start collecting meals to see your history here'**
  String get svc_historyEmpty;

  /// No description provided for @svc_historyComplete.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end'**
  String get svc_historyComplete;

  /// No description provided for @svc_loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get svc_loadingMore;

  /// No description provided for @wordle_title.
  ///
  /// In en, this message translates to:
  /// **'Wordle'**
  String get wordle_title;

  /// No description provided for @wordle_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Guess today\'s 5-letter word'**
  String get wordle_subtitle;

  /// No description provided for @wordle_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get wordle_play;

  /// No description provided for @wordle_youWon.
  ///
  /// In en, this message translates to:
  /// **'Brilliant!'**
  String get wordle_youWon;

  /// No description provided for @wordle_youLost.
  ///
  /// In en, this message translates to:
  /// **'Better luck tomorrow!'**
  String get wordle_youLost;

  /// No description provided for @wordle_playAgainTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for a new puzzle.'**
  String get wordle_playAgainTomorrow;

  /// No description provided for @wordle_invalidWord.
  ///
  /// In en, this message translates to:
  /// **'Not in word list'**
  String get wordle_invalidWord;

  /// No description provided for @wordle_tooShort.
  ///
  /// In en, this message translates to:
  /// **'Not enough letters'**
  String get wordle_tooShort;

  /// No description provided for @wordle_networkError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Try again later.'**
  String get wordle_networkError;

  /// No description provided for @wordle_streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get wordle_streak;

  /// No description provided for @wordle_bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get wordle_bestStreak;

  /// No description provided for @wordle_totalGames.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get wordle_totalGames;

  /// No description provided for @wordle_winRate.
  ///
  /// In en, this message translates to:
  /// **'Win %'**
  String get wordle_winRate;

  /// No description provided for @wordle_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get wordle_statistics;

  /// No description provided for @wordle_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get wordle_history;

  /// No description provided for @wordle_noHistory.
  ///
  /// In en, this message translates to:
  /// **'No games played yet'**
  String get wordle_noHistory;

  /// No description provided for @wordle_failed.
  ///
  /// In en, this message translates to:
  /// **'Not solved'**
  String get wordle_failed;

  /// No description provided for @wordle_reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get wordle_reminderTitle;

  /// No description provided for @wordle_reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when puzzle is ready'**
  String get wordle_reminderSubtitle;

  /// No description provided for @wordle_reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get wordle_reminderTime;

  /// No description provided for @wordle_reminderInfo.
  ///
  /// In en, this message translates to:
  /// **'The reminder appears when you open the app after the set time.'**
  String get wordle_reminderInfo;

  /// No description provided for @wordle_reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get wordle_reminderEnabled;

  /// No description provided for @wordle_notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Wordle is ready!'**
  String get wordle_notifTitle;

  /// No description provided for @wordle_notifBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle is waiting for you.'**
  String get wordle_notifBody;

  /// No description provided for @wordle_viewStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get wordle_viewStats;

  /// No description provided for @wordle_alreadyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Already played today'**
  String get wordle_alreadyPlayed;

  /// No description provided for @wordle_solvedIn.
  ///
  /// In en, this message translates to:
  /// **'Solved in {attempts} attempt(s)'**
  String wordle_solvedIn(Object attempts);

  /// No description provided for @settings_community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get settings_community;

  /// No description provided for @settings_shareJasWallet.
  ///
  /// In en, this message translates to:
  /// **'Share Jas Wallet'**
  String get settings_shareJasWallet;

  /// No description provided for @settings_inviteEarn.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get settings_inviteEarn;

  /// No description provided for @settings_rateJasWallet.
  ///
  /// In en, this message translates to:
  /// **'Rate Jas Wallet'**
  String get settings_rateJasWallet;

  /// No description provided for @share_title.
  ///
  /// In en, this message translates to:
  /// **'Share Jas Wallet'**
  String get share_title;

  /// No description provided for @share_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Help your friends discover Jas Wallet'**
  String get share_subtitle;

  /// No description provided for @share_shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get share_shareApp;

  /// No description provided for @share_shareAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp, Telegram, and other social media'**
  String get share_shareAppSubtitle;

  /// No description provided for @share_copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy App Link'**
  String get share_copyLink;

  /// No description provided for @share_copyLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the download link to clipboard'**
  String get share_copyLinkSubtitle;

  /// No description provided for @share_openStore.
  ///
  /// In en, this message translates to:
  /// **'Open Store Page'**
  String get share_openStore;

  /// No description provided for @share_openStoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View Jas Wallet on the App Store or Play Store'**
  String get share_openStoreSubtitle;

  /// No description provided for @share_linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get share_linkCopied;

  /// No description provided for @share_storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store page is not yet available'**
  String get share_storeUnavailable;

  /// No description provided for @referral_title.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral_title;

  /// No description provided for @referral_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and unlock achievements'**
  String get referral_subtitle;

  /// No description provided for @referral_yourCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referral_yourCode;

  /// No description provided for @referral_invitedFriends.
  ///
  /// In en, this message translates to:
  /// **'Invited Friends'**
  String get referral_invitedFriends;

  /// No description provided for @referral_badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Badges Earned'**
  String get referral_badgesEarned;

  /// No description provided for @referral_copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get referral_copyCode;

  /// No description provided for @referral_shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get referral_shareInvite;

  /// No description provided for @referral_codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied!'**
  String get referral_codeCopied;

  /// No description provided for @referral_yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get referral_yourProgress;

  /// No description provided for @referral_currentLevel.
  ///
  /// In en, this message translates to:
  /// **'Level: {name}'**
  String referral_currentLevel(String name);

  /// No description provided for @referral_noLevelYet.
  ///
  /// In en, this message translates to:
  /// **'Invite your first friend to unlock a badge'**
  String get referral_noLevelYet;

  /// No description provided for @referral_invites.
  ///
  /// In en, this message translates to:
  /// **'invite(s)'**
  String get referral_invites;

  /// No description provided for @referral_nextMilestone.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} ({count} invites)'**
  String referral_nextMilestone(String name, int count);

  /// No description provided for @referral_invitesNeeded.
  ///
  /// In en, this message translates to:
  /// **'{count} more invite(s) to go'**
  String referral_invitesNeeded(int count);

  /// No description provided for @referral_rewardRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Achievement Roadmap'**
  String get referral_rewardRoadmap;

  /// No description provided for @referral_leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Referrers'**
  String get referral_leaderboardTitle;

  /// No description provided for @rateApp_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your feedback helps us improve.'**
  String get rateApp_thanks;

  /// No description provided for @rateApp_error.
  ///
  /// In en, this message translates to:
  /// **'Could not open review dialog'**
  String get rateApp_error;

  /// No description provided for @appUpdate_title.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get appUpdate_title;

  /// No description provided for @appUpdate_optionalMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Jas Wallet is available with new features and improvements.'**
  String get appUpdate_optionalMessage;

  /// No description provided for @appUpdate_requiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get appUpdate_requiredTitle;

  /// No description provided for @appUpdate_requiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please update Jas Wallet to continue. This version is no longer supported.'**
  String get appUpdate_requiredMessage;

  /// No description provided for @appUpdate_updateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdate_updateButton;

  /// No description provided for @appUpdate_laterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdate_laterButton;

  /// No description provided for @events_nuTitle.
  ///
  /// In en, this message translates to:
  /// **'NU Events'**
  String get events_nuTitle;

  /// No description provided for @events_aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About the event'**
  String get events_aboutSection;

  /// No description provided for @events_organizerSection.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get events_organizerSection;

  /// No description provided for @events_openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get events_openInBrowser;

  /// No description provided for @widgets_alwaysVisible.
  ///
  /// In en, this message translates to:
  /// **'Always visible'**
  String get widgets_alwaysVisible;

  /// No description provided for @security_fingerprintSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint to unlock'**
  String get security_fingerprintSubtitle;

  /// No description provided for @security_faceIdSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID to unlock'**
  String get security_faceIdSubtitle;

  /// No description provided for @security_authenticationSection.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get security_authenticationSection;

  /// No description provided for @help_subtitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help you today?'**
  String get help_subtitle;

  /// No description provided for @help_telegramTitle.
  ///
  /// In en, this message translates to:
  /// **'Telegram Group'**
  String get help_telegramTitle;

  /// No description provided for @help_telegramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Write your question in the group'**
  String get help_telegramSubtitle;

  /// No description provided for @help_telegramOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Telegram link'**
  String get help_telegramOpenFailed;

  /// No description provided for @help_emailSubject.
  ///
  /// In en, this message translates to:
  /// **'Jas Wallet Support'**
  String get help_emailSubject;

  /// No description provided for @help_emailSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send email to {email}'**
  String help_emailSendFailed(String email);

  /// No description provided for @help_chatGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! How can we help you today?'**
  String get help_chatGreeting;

  /// No description provided for @help_chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get help_chatMessageHint;

  /// No description provided for @help_chatAutoReply.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your message! Our support team will respond shortly.'**
  String get help_chatAutoReply;

  /// No description provided for @tasks_progressCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} tasks completed'**
  String tasks_progressCompleted(int completed, int total);

  /// No description provided for @tasks_progressAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks available'**
  String tasks_progressAvailable(int count);

  /// No description provided for @gamification_rewardsCollected.
  ///
  /// In en, this message translates to:
  /// **'rewards collected'**
  String get gamification_rewardsCollected;

  /// No description provided for @gamification_percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String gamification_percentComplete(int percent);

  /// No description provided for @common_now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get common_now;

  /// No description provided for @common_routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {route}'**
  String common_routeNotFound(String route);

  /// No description provided for @notifications_silentModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications saved silently (no banners)'**
  String get notifications_silentModeDesc;

  /// No description provided for @notifications_categoryDisabled.
  ///
  /// In en, this message translates to:
  /// **'This category is disabled in notification settings.'**
  String get notifications_categoryDisabled;

  /// No description provided for @settings_privacyPolicyOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open privacy policy'**
  String get settings_privacyPolicyOpenFailed;

  /// No description provided for @about_storeOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open store'**
  String get about_storeOpenFailed;

  /// No description provided for @about_developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by the JASAIM team'**
  String get about_developedBy;

  /// No description provided for @about_supportedBy.
  ///
  /// In en, this message translates to:
  /// **'Supported by NU Impact Foundation'**
  String get about_supportedBy;

  /// No description provided for @editProfile_dateFormatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter date as DD.MM.YYYY'**
  String get editProfile_dateFormatInvalid;

  /// No description provided for @editProfile_dateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'DD.MM.YYYY'**
  String get editProfile_dateFormatHint;

  /// No description provided for @editProfile_phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+7 XXX XXX XX XX'**
  String get editProfile_phoneHint;

  /// No description provided for @auth_emailExample.
  ///
  /// In en, this message translates to:
  /// **'example@nu.edu.kz'**
  String get auth_emailExample;

  /// No description provided for @motivation_goalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Complete 50 lessons'**
  String get motivation_goalTitleHint;

  /// No description provided for @motivation_goalDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is your goal?'**
  String get motivation_goalDescriptionHint;

  /// No description provided for @motivation_unitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., lessons, points, days'**
  String get motivation_unitHint;

  /// No description provided for @motivation_goalDone.
  ///
  /// In en, this message translates to:
  /// **'Done! ✓'**
  String get motivation_goalDone;

  /// No description provided for @hub_noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String hub_noSearchResults(String query);

  /// No description provided for @sos_callButton.
  ///
  /// In en, this message translates to:
  /// **'CALL'**
  String get sos_callButton;

  /// No description provided for @svc_mealDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal Date:'**
  String get svc_mealDateLabel;

  /// No description provided for @svc_mealTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get svc_mealTypeLabel;

  /// No description provided for @language_nameKazakh.
  ///
  /// In en, this message translates to:
  /// **'Қазақша'**
  String get language_nameKazakh;

  /// No description provided for @language_nameRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get language_nameRussian;

  /// No description provided for @language_nameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_nameEnglish;

  /// No description provided for @referral_enterCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Have a Referral Code?'**
  String get referral_enterCodeTitle;

  /// No description provided for @referral_enterCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s referral code. They\'ll earn rewards when you join — completely optional.'**
  String get referral_enterCodeDesc;

  /// No description provided for @referral_codeFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get referral_codeFieldHint;

  /// No description provided for @referral_applyCode.
  ///
  /// In en, this message translates to:
  /// **'Apply Code'**
  String get referral_applyCode;

  /// No description provided for @referral_skipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get referral_skipStep;

  /// No description provided for @referral_codeApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code saved!'**
  String get referral_codeApplied;

  /// No description provided for @referral_invalidCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Code must be 3–10 letters or digits'**
  String get referral_invalidCodeFormat;

  /// No description provided for @tutorial_svcMeal_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Your Meals, Covered'**
  String get tutorial_svcMeal_slide1_title;

  /// No description provided for @tutorial_svcMeal_slide1_body.
  ///
  /// In en, this message translates to:
  /// **'NU Impact Foundation credits your account with meal allowances. Enjoy campus food — fully or partially covered.'**
  String get tutorial_svcMeal_slide1_body;

  /// No description provided for @tutorial_svcMeal_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Scan and Pay'**
  String get tutorial_svcMeal_slide2_title;

  /// No description provided for @tutorial_svcMeal_slide2_body.
  ///
  /// In en, this message translates to:
  /// **'Show your QR code at the cafeteria counter to redeem your meal allowance. Fast, contactless, cashless.'**
  String get tutorial_svcMeal_slide2_body;

  /// No description provided for @tutorial_svcMeal_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Build Your Streak'**
  String get tutorial_svcMeal_slide3_title;

  /// No description provided for @tutorial_svcMeal_slide3_body.
  ///
  /// In en, this message translates to:
  /// **'Eat consistently every day and climb the leaderboard. Earn badges, fire streaks, and compete with the whole campus.'**
  String get tutorial_svcMeal_slide3_body;

  /// No description provided for @tutorial_salto_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Say Goodbye to Physical Cards'**
  String get tutorial_salto_slide1_title;

  /// No description provided for @tutorial_salto_slide1_body.
  ///
  /// In en, this message translates to:
  /// **'No more digging for your access card. Your smartphone replaces every plastic campus card.'**
  String get tutorial_salto_slide1_body;

  /// No description provided for @tutorial_salto_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Tap to Unlock'**
  String get tutorial_salto_slide2_title;

  /// No description provided for @tutorial_salto_slide2_body.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone near any Salto lock. One tap over Bluetooth — and you\'re in.'**
  String get tutorial_salto_slide2_body;

  /// No description provided for @tutorial_salto_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Make It Yours'**
  String get tutorial_salto_slide3_title;

  /// No description provided for @tutorial_salto_slide3_body.
  ///
  /// In en, this message translates to:
  /// **'Choose from multiple student card designs. Personalize your digital ID to match your style.'**
  String get tutorial_salto_slide3_body;

  /// No description provided for @tutorial_referral_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get tutorial_referral_slide1_title;

  /// No description provided for @tutorial_referral_slide1_body.
  ///
  /// In en, this message translates to:
  /// **'Share your unique referral code with classmates. You both earn rewards when they join Jas Wallet.'**
  String get tutorial_referral_slide1_body;

  /// No description provided for @tutorial_referral_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Share Your Code'**
  String get tutorial_referral_slide2_title;

  /// No description provided for @tutorial_referral_slide2_body.
  ///
  /// In en, this message translates to:
  /// **'Copy your referral link and send it to friends via any app. They sign up, you both get rewarded instantly.'**
  String get tutorial_referral_slide2_body;

  /// No description provided for @tutorial_referral_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Climb the Leaderboard'**
  String get tutorial_referral_slide3_title;

  /// No description provided for @tutorial_referral_slide3_body.
  ///
  /// In en, this message translates to:
  /// **'See how you rank against other inviters. Compete for the top spot and show off your network.'**
  String get tutorial_referral_slide3_body;

  /// No description provided for @tutorial_profile_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Your Digital Identity'**
  String get tutorial_profile_slide1_title;

  /// No description provided for @tutorial_profile_slide1_body.
  ///
  /// In en, this message translates to:
  /// **'One card connects your campus life — meals, building access, referrals, and more, all in a single digital profile.'**
  String get tutorial_profile_slide1_body;

  /// No description provided for @tutorial_profile_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Showcase Yourself'**
  String get tutorial_profile_slide2_title;

  /// No description provided for @tutorial_profile_slide2_body.
  ///
  /// In en, this message translates to:
  /// **'Build your campus presence with a profile that shows your achievements, activity, and student life highlights.'**
  String get tutorial_profile_slide2_body;

  /// No description provided for @tutorial_profile_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get tutorial_profile_slide3_title;

  /// No description provided for @tutorial_profile_slide3_body.
  ///
  /// In en, this message translates to:
  /// **'The more you fill in, the more you unlock. A complete profile gives you full access to everything Jas Wallet offers.'**
  String get tutorial_profile_slide3_body;

  /// No description provided for @contest_title.
  ///
  /// In en, this message translates to:
  /// **'Contest'**
  String get contest_title;

  /// No description provided for @referral_contestDeadline.
  ///
  /// In en, this message translates to:
  /// **'Contest ends September 10, 2026'**
  String get referral_contestDeadline;

  /// No description provided for @contest_headline.
  ///
  /// In en, this message translates to:
  /// **'Win Up to\n₸100,000'**
  String get contest_headline;

  /// No description provided for @contest_intro.
  ///
  /// In en, this message translates to:
  /// **'Three competitions. One deadline. Real prizes — winners announced by the BFLAB team on September 10, 2026.'**
  String get contest_intro;

  /// No description provided for @contest_card1Title.
  ///
  /// In en, this message translates to:
  /// **'Top 3 Referrers'**
  String get contest_card1Title;

  /// No description provided for @contest_card1Desc.
  ///
  /// In en, this message translates to:
  /// **'Invite the most friends to Jas Wallet.'**
  String get contest_card1Desc;

  /// No description provided for @contest_card2Title.
  ///
  /// In en, this message translates to:
  /// **'Best Instagram Reel'**
  String get contest_card2Title;

  /// No description provided for @contest_card2Desc.
  ///
  /// In en, this message translates to:
  /// **'Create a Reel about Jas Wallet or your campus life highlights. Tag @blockchain.fintech.lab and @nu_impact_foundation when you post.'**
  String get contest_card2Desc;

  /// No description provided for @contest_card3Title.
  ///
  /// In en, this message translates to:
  /// **'Most Creative Profile'**
  String get contest_card3Title;

  /// No description provided for @contest_card3Desc.
  ///
  /// In en, this message translates to:
  /// **'Design the most creative profile on Jas Wallet — make your ID stand out and fill your profile completely. The whole profile matters, not just the ID.'**
  String get contest_card3Desc;

  /// No description provided for @contest_card3Note.
  ///
  /// In en, this message translates to:
  /// **'Submit your profile in a DM to @blockchain.fintech.lab on Instagram.'**
  String get contest_card3Note;

  /// No description provided for @contest_mandatoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Required for all contests'**
  String get contest_mandatoryLabel;

  /// No description provided for @contest_mandatoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Every entry must tag @blockchain.fintech.lab and @nu_impact_foundation. Entries without the tag will not be considered.'**
  String get contest_mandatoryDesc;

  /// No description provided for @contest_announcement.
  ///
  /// In en, this message translates to:
  /// **'Winners announced\nSeptember 10, 2026.'**
  String get contest_announcement;

  /// No description provided for @contest_legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By participating in this contest, you automatically agree to the '**
  String get contest_legalPrefix;

  /// No description provided for @contest_legalLink.
  ///
  /// In en, this message translates to:
  /// **'Contest Rules and Terms'**
  String get contest_legalLink;

  /// No description provided for @referral_inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get referral_inviteFriends;

  /// No description provided for @referral_howItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get referral_howItWorksTitle;

  /// No description provided for @referral_step1Title.
  ///
  /// In en, this message translates to:
  /// **'Share Your Code'**
  String get referral_step1Title;

  /// No description provided for @referral_step1Desc.
  ///
  /// In en, this message translates to:
  /// **'Copy your unique code or share it directly with friends.'**
  String get referral_step1Desc;

  /// No description provided for @referral_step2Title.
  ///
  /// In en, this message translates to:
  /// **'Friend Signs Up'**
  String get referral_step2Title;

  /// No description provided for @referral_step2Desc.
  ///
  /// In en, this message translates to:
  /// **'Your friend downloads Jas Wallet and registers using your code.'**
  String get referral_step2Desc;

  /// No description provided for @referral_step3Title.
  ///
  /// In en, this message translates to:
  /// **'Both Earn Rewards'**
  String get referral_step3Title;

  /// No description provided for @referral_step3Desc.
  ///
  /// In en, this message translates to:
  /// **'Reach milestones to unlock exclusive badges and climb the leaderboard.'**
  String get referral_step3Desc;

  /// No description provided for @referral_promoTitle.
  ///
  /// In en, this message translates to:
  /// **'The more you share,\nthe more you earn'**
  String get referral_promoTitle;

  /// No description provided for @referral_promoDesc.
  ///
  /// In en, this message translates to:
  /// **'Every friend you invite brings you closer to the next reward tier.'**
  String get referral_promoDesc;

  /// No description provided for @referral_faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get referral_faqTitle;

  /// No description provided for @referral_faq1Q.
  ///
  /// In en, this message translates to:
  /// **'Who can join the referral program?'**
  String get referral_faq1Q;

  /// No description provided for @referral_faq1A.
  ///
  /// In en, this message translates to:
  /// **'Any registered Jas Wallet user with a verified account can invite friends and earn rewards.'**
  String get referral_faq1A;

  /// No description provided for @referral_faq2Q.
  ///
  /// In en, this message translates to:
  /// **'When do I get my reward?'**
  String get referral_faq2Q;

  /// No description provided for @referral_faq2A.
  ///
  /// In en, this message translates to:
  /// **'Rewards are credited once your friend completes registration and verifies their account.'**
  String get referral_faq2A;

  /// No description provided for @referral_faq3Q.
  ///
  /// In en, this message translates to:
  /// **'Is there a limit on invites?'**
  String get referral_faq3Q;

  /// No description provided for @referral_faq3A.
  ///
  /// In en, this message translates to:
  /// **'No limit — invite as many friends as you want and keep unlocking higher tiers.'**
  String get referral_faq3A;

  /// No description provided for @referral_faq4Q.
  ///
  /// In en, this message translates to:
  /// **'What if my friend already has an account?'**
  String get referral_faq4Q;

  /// No description provided for @referral_faq4A.
  ///
  /// In en, this message translates to:
  /// **'The referral code only works for new users signing up for the first time.'**
  String get referral_faq4A;

  /// No description provided for @referral_detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get referral_detailsTitle;

  /// No description provided for @referral_termsLink.
  ///
  /// In en, this message translates to:
  /// **'Referral Terms'**
  String get referral_termsLink;

  /// No description provided for @referral_historyLink.
  ///
  /// In en, this message translates to:
  /// **'Referral History'**
  String get referral_historyLink;

  /// No description provided for @referral_supportLink.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get referral_supportLink;

  /// No description provided for @contest_prizePool.
  ///
  /// In en, this message translates to:
  /// **'Prize Pool'**
  String get contest_prizePool;

  /// No description provided for @contest_condSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contest Rules'**
  String get contest_condSectionTitle;

  /// No description provided for @contest_cond1Title.
  ///
  /// In en, this message translates to:
  /// **'Who can participate'**
  String get contest_cond1Title;

  /// No description provided for @contest_cond1Desc.
  ///
  /// In en, this message translates to:
  /// **'Any student with a registered Jas Wallet account.'**
  String get contest_cond1Desc;

  /// No description provided for @contest_cond3Title.
  ///
  /// In en, this message translates to:
  /// **'Contest deadline'**
  String get contest_cond3Title;

  /// No description provided for @contest_cond4Title.
  ///
  /// In en, this message translates to:
  /// **'Winner selection'**
  String get contest_cond4Title;

  /// No description provided for @contest_cond4Desc.
  ///
  /// In en, this message translates to:
  /// **'Referrals: top 3 by invite count. Reel and Profile: judged by the @blockchain.fintech.lab team.'**
  String get contest_cond4Desc;

  /// No description provided for @contest_cond5Title.
  ///
  /// In en, this message translates to:
  /// **'Prize announcement'**
  String get contest_cond5Title;

  /// No description provided for @contest_faq1Q.
  ///
  /// In en, this message translates to:
  /// **'How are winners selected?'**
  String get contest_faq1Q;

  /// No description provided for @contest_faq1A.
  ///
  /// In en, this message translates to:
  /// **'Top 3 referrers by invite count. Reel and Profile winners are chosen by the @blockchain.fintech.lab team.'**
  String get contest_faq1A;

  /// No description provided for @contest_faq2Q.
  ///
  /// In en, this message translates to:
  /// **'Can I enter all three contests?'**
  String get contest_faq2Q;

  /// No description provided for @contest_faq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes! You can participate in all three simultaneously and win in multiple categories.'**
  String get contest_faq2A;

  /// No description provided for @contest_faq3Q.
  ///
  /// In en, this message translates to:
  /// **'When will prizes be awarded?'**
  String get contest_faq3Q;

  /// No description provided for @contest_faq3A.
  ///
  /// In en, this message translates to:
  /// **'Winners will be announced and prizes awarded on September 10, 2026.'**
  String get contest_faq3A;

  /// No description provided for @contest_faq4Q.
  ///
  /// In en, this message translates to:
  /// **'Have questions?'**
  String get contest_faq4Q;

  /// No description provided for @contest_faq4A.
  ///
  /// In en, this message translates to:
  /// **'DM @blockchain.fintech.lab on Instagram with any questions.'**
  String get contest_faq4A;

  /// No description provided for @notifications_sectionEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notifications_sectionEvents;

  /// No description provided for @notifications_eventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders for events you follow. Tap the bell on an event to subscribe.'**
  String get notifications_eventsSubtitle;

  /// No description provided for @events_followTooltip.
  ///
  /// In en, this message translates to:
  /// **'Follow this event'**
  String get events_followTooltip;

  /// No description provided for @events_unfollowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unfollow this event'**
  String get events_unfollowTooltip;

  /// No description provided for @events_followedToast.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get reminders for this event'**
  String get events_followedToast;

  /// No description provided for @events_unfollowedToast.
  ///
  /// In en, this message translates to:
  /// **'Reminders for this event are off'**
  String get events_unfollowedToast;

  /// No description provided for @events_reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Event'**
  String get events_reminderTitle;

  /// No description provided for @events_reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time} — {title}'**
  String events_reminderBody(String time, String title);

  /// No description provided for @events_reminderBodyAllDay.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow — {title}'**
  String events_reminderBodyAllDay(String title);

  /// No description provided for @events_reminderBody12h.
  ///
  /// In en, this message translates to:
  /// **'In 12 hours at {time} — {title}'**
  String events_reminderBody12h(String time, String title);

  /// No description provided for @events_reminderBody1h.
  ///
  /// In en, this message translates to:
  /// **'In 1 hour at {time} — {title}'**
  String events_reminderBody1h(String time, String title);

  /// No description provided for @orientation_week_title.
  ///
  /// In en, this message translates to:
  /// **'Club Fair'**
  String get orientation_week_title;

  /// No description provided for @orientation_hub_banner_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete quests, explore campus, win prizes'**
  String get orientation_hub_banner_subtitle;

  /// No description provided for @orientation_day_of.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String orientation_day_of(Object day, Object total);

  /// No description provided for @orientation_tokens_label.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get orientation_tokens_label;

  /// No description provided for @orientation_continue_journey.
  ///
  /// In en, this message translates to:
  /// **'Continue Journey'**
  String get orientation_continue_journey;

  /// No description provided for @orientation_networking_bingo.
  ///
  /// In en, this message translates to:
  /// **'Campus Bingo'**
  String get orientation_networking_bingo;

  /// No description provided for @orientation_photo_quests.
  ///
  /// In en, this message translates to:
  /// **'Photo Quests'**
  String get orientation_photo_quests;

  /// No description provided for @orientation_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get orientation_leaderboard;

  /// No description provided for @orientation_rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get orientation_rewards;

  /// No description provided for @orientation_mini_games.
  ///
  /// In en, this message translates to:
  /// **'Mini Games'**
  String get orientation_mini_games;

  /// No description provided for @orientation_min_short.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String orientation_min_short(Object minutes);

  /// No description provided for @orientation_xp_short.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String orientation_xp_short(Object xp);

  /// No description provided for @orientation_error_title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get orientation_error_title;

  /// No description provided for @orientation_error_message.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load Orientation Quest. Please try again.'**
  String get orientation_error_message;

  /// No description provided for @orientation_offline_title.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get orientation_offline_title;

  /// No description provided for @orientation_offline_message.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to load Orientation Quest.'**
  String get orientation_offline_message;

  /// No description provided for @orientation_bingo_title.
  ///
  /// In en, this message translates to:
  /// **'Campus Bingo'**
  String get orientation_bingo_title;

  /// No description provided for @orientation_bingo_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore campus to close each square'**
  String get orientation_bingo_subtitle;

  /// No description provided for @orientation_cells_completed.
  ///
  /// In en, this message translates to:
  /// **'{count}/{total} cells'**
  String orientation_cells_completed(Object count, Object total);

  /// No description provided for @orientation_foundation_year.
  ///
  /// In en, this message translates to:
  /// **'Foundation Year'**
  String get orientation_foundation_year;

  /// No description provided for @orientation_day_n.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String orientation_day_n(Object day);

  /// No description provided for @orientation_profile_title.
  ///
  /// In en, this message translates to:
  /// **'My Orientation Profile'**
  String get orientation_profile_title;

  /// No description provided for @orientation_level_n.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String orientation_level_n(Object level);

  /// No description provided for @orientation_friends_met.
  ///
  /// In en, this message translates to:
  /// **'Places Discovered'**
  String get orientation_friends_met;

  /// No description provided for @orientation_locations_visited.
  ///
  /// In en, this message translates to:
  /// **'Locations Visited'**
  String get orientation_locations_visited;

  /// No description provided for @orientation_badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get orientation_badges;

  /// No description provided for @orientation_photo_status_not_started.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get orientation_photo_status_not_started;

  /// No description provided for @orientation_photo_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get orientation_photo_status_pending;

  /// No description provided for @orientation_photo_status_approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get orientation_photo_status_approved;

  /// No description provided for @orientation_photo_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected — try again'**
  String get orientation_photo_status_rejected;

  /// No description provided for @orientation_redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get orientation_redeem;

  /// No description provided for @orientation_insufficient_tokens.
  ///
  /// In en, this message translates to:
  /// **'Not enough tokens'**
  String get orientation_insufficient_tokens;

  /// No description provided for @orientation_awarded_automatically.
  ///
  /// In en, this message translates to:
  /// **'Awarded from leaderboard'**
  String get orientation_awarded_automatically;

  /// No description provided for @orientation_completed_label.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orientation_completed_label;

  /// No description provided for @orientation_submit_answer.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get orientation_submit_answer;

  /// No description provided for @orientation_true_or_myth_statement.
  ///
  /// In en, this message translates to:
  /// **'NU\'s library was the first building completed on campus.'**
  String get orientation_true_or_myth_statement;

  /// No description provided for @orientation_location_library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get orientation_location_library;

  /// No description provided for @orientation_location_registrar.
  ///
  /// In en, this message translates to:
  /// **'Registrar'**
  String get orientation_location_registrar;

  /// No description provided for @orientation_location_sports_complex.
  ///
  /// In en, this message translates to:
  /// **'Sports Complex'**
  String get orientation_location_sports_complex;

  /// No description provided for @orientation_location_cafe.
  ///
  /// In en, this message translates to:
  /// **'Campus Café'**
  String get orientation_location_cafe;

  /// No description provided for @orientation_leaderboard_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get orientation_leaderboard_weekly;

  /// No description provided for @orientation_leaderboard_friends.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get orientation_leaderboard_friends;

  /// No description provided for @orientation_leaderboard_global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get orientation_leaderboard_global;

  /// No description provided for @orientation_photo_submitted_message.
  ///
  /// In en, this message translates to:
  /// **'Photo submitted for review!'**
  String get orientation_photo_submitted_message;

  /// No description provided for @orientation_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get orientation_progress_title;

  /// No description provided for @orientation_statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get orientation_statistics;

  /// No description provided for @orientation_tokens_earned.
  ///
  /// In en, this message translates to:
  /// **'Tokens Earned'**
  String get orientation_tokens_earned;

  /// No description provided for @orientation_bingo_completion.
  ///
  /// In en, this message translates to:
  /// **'Bingo Completion'**
  String get orientation_bingo_completion;

  /// No description provided for @orientation_achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get orientation_achievements;

  /// No description provided for @orientation_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get orientation_take_photo;

  /// No description provided for @orientation_choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get orientation_choose_from_gallery;

  /// No description provided for @orientation_submit_photo.
  ///
  /// In en, this message translates to:
  /// **'Submit Photo'**
  String get orientation_submit_photo;

  /// No description provided for @orientation_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get orientation_available;

  /// No description provided for @orientation_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get orientation_start;

  /// No description provided for @orientation_plus_n.
  ///
  /// In en, this message translates to:
  /// **'+{n}'**
  String orientation_plus_n(Object n);

  /// No description provided for @orientation_interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get orientation_interests;

  /// No description provided for @orientation_you_will_earn.
  ///
  /// In en, this message translates to:
  /// **'You will earn'**
  String get orientation_you_will_earn;

  /// No description provided for @orientation_foundation_year_short.
  ///
  /// In en, this message translates to:
  /// **'First Year'**
  String get orientation_foundation_year_short;

  /// No description provided for @orientation_leaderboard_school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get orientation_leaderboard_school;

  /// No description provided for @orientation_bingo_line_hint.
  ///
  /// In en, this message translates to:
  /// **'Complete a line to earn'**
  String get orientation_bingo_line_hint;

  /// No description provided for @orientation_bingo_start_hint.
  ///
  /// In en, this message translates to:
  /// **'Complete one more to earn'**
  String get orientation_bingo_start_hint;

  /// No description provided for @orientation_your_rank.
  ///
  /// In en, this message translates to:
  /// **'Your Rank'**
  String get orientation_your_rank;

  /// No description provided for @orientation_todays_highlights.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Highlights'**
  String get orientation_todays_highlights;

  /// No description provided for @orientation_highlight_bingo_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Progress {completed}/{total}'**
  String orientation_highlight_bingo_subtitle(Object completed, Object total);

  /// No description provided for @orientation_highlight_photo_quest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} locations left'**
  String orientation_highlight_photo_quest_subtitle(Object count);

  /// No description provided for @orientation_highlight_rewards_subtitle.
  ///
  /// In en, this message translates to:
  /// **'New rewards available'**
  String get orientation_highlight_rewards_subtitle;

  /// No description provided for @orientation_day_n_of_total.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String orientation_day_n_of_total(Object day, Object total);

  /// No description provided for @orientation_keep_going_name.
  ///
  /// In en, this message translates to:
  /// **'Keep going, {name}!'**
  String orientation_keep_going_name(Object name);

  /// No description provided for @orientation_keep_going.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get orientation_keep_going;

  /// No description provided for @orientation_friends_added.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get orientation_friends_added;

  /// No description provided for @orientation_locations_visited_label.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get orientation_locations_visited_label;

  /// No description provided for @orientation_how_it_works.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get orientation_how_it_works;

  /// No description provided for @orientation_how_it_works_body.
  ///
  /// In en, this message translates to:
  /// **'Take a photo at the location shown, then submit it for review. Once approved, your tokens are added automatically. Each location can only be completed once.'**
  String get orientation_how_it_works_body;

  /// No description provided for @orientation_status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orientation_status_label;

  /// No description provided for @orientation_reward_label.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get orientation_reward_label;

  /// No description provided for @orientation_campus_rewards.
  ///
  /// In en, this message translates to:
  /// **'Campus Rewards'**
  String get orientation_campus_rewards;

  /// No description provided for @orientation_nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get orientation_nav_home;

  /// No description provided for @orientation_nav_bingo.
  ///
  /// In en, this message translates to:
  /// **'Bingo'**
  String get orientation_nav_bingo;

  /// No description provided for @orientation_nav_quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get orientation_nav_quests;

  /// No description provided for @orientation_nav_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get orientation_nav_leaderboard;

  /// No description provided for @orientation_nav_rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get orientation_nav_rewards;

  /// No description provided for @orientation_bingo_bonus_label.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get orientation_bingo_bonus_label;

  /// No description provided for @orientation_bingo_bonus_lines.
  ///
  /// In en, this message translates to:
  /// **'{count} Lines'**
  String orientation_bingo_bonus_lines(Object count);

  /// No description provided for @orientation_mission_reward.
  ///
  /// In en, this message translates to:
  /// **'Mission Reward'**
  String get orientation_mission_reward;

  /// No description provided for @orientation_line_completion_reward.
  ///
  /// In en, this message translates to:
  /// **'Line Completion Reward'**
  String get orientation_line_completion_reward;

  /// No description provided for @orientation_board_completion_reward.
  ///
  /// In en, this message translates to:
  /// **'Board Completion Reward'**
  String get orientation_board_completion_reward;

  /// No description provided for @orientation_completed_missions.
  ///
  /// In en, this message translates to:
  /// **'Completed Missions'**
  String get orientation_completed_missions;

  /// No description provided for @orientation_your_journey.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get orientation_your_journey;

  /// No description provided for @orientation_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get orientation_you;

  /// No description provided for @orientation_leaderboard_rankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get orientation_leaderboard_rankings;

  /// No description provided for @orientation_your_position.
  ///
  /// In en, this message translates to:
  /// **'Your Position'**
  String get orientation_your_position;

  /// No description provided for @orientation_tokens_to_rank.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tokens to rank #{rank}'**
  String orientation_tokens_to_rank(Object tokens, Object rank);

  /// No description provided for @orientation_top_of_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'You\'re at the top!'**
  String get orientation_top_of_leaderboard;

  /// No description provided for @orientation_student_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get orientation_student_profile_title;

  /// No description provided for @orientation_orientation_explorer_badge.
  ///
  /// In en, this message translates to:
  /// **'Orientation Explorer'**
  String get orientation_orientation_explorer_badge;

  /// No description provided for @orientation_streak_days_n.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String orientation_streak_days_n(Object count);

  /// No description provided for @orientation_streak_active_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve completed challenges every day.'**
  String get orientation_streak_active_subtitle;

  /// No description provided for @orientation_streak_inactive_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new streak today.'**
  String get orientation_streak_inactive_subtitle;

  /// No description provided for @orientation_next_milestone.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get orientation_next_milestone;

  /// No description provided for @orientation_recently_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Recently Unlocked'**
  String get orientation_recently_unlocked;

  /// No description provided for @orientation_activity_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Activity Breakdown'**
  String get orientation_activity_breakdown;

  /// No description provided for @orientation_days_remaining.
  ///
  /// In en, this message translates to:
  /// **'{days} Days Remaining'**
  String orientation_days_remaining(Object days);

  /// No description provided for @orientation_orientation_complete.
  ///
  /// In en, this message translates to:
  /// **'Orientation Complete'**
  String get orientation_orientation_complete;

  /// No description provided for @orientation_milestone_started.
  ///
  /// In en, this message translates to:
  /// **'Orientation Started'**
  String get orientation_milestone_started;

  /// No description provided for @orientation_milestone_first_friend.
  ///
  /// In en, this message translates to:
  /// **'First Place Discovered'**
  String get orientation_milestone_first_friend;

  /// No description provided for @orientation_milestone_first_reward.
  ///
  /// In en, this message translates to:
  /// **'First Reward Earned'**
  String get orientation_milestone_first_reward;

  /// No description provided for @orientation_milestone_halfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway Complete'**
  String get orientation_milestone_halfway;

  /// No description provided for @orientation_milestone_campus_explorer.
  ///
  /// In en, this message translates to:
  /// **'Campus Explorer'**
  String get orientation_milestone_campus_explorer;

  /// No description provided for @orientation_milestone_complete.
  ///
  /// In en, this message translates to:
  /// **'Orientation Complete'**
  String get orientation_milestone_complete;

  /// No description provided for @orientation_category_orientation.
  ///
  /// In en, this message translates to:
  /// **'Orientation'**
  String get orientation_category_orientation;

  /// No description provided for @orientation_category_networking.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get orientation_category_networking;

  /// No description provided for @orientation_category_exploration.
  ///
  /// In en, this message translates to:
  /// **'Exploration'**
  String get orientation_category_exploration;

  /// No description provided for @orientation_category_participation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get orientation_category_participation;

  /// No description provided for @orientation_category_community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get orientation_category_community;

  /// No description provided for @orientation_category_special.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get orientation_category_special;

  /// No description provided for @orientation_achievements_unlocked_of_total.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked'**
  String orientation_achievements_unlocked_of_total(
    Object unlocked,
    Object total,
  );

  /// No description provided for @orientation_featured_achievement.
  ///
  /// In en, this message translates to:
  /// **'Featured Achievement'**
  String get orientation_featured_achievement;

  /// No description provided for @orientation_view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get orientation_view_details;

  /// No description provided for @orientation_hero_subtitle_1.
  ///
  /// In en, this message translates to:
  /// **'Your journey starts here.'**
  String get orientation_hero_subtitle_1;

  /// No description provided for @orientation_hero_subtitle_2.
  ///
  /// In en, this message translates to:
  /// **'Complete challenges, earn tokens, and unlock rewards.'**
  String get orientation_hero_subtitle_2;

  /// No description provided for @orientation_activities_completed.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} Activities Completed'**
  String orientation_activities_completed(Object completed, Object total);

  /// No description provided for @orientation_your_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get orientation_your_progress_title;

  /// No description provided for @orientation_tokens_of_level.
  ///
  /// In en, this message translates to:
  /// **'{tokens} / {total} Tokens'**
  String orientation_tokens_of_level(Object tokens, Object total);

  /// No description provided for @orientation_tokens_to_next_level.
  ///
  /// In en, this message translates to:
  /// **'{tokens} Tokens to next level'**
  String orientation_tokens_to_next_level(Object tokens);

  /// No description provided for @orientation_featured_reward_title.
  ///
  /// In en, this message translates to:
  /// **'Featured Reward'**
  String get orientation_featured_reward_title;

  /// No description provided for @orientation_recent_achievement_title.
  ///
  /// In en, this message translates to:
  /// **'Recent Achievement'**
  String get orientation_recent_achievement_title;

  /// No description provided for @orientation_continue_your_journey.
  ///
  /// In en, this message translates to:
  /// **'Continue Your Journey'**
  String get orientation_continue_your_journey;

  /// No description provided for @orientation_tab_overview.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get orientation_tab_overview;

  /// No description provided for @orientation_tab_challenges.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get orientation_tab_challenges;

  /// No description provided for @orientation_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get orientation_schedule;

  /// No description provided for @orientation_schedule_label.
  ///
  /// In en, this message translates to:
  /// **'ORIENTATION WEEK'**
  String get orientation_schedule_label;

  /// No description provided for @orientation_schedule_full.
  ///
  /// In en, this message translates to:
  /// **'Full schedule'**
  String get orientation_schedule_full;

  /// No description provided for @orientation_schedule_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get orientation_schedule_empty_title;

  /// No description provided for @orientation_schedule_empty_body.
  ///
  /// In en, this message translates to:
  /// **'No sessions on this day for your programme.'**
  String get orientation_schedule_empty_body;

  /// No description provided for @orientation_schedule_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get orientation_schedule_today;

  /// No description provided for @orientation_schedule_mandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory'**
  String get orientation_schedule_mandatory;

  /// No description provided for @orientation_schedule_recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get orientation_schedule_recommended;

  /// No description provided for @orientation_schedule_sessions.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String orientation_schedule_sessions(Object count);

  /// No description provided for @orientation_schedule_mandatory_count.
  ///
  /// In en, this message translates to:
  /// **'{count} mandatory'**
  String orientation_schedule_mandatory_count(Object count);

  /// No description provided for @orientation_track_question.
  ///
  /// In en, this message translates to:
  /// **'Which programme are you on?'**
  String get orientation_track_question;

  /// No description provided for @orientation_track_body.
  ///
  /// In en, this message translates to:
  /// **'The week runs two parallel timetables. Pick yours and the schedule will only show sessions that apply to you.'**
  String get orientation_track_body;

  /// No description provided for @orientation_track_ug.
  ///
  /// In en, this message translates to:
  /// **'Undergraduate'**
  String get orientation_track_ug;

  /// No description provided for @orientation_track_gr.
  ///
  /// In en, this message translates to:
  /// **'Graduate'**
  String get orientation_track_gr;

  /// No description provided for @orientation_track_change.
  ///
  /// In en, this message translates to:
  /// **'Change programme'**
  String get orientation_track_change;

  /// No description provided for @orientation_my_qr.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get orientation_my_qr;

  /// No description provided for @orientation_my_qr_body.
  ///
  /// In en, this message translates to:
  /// **'Show this to another student so they can scan you. Yours stays the same all week.'**
  String get orientation_my_qr_body;

  /// No description provided for @orientation_qr_scan_someone.
  ///
  /// In en, this message translates to:
  /// **'Scan someone'**
  String get orientation_qr_scan_someone;

  /// No description provided for @orientation_school_pending.
  ///
  /// In en, this message translates to:
  /// **'Detecting your school…'**
  String get orientation_school_pending;

  /// No description provided for @orientation_school_pending_body.
  ///
  /// In en, this message translates to:
  /// **'We match this automatically from your student ID. This only takes a moment.'**
  String get orientation_school_pending_body;

  /// No description provided for @orientation_school_unresolved_title.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t detect your school'**
  String get orientation_school_unresolved_title;

  /// No description provided for @orientation_school_unresolved_body.
  ///
  /// In en, this message translates to:
  /// **'Your student record doesn\'t have a school on file yet. Contact ADSL if this doesn\'t resolve on its own.'**
  String get orientation_school_unresolved_body;

  /// No description provided for @orientation_school_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get orientation_school_retry;

  /// No description provided for @orientation_school_scan_blocked.
  ///
  /// In en, this message translates to:
  /// **'We\'re still verifying your school. Try again in a moment.'**
  String get orientation_school_scan_blocked;

  /// No description provided for @orientation_scan_not_ours.
  ///
  /// In en, this message translates to:
  /// **'That is not an Orientation code'**
  String get orientation_scan_not_ours;

  /// No description provided for @orientation_scan_not_ours_body.
  ///
  /// In en, this message translates to:
  /// **'Ask them to open Orientation Week and show their own QR code.'**
  String get orientation_scan_not_ours_body;

  /// No description provided for @orientation_scan_self.
  ///
  /// In en, this message translates to:
  /// **'That is your own code'**
  String get orientation_scan_self;

  /// No description provided for @orientation_scan_self_body.
  ///
  /// In en, this message translates to:
  /// **'Find another student and scan theirs.'**
  String get orientation_scan_self_body;

  /// No description provided for @orientation_scan_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Already scanned'**
  String get orientation_scan_duplicate;

  /// No description provided for @orientation_scan_duplicate_body.
  ///
  /// In en, this message translates to:
  /// **'You have already counted {name} for this task.'**
  String orientation_scan_duplicate_body(Object name);

  /// No description provided for @orientation_scan_accepted.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get orientation_scan_accepted;

  /// No description provided for @orientation_challenges_title.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get orientation_challenges_title;

  /// No description provided for @orientation_challenges_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks that need an answer, a scan or a post.'**
  String get orientation_challenges_subtitle;

  /// No description provided for @orientation_ch_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Challenges Progress'**
  String get orientation_ch_progress_title;

  /// No description provided for @orientation_ch_progress_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer, scan and share your way through the week'**
  String get orientation_ch_progress_subtitle;

  /// No description provided for @orientation_ch_completed.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} challenges completed'**
  String orientation_ch_completed(Object done, Object total);

  /// No description provided for @orientation_ch_tokens_earned.
  ///
  /// In en, this message translates to:
  /// **'Tokens Earned'**
  String get orientation_ch_tokens_earned;

  /// No description provided for @orientation_challenge_save.
  ///
  /// In en, this message translates to:
  /// **'Save answer'**
  String get orientation_challenge_save;

  /// No description provided for @orientation_challenge_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit answer'**
  String get orientation_challenge_edit;

  /// No description provided for @orientation_challenge_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear answer'**
  String get orientation_challenge_clear;

  /// No description provided for @orientation_challenge_your_answer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get orientation_challenge_your_answer;

  /// No description provided for @orientation_challenge_open_referral.
  ///
  /// In en, this message translates to:
  /// **'Open referral'**
  String get orientation_challenge_open_referral;

  /// No description provided for @orientation_challenge_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get orientation_challenge_done;

  /// No description provided for @orientation_challenge_progress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String orientation_challenge_progress(Object done, Object total);

  /// No description provided for @orientation_tab_bingo.
  ///
  /// In en, this message translates to:
  /// **'Bingo'**
  String get orientation_tab_bingo;

  /// No description provided for @orientation_tab_photo_quest.
  ///
  /// In en, this message translates to:
  /// **'Photo Quest'**
  String get orientation_tab_photo_quest;

  /// No description provided for @orientation_tab_rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get orientation_tab_rewards;

  /// No description provided for @orientation_next_bingo_mission.
  ///
  /// In en, this message translates to:
  /// **'Next Mission'**
  String get orientation_next_bingo_mission;

  /// No description provided for @orientation_visit_location.
  ///
  /// In en, this message translates to:
  /// **'Visit the {location}'**
  String orientation_visit_location(Object location);

  /// No description provided for @orientation_redeem_a_reward.
  ///
  /// In en, this message translates to:
  /// **'Redeem a Reward'**
  String get orientation_redeem_a_reward;

  /// No description provided for @orientation_days_remaining_label.
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get orientation_days_remaining_label;

  /// No description provided for @orientation_total_tokens.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get orientation_total_tokens;

  /// No description provided for @orientation_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Orientation Week! 🎉'**
  String get orientation_welcome_title;

  /// No description provided for @orientation_welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Take part in exciting activities, explore the campus and earn rewards.'**
  String get orientation_welcome_subtitle;

  /// No description provided for @orientation_overall_progress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get orientation_overall_progress;

  /// No description provided for @orientation_missions_progress.
  ///
  /// In en, this message translates to:
  /// **'You\'ve completed {completed} of {total} missions'**
  String orientation_missions_progress(Object completed, Object total);

  /// No description provided for @orientation_complete_label.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get orientation_complete_label;

  /// No description provided for @orientation_missions_completed_label.
  ///
  /// In en, this message translates to:
  /// **'missions completed'**
  String get orientation_missions_completed_label;

  /// No description provided for @orientation_quick_access.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get orientation_quick_access;

  /// No description provided for @orientation_qr_scanner.
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get orientation_qr_scanner;

  /// No description provided for @orientation_qa_bingo.
  ///
  /// In en, this message translates to:
  /// **'Bingo'**
  String get orientation_qa_bingo;

  /// No description provided for @orientation_qa_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get orientation_qa_photos;

  /// No description provided for @orientation_qa_scan.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get orientation_qa_scan;

  /// No description provided for @orientation_qa_challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get orientation_qa_challenges;

  /// No description provided for @orientation_earn_rewards_title.
  ///
  /// In en, this message translates to:
  /// **'Earn Amazing Rewards'**
  String get orientation_earn_rewards_title;

  /// No description provided for @orientation_earn_rewards_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete missions, collect tokens and unlock exclusive Orientation Week rewards.'**
  String get orientation_earn_rewards_subtitle;

  /// No description provided for @orientation_view_rewards.
  ///
  /// In en, this message translates to:
  /// **'View Rewards'**
  String get orientation_view_rewards;

  /// No description provided for @orientation_bingo_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Complete. Mark. Win.'**
  String get orientation_bingo_hero_title;

  /// No description provided for @orientation_bingo_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete activities and get Bingo to earn more tokens!'**
  String get orientation_bingo_hero_subtitle;

  /// No description provided for @orientation_bingo_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Bingo Progress'**
  String get orientation_bingo_progress_title;

  /// No description provided for @orientation_bingo_progress_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete {target} lines to win big!'**
  String orientation_bingo_progress_subtitle(Object target);

  /// No description provided for @orientation_bingo_lines_completed.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} lines completed'**
  String orientation_bingo_lines_completed(Object completed, Object total);

  /// No description provided for @orientation_bingo_bonus_tokens.
  ///
  /// In en, this message translates to:
  /// **'Bonus Tokens'**
  String get orientation_bingo_bonus_tokens;

  /// No description provided for @orientation_bingo_free_space.
  ///
  /// In en, this message translates to:
  /// **'FREE SPACE'**
  String get orientation_bingo_free_space;

  /// No description provided for @orientation_bingo_cta_title.
  ///
  /// In en, this message translates to:
  /// **'Complete more, win more'**
  String get orientation_bingo_cta_title;

  /// No description provided for @orientation_bingo_cta_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep playing and unlock amazing rewards!'**
  String get orientation_bingo_cta_subtitle;

  /// No description provided for @orientation_bingo_mark_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get orientation_bingo_mark_complete;

  /// No description provided for @orientation_bingo_completed_label.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orientation_bingo_completed_label;

  /// No description provided for @orientation_bingo_squares_completed.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} squares'**
  String orientation_bingo_squares_completed(Object completed, Object total);

  /// No description provided for @orientation_bingo_line_complete_toast.
  ///
  /// In en, this message translates to:
  /// **'Line complete!'**
  String get orientation_bingo_line_complete_toast;

  /// No description provided for @orientation_bingo_board_complete_toast.
  ///
  /// In en, this message translates to:
  /// **'Bingo! Board complete'**
  String get orientation_bingo_board_complete_toast;

  /// No description provided for @orientation_pq_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Capture. Share. Earn.'**
  String get orientation_pq_hero_title;

  /// No description provided for @orientation_pq_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete photo missions around campus and earn amazing rewards!'**
  String get orientation_pq_hero_subtitle;

  /// No description provided for @orientation_pq_progress_title.
  ///
  /// In en, this message translates to:
  /// **'Photo Quest Progress'**
  String get orientation_pq_progress_title;

  /// No description provided for @orientation_pq_progress_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete missions to earn tokens!'**
  String get orientation_pq_progress_subtitle;

  /// No description provided for @orientation_pq_missions_completed.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} missions completed'**
  String orientation_pq_missions_completed(Object completed, Object total);

  /// No description provided for @orientation_pq_complete_all.
  ///
  /// In en, this message translates to:
  /// **'Complete all to earn'**
  String get orientation_pq_complete_all;

  /// No description provided for @orientation_pq_all_missions.
  ///
  /// In en, this message translates to:
  /// **'All Missions'**
  String get orientation_pq_all_missions;

  /// No description provided for @orientation_pq_easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get orientation_pq_easy;

  /// No description provided for @orientation_pq_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get orientation_pq_medium;

  /// No description provided for @orientation_pq_hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get orientation_pq_hard;

  /// No description provided for @orientation_pq_cta_title.
  ///
  /// In en, this message translates to:
  /// **'Complete more photo quests!'**
  String get orientation_pq_cta_title;

  /// No description provided for @orientation_pq_cta_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish all missions to earn bonus tokens and exclusive rewards.'**
  String get orientation_pq_cta_subtitle;

  /// No description provided for @orientation_pq_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get orientation_pq_completed;

  /// No description provided for @orientation_pq_requirements.
  ///
  /// In en, this message translates to:
  /// **'What your photo must show'**
  String get orientation_pq_requirements;

  /// No description provided for @orientation_pq_where.
  ///
  /// In en, this message translates to:
  /// **'Where to take it'**
  String get orientation_pq_where;

  /// No description provided for @orientation_pq_reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get orientation_pq_reward;

  /// No description provided for @orientation_pq_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get orientation_pq_difficulty;

  /// No description provided for @orientation_pq_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get orientation_pq_take_photo;

  /// No description provided for @orientation_pq_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get orientation_pq_from_gallery;

  /// No description provided for @orientation_pq_retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get orientation_pq_retake;

  /// No description provided for @orientation_pq_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit Photo'**
  String get orientation_pq_submit;

  /// No description provided for @orientation_pq_submission_title.
  ///
  /// In en, this message translates to:
  /// **'Submit your photo'**
  String get orientation_pq_submission_title;

  /// No description provided for @orientation_pq_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get orientation_pq_status_pending;

  /// No description provided for @orientation_pq_status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Needs a better photo'**
  String get orientation_pq_status_rejected;

  /// No description provided for @orientation_pq_status_locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get orientation_pq_status_locked;

  /// No description provided for @orientation_pq_status_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get orientation_pq_status_expired;

  /// No description provided for @orientation_pq_notify_approved_title.
  ///
  /// In en, this message translates to:
  /// **'Photo Quest approved'**
  String get orientation_pq_notify_approved_title;

  /// No description provided for @orientation_pq_notify_approved_body.
  ///
  /// In en, this message translates to:
  /// **'{mission} was verified — you earned {tokens} tokens.'**
  String orientation_pq_notify_approved_body(String mission, int tokens);

  /// No description provided for @orientation_pq_notify_declined_title.
  ///
  /// In en, this message translates to:
  /// **'Photo needs a retake'**
  String get orientation_pq_notify_declined_title;

  /// No description provided for @orientation_pq_notify_declined_body.
  ///
  /// In en, this message translates to:
  /// **'{mission} was not accepted. Take a new photo to try again.'**
  String orientation_pq_notify_declined_body(String mission);

  /// No description provided for @orientation_pq_empty_filter.
  ///
  /// In en, this message translates to:
  /// **'No missions at this difficulty yet.'**
  String get orientation_pq_empty_filter;

  /// No description provided for @orientation_pq_bonus_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Photo Quest complete!'**
  String get orientation_pq_bonus_unlocked;

  /// No description provided for @orientation_rw_hero_title_1.
  ///
  /// In en, this message translates to:
  /// **'Your effort.'**
  String get orientation_rw_hero_title_1;

  /// No description provided for @orientation_rw_hero_title_2a.
  ///
  /// In en, this message translates to:
  /// **'Great '**
  String get orientation_rw_hero_title_2a;

  /// No description provided for @orientation_rw_hero_title_2b.
  ///
  /// In en, this message translates to:
  /// **'rewards.'**
  String get orientation_rw_hero_title_2b;

  /// No description provided for @orientation_rw_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem your tokens for amazing rewards and experiences.'**
  String get orientation_rw_hero_subtitle;

  /// No description provided for @orientation_rw_browse_category.
  ///
  /// In en, this message translates to:
  /// **'Browse by Category'**
  String get orientation_rw_browse_category;

  /// No description provided for @orientation_rw_token_rewards.
  ///
  /// In en, this message translates to:
  /// **'Token Rewards'**
  String get orientation_rw_token_rewards;

  /// No description provided for @orientation_rw_cat_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get orientation_rw_cat_all;

  /// No description provided for @orientation_rw_cat_merch.
  ///
  /// In en, this message translates to:
  /// **'Merch'**
  String get orientation_rw_cat_merch;

  /// No description provided for @orientation_rw_cat_gift_cards.
  ///
  /// In en, this message translates to:
  /// **'Gift Cards'**
  String get orientation_rw_cat_gift_cards;

  /// No description provided for @orientation_rw_cat_experiences.
  ///
  /// In en, this message translates to:
  /// **'Experiences'**
  String get orientation_rw_cat_experiences;

  /// No description provided for @orientation_rw_cat_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get orientation_rw_cat_other;

  /// No description provided for @orientation_rw_tokens_suffix.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String orientation_rw_tokens_suffix(Object count);

  /// No description provided for @orientation_rw_hot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get orientation_rw_hot;

  /// No description provided for @orientation_rw_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get orientation_rw_unlimited;

  /// No description provided for @orientation_rw_limited.
  ///
  /// In en, this message translates to:
  /// **'Limited: {count} left'**
  String orientation_rw_limited(Object count);

  /// No description provided for @orientation_rw_out_of_stock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get orientation_rw_out_of_stock;

  /// No description provided for @orientation_rw_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get orientation_rw_coming_soon;

  /// No description provided for @orientation_rw_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get orientation_rw_expired;

  /// No description provided for @orientation_rw_redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get orientation_rw_redeem;

  /// No description provided for @orientation_rw_redeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get orientation_rw_redeemed;

  /// No description provided for @orientation_rw_need_more.
  ///
  /// In en, this message translates to:
  /// **'You need {count} more tokens'**
  String orientation_rw_need_more(Object count);

  /// No description provided for @orientation_rw_earn_more.
  ///
  /// In en, this message translates to:
  /// **'Earn more'**
  String get orientation_rw_earn_more;

  /// No description provided for @orientation_rw_details.
  ///
  /// In en, this message translates to:
  /// **'Reward Details'**
  String get orientation_rw_details;

  /// No description provided for @orientation_rw_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get orientation_rw_terms;

  /// No description provided for @orientation_rw_how_to_redeem.
  ///
  /// In en, this message translates to:
  /// **'How to redeem'**
  String get orientation_rw_how_to_redeem;

  /// No description provided for @orientation_rw_availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get orientation_rw_availability;

  /// No description provided for @orientation_rw_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get orientation_rw_remaining;

  /// No description provided for @orientation_rw_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Confirm redemption'**
  String get orientation_rw_confirm_title;

  /// No description provided for @orientation_rw_confirm_balance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get orientation_rw_confirm_balance;

  /// No description provided for @orientation_rw_confirm_cost.
  ///
  /// In en, this message translates to:
  /// **'Reward cost'**
  String get orientation_rw_confirm_cost;

  /// No description provided for @orientation_rw_confirm_after.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get orientation_rw_confirm_after;

  /// No description provided for @orientation_rw_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get orientation_rw_cancel;

  /// No description provided for @orientation_rw_success_title.
  ///
  /// In en, this message translates to:
  /// **'Reward redeemed!'**
  String get orientation_rw_success_title;

  /// No description provided for @orientation_rw_success_body.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your reward. Check your history to collect it.'**
  String get orientation_rw_success_body;

  /// No description provided for @orientation_rw_view_history.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get orientation_rw_view_history;

  /// No description provided for @orientation_rw_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get orientation_rw_done;

  /// No description provided for @orientation_rw_history_title.
  ///
  /// In en, this message translates to:
  /// **'Redemption History'**
  String get orientation_rw_history_title;

  /// No description provided for @orientation_rw_exclusive_claimed_title.
  ///
  /// In en, this message translates to:
  /// **'Exclusive prize claimed'**
  String get orientation_rw_exclusive_claimed_title;

  /// No description provided for @orientation_rw_exclusive_claimed_body.
  ///
  /// In en, this message translates to:
  /// **'You already claimed one of the top prizes — further redeems are locked.'**
  String get orientation_rw_exclusive_claimed_body;

  /// No description provided for @orientation_rw_history_empty.
  ///
  /// In en, this message translates to:
  /// **'You have not redeemed any rewards yet.'**
  String get orientation_rw_history_empty;

  /// No description provided for @orientation_rw_collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get orientation_rw_collected;

  /// No description provided for @orientation_rw_to_collect.
  ///
  /// In en, this message translates to:
  /// **'Ready to collect'**
  String get orientation_rw_to_collect;

  /// No description provided for @orientation_rw_milestones_title.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get orientation_rw_milestones_title;

  /// No description provided for @orientation_rw_keep_collecting.
  ///
  /// In en, this message translates to:
  /// **'Keep collecting!'**
  String get orientation_rw_keep_collecting;

  /// No description provided for @orientation_rw_milestone_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach new milestones to unlock even better rewards.'**
  String get orientation_rw_milestone_subtitle;

  /// No description provided for @orientation_rw_view_milestones.
  ///
  /// In en, this message translates to:
  /// **'View Milestones'**
  String get orientation_rw_view_milestones;

  /// No description provided for @orientation_rw_next_milestone.
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get orientation_rw_next_milestone;

  /// No description provided for @orientation_rw_unlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get orientation_rw_unlocked;

  /// No description provided for @orientation_rw_locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get orientation_rw_locked;

  /// No description provided for @orientation_rw_empty_category.
  ///
  /// In en, this message translates to:
  /// **'No rewards in this category yet.'**
  String get orientation_rw_empty_category;

  /// No description provided for @orientation_bingo_scan_qr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get orientation_bingo_scan_qr;

  /// No description provided for @orientation_bingo_scan_hint.
  ///
  /// In en, this message translates to:
  /// **'Ask a supervisor to show their QR code to confirm this task.'**
  String get orientation_bingo_scan_hint;

  /// No description provided for @orientation_bingo_auto_title.
  ///
  /// In en, this message translates to:
  /// **'Tracked automatically'**
  String get orientation_bingo_auto_title;

  /// No description provided for @orientation_bingo_auto_hint.
  ///
  /// In en, this message translates to:
  /// **'The app marks this done for you when you complete it.'**
  String get orientation_bingo_auto_hint;

  /// No description provided for @orientation_bingo_open_task.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get orientation_bingo_open_task;

  /// No description provided for @orientation_bingo_photo_hint.
  ///
  /// In en, this message translates to:
  /// **'This square is a Photo Quest — take the photo in the Photo Quest tab.'**
  String get orientation_bingo_photo_hint;

  /// No description provided for @orientation_challenge_wrong_answer.
  ///
  /// In en, this message translates to:
  /// **'That\'s not the right answer — check it and try again.'**
  String get orientation_challenge_wrong_answer;

  /// No description provided for @orientation_challenge_invalid_student_id.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Student ID — the number on their NU card.'**
  String get orientation_challenge_invalid_student_id;

  /// No description provided for @orientation_challenge_senior_not_found.
  ///
  /// In en, this message translates to:
  /// **'This Student ID was not found in the university directory. Check the number and try again.'**
  String get orientation_challenge_senior_not_found;

  /// No description provided for @orientation_challenge_senior_too_recent.
  ///
  /// In en, this message translates to:
  /// **'This person has been at NU for less than three years. Find someone more senior!'**
  String get orientation_challenge_senior_too_recent;

  /// No description provided for @orientation_challenge_own_student_id.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own Student ID — the advice has to come from someone else!'**
  String get orientation_challenge_own_student_id;

  /// No description provided for @orientation_bingo_scan_instruction.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the club\'s QR'**
  String get orientation_bingo_scan_instruction;

  /// No description provided for @orientation_bingo_scan_failed.
  ///
  /// In en, this message translates to:
  /// **'That code was not recognised. Try again.'**
  String get orientation_bingo_scan_failed;

  /// No description provided for @orientation_rw_total_spent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get orientation_rw_total_spent;

  /// No description provided for @orientation_rw_redeemed_count.
  ///
  /// In en, this message translates to:
  /// **'{count} redeemed'**
  String orientation_rw_redeemed_count(Object count);

  /// No description provided for @orientation_about_title.
  ///
  /// In en, this message translates to:
  /// **'What is Club Fair?'**
  String get orientation_about_title;

  /// No description provided for @orientation_about_body.
  ///
  /// In en, this message translates to:
  /// **'NU clubs in the Atrium - walk the stands, scan club QRs, complete tasks, and spend tokens on prizes.'**
  String get orientation_about_body;

  /// No description provided for @orientation_about_point_explore_title.
  ///
  /// In en, this message translates to:
  /// **'Getting to know the clubs'**
  String get orientation_about_point_explore_title;

  /// No description provided for @orientation_about_point_explore_body.
  ///
  /// In en, this message translates to:
  /// **'All booths are in the NU Atrium, in two time blocks: 11:00–14:00 and 15:00–18:00.'**
  String get orientation_about_point_explore_body;

  /// No description provided for @orientation_about_point_connect_title.
  ///
  /// In en, this message translates to:
  /// **'Scan and bingo'**
  String get orientation_about_point_connect_title;

  /// No description provided for @orientation_about_point_connect_body.
  ///
  /// In en, this message translates to:
  /// **'Scan club QRs for tokens. Bingo is 16 random clubs from the full list.'**
  String get orientation_about_point_connect_body;

  /// No description provided for @orientation_about_point_earn_title.
  ///
  /// In en, this message translates to:
  /// **'Tokens and prizes'**
  String get orientation_about_point_earn_title;

  /// No description provided for @orientation_about_point_earn_body.
  ///
  /// In en, this message translates to:
  /// **'Redeem tokens in the Rewards tab.'**
  String get orientation_about_point_earn_body;

  /// No description provided for @orientation_about_hide.
  ///
  /// In en, this message translates to:
  /// **'Got it, hide'**
  String get orientation_about_hide;

  /// No description provided for @orientation_partner_title.
  ///
  /// In en, this message translates to:
  /// **'Together with ADSL'**
  String get orientation_partner_title;

  /// No description provided for @orientation_partner_body.
  ///
  /// In en, this message translates to:
  /// **'ADSL (Association for the Development of Student Life) is NU\'s student nonprofit that supports initiatives, leadership, and an active student community.'**
  String get orientation_partner_body;

  /// No description provided for @orientation_partner_instagram_cta.
  ///
  /// In en, this message translates to:
  /// **'Open Instagram'**
  String get orientation_partner_instagram_cta;

  /// No description provided for @orientation_challenge_open_link.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get orientation_challenge_open_link;

  /// No description provided for @orientation_rw_claim_title.
  ///
  /// In en, this message translates to:
  /// **'How to get your prize'**
  String get orientation_rw_claim_title;

  /// No description provided for @orientation_rw_claim_intro.
  ///
  /// In en, this message translates to:
  /// **'Rewards are redeemed in the app, and handed over in person.'**
  String get orientation_rw_claim_intro;

  /// No description provided for @orientation_rw_claim_step1.
  ///
  /// In en, this message translates to:
  /// **'Redeem the reward in the app.'**
  String get orientation_rw_claim_step1;

  /// No description provided for @orientation_rw_claim_step2.
  ///
  /// In en, this message translates to:
  /// **'Message {number} on WhatsApp and say which reward you redeemed.'**
  String orientation_rw_claim_step2(String number);

  /// No description provided for @orientation_rw_claim_step3.
  ///
  /// In en, this message translates to:
  /// **'Collect it in person. There is an additional check on site before the prize is handed over.'**
  String get orientation_rw_claim_step3;

  /// No description provided for @orientation_rw_claim_cta.
  ///
  /// In en, this message translates to:
  /// **'Message on WhatsApp'**
  String get orientation_rw_claim_cta;

  /// No description provided for @orientation_closed_title.
  ///
  /// In en, this message translates to:
  /// **'Club Fair has ended'**
  String get orientation_closed_title;

  /// No description provided for @orientation_closed_body.
  ///
  /// In en, this message translates to:
  /// **'This year\'s Club Fair is over. Thank you for taking part — see you next year!'**
  String get orientation_closed_body;

  /// No description provided for @orientation_freshmen_title.
  ///
  /// In en, this message translates to:
  /// **'For freshmen only'**
  String get orientation_freshmen_title;

  /// No description provided for @orientation_freshmen_body.
  ///
  /// In en, this message translates to:
  /// **'Orientation Week is only for first-year students — NUFYP, first-year undergraduates, and first-year graduate students. If you\'re not a freshman, please don\'t complete the tasks — you won\'t receive the prizes anyway. If you claim a prize regardless, you won\'t be able to collect it, and it will cause problems for the freshmen who are eligible. Please be considerate.'**
  String get orientation_freshmen_body;

  /// No description provided for @orientation_freshmen_acknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get orientation_freshmen_acknowledge;

  /// No description provided for @orientation_freshmen_card_title.
  ///
  /// In en, this message translates to:
  /// **'Who can participate'**
  String get orientation_freshmen_card_title;

  /// No description provided for @orientation_rw_view_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get orientation_rw_view_details;

  /// No description provided for @orientation_rw_redemption_details.
  ///
  /// In en, this message translates to:
  /// **'Redemption details'**
  String get orientation_rw_redemption_details;

  /// No description provided for @orientation_rw_redeemed_on.
  ///
  /// In en, this message translates to:
  /// **'Redeemed on'**
  String get orientation_rw_redeemed_on;

  /// No description provided for @orientation_rw_tokens_spent.
  ///
  /// In en, this message translates to:
  /// **'Tokens spent'**
  String get orientation_rw_tokens_spent;

  /// No description provided for @orientation_rw_redeemed_by.
  ///
  /// In en, this message translates to:
  /// **'Redeemed by'**
  String get orientation_rw_redeemed_by;

  /// No description provided for @orientation_rw_field_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get orientation_rw_field_name;

  /// No description provided for @orientation_rw_field_student_id.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get orientation_rw_field_student_id;

  /// No description provided for @orientation_rw_field_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get orientation_rw_field_email;

  /// No description provided for @orientation_rw_field_unset.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get orientation_rw_field_unset;

  /// No description provided for @orientation_journey_title.
  ///
  /// In en, this message translates to:
  /// **'Your 7-Day Journey'**
  String get orientation_journey_title;

  /// No description provided for @orientation_journey_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Day {current} of {total}'**
  String orientation_journey_subtitle(Object current, Object total);

  /// No description provided for @orientation_journey_day.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String orientation_journey_day(Object n);

  /// No description provided for @orientation_view_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'View Leaderboard'**
  String get orientation_view_leaderboard;

  /// No description provided for @orientation_leaderboard_cta_subtitle.
  ///
  /// In en, this message translates to:
  /// **'See how you rank against other students'**
  String get orientation_leaderboard_cta_subtitle;

  /// No description provided for @orientation_faq_title.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get orientation_faq_title;

  /// No description provided for @orientation_faq_q1.
  ///
  /// In en, this message translates to:
  /// **'Who can take part?'**
  String get orientation_faq_q1;

  /// No description provided for @orientation_faq_a1.
  ///
  /// In en, this message translates to:
  /// **'Any NU student. Club Fair is for the whole campus!'**
  String get orientation_faq_a1;

  /// No description provided for @orientation_faq_q2.
  ///
  /// In en, this message translates to:
  /// **'When and where is it?'**
  String get orientation_faq_q2;

  /// No description provided for @orientation_faq_a2.
  ///
  /// In en, this message translates to:
  /// **'From 23 to 27 August 2026 at NU Atrium. Club stands - Mon–Thu, 11:00–14:00 and 15:00–18:00 (Thursday morning only).'**
  String get orientation_faq_a2;

  /// No description provided for @orientation_faq_q3.
  ///
  /// In en, this message translates to:
  /// **'How do club QR scans work?'**
  String get orientation_faq_q3;

  /// No description provided for @orientation_faq_a3.
  ///
  /// In en, this message translates to:
  /// **'The club representative shows a QR (it changes every 20 seconds). Scan it and get tokens, awarded once per club.'**
  String get orientation_faq_a3;

  /// No description provided for @orientation_faq_q4.
  ///
  /// In en, this message translates to:
  /// **'How do tokens work?'**
  String get orientation_faq_q4;

  /// No description provided for @orientation_faq_a4.
  ///
  /// In en, this message translates to:
  /// **'There is no daily or weekly earn cap. You earn tokens from club scans, tasks, photo missions, venue QRs, bingo lines (+50) and grand bingo (+200). Spend them in the Rewards tab.'**
  String get orientation_faq_a4;

  /// No description provided for @orientation_faq_q5.
  ///
  /// In en, this message translates to:
  /// **'How does bingo work?'**
  String get orientation_faq_q5;

  /// No description provided for @orientation_faq_a5.
  ///
  /// In en, this message translates to:
  /// **'The card is 16 random clubs on a 4×4 grid. Scanning a club closes that square. A line gives +50, four lines - +200 once.'**
  String get orientation_faq_a5;

  /// No description provided for @orientation_faq_q6.
  ///
  /// In en, this message translates to:
  /// **'How do I collect a prize?'**
  String get orientation_faq_q6;

  /// No description provided for @orientation_faq_a6.
  ///
  /// In en, this message translates to:
  /// **'Redeem in the Rewards tab, then message the listed number on WhatsApp. The prize is handed over in person after a check. If you have technical questions about the app or the quest, please use the button provided to reach our Telegram channel.'**
  String get orientation_faq_a6;

  /// No description provided for @orientation_club_scan_title.
  ///
  /// In en, this message translates to:
  /// **'Club QR'**
  String get orientation_club_scan_title;

  /// No description provided for @orientation_club_scan_cta.
  ///
  /// In en, this message translates to:
  /// **'Scan club QR'**
  String get orientation_club_scan_cta;

  /// No description provided for @orientation_club_scan_progress.
  ///
  /// In en, this message translates to:
  /// **'{scanned} of {total} clubs'**
  String orientation_club_scan_progress(Object scanned, Object total);

  /// No description provided for @orientation_club_scan_tokens.
  ///
  /// In en, this message translates to:
  /// **'{tokens} tokens from scans'**
  String orientation_club_scan_tokens(Object tokens);

  /// No description provided for @orientation_club_scan_already.
  ///
  /// In en, this message translates to:
  /// **'You already scanned this club.'**
  String get orientation_club_scan_already;

  /// No description provided for @orientation_club_scan_wrong.
  ///
  /// In en, this message translates to:
  /// **'That is not a Club Fair stand QR.'**
  String get orientation_club_scan_wrong;

  /// No description provided for @orientation_club_scan_expired.
  ///
  /// In en, this message translates to:
  /// **'QR expired - ask them to show a fresh one.'**
  String get orientation_club_scan_expired;

  /// No description provided for @orientation_club_scan_own.
  ///
  /// In en, this message translates to:
  /// **'You cannot scan your own club QR.'**
  String get orientation_club_scan_own;

  /// No description provided for @orientation_club_scan_outside.
  ///
  /// In en, this message translates to:
  /// **'This club is not at Club Fair right now. Check the time and schedule.'**
  String get orientation_club_scan_outside;

  /// No description provided for @orientation_club_scan_closed.
  ///
  /// In en, this message translates to:
  /// **'Club Fair is not open yet.'**
  String get orientation_club_scan_closed;

  /// No description provided for @orientation_tasks_group_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get orientation_tasks_group_all;

  /// No description provided for @orientation_tasks_group_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get orientation_tasks_group_general;

  /// No description provided for @orientation_tasks_group_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get orientation_tasks_group_today;

  /// No description provided for @orientation_tasks_group_clubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get orientation_tasks_group_clubs;

  /// No description provided for @orientation_tasks_group_photos.
  ///
  /// In en, this message translates to:
  /// **'Photo tasks'**
  String get orientation_tasks_group_photos;

  /// No description provided for @orientation_tasks_group_qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get orientation_tasks_group_qr;

  /// No description provided for @orientation_schedule_morning.
  ///
  /// In en, this message translates to:
  /// **'11:00–14:00'**
  String get orientation_schedule_morning;

  /// No description provided for @orientation_schedule_afternoon.
  ///
  /// In en, this message translates to:
  /// **'15:00–18:00'**
  String get orientation_schedule_afternoon;

  /// No description provided for @orientation_schedule_always.
  ///
  /// In en, this message translates to:
  /// **'All week'**
  String get orientation_schedule_always;

  /// No description provided for @orientation_schedule_atrium.
  ///
  /// In en, this message translates to:
  /// **'NU Atrium'**
  String get orientation_schedule_atrium;

  /// No description provided for @orientation_schedule_in_quest.
  ///
  /// In en, this message translates to:
  /// **'Quest'**
  String get orientation_schedule_in_quest;

  /// No description provided for @orientation_rw_tech_cta.
  ///
  /// In en, this message translates to:
  /// **'Technical questions'**
  String get orientation_rw_tech_cta;

  /// No description provided for @orientation_rw_tech_body.
  ///
  /// In en, this message translates to:
  /// **'If you have technical problems or questions, please reach out in our Telegram channel!'**
  String get orientation_rw_tech_body;

  /// No description provided for @orientation_rw_tech_open.
  ///
  /// In en, this message translates to:
  /// **'Open Telegram'**
  String get orientation_rw_tech_open;

  /// No description provided for @orientation_qa_rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get orientation_qa_rewards;

  /// No description provided for @orientation_club_stand_qr_cta.
  ///
  /// In en, this message translates to:
  /// **'Show stand QR'**
  String get orientation_club_stand_qr_cta;

  /// No description provided for @orientation_club_stand_qr_title.
  ///
  /// In en, this message translates to:
  /// **'Stand QR'**
  String get orientation_club_stand_qr_title;

  /// No description provided for @orientation_club_stand_qr_body.
  ///
  /// In en, this message translates to:
  /// **'Hold this up at your booth. The code changes every {seconds} seconds so a photo from the chat will not work.'**
  String orientation_club_stand_qr_body(int seconds);

  /// No description provided for @orientation_club_stand_qr_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refreshes in {seconds}s'**
  String orientation_club_stand_qr_refresh(int seconds);

  /// No description provided for @orientation_club_stand_qr_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get orientation_club_stand_qr_live;

  /// No description provided for @orientation_club_stand_qr_waiting.
  ///
  /// In en, this message translates to:
  /// **'Stand closed'**
  String get orientation_club_stand_qr_waiting;

  /// No description provided for @orientation_club_stand_qr_waiting_body.
  ///
  /// In en, this message translates to:
  /// **'The live code appears only during your Club Fair slot.'**
  String get orientation_club_stand_qr_waiting_body;

  /// No description provided for @orientation_club_stand_qr_window.
  ///
  /// In en, this message translates to:
  /// **'Show this QR {window}.'**
  String orientation_club_stand_qr_window(String window);

  /// No description provided for @orientation_club_stand_qr_all_week.
  ///
  /// In en, this message translates to:
  /// **'any time during Club Fair'**
  String get orientation_club_stand_qr_all_week;

  /// No description provided for @orientation_club_stand_qr_not_rep.
  ///
  /// In en, this message translates to:
  /// **'This account is not listed as a club representative.'**
  String get orientation_club_stand_qr_not_rep;

  /// No description provided for @orientation_club_ranking_cta.
  ///
  /// In en, this message translates to:
  /// **'Club Fair ranking'**
  String get orientation_club_ranking_cta;

  /// No description provided for @orientation_club_ranking_cta_subtitle.
  ///
  /// In en, this message translates to:
  /// **'See which clubs students visited most'**
  String get orientation_club_ranking_cta_subtitle;

  /// No description provided for @orientation_club_ranking_title.
  ///
  /// In en, this message translates to:
  /// **'Club Fair ranking'**
  String get orientation_club_ranking_title;

  /// No description provided for @orientation_club_ranking_list.
  ///
  /// In en, this message translates to:
  /// **'All clubs'**
  String get orientation_club_ranking_list;

  /// No description provided for @orientation_club_ranking_scans.
  ///
  /// In en, this message translates to:
  /// **'{count} scans'**
  String orientation_club_ranking_scans(int count);

  /// No description provided for @orientation_club_ranking_total.
  ///
  /// In en, this message translates to:
  /// **'{scans} scans · {clubs} clubs'**
  String orientation_club_ranking_total(int scans, int clubs);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
