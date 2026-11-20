import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('ca'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ca, this message translates to:
  /// **'AProp!'**
  String get appTitle;

  /// No description provided for @profileTitleFallback.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get profileTitleFallback;

  /// No description provided for @profilePeopleSearchSoon.
  ///
  /// In ca, this message translates to:
  /// **'Cerca de persones disponible properament'**
  String get profilePeopleSearchSoon;

  /// No description provided for @settingsTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Configuració'**
  String get settingsTooltip;

  /// No description provided for @profileLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant el perfil'**
  String get profileLoading;

  /// No description provided for @retry.
  ///
  /// In ca, this message translates to:
  /// **'Tornar-ho a provar'**
  String get retry;

  /// No description provided for @profileTabCompletedPlans.
  ///
  /// In ca, this message translates to:
  /// **'Plans fets'**
  String get profileTabCompletedPlans;

  /// No description provided for @profileTabCreatedByMe.
  ///
  /// In ca, this message translates to:
  /// **'Creats per mi'**
  String get profileTabCreatedByMe;

  /// No description provided for @profileCreatedLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant les activitats creades'**
  String get profileCreatedLoading;

  /// No description provided for @profileNoCompletedPlans.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens plans fets'**
  String get profileNoCompletedPlans;

  /// No description provided for @profileCompletedHistorySoon.
  ///
  /// In ca, this message translates to:
  /// **'Historial d’assistència disponible properament'**
  String get profileCompletedHistorySoon;

  /// No description provided for @profileNoCreated.
  ///
  /// In ca, this message translates to:
  /// **'Encara no has creat cap activitat'**
  String get profileNoCreated;

  /// No description provided for @profileCompletedHint.
  ///
  /// In ca, this message translates to:
  /// **'Aquí veuràs les activitats amb assistència confirmada.'**
  String get profileCompletedHint;

  /// No description provided for @profileSavedPlansHint.
  ///
  /// In ca, this message translates to:
  /// **'Pots consultar els plans guardats a l’Agenda.'**
  String get profileSavedPlansHint;

  /// No description provided for @profileCreateHint.
  ///
  /// In ca, this message translates to:
  /// **'Pots crear-ne una des d’Inici.'**
  String get profileCreateHint;

  /// No description provided for @profileLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar el perfil. Torna-ho a provar.'**
  String get profileLoadError;

  /// No description provided for @profileCreatedLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les activitats creades.'**
  String get profileCreatedLoadError;

  /// No description provided for @publicProfileLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar el perfil.'**
  String get publicProfileLoadError;

  /// No description provided for @publicProfileNotFound.
  ///
  /// In ca, this message translates to:
  /// **'Aquest perfil no existeix o ja no està disponible.'**
  String get publicProfileNotFound;

  /// No description provided for @publicProfileTabCreated.
  ///
  /// In ca, this message translates to:
  /// **'Creats'**
  String get publicProfileTabCreated;

  /// No description provided for @publicProfilePlansLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar els plans.'**
  String get publicProfilePlansLoadError;

  /// No description provided for @publicProfilePlansFriendsOnly.
  ///
  /// In ca, this message translates to:
  /// **'Els plans de {name} només els poden veure els seus amics.'**
  String publicProfilePlansFriendsOnly(String name);

  /// No description provided for @publicProfilePlansHidden.
  ///
  /// In ca, this message translates to:
  /// **'{name} no comparteix els seus plans.'**
  String publicProfilePlansHidden(String name);

  /// No description provided for @publicProfileNoPlans.
  ///
  /// In ca, this message translates to:
  /// **'{name} encara no té plans fets.'**
  String publicProfileNoPlans(String name);

  /// No description provided for @publicProfileNoCreated.
  ///
  /// In ca, this message translates to:
  /// **'{name} encara no ha creat cap activitat.'**
  String publicProfileNoCreated(String name);

  /// No description provided for @profileBiographyTooLong.
  ///
  /// In ca, this message translates to:
  /// **'La biografia és massa llarga. Prova de fer-la més curta.'**
  String get profileBiographyTooLong;

  /// No description provided for @profileMunicipalityTooLong.
  ///
  /// In ca, this message translates to:
  /// **'Escriu com a màxim 80 caràcters.'**
  String get profileMunicipalityTooLong;

  /// No description provided for @profileNameRequired.
  ///
  /// In ca, this message translates to:
  /// **'Escriu el teu nom.'**
  String get profileNameRequired;

  /// No description provided for @profileNameTooLong.
  ///
  /// In ca, this message translates to:
  /// **'El nom és massa llarg.'**
  String get profileNameTooLong;

  /// No description provided for @profileUsernameInvalid.
  ///
  /// In ca, this message translates to:
  /// **'Fes servir entre 3 i 30 lletres, números o guions baixos.'**
  String get profileUsernameInvalid;

  /// No description provided for @profileUsernameTaken.
  ///
  /// In ca, this message translates to:
  /// **'El nom d’usuari ja està ocupat. Tria’n un altre.'**
  String get profileUsernameTaken;

  /// No description provided for @profileSaveError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar el perfil. Torna-ho a provar.'**
  String get profileSaveError;

  /// No description provided for @profileAvatarError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut canviar la foto. Torna-ho a provar.'**
  String get profileAvatarError;

  /// No description provided for @profileAvatarInterrupted.
  ///
  /// In ca, this message translates to:
  /// **'S’ha interromput una selecció de foto. Torna-la a triar.'**
  String get profileAvatarInterrupted;

  /// No description provided for @avatarTooBig.
  ///
  /// In ca, this message translates to:
  /// **'Tria una foto de menys de 5 MB.'**
  String get avatarTooBig;

  /// No description provided for @avatarNameUnreadable.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut llegir el nom de la foto.'**
  String get avatarNameUnreadable;

  /// No description provided for @avatarWrongFormat.
  ///
  /// In ca, this message translates to:
  /// **'Tria una foto JPG, PNG o WebP.'**
  String get avatarWrongFormat;

  /// No description provided for @editProfileTitle.
  ///
  /// In ca, this message translates to:
  /// **'Editar perfil'**
  String get editProfileTitle;

  /// No description provided for @close.
  ///
  /// In ca, this message translates to:
  /// **'Tancar'**
  String get close;

  /// No description provided for @fieldName.
  ///
  /// In ca, this message translates to:
  /// **'Nom'**
  String get fieldName;

  /// No description provided for @fieldUsername.
  ///
  /// In ca, this message translates to:
  /// **'Nom d’usuari'**
  String get fieldUsername;

  /// No description provided for @fieldBiography.
  ///
  /// In ca, this message translates to:
  /// **'Biografia'**
  String get fieldBiography;

  /// No description provided for @fieldMunicipality.
  ///
  /// In ca, this message translates to:
  /// **'Municipi'**
  String get fieldMunicipality;

  /// No description provided for @municipalityEditSoon.
  ///
  /// In ca, this message translates to:
  /// **'L’edició del municipi estarà disponible properament.'**
  String get municipalityEditSoon;

  /// No description provided for @saving.
  ///
  /// In ca, this message translates to:
  /// **'Desant…'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In ca, this message translates to:
  /// **'Desar'**
  String get save;

  /// No description provided for @profileActivityViewLabel.
  ///
  /// In ca, this message translates to:
  /// **'Veure activitat: {title}'**
  String profileActivityViewLabel(String title);

  /// No description provided for @profileActivityRatingSuffix.
  ///
  /// In ca, this message translates to:
  /// **'Valoració: {rating} de 5'**
  String profileActivityRatingSuffix(int rating);

  /// No description provided for @statPlans.
  ///
  /// In ca, this message translates to:
  /// **'Plans'**
  String get statPlans;

  /// No description provided for @statFriends.
  ///
  /// In ca, this message translates to:
  /// **'Amics'**
  String get statFriends;

  /// No description provided for @statRating.
  ///
  /// In ca, this message translates to:
  /// **'Valoració'**
  String get statRating;

  /// No description provided for @reliabilityNone.
  ///
  /// In ca, this message translates to:
  /// **'Fiabilitat com a organitzador: sense valoracions'**
  String get reliabilityNone;

  /// No description provided for @reliabilityOutOfFive.
  ///
  /// In ca, this message translates to:
  /// **'Fiabilitat com a organitzador: {value} sobre 5'**
  String reliabilityOutOfFive(String value);

  /// No description provided for @changing.
  ///
  /// In ca, this message translates to:
  /// **'Canviant…'**
  String get changing;

  /// No description provided for @changePhoto.
  ///
  /// In ca, this message translates to:
  /// **'Canviar foto'**
  String get changePhoto;

  /// No description provided for @shareProfile.
  ///
  /// In ca, this message translates to:
  /// **'Compartir perfil'**
  String get shareProfile;

  /// No description provided for @shareNeedsUsername.
  ///
  /// In ca, this message translates to:
  /// **'Cal un nom d’usuari per compartir el perfil'**
  String get shareNeedsUsername;

  /// No description provided for @shareUsername.
  ///
  /// In ca, this message translates to:
  /// **'Compartir el nom d’usuari'**
  String get shareUsername;

  /// No description provided for @photoOf.
  ///
  /// In ca, this message translates to:
  /// **'Foto de {name}'**
  String photoOf(String name);

  /// No description provided for @xpValue.
  ///
  /// In ca, this message translates to:
  /// **'{xp} XP'**
  String xpValue(int xp);

  /// No description provided for @xpOfTarget.
  ///
  /// In ca, this message translates to:
  /// **'{xp} / {target} XP'**
  String xpOfTarget(int xp, int target);

  /// No description provided for @xpMaxLevel.
  ///
  /// In ca, this message translates to:
  /// **'Has assolit el nivell màxim'**
  String get xpMaxLevel;

  /// No description provided for @xpStart.
  ///
  /// In ca, this message translates to:
  /// **'El teu recorregut cultural comença aquí'**
  String get xpStart;

  /// No description provided for @xpRemainingForLevel.
  ///
  /// In ca, this message translates to:
  /// **'{remaining} XP per a {level}'**
  String xpRemainingForLevel(int remaining, String level);

  /// No description provided for @xpProgressSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Progrés d’experiència: {xp} XP'**
  String xpProgressSemantics(int xp);

  /// No description provided for @xpProgressOfSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Progrés d’experiència: {xp} de {target} XP'**
  String xpProgressOfSemantics(int xp, int target);

  /// No description provided for @levelStateCurrent.
  ///
  /// In ca, this message translates to:
  /// **'nivell actual'**
  String get levelStateCurrent;

  /// No description provided for @levelStateReached.
  ///
  /// In ca, this message translates to:
  /// **'assolit'**
  String get levelStateReached;

  /// No description provided for @levelStatePending.
  ///
  /// In ca, this message translates to:
  /// **'pendent'**
  String get levelStatePending;

  /// No description provided for @levelCurious.
  ///
  /// In ca, this message translates to:
  /// **'Curiós/a'**
  String get levelCurious;

  /// No description provided for @levelExplorer.
  ///
  /// In ca, this message translates to:
  /// **'Explorador/a'**
  String get levelExplorer;

  /// No description provided for @levelAdventurer.
  ///
  /// In ca, this message translates to:
  /// **'Aventurer/a'**
  String get levelAdventurer;

  /// No description provided for @levelDiscoverer.
  ///
  /// In ca, this message translates to:
  /// **'Descobridor/a'**
  String get levelDiscoverer;

  /// No description provided for @levelAmbassador.
  ///
  /// In ca, this message translates to:
  /// **'Ambaixador/a'**
  String get levelAmbassador;

  /// No description provided for @levelCultural.
  ///
  /// In ca, this message translates to:
  /// **'{label} cultural'**
  String levelCultural(String label);

  /// No description provided for @comingSoon.
  ///
  /// In ca, this message translates to:
  /// **'Disponible properament'**
  String get comingSoon;

  /// No description provided for @comingSoonTitled.
  ///
  /// In ca, this message translates to:
  /// **'{title}: disponible properament'**
  String comingSoonTitled(String title);

  /// No description provided for @settingsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Configuració'**
  String get settingsTitle;

  /// No description provided for @goBack.
  ///
  /// In ca, this message translates to:
  /// **'Tornar enrere'**
  String get goBack;

  /// No description provided for @settingsLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant la configuració'**
  String get settingsLoading;

  /// No description provided for @settingsSavingChange.
  ///
  /// In ca, this message translates to:
  /// **'Desant el canvi…'**
  String get settingsSavingChange;

  /// No description provided for @settingsGroupPreferences.
  ///
  /// In ca, this message translates to:
  /// **'PREFERÈNCIES'**
  String get settingsGroupPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In ca, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @languageNameCa.
  ///
  /// In ca, this message translates to:
  /// **'Català'**
  String get languageNameCa;

  /// No description provided for @languageNameEs.
  ///
  /// In ca, this message translates to:
  /// **'Castellano'**
  String get languageNameEs;

  /// No description provided for @languageNameEn.
  ///
  /// In ca, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// No description provided for @settingsLanguageSyncError.
  ///
  /// In ca, this message translates to:
  /// **'L’idioma s’ha canviat, però no l’hem pogut desar al teu compte. Torna-ho a provar.'**
  String get settingsLanguageSyncError;

  /// No description provided for @settingsTheme.
  ///
  /// In ca, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In ca, this message translates to:
  /// **'Clar'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ca, this message translates to:
  /// **'Fosc'**
  String get themeDark;

  /// No description provided for @settingsDarkThemeSoon.
  ///
  /// In ca, this message translates to:
  /// **'Tema fosc disponible properament'**
  String get settingsDarkThemeSoon;

  /// No description provided for @settingsGroupPrivacy.
  ///
  /// In ca, this message translates to:
  /// **'PRIVACITAT'**
  String get settingsGroupPrivacy;

  /// No description provided for @settingsShowMyPlans.
  ///
  /// In ca, this message translates to:
  /// **'Mostrar els meus plans'**
  String get settingsShowMyPlans;

  /// No description provided for @settingsShowMyPlansHint.
  ///
  /// In ca, this message translates to:
  /// **'Els amics veuen a què t’apuntes'**
  String get settingsShowMyPlansHint;

  /// No description provided for @settingsBlockedUsers.
  ///
  /// In ca, this message translates to:
  /// **'Usuaris bloquejats'**
  String get settingsBlockedUsers;

  /// No description provided for @settingsGroupNotifications.
  ///
  /// In ca, this message translates to:
  /// **'NOTIFICACIONS'**
  String get settingsGroupNotifications;

  /// No description provided for @settingsReminders.
  ///
  /// In ca, this message translates to:
  /// **'Recordatoris'**
  String get settingsReminders;

  /// No description provided for @settingsRemindersHint.
  ///
  /// In ca, this message translates to:
  /// **'Avisos dels plans de la teva agenda'**
  String get settingsRemindersHint;

  /// No description provided for @settingsFriendActivity.
  ///
  /// In ca, this message translates to:
  /// **'Activitat dels amics'**
  String get settingsFriendActivity;

  /// No description provided for @settingsFriendActivityHint.
  ///
  /// In ca, this message translates to:
  /// **'Quan un amic s’apunta a un pla'**
  String get settingsFriendActivityHint;

  /// No description provided for @settingsRecommendations.
  ///
  /// In ca, this message translates to:
  /// **'Recomanacions'**
  String get settingsRecommendations;

  /// No description provided for @settingsFriendRequests.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licituds d’amistat'**
  String get settingsFriendRequests;

  /// No description provided for @settingsPersistsAccount.
  ///
  /// In ca, this message translates to:
  /// **'Els canvis disponibles es desen al teu compte.'**
  String get settingsPersistsAccount;

  /// No description provided for @settingsPersistsSession.
  ///
  /// In ca, this message translates to:
  /// **'Les preferències es conserven durant aquesta sessió de l’app.'**
  String get settingsPersistsSession;

  /// No description provided for @settingsGroupAccount.
  ///
  /// In ca, this message translates to:
  /// **'COMPTE'**
  String get settingsGroupAccount;

  /// No description provided for @settingsGoogleCalendar.
  ///
  /// In ca, this message translates to:
  /// **'Google Calendar'**
  String get settingsGoogleCalendar;

  /// No description provided for @settingsGoogleCalendarHint.
  ///
  /// In ca, this message translates to:
  /// **'Exportació disponible properament'**
  String get settingsGoogleCalendarHint;

  /// No description provided for @settingsNotConnected.
  ///
  /// In ca, this message translates to:
  /// **'No connectat'**
  String get settingsNotConnected;

  /// No description provided for @settingsRetakeInterestTest.
  ///
  /// In ca, this message translates to:
  /// **'Tornar a fer el test d’interessos'**
  String get settingsRetakeInterestTest;

  /// No description provided for @settingsSigningOut.
  ///
  /// In ca, this message translates to:
  /// **'Tancant sessió…'**
  String get settingsSigningOut;

  /// No description provided for @settingsSignOut.
  ///
  /// In ca, this message translates to:
  /// **'Tancar sessió'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar compte'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar la configuració. Torna-ho a provar.'**
  String get settingsLoadError;

  /// No description provided for @settingsSaveError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar el canvi. Torna-ho a provar.'**
  String get settingsSaveError;

  /// No description provided for @settingsSignOutError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut tancar la sessió. Torna-ho a provar.'**
  String get settingsSignOutError;

  /// No description provided for @authGreetingNamed.
  ///
  /// In ca, this message translates to:
  /// **'Hola, {name}!'**
  String authGreetingNamed(String name);

  /// No description provided for @authGreeting.
  ///
  /// In ca, this message translates to:
  /// **'Hola!'**
  String get authGreeting;

  /// No description provided for @authChooseUsernameTitle.
  ///
  /// In ca, this message translates to:
  /// **'Tria el teu nom d\'usuari'**
  String get authChooseUsernameTitle;

  /// No description provided for @authChooseUsernameBody.
  ///
  /// In ca, this message translates to:
  /// **'{greeting} Tria el nom amb què et trobaran a l\'app.'**
  String authChooseUsernameBody(String greeting);

  /// No description provided for @authUsernameTaken.
  ///
  /// In ca, this message translates to:
  /// **'El nom «{username}» ja és d\'una altra persona. Tria\'n un altre.'**
  String authUsernameTaken(String username);

  /// No description provided for @authUsernameLabel.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameHelper.
  ///
  /// In ca, this message translates to:
  /// **'Minúscules, números, punt o guió baix (3-20).'**
  String get authUsernameHelper;

  /// No description provided for @authContinue.
  ///
  /// In ca, this message translates to:
  /// **'Continua'**
  String get authContinue;

  /// No description provided for @authNotYourAccount.
  ///
  /// In ca, this message translates to:
  /// **'No és el teu compte?'**
  String get authNotYourAccount;

  /// No description provided for @authSignOutLink.
  ///
  /// In ca, this message translates to:
  /// **'Tanca la sessió'**
  String get authSignOutLink;

  /// No description provided for @authLoginTitle.
  ///
  /// In ca, this message translates to:
  /// **'Inicia sessió'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Troba plans culturals a prop teu.'**
  String get authLoginSubtitle;

  /// No description provided for @authUsernameOrEmail.
  ///
  /// In ca, this message translates to:
  /// **'Nom d\'usuari o correu'**
  String get authUsernameOrEmail;

  /// No description provided for @authPassword.
  ///
  /// In ca, this message translates to:
  /// **'Contrasenya'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In ca, this message translates to:
  /// **'Entra'**
  String get authSignIn;

  /// No description provided for @authNoAccount.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens compte?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccountLink.
  ///
  /// In ca, this message translates to:
  /// **'Crea un compte'**
  String get authCreateAccountLink;

  /// No description provided for @authRegisterIntro.
  ///
  /// In ca, this message translates to:
  /// **'Uneix-te a AProp! per apuntar-te a activitats i crear-ne de noves.'**
  String get authRegisterIntro;

  /// No description provided for @authFirstName.
  ///
  /// In ca, this message translates to:
  /// **'Nom'**
  String get authFirstName;

  /// No description provided for @authLastName.
  ///
  /// In ca, this message translates to:
  /// **'Cognoms'**
  String get authLastName;

  /// No description provided for @authEmail.
  ///
  /// In ca, this message translates to:
  /// **'Correu electrònic'**
  String get authEmail;

  /// No description provided for @authPasswordHelper.
  ///
  /// In ca, this message translates to:
  /// **'Mínim 8 caràcters, amb majúscula, minúscula, número i caràcter especial.'**
  String get authPasswordHelper;

  /// No description provided for @authRepeatPassword.
  ///
  /// In ca, this message translates to:
  /// **'Repeteix la contrasenya'**
  String get authRepeatPassword;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In ca, this message translates to:
  /// **'Crea el compte'**
  String get authCreateAccountButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In ca, this message translates to:
  /// **'Ja tens compte?'**
  String get authHaveAccount;

  /// No description provided for @authVerifyTitle.
  ///
  /// In ca, this message translates to:
  /// **'Verifica el teu correu'**
  String get authVerifyTitle;

  /// No description provided for @authVerifySentTo.
  ///
  /// In ca, this message translates to:
  /// **'T\'hem enviat un enllaç a'**
  String get authVerifySentTo;

  /// No description provided for @authVerifyOpenIt.
  ///
  /// In ca, this message translates to:
  /// **'. Obre\'l per activar el compte i després torna aquí.'**
  String get authVerifyOpenIt;

  /// No description provided for @authAlreadyVerified.
  ///
  /// In ca, this message translates to:
  /// **'Ja l\'he verificat'**
  String get authAlreadyVerified;

  /// No description provided for @authResendEmailIn.
  ///
  /// In ca, this message translates to:
  /// **'Torna a enviar el correu ({seconds} s)'**
  String authResendEmailIn(int seconds);

  /// No description provided for @authResendEmail.
  ///
  /// In ca, this message translates to:
  /// **'Torna a enviar el correu'**
  String get authResendEmail;

  /// No description provided for @authWrongEmail.
  ///
  /// In ca, this message translates to:
  /// **'T\'has equivocat de correu?'**
  String get authWrongEmail;

  /// No description provided for @authUnexpectedError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut completar l\'operació. Torna-ho a provar.'**
  String get authUnexpectedError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ca, this message translates to:
  /// **'L\'usuari o la contrasenya no són correctes.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailInUse.
  ///
  /// In ca, this message translates to:
  /// **'Ja hi ha un compte amb aquest correu.'**
  String get authEmailInUse;

  /// No description provided for @authUsernameInUse.
  ///
  /// In ca, this message translates to:
  /// **'Aquest nom d\'usuari ja està agafat. Prova\'n un altre.'**
  String get authUsernameInUse;

  /// No description provided for @authNetworkError.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha connexió. Comprova la xarxa i torna-ho a provar.'**
  String get authNetworkError;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ca, this message translates to:
  /// **'Massa intents seguits. Espera una mica i torna-ho a provar.'**
  String get authTooManyRequests;

  /// No description provided for @authEmailRequired.
  ///
  /// In ca, this message translates to:
  /// **'De moment només pots entrar amb el correu electrònic.'**
  String get authEmailRequired;

  /// No description provided for @authPopupBlocked.
  ///
  /// In ca, this message translates to:
  /// **'El navegador ha bloquejat la finestra de Google. Permet les finestres emergents i torna-ho a provar.'**
  String get authPopupBlocked;

  /// No description provided for @authEmailRequiredField.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el correu.'**
  String get authEmailRequiredField;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ca, this message translates to:
  /// **'El correu no és vàlid.'**
  String get authEmailInvalid;

  /// No description provided for @forgotTitle.
  ///
  /// In ca, this message translates to:
  /// **'Recupera la contrasenya'**
  String get forgotTitle;

  /// No description provided for @forgotLink.
  ///
  /// In ca, this message translates to:
  /// **'Has oblidat la contrasenya?'**
  String get forgotLink;

  /// No description provided for @forgotIntro.
  ///
  /// In ca, this message translates to:
  /// **'Escriu el correu del teu compte i t’enviarem un enllaç per triar-ne una de nova.'**
  String get forgotIntro;

  /// No description provided for @forgotEmailLabel.
  ///
  /// In ca, this message translates to:
  /// **'Correu'**
  String get forgotEmailLabel;

  /// No description provided for @forgotSend.
  ///
  /// In ca, this message translates to:
  /// **'Envia l’enllaç'**
  String get forgotSend;

  /// No description provided for @forgotResendIn.
  ///
  /// In ca, this message translates to:
  /// **'Torna a enviar l’enllaç ({seconds} s)'**
  String forgotResendIn(int seconds);

  /// No description provided for @forgotResend.
  ///
  /// In ca, this message translates to:
  /// **'Torna a enviar l’enllaç'**
  String get forgotResend;

  /// No description provided for @forgotRemember.
  ///
  /// In ca, this message translates to:
  /// **'Ja la recordes?'**
  String get forgotRemember;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In ca, this message translates to:
  /// **'Torna a l’inici de sessió'**
  String get forgotBackToLogin;

  /// No description provided for @forgotSent.
  ///
  /// In ca, this message translates to:
  /// **'Si hi ha un compte amb aquest correu, t’hi hem enviat un enllaç per triar una contrasenya nova. Si no el trobes, mira el correu brossa.'**
  String get forgotSent;

  /// No description provided for @authUsernameRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un nom d\'usuari.'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameRules.
  ///
  /// In ca, this message translates to:
  /// **'Entre 3 i 20 caràcters: minúscules, números, punt o guió baix.'**
  String get authUsernameRules;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix una contrasenya.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMissingLength.
  ///
  /// In ca, this message translates to:
  /// **'almenys {min} caràcters'**
  String authPasswordMissingLength(int min);

  /// No description provided for @authPasswordMissingUpper.
  ///
  /// In ca, this message translates to:
  /// **'una majúscula'**
  String get authPasswordMissingUpper;

  /// No description provided for @authPasswordMissingLower.
  ///
  /// In ca, this message translates to:
  /// **'una minúscula'**
  String get authPasswordMissingLower;

  /// No description provided for @authPasswordMissingDigit.
  ///
  /// In ca, this message translates to:
  /// **'un número'**
  String get authPasswordMissingDigit;

  /// No description provided for @authPasswordMissingSpecial.
  ///
  /// In ca, this message translates to:
  /// **'un caràcter especial'**
  String get authPasswordMissingSpecial;

  /// No description provided for @authPasswordMustHave.
  ///
  /// In ca, this message translates to:
  /// **'Ha de tenir {requirements}.'**
  String authPasswordMustHave(String requirements);

  /// No description provided for @authListAnd.
  ///
  /// In ca, this message translates to:
  /// **'{list} i {last}'**
  String authListAnd(String list, String last);

  /// No description provided for @authRepeatPasswordRequired.
  ///
  /// In ca, this message translates to:
  /// **'Repeteix la contrasenya.'**
  String get authRepeatPasswordRequired;

  /// No description provided for @authPasswordsDiffer.
  ///
  /// In ca, this message translates to:
  /// **'Les contrasenyes no coincideixen.'**
  String get authPasswordsDiffer;

  /// No description provided for @authUsernameOrEmailRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el nom d\'usuari o el correu.'**
  String get authUsernameOrEmailRequired;

  /// No description provided for @authFirstNameRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el nom.'**
  String get authFirstNameRequired;

  /// No description provided for @authLastNameRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix els cognoms.'**
  String get authLastNameRequired;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In ca, this message translates to:
  /// **'Encara no consta que hagis verificat el correu. Obre l\'enllaç que t\'hem enviat i torna-ho a provar.'**
  String get authEmailNotVerified;

  /// No description provided for @authVerificationSent.
  ///
  /// In ca, this message translates to:
  /// **'T\'hem tornat a enviar el correu.'**
  String get authVerificationSent;

  /// No description provided for @loading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant'**
  String get loading;

  /// No description provided for @authOr.
  ///
  /// In ca, this message translates to:
  /// **'o'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In ca, this message translates to:
  /// **'Continua amb Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authShowPassword.
  ///
  /// In ca, this message translates to:
  /// **'Mostra la contrasenya'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In ca, this message translates to:
  /// **'Amaga la contrasenya'**
  String get authHidePassword;

  /// No description provided for @authLoginPasswordRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix la contrasenya.'**
  String get authLoginPasswordRequired;

  /// No description provided for @assistantTitle.
  ///
  /// In ca, this message translates to:
  /// **'Assistent'**
  String get assistantTitle;

  /// No description provided for @assistantAnnouncement.
  ///
  /// In ca, this message translates to:
  /// **'Assistent: {text}'**
  String assistantAnnouncement(String text);

  /// No description provided for @assistantSuggestedQuestion.
  ///
  /// In ca, this message translates to:
  /// **'Pregunta suggerida: {text}'**
  String assistantSuggestedQuestion(String text);

  /// No description provided for @assistantSearching.
  ///
  /// In ca, this message translates to:
  /// **'Cercant recomanacions'**
  String get assistantSearching;

  /// No description provided for @assistantGoToLast.
  ///
  /// In ca, this message translates to:
  /// **'Anar a l’últim missatge'**
  String get assistantGoToLast;

  /// No description provided for @assistantWelcome.
  ///
  /// In ca, this message translates to:
  /// **'Hola! Sóc l’assistent d’AProp!. Digue’m quin tipus d’activitat busques, a quin municipi i per a quines dates, i et proposaré plans culturals.'**
  String get assistantWelcome;

  /// No description provided for @assistantRateError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar la valoració. Torna-ho a provar.'**
  String get assistantRateError;

  /// No description provided for @assistantTooManyMessages.
  ///
  /// In ca, this message translates to:
  /// **'Massa missatges, espera un minut'**
  String get assistantTooManyMessages;

  /// No description provided for @assistantReplyError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.'**
  String get assistantReplyError;

  /// No description provided for @assistantViewActivity.
  ///
  /// In ca, this message translates to:
  /// **'Veure activitat: {title}'**
  String assistantViewActivity(String title);

  /// No description provided for @assistantVoiceSoon.
  ///
  /// In ca, this message translates to:
  /// **'Entrada per veu disponible properament'**
  String get assistantVoiceSoon;

  /// No description provided for @assistantInputHint.
  ///
  /// In ca, this message translates to:
  /// **'Escriu una consulta…'**
  String get assistantInputHint;

  /// No description provided for @assistantSend.
  ///
  /// In ca, this message translates to:
  /// **'Enviar'**
  String get assistantSend;

  /// No description provided for @assistantChipType.
  ///
  /// In ca, this message translates to:
  /// **'Tipus: {value}'**
  String assistantChipType(String value);

  /// No description provided for @assistantChipMunicipality.
  ///
  /// In ca, this message translates to:
  /// **'Municipi: {value}'**
  String assistantChipMunicipality(String value);

  /// No description provided for @assistantChipDates.
  ///
  /// In ca, this message translates to:
  /// **'Dates: {value}'**
  String assistantChipDates(String value);

  /// No description provided for @assistantOpenHome.
  ///
  /// In ca, this message translates to:
  /// **'Obre Inici'**
  String get assistantOpenHome;

  /// No description provided for @assistantOpenAgenda.
  ///
  /// In ca, this message translates to:
  /// **'Obre Agenda'**
  String get assistantOpenAgenda;

  /// No description provided for @assistantOpenDiscover.
  ///
  /// In ca, this message translates to:
  /// **'Obre Descobreix'**
  String get assistantOpenDiscover;

  /// No description provided for @assistantOpenNotifications.
  ///
  /// In ca, this message translates to:
  /// **'Obre Avisos'**
  String get assistantOpenNotifications;

  /// No description provided for @assistantOpenProfile.
  ///
  /// In ca, this message translates to:
  /// **'Obre Perfil'**
  String get assistantOpenProfile;

  /// No description provided for @assistantOpenSettings.
  ///
  /// In ca, this message translates to:
  /// **'Obre Configuració'**
  String get assistantOpenSettings;

  /// No description provided for @assistantOpenInterestTest.
  ///
  /// In ca, this message translates to:
  /// **'Obre el test d’interessos'**
  String get assistantOpenInterestTest;

  /// No description provided for @assistantHelpful.
  ///
  /// In ca, this message translates to:
  /// **'Resposta útil'**
  String get assistantHelpful;

  /// No description provided for @assistantNotHelpful.
  ///
  /// In ca, this message translates to:
  /// **'Resposta poc útil'**
  String get assistantNotHelpful;

  /// No description provided for @selected.
  ///
  /// In ca, this message translates to:
  /// **'Seleccionat'**
  String get selected;

  /// No description provided for @assistantYou.
  ///
  /// In ca, this message translates to:
  /// **'Tu'**
  String get assistantYou;

  /// No description provided for @monthName.
  ///
  /// In ca, this message translates to:
  /// **'{n, select, 1{gener} 2{febrer} 3{març} 4{abril} 5{maig} 6{juny} 7{juliol} 8{agost} 9{setembre} 10{octubre} 11{novembre} 12{desembre} other{}}'**
  String monthName(String n);

  /// No description provided for @monthOf.
  ///
  /// In ca, this message translates to:
  /// **'{n, select, 1{de gener} 2{de febrer} 3{de març} 4{d’abril} 5{de maig} 6{de juny} 7{de juliol} 8{d’agost} 9{de setembre} 10{d’octubre} 11{de novembre} 12{de desembre} other{}}'**
  String monthOf(String n);

  /// No description provided for @weekdayName.
  ///
  /// In ca, this message translates to:
  /// **'{n, select, 1{Dilluns} 2{Dimarts} 3{Dimecres} 4{Dijous} 5{Divendres} 6{Dissabte} 7{Diumenge} other{}}'**
  String weekdayName(String n);

  /// No description provided for @weekdayAbbr.
  ///
  /// In ca, this message translates to:
  /// **'{n, select, 1{Dl} 2{Dt} 3{Dc} 4{Dj} 5{Dv} 6{Ds} 7{Dg} other{}}'**
  String weekdayAbbr(String n);

  /// No description provided for @timeOfDay.
  ///
  /// In ca, this message translates to:
  /// **'{hour}.{minute} h'**
  String timeOfDay(String hour, String minute);

  /// No description provided for @dateLong.
  ///
  /// In ca, this message translates to:
  /// **'{weekday} {day} {monthOf} de {year}'**
  String dateLong(String weekday, int day, String monthOf, int year);

  /// No description provided for @dateWithYear.
  ///
  /// In ca, this message translates to:
  /// **'{day} {monthOf} de {year}'**
  String dateWithYear(int day, String monthOf, int year);

  /// No description provided for @dateNoYear.
  ///
  /// In ca, this message translates to:
  /// **'{day} {monthOf}'**
  String dateNoYear(int day, String monthOf);

  /// No description provided for @monthHeader.
  ///
  /// In ca, this message translates to:
  /// **'{month} de {year}'**
  String monthHeader(String month, int year);

  /// No description provided for @monthYear.
  ///
  /// In ca, this message translates to:
  /// **'{month} {year}'**
  String monthYear(String month, int year);

  /// No description provided for @weekdayDay.
  ///
  /// In ca, this message translates to:
  /// **'{weekday}, {day} {monthOf}'**
  String weekdayDay(String weekday, int day, String monthOf);

  /// No description provided for @scheduleJoin.
  ///
  /// In ca, this message translates to:
  /// **'{day} · {time}'**
  String scheduleJoin(String day, String time);

  /// No description provided for @dateUnknown.
  ///
  /// In ca, this message translates to:
  /// **'Data no informada'**
  String get dateUnknown;

  /// No description provided for @rangeAll.
  ///
  /// In ca, this message translates to:
  /// **'Totes les dates'**
  String get rangeAll;

  /// No description provided for @rangeFromTo.
  ///
  /// In ca, this message translates to:
  /// **'Del {start} al {end}'**
  String rangeFromTo(String start, String end);

  /// No description provided for @rangeFromDayTo.
  ///
  /// In ca, this message translates to:
  /// **'Del {startDay} al {end}'**
  String rangeFromDayTo(int startDay, String start, String end);

  /// No description provided for @today.
  ///
  /// In ca, this message translates to:
  /// **'Avui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ca, this message translates to:
  /// **'Ahir'**
  String get yesterday;

  /// No description provided for @notifCategorySocial.
  ///
  /// In ca, this message translates to:
  /// **'Social'**
  String get notifCategorySocial;

  /// No description provided for @notifCategoryReminder.
  ///
  /// In ca, this message translates to:
  /// **'Recordatori'**
  String get notifCategoryReminder;

  /// No description provided for @notifCategoryRecommendation.
  ///
  /// In ca, this message translates to:
  /// **'Recomanació'**
  String get notifCategoryRecommendation;

  /// No description provided for @notifCategoryNotice.
  ///
  /// In ca, this message translates to:
  /// **'Avís'**
  String get notifCategoryNotice;

  /// No description provided for @notifFilterAll.
  ///
  /// In ca, this message translates to:
  /// **'Tots'**
  String get notifFilterAll;

  /// No description provided for @notifFilterReminders.
  ///
  /// In ca, this message translates to:
  /// **'Recordatoris'**
  String get notifFilterReminders;

  /// No description provided for @notifFilterRecommendations.
  ///
  /// In ca, this message translates to:
  /// **'Recomanacions'**
  String get notifFilterRecommendations;

  /// No description provided for @notifMessageReminder.
  ///
  /// In ca, this message translates to:
  /// **'Tens un recordatori cultural.'**
  String get notifMessageReminder;

  /// No description provided for @notifMessageRecommendation.
  ///
  /// In ca, this message translates to:
  /// **'Tens una recomanació cultural.'**
  String get notifMessageRecommendation;

  /// No description provided for @notifMessageRecommendationFor.
  ///
  /// In ca, this message translates to:
  /// **'“{title}” et pot interessar.'**
  String notifMessageRecommendationFor(String title);

  /// No description provided for @notifMessageSocialAbout.
  ///
  /// In ca, this message translates to:
  /// **'Avís social sobre “{title}”.'**
  String notifMessageSocialAbout(String title);

  /// No description provided for @notifMessageSocialPerson.
  ///
  /// In ca, this message translates to:
  /// **'Tens un avís social relacionat amb {name}.'**
  String notifMessageSocialPerson(String name);

  /// No description provided for @notifMessageSocial.
  ///
  /// In ca, this message translates to:
  /// **'Tens un nou avís social.'**
  String get notifMessageSocial;

  /// No description provided for @notifMessageOther.
  ///
  /// In ca, this message translates to:
  /// **'Tens un nou avís.'**
  String get notifMessageOther;

  /// No description provided for @notifMessagePublished.
  ///
  /// In ca, this message translates to:
  /// **'{name} ha publicat “{title}”.'**
  String notifMessagePublished(String name, String title);

  /// No description provided for @notifMessageEnrolled.
  ///
  /// In ca, this message translates to:
  /// **'{name} s’ha apuntat a “{title}”.'**
  String notifMessageEnrolled(String name, String title);

  /// No description provided for @notifMessageFriendRequest.
  ///
  /// In ca, this message translates to:
  /// **'{name} t’ha enviat una sol·licitud d’amistat.'**
  String notifMessageFriendRequest(String name);

  /// No description provided for @notifMessageFriendAccepted.
  ///
  /// In ca, this message translates to:
  /// **'{name} ha acceptat la teva sol·licitud d’amistat.'**
  String notifMessageFriendAccepted(String name);

  /// No description provided for @notifLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant els avisos'**
  String get notifLoading;

  /// No description provided for @notifEmptyAll.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap avís'**
  String get notifEmptyAll;

  /// No description provided for @notifEmptySocial.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens avisos socials'**
  String get notifEmptySocial;

  /// No description provided for @notifEmptyReminders.
  ///
  /// In ca, this message translates to:
  /// **'Encara no has rebut cap recordatori'**
  String get notifEmptyReminders;

  /// No description provided for @notifEmptyRecommendations.
  ///
  /// In ca, this message translates to:
  /// **'Encara no has rebut recomanacions'**
  String get notifEmptyRecommendations;

  /// No description provided for @notifEmptyRemindersHint.
  ///
  /// In ca, this message translates to:
  /// **'Els recordatoris que configuris a l’agenda apareixeran aquí quan arribi l’hora de l’avís.'**
  String get notifEmptyRemindersHint;

  /// No description provided for @notifEmptySocialHint.
  ///
  /// In ca, this message translates to:
  /// **'Aquí trobaràs les sol·licituds d’amistat i les novetats dels teus amics.'**
  String get notifEmptySocialHint;

  /// No description provided for @notifEmptyRecommendationsHint.
  ///
  /// In ca, this message translates to:
  /// **'Aquí trobaràs avisos d’activitats que et poden interessar.'**
  String get notifEmptyRecommendationsHint;

  /// No description provided for @notifEmptyAllHint.
  ///
  /// In ca, this message translates to:
  /// **'Aquí trobaràs els avisos socials, els recordatoris i les recomanacions que rebis.'**
  String get notifEmptyAllHint;

  /// No description provided for @notifSeeAll.
  ///
  /// In ca, this message translates to:
  /// **'Veure tots els avisos'**
  String get notifSeeAll;

  /// No description provided for @notifLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar els avisos. Torna-ho a provar.'**
  String get notifLoadError;

  /// No description provided for @notifMarkReadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut marcar l’avís com a llegit. Torna-ho a provar.'**
  String get notifMarkReadError;

  /// No description provided for @notifRespondError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut respondre la sol·licitud. Torna-ho a provar.'**
  String get notifRespondError;

  /// No description provided for @notifRead.
  ///
  /// In ca, this message translates to:
  /// **'Llegit'**
  String get notifRead;

  /// No description provided for @notifUnread.
  ///
  /// In ca, this message translates to:
  /// **'Sense llegir'**
  String get notifUnread;

  /// No description provided for @notifHintProfileUnavailable.
  ///
  /// In ca, this message translates to:
  /// **'Marca l’avís com a llegit. El perfil encara no està disponible.'**
  String get notifHintProfileUnavailable;

  /// No description provided for @notifHintOpenActivity.
  ///
  /// In ca, this message translates to:
  /// **'Obre l’activitat'**
  String get notifHintOpenActivity;

  /// No description provided for @notifHintOpenProfile.
  ///
  /// In ca, this message translates to:
  /// **'Obre el perfil'**
  String get notifHintOpenProfile;

  /// No description provided for @notifHintMarkRead.
  ///
  /// In ca, this message translates to:
  /// **'Marca l’avís com a llegit'**
  String get notifHintMarkRead;

  /// No description provided for @notifReceivedAt.
  ///
  /// In ca, this message translates to:
  /// **'Rebut a les {time}'**
  String notifReceivedAt(String time);

  /// No description provided for @notifProfileSoon.
  ///
  /// In ca, this message translates to:
  /// **'Perfil disponible properament'**
  String get notifProfileSoon;

  /// No description provided for @notifActivityGone.
  ///
  /// In ca, this message translates to:
  /// **'L’activitat ja no està disponible.'**
  String get notifActivityGone;

  /// No description provided for @notifActivityLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No s’ha pogut carregar la informació de l’activitat. Pots provar d’obrir-la.'**
  String get notifActivityLoadError;

  /// No description provided for @notifSendingResponse.
  ///
  /// In ca, this message translates to:
  /// **'Enviant la resposta'**
  String get notifSendingResponse;

  /// No description provided for @notifAccept.
  ///
  /// In ca, this message translates to:
  /// **'Acceptar'**
  String get notifAccept;

  /// No description provided for @notifDecline.
  ///
  /// In ca, this message translates to:
  /// **'Rebutjar'**
  String get notifDecline;

  /// No description provided for @notifRequestAccepted.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud acceptada'**
  String get notifRequestAccepted;

  /// No description provided for @notifRequestDeclined.
  ///
  /// In ca, this message translates to:
  /// **'Sol·licitud rebutjada'**
  String get notifRequestDeclined;

  /// No description provided for @interestTestTitle.
  ///
  /// In ca, this message translates to:
  /// **'Test d’interessos'**
  String get interestTestTitle;

  /// No description provided for @interestTestLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant el test'**
  String get interestTestLoading;

  /// No description provided for @interestTestEmpty.
  ///
  /// In ca, this message translates to:
  /// **'Ara mateix no hi ha activitats per al test.'**
  String get interestTestEmpty;

  /// No description provided for @interestTestBack.
  ///
  /// In ca, this message translates to:
  /// **'Tornar'**
  String get interestTestBack;

  /// No description provided for @interestTestDone.
  ///
  /// In ca, this message translates to:
  /// **'Hem actualitzat els teus interessos. Les recomanacions de «Per a tu» els tindran en compte.'**
  String get interestTestDone;

  /// No description provided for @interestTestBackToSettings.
  ///
  /// In ca, this message translates to:
  /// **'Tornar a la configuració'**
  String get interestTestBackToSettings;

  /// No description provided for @interestTestSaving.
  ///
  /// In ca, this message translates to:
  /// **'Desant les respostes'**
  String get interestTestSaving;

  /// No description provided for @interestTestProgress.
  ///
  /// In ca, this message translates to:
  /// **'{current} de {total}'**
  String interestTestProgress(int current, int total);

  /// No description provided for @interestTestProgressSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Progrés del test'**
  String get interestTestProgressSemantics;

  /// No description provided for @interestTestSwipeHint.
  ///
  /// In ca, this message translates to:
  /// **'Llisca cap a la dreta si t’interessa i cap a l’esquerra si no.'**
  String get interestTestSwipeHint;

  /// No description provided for @interestTestLike.
  ///
  /// In ca, this message translates to:
  /// **'M’interessa'**
  String get interestTestLike;

  /// No description provided for @interestTestDislike.
  ///
  /// In ca, this message translates to:
  /// **'No m’interessa'**
  String get interestTestDislike;

  /// No description provided for @interestTestLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar el test. Torna-ho a provar.'**
  String get interestTestLoadError;

  /// No description provided for @interestTestSaveError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar les respostes. Torna-ho a provar.'**
  String get interestTestSaveError;

  /// No description provided for @ratingDeleteTitle.
  ///
  /// In ca, this message translates to:
  /// **'Eliminar la valoració?'**
  String get ratingDeleteTitle;

  /// No description provided for @ratingDeleteBody.
  ///
  /// In ca, this message translates to:
  /// **'La teva valoració s’eliminarà i podràs tornar a valorar l’activitat.'**
  String get ratingDeleteBody;

  /// No description provided for @cancel.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·la'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ca, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @ratingEdit.
  ///
  /// In ca, this message translates to:
  /// **'Modifica la valoració'**
  String get ratingEdit;

  /// No description provided for @ratingOrganizerRated.
  ///
  /// In ca, this message translates to:
  /// **'Ja has valorat {name}'**
  String ratingOrganizerRated(String name);

  /// No description provided for @ratingOrganizerAsk.
  ///
  /// In ca, this message translates to:
  /// **'Com ha anat l’organitzador/a {name}?'**
  String ratingOrganizerAsk(String name);

  /// No description provided for @ratingActivityRated.
  ///
  /// In ca, this message translates to:
  /// **'Ja has valorat aquesta activitat'**
  String get ratingActivityRated;

  /// No description provided for @ratingAsk.
  ///
  /// In ca, this message translates to:
  /// **'Com t’ha anat?'**
  String get ratingAsk;

  /// No description provided for @ratingCancelEdit.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·la la modificació'**
  String get ratingCancelEdit;

  /// No description provided for @ratingEditShort.
  ///
  /// In ca, this message translates to:
  /// **'Modifica'**
  String get ratingEditShort;

  /// No description provided for @ratingDelete.
  ///
  /// In ca, this message translates to:
  /// **'Elimina la valoració'**
  String get ratingDelete;

  /// No description provided for @ratingScore.
  ///
  /// In ca, this message translates to:
  /// **'Valoració: {score} de 5'**
  String ratingScore(int score);

  /// No description provided for @ratingStarLabel.
  ///
  /// In ca, this message translates to:
  /// **'{star, plural, one{Valora amb {star} estrella} other{Valora amb {star} estrelles}}'**
  String ratingStarLabel(int star);

  /// No description provided for @ratingStarValue.
  ///
  /// In ca, this message translates to:
  /// **'{star} de 5'**
  String ratingStarValue(int star);

  /// No description provided for @ratingSaving.
  ///
  /// In ca, this message translates to:
  /// **'Desant la valoració'**
  String get ratingSaving;

  /// No description provided for @ratingSaveError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar la valoració. Torna-ho a provar.'**
  String get ratingSaveError;

  /// No description provided for @ratingEditError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut modificar la valoració. Torna-ho a provar.'**
  String get ratingEditError;

  /// No description provided for @ratingDeleteError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut eliminar la valoració. Torna-ho a provar.'**
  String get ratingDeleteError;

  /// No description provided for @ratingGone.
  ///
  /// In ca, this message translates to:
  /// **'La valoració ja no existeix.'**
  String get ratingGone;

  /// No description provided for @agendaLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant la teva agenda'**
  String get agendaLoading;

  /// No description provided for @agendaEmptyDay.
  ///
  /// In ca, this message translates to:
  /// **'No tens cap pla per a aquest dia.'**
  String get agendaEmptyDay;

  /// No description provided for @agendaEmptyHint.
  ///
  /// In ca, this message translates to:
  /// **'Apunta’t a activitats des d’Inici i les veuràs aquí.'**
  String get agendaEmptyHint;

  /// No description provided for @agendaLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar la teva agenda. Torna-ho a provar.'**
  String get agendaLoadError;

  /// No description provided for @agendaPublishedBy.
  ///
  /// In ca, this message translates to:
  /// **'Publicat per {name}'**
  String agendaPublishedBy(String name);

  /// No description provided for @agendaSourceOfficial.
  ///
  /// In ca, this message translates to:
  /// **'Font: Agenda Cultural · Generalitat'**
  String get agendaSourceOfficial;

  /// No description provided for @agendaPreviousMonth.
  ///
  /// In ca, this message translates to:
  /// **'Mes anterior'**
  String get agendaPreviousMonth;

  /// No description provided for @agendaNextMonth.
  ///
  /// In ca, this message translates to:
  /// **'Mes següent'**
  String get agendaNextMonth;

  /// No description provided for @agendaDayToday.
  ///
  /// In ca, this message translates to:
  /// **'avui'**
  String get agendaDayToday;

  /// No description provided for @agendaDayWithPlans.
  ///
  /// In ca, this message translates to:
  /// **'amb plans'**
  String get agendaDayWithPlans;

  /// No description provided for @agendaDayWithoutPlans.
  ///
  /// In ca, this message translates to:
  /// **'sense plans'**
  String get agendaDayWithoutPlans;

  /// No description provided for @actCloseFilter.
  ///
  /// In ca, this message translates to:
  /// **'Tancar el filtre'**
  String get actCloseFilter;

  /// No description provided for @actUpdating.
  ///
  /// In ca, this message translates to:
  /// **'Actualitzant les activitats'**
  String get actUpdating;

  /// No description provided for @actNoneAvailable.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha activitats disponibles.'**
  String get actNoneAvailable;

  /// No description provided for @actLoadingZone.
  ///
  /// In ca, this message translates to:
  /// **'Carregant les activitats de la zona'**
  String get actLoadingZone;

  /// No description provided for @actFilterLocation.
  ///
  /// In ca, this message translates to:
  /// **'Catalunya'**
  String get actFilterLocation;

  /// No description provided for @actFilterDates.
  ///
  /// In ca, this message translates to:
  /// **'Dates'**
  String get actFilterDates;

  /// No description provided for @actFilterCategories.
  ///
  /// In ca, this message translates to:
  /// **'Categories'**
  String get actFilterCategories;

  /// No description provided for @actClearAllFilters.
  ///
  /// In ca, this message translates to:
  /// **'Netejar tots els filtres'**
  String get actClearAllFilters;

  /// No description provided for @actViewMap.
  ///
  /// In ca, this message translates to:
  /// **'Mapa'**
  String get actViewMap;

  /// No description provided for @actViewList.
  ///
  /// In ca, this message translates to:
  /// **'Llista'**
  String get actViewList;

  /// No description provided for @actCreate.
  ///
  /// In ca, this message translates to:
  /// **'Crear activitat'**
  String get actCreate;

  /// No description provided for @actCreateSoon.
  ///
  /// In ca, this message translates to:
  /// **'Crear activitat disponible properament'**
  String get actCreateSoon;

  /// No description provided for @actViewSelected.
  ///
  /// In ca, this message translates to:
  /// **'Vista {label} seleccionada'**
  String actViewSelected(String label);

  /// No description provided for @actViewSoon.
  ///
  /// In ca, this message translates to:
  /// **'Vista {label} disponible properament'**
  String actViewSoon(String label);

  /// No description provided for @actViewShow.
  ///
  /// In ca, this message translates to:
  /// **'Mostrar {label}'**
  String actViewShow(String label);

  /// No description provided for @actDetailsTitle.
  ///
  /// In ca, this message translates to:
  /// **'Activitat'**
  String get actDetailsTitle;

  /// No description provided for @actEdit.
  ///
  /// In ca, this message translates to:
  /// **'Edita l’activitat'**
  String get actEdit;

  /// No description provided for @actNotFound.
  ///
  /// In ca, this message translates to:
  /// **'No hem trobat aquesta activitat.'**
  String get actNotFound;

  /// No description provided for @actAbout.
  ///
  /// In ca, this message translates to:
  /// **'Sobre l’activitat'**
  String get actAbout;

  /// No description provided for @actNoDescription.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha una descripció disponible.'**
  String get actNoDescription;

  /// No description provided for @actPracticalInfo.
  ///
  /// In ca, this message translates to:
  /// **'Informació pràctica'**
  String get actPracticalInfo;

  /// No description provided for @actOriginalLinkSoon.
  ///
  /// In ca, this message translates to:
  /// **'Enllaç original disponible properament'**
  String get actOriginalLinkSoon;

  /// No description provided for @actOriginalLink.
  ///
  /// In ca, this message translates to:
  /// **'Consultar informació original'**
  String get actOriginalLink;

  /// No description provided for @actChatSoon.
  ///
  /// In ca, this message translates to:
  /// **'Xat disponible properament'**
  String get actChatSoon;

  /// No description provided for @actChat.
  ///
  /// In ca, this message translates to:
  /// **'Xat de l’activitat'**
  String get actChat;

  /// No description provided for @actChatHint.
  ///
  /// In ca, this message translates to:
  /// **'Parla amb les persones que també s’hi han apuntat.'**
  String get actChatHint;

  /// No description provided for @actPublishedBy.
  ///
  /// In ca, this message translates to:
  /// **'Publicat per'**
  String get actPublishedBy;

  /// No description provided for @actReliabilityNone.
  ///
  /// In ca, this message translates to:
  /// **'Fiabilitat de l’organitzador: sense valoracions'**
  String get actReliabilityNone;

  /// No description provided for @actReliabilityOutOfFive.
  ///
  /// In ca, this message translates to:
  /// **'Fiabilitat de l’organitzador: {value} sobre 5'**
  String actReliabilityOutOfFive(String value);

  /// No description provided for @actReliabilityChip.
  ///
  /// In ca, this message translates to:
  /// **'Fiabilitat {value}'**
  String actReliabilityChip(String value);

  /// No description provided for @actViewProfile.
  ///
  /// In ca, this message translates to:
  /// **'Veure perfil'**
  String get actViewProfile;

  /// No description provided for @actSearchTitle.
  ///
  /// In ca, this message translates to:
  /// **'Cerca'**
  String get actSearchTitle;

  /// No description provided for @actSearchHint.
  ///
  /// In ca, this message translates to:
  /// **'Cerca activitats…'**
  String get actSearchHint;

  /// No description provided for @actSearchLabel.
  ///
  /// In ca, this message translates to:
  /// **'Cerca activitats'**
  String get actSearchLabel;

  /// No description provided for @actClearSearch.
  ///
  /// In ca, this message translates to:
  /// **'Esborrar la cerca'**
  String get actClearSearch;

  /// No description provided for @actSegActivities.
  ///
  /// In ca, this message translates to:
  /// **'Activitats'**
  String get actSegActivities;

  /// No description provided for @actSegPeople.
  ///
  /// In ca, this message translates to:
  /// **'Persones'**
  String get actSegPeople;

  /// No description provided for @actSearchPromptTitle.
  ///
  /// In ca, this message translates to:
  /// **'Quina activitat busques?'**
  String get actSearchPromptTitle;

  /// No description provided for @actSearchPromptBody.
  ///
  /// In ca, this message translates to:
  /// **'Escriu el nom d’una activitat o un municipi.'**
  String get actSearchPromptBody;

  /// No description provided for @actSearching.
  ///
  /// In ca, this message translates to:
  /// **'Cercant activitats'**
  String get actSearching;

  /// No description provided for @actFoundCount.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 activitat trobada} other{{count} activitats trobades}}'**
  String actFoundCount(int count);

  /// No description provided for @actNoResultsTitle.
  ///
  /// In ca, this message translates to:
  /// **'No hem trobat activitats'**
  String get actNoResultsTitle;

  /// No description provided for @actNoResultsBody.
  ///
  /// In ca, this message translates to:
  /// **'Prova amb altres paraules.'**
  String get actNoResultsBody;

  /// No description provided for @actMapLabel.
  ///
  /// In ca, this message translates to:
  /// **'Mapa d’activitats'**
  String get actMapLabel;

  /// No description provided for @actLegend.
  ///
  /// In ca, this message translates to:
  /// **'Llegenda'**
  String get actLegend;

  /// No description provided for @actLegendOfficial.
  ///
  /// In ca, this message translates to:
  /// **'Activitat de l’Agenda Cultural'**
  String get actLegendOfficial;

  /// No description provided for @actLegendCommunity.
  ///
  /// In ca, this message translates to:
  /// **'Publicada per un usuari'**
  String get actLegendCommunity;

  /// No description provided for @actLegendFriend.
  ///
  /// In ca, this message translates to:
  /// **'Publicada per una amistat'**
  String get actLegendFriend;

  /// No description provided for @actLegendCluster.
  ///
  /// In ca, this message translates to:
  /// **'Diverses activitats a prop: toca per veure-les'**
  String get actLegendCluster;

  /// No description provided for @actWithoutLocation.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 activitat no té ubicació i només surt a la llista.} other{{count} activitats no tenen ubicació i només surten a la llista.}}'**
  String actWithoutLocation(int count);

  /// No description provided for @mapMyLocation.
  ///
  /// In ca, this message translates to:
  /// **'La meva ubicació'**
  String get mapMyLocation;

  /// No description provided for @mapYouAreHere.
  ///
  /// In ca, this message translates to:
  /// **'On ets tu'**
  String get mapYouAreHere;

  /// No description provided for @mapLocateError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut trobar on ets. Torna-ho a provar.'**
  String get mapLocateError;

  /// No description provided for @mapLocateDenied.
  ///
  /// In ca, this message translates to:
  /// **'Per veure on ets, cal que permetis que AProp! faci servir la teva ubicació.'**
  String get mapLocateDenied;

  /// No description provided for @mapLocateDeniedForever.
  ///
  /// In ca, this message translates to:
  /// **'Has denegat l’accés a la ubicació. Pots activar-lo a la configuració.'**
  String get mapLocateDeniedForever;

  /// No description provided for @mapLocateSettings.
  ///
  /// In ca, this message translates to:
  /// **'Configuració'**
  String get mapLocateSettings;

  /// No description provided for @mapLocateBrowserDenied.
  ///
  /// In ca, this message translates to:
  /// **'El navegador no deixa veure on ets. Pots permetre-ho des de la icona del costat de l’adreça.'**
  String get mapLocateBrowserDenied;

  /// No description provided for @mapLocationDisabled.
  ///
  /// In ca, this message translates to:
  /// **'La ubicació del dispositiu està desactivada.'**
  String get mapLocationDisabled;

  /// No description provided for @mapLocationEnable.
  ///
  /// In ca, this message translates to:
  /// **'Activar'**
  String get mapLocationEnable;

  /// No description provided for @actInThisPlace.
  ///
  /// In ca, this message translates to:
  /// **'{count} activitats en aquest lloc'**
  String actInThisPlace(int count);

  /// No description provided for @actPublishedByName.
  ///
  /// In ca, this message translates to:
  /// **'Publicat per {name}'**
  String actPublishedByName(String name);

  /// No description provided for @actViewActivity.
  ///
  /// In ca, this message translates to:
  /// **'Veure activitat'**
  String get actViewActivity;

  /// No description provided for @actFriendBadge.
  ///
  /// In ca, this message translates to:
  /// **'Amiga'**
  String get actFriendBadge;

  /// No description provided for @actCategoriesTitle.
  ///
  /// In ca, this message translates to:
  /// **'Categories'**
  String get actCategoriesTitle;

  /// No description provided for @actCategoriesSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Pots triar més d’una categoria'**
  String get actCategoriesSubtitle;

  /// No description provided for @categoriesAll.
  ///
  /// In ca, this message translates to:
  /// **'Totes les categories'**
  String get categoriesAll;

  /// No description provided for @categoriesSelected.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 categoria seleccionada} other{{count} categories seleccionades}}'**
  String categoriesSelected(int count);

  /// No description provided for @actCategoriesLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant categories'**
  String get actCategoriesLoading;

  /// No description provided for @actCategoriesEmpty.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha categories disponibles. Pots consultar totes les activitats.'**
  String get actCategoriesEmpty;

  /// No description provided for @actDatesTitle.
  ///
  /// In ca, this message translates to:
  /// **'Dates'**
  String get actDatesTitle;

  /// No description provided for @actDatesSubtitle.
  ///
  /// In ca, this message translates to:
  /// **'Tria un dia o un interval'**
  String get actDatesSubtitle;

  /// No description provided for @actPresetToday.
  ///
  /// In ca, this message translates to:
  /// **'Avui'**
  String get actPresetToday;

  /// No description provided for @actPresetTomorrow.
  ///
  /// In ca, this message translates to:
  /// **'Demà'**
  String get actPresetTomorrow;

  /// No description provided for @actPresetWeekend.
  ///
  /// In ca, this message translates to:
  /// **'Aquest cap de setmana'**
  String get actPresetWeekend;

  /// No description provided for @actDayToday.
  ///
  /// In ca, this message translates to:
  /// **'avui'**
  String get actDayToday;

  /// No description provided for @actClearFilters.
  ///
  /// In ca, this message translates to:
  /// **'Netejar filtres'**
  String get actClearFilters;

  /// No description provided for @actNoMatchLoaded.
  ///
  /// In ca, this message translates to:
  /// **'Cap coincidència entre les activitats carregades'**
  String get actNoMatchLoaded;

  /// No description provided for @actNoMatchFilters.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha activitats amb aquests filtres'**
  String get actNoMatchFilters;

  /// No description provided for @actTryOther.
  ///
  /// In ca, this message translates to:
  /// **'Prova unes altres dates o categories.'**
  String get actTryOther;

  /// No description provided for @actNoMatchZone.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha activitats amb aquests filtres en aquesta zona.'**
  String get actNoMatchZone;

  /// No description provided for @actUncategorised.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 activitat sense categoria informada no s’inclou en aquest filtre.} other{{count} activitats sense categoria informada no s’inclouen en aquest filtre.}}'**
  String actUncategorised(int count);

  /// No description provided for @actSeeListHint.
  ///
  /// In ca, this message translates to:
  /// **'Consulta la llista per veure els resultats per categoria.'**
  String get actSeeListHint;

  /// No description provided for @actSeeList.
  ///
  /// In ca, this message translates to:
  /// **'Veure llista'**
  String get actSeeList;

  /// No description provided for @actClear.
  ///
  /// In ca, this message translates to:
  /// **'Netejar'**
  String get actClear;

  /// No description provided for @actApply.
  ///
  /// In ca, this message translates to:
  /// **'Aplicar'**
  String get actApply;

  /// No description provided for @actLoadedCount.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 activitat carregada} other{{count} activitats carregades}}'**
  String actLoadedCount(int count);

  /// No description provided for @actLoadingMore.
  ///
  /// In ca, this message translates to:
  /// **'Carregant més activitats'**
  String get actLoadingMore;

  /// No description provided for @actLoadMore.
  ///
  /// In ca, this message translates to:
  /// **'Carregar més activitats'**
  String get actLoadMore;

  /// No description provided for @enrollLeaving.
  ///
  /// In ca, this message translates to:
  /// **'Desapuntant…'**
  String get enrollLeaving;

  /// No description provided for @enrollLeave.
  ///
  /// In ca, this message translates to:
  /// **'Desapunta’m'**
  String get enrollLeave;

  /// No description provided for @enrollSigningUp.
  ///
  /// In ca, this message translates to:
  /// **'Apuntant…'**
  String get enrollSigningUp;

  /// No description provided for @enrollLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant…'**
  String get enrollLoading;

  /// No description provided for @enrollSignUp.
  ///
  /// In ca, this message translates to:
  /// **'M’hi apunto'**
  String get enrollSignUp;

  /// No description provided for @enrollLeavingSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Desapuntant-te de l’activitat'**
  String get enrollLeavingSemantics;

  /// No description provided for @enrollSigningUpSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Apuntant-te a l’activitat'**
  String get enrollSigningUpSemantics;

  /// No description provided for @enrollCheckingSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Consultant els teus plans'**
  String get enrollCheckingSemantics;

  /// No description provided for @enrollLeaveTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Desapuntar-me de {title}'**
  String enrollLeaveTooltip(String title);

  /// No description provided for @enrollRecheckTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Tornar a consultar els teus plans'**
  String get enrollRecheckTooltip;

  /// No description provided for @enrollSignUpTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Apuntar-me a {title}'**
  String enrollSignUpTooltip(String title);

  /// No description provided for @enrollHelperEnrolled.
  ///
  /// In ca, this message translates to:
  /// **'Aquest pla ja és a la teva agenda.'**
  String get enrollHelperEnrolled;

  /// No description provided for @enrollHelperNot.
  ///
  /// In ca, this message translates to:
  /// **'Afegeix aquest pla a la teva agenda.'**
  String get enrollHelperNot;

  /// No description provided for @enrollLeftSnack.
  ///
  /// In ca, this message translates to:
  /// **'T’has desapuntat de «{title}».'**
  String enrollLeftSnack(String title);

  /// No description provided for @enrollUndo.
  ///
  /// In ca, this message translates to:
  /// **'Desfer'**
  String get enrollUndo;

  /// No description provided for @enrollBadge.
  ///
  /// In ca, this message translates to:
  /// **'Apuntat'**
  String get enrollBadge;

  /// No description provided for @enrollLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut consultar els teus plans. Torna-ho a provar.'**
  String get enrollLoadError;

  /// No description provided for @enrollSignUpError.
  ///
  /// In ca, this message translates to:
  /// **'No t’hi hem pogut apuntar. Torna-ho a provar.'**
  String get enrollSignUpError;

  /// No description provided for @enrollLeaveError.
  ///
  /// In ca, this message translates to:
  /// **'No t’hem pogut desapuntar. Torna-ho a provar.'**
  String get enrollLeaveError;

  /// No description provided for @pickerMapLabel.
  ///
  /// In ca, this message translates to:
  /// **'Mapa per marcar el lloc de l’activitat'**
  String get pickerMapLabel;

  /// No description provided for @pickerTapToAdjust.
  ///
  /// In ca, this message translates to:
  /// **'Toca per ajustar el punt'**
  String get pickerTapToAdjust;

  /// No description provided for @startSheetTitle.
  ///
  /// In ca, this message translates to:
  /// **'Data i hora d’inici'**
  String get startSheetTitle;

  /// No description provided for @startSheetError.
  ///
  /// In ca, this message translates to:
  /// **'L’inici ha de ser posterior a ara.'**
  String get startSheetError;

  /// No description provided for @endSheetTitle.
  ///
  /// In ca, this message translates to:
  /// **'Data i hora de fi'**
  String get endSheetTitle;

  /// No description provided for @endSheetError.
  ///
  /// In ca, this message translates to:
  /// **'La fi ha de ser posterior a l’inici.'**
  String get endSheetError;

  /// No description provided for @wheelDay.
  ///
  /// In ca, this message translates to:
  /// **'Dia'**
  String get wheelDay;

  /// No description provided for @wheelMonth.
  ///
  /// In ca, this message translates to:
  /// **'Mes'**
  String get wheelMonth;

  /// No description provided for @wheelYear.
  ///
  /// In ca, this message translates to:
  /// **'Any'**
  String get wheelYear;

  /// No description provided for @wheelTime.
  ///
  /// In ca, this message translates to:
  /// **'Hora'**
  String get wheelTime;

  /// No description provided for @done.
  ///
  /// In ca, this message translates to:
  /// **'Fet'**
  String get done;

  /// No description provided for @priceFree.
  ///
  /// In ca, this message translates to:
  /// **'Gratuït'**
  String get priceFree;

  /// No description provided for @actLoadCategoriesError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les categories.'**
  String get actLoadCategoriesError;

  /// No description provided for @actLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les activitats. Torna-ho a provar.'**
  String get actLoadError;

  /// No description provided for @actLoadMoreError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar més activitats. Torna-ho a provar.'**
  String get actLoadMoreError;

  /// No description provided for @actLoadZoneError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les activitats d’aquesta zona. Torna-ho a provar.'**
  String get actLoadZoneError;

  /// No description provided for @actLoadDetailError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar l’activitat. Torna-ho a provar.'**
  String get actLoadDetailError;

  /// No description provided for @actSearchError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut cercar les activitats. Torna-ho a provar.'**
  String get actSearchError;

  /// No description provided for @discoverSearchField.
  ///
  /// In ca, this message translates to:
  /// **'Cerca activitats'**
  String get discoverSearchField;

  /// No description provided for @discoverLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant propostes'**
  String get discoverLoading;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In ca, this message translates to:
  /// **'Encara no hi ha propostes'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyBody.
  ///
  /// In ca, this message translates to:
  /// **'Pots cercar activitats o tornar-ho a provar més tard.'**
  String get discoverEmptyBody;

  /// No description provided for @discoverForYou.
  ///
  /// In ca, this message translates to:
  /// **'Per a tu'**
  String get discoverForYou;

  /// No description provided for @discoverByInterests.
  ///
  /// In ca, this message translates to:
  /// **'Segons els teus interessos'**
  String get discoverByInterests;

  /// No description provided for @discoverStarter.
  ///
  /// In ca, this message translates to:
  /// **'Una selecció per començar'**
  String get discoverStarter;

  /// No description provided for @discoverNoRecommendations.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha recomanacions disponibles.'**
  String get discoverNoRecommendations;

  /// No description provided for @discoverRecommendationsAfterTest.
  ///
  /// In ca, this message translates to:
  /// **'Les recomanacions estaran disponibles quan hagis completat el test d’interessos.'**
  String get discoverRecommendationsAfterTest;

  /// No description provided for @discoverRecommendationsError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les recomanacions.'**
  String get discoverRecommendationsError;

  /// No description provided for @discoverFeatured.
  ///
  /// In ca, this message translates to:
  /// **'Destacats'**
  String get discoverFeatured;

  /// No description provided for @discoverNoFeatured.
  ///
  /// In ca, this message translates to:
  /// **'No hi ha activitats destacades.'**
  String get discoverNoFeatured;

  /// No description provided for @discoverFeaturedError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les activitats destacades.'**
  String get discoverFeaturedError;

  /// No description provided for @discoverGetToKnowYou.
  ///
  /// In ca, this message translates to:
  /// **'Coneguem els teus gustos'**
  String get discoverGetToKnowYou;

  /// No description provided for @discoverLoadError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut carregar les propostes. Torna-ho a provar.'**
  String get discoverLoadError;

  /// No description provided for @createLocationEmpty.
  ///
  /// In ca, this message translates to:
  /// **'Escriu el municipi o toca el mapa per marcar el lloc.'**
  String get createLocationEmpty;

  /// No description provided for @createLocationApproximate.
  ///
  /// In ca, this message translates to:
  /// **'Marcador al centre del municipi: toca el lloc exacte.'**
  String get createLocationApproximate;

  /// No description provided for @createLocationMarked.
  ///
  /// In ca, this message translates to:
  /// **'Lloc marcat. Pots tornar a tocar el mapa per canviar-lo.'**
  String get createLocationMarked;

  /// No description provided for @createTitleEdit.
  ///
  /// In ca, this message translates to:
  /// **'Edita l’activitat'**
  String get createTitleEdit;

  /// No description provided for @createTitleNew.
  ///
  /// In ca, this message translates to:
  /// **'Crea una activitat'**
  String get createTitleNew;

  /// No description provided for @createFieldTitle.
  ///
  /// In ca, this message translates to:
  /// **'Títol'**
  String get createFieldTitle;

  /// No description provided for @createFieldDescription.
  ///
  /// In ca, this message translates to:
  /// **'Descripció'**
  String get createFieldDescription;

  /// No description provided for @createFieldCategory.
  ///
  /// In ca, this message translates to:
  /// **'Categoria'**
  String get createFieldCategory;

  /// No description provided for @createCategoriesLoading.
  ///
  /// In ca, this message translates to:
  /// **'Carregant les categories'**
  String get createCategoriesLoading;

  /// No description provided for @createFieldStart.
  ///
  /// In ca, this message translates to:
  /// **'Data i hora d’inici'**
  String get createFieldStart;

  /// No description provided for @createPickStart.
  ///
  /// In ca, this message translates to:
  /// **'Tria la data i l’hora'**
  String get createPickStart;

  /// No description provided for @createFieldEnd.
  ///
  /// In ca, this message translates to:
  /// **'Data i hora de fi (opcional)'**
  String get createFieldEnd;

  /// No description provided for @createRemoveEnd.
  ///
  /// In ca, this message translates to:
  /// **'Treu la data de fi'**
  String get createRemoveEnd;

  /// No description provided for @createPickStartFirst.
  ///
  /// In ca, this message translates to:
  /// **'Tria primer l’inici'**
  String get createPickStartFirst;

  /// No description provided for @createNoEnd.
  ///
  /// In ca, this message translates to:
  /// **'Sense data de fi'**
  String get createNoEnd;

  /// No description provided for @createFieldMunicipality.
  ///
  /// In ca, this message translates to:
  /// **'Municipi (opcional)'**
  String get createFieldMunicipality;

  /// No description provided for @createFieldDirections.
  ///
  /// In ca, this message translates to:
  /// **'Indicacions (opcional)'**
  String get createFieldDirections;

  /// No description provided for @createDirectionsHint.
  ///
  /// In ca, this message translates to:
  /// **'Per exemple: entrada pel pati, 2n pis'**
  String get createDirectionsHint;

  /// No description provided for @createFieldPrice.
  ///
  /// In ca, this message translates to:
  /// **'Preu (opcional)'**
  String get createFieldPrice;

  /// No description provided for @createPriceHelperUnknown.
  ///
  /// In ca, this message translates to:
  /// **'Si el deixes buit, no es canvia. Escriu 0 si és gratuïta.'**
  String get createPriceHelperUnknown;

  /// No description provided for @createPriceHelper.
  ///
  /// In ca, this message translates to:
  /// **'Deixa-ho buit si és gratuïta.'**
  String get createPriceHelper;

  /// No description provided for @createPublishing.
  ///
  /// In ca, this message translates to:
  /// **'Publicant'**
  String get createPublishing;

  /// No description provided for @createSaveChanges.
  ///
  /// In ca, this message translates to:
  /// **'Desa els canvis'**
  String get createSaveChanges;

  /// No description provided for @createPublish.
  ///
  /// In ca, this message translates to:
  /// **'Publica'**
  String get createPublish;

  /// No description provided for @createCoverSemantics.
  ///
  /// In ca, this message translates to:
  /// **'Imatge de portada. Canvia la imatge'**
  String get createCoverSemantics;

  /// No description provided for @createChangeImage.
  ///
  /// In ca, this message translates to:
  /// **'Canvia la imatge'**
  String get createChangeImage;

  /// No description provided for @createCoverTitle.
  ///
  /// In ca, this message translates to:
  /// **'Imatge de portada'**
  String get createCoverTitle;

  /// No description provided for @createUploadSoonTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Pujar fotos estarà disponible properament'**
  String get createUploadSoonTooltip;

  /// No description provided for @createUploadSoon.
  ///
  /// In ca, this message translates to:
  /// **'Puja una foto (properament)'**
  String get createUploadSoon;

  /// No description provided for @createOrPickOurs.
  ///
  /// In ca, this message translates to:
  /// **'O tria una de les nostres'**
  String get createOrPickOurs;

  /// No description provided for @createImageOption.
  ///
  /// In ca, this message translates to:
  /// **'Imatge {number}'**
  String createImageOption(int number);

  /// No description provided for @createPublishError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut publicar l’activitat. Torna-ho a provar.'**
  String get createPublishError;

  /// No description provided for @createUpdateError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut desar els canvis. Torna-ho a provar.'**
  String get createUpdateError;

  /// No description provided for @createCategoryRequired.
  ///
  /// In ca, this message translates to:
  /// **'Tria una categoria.'**
  String get createCategoryRequired;

  /// No description provided for @createPriceInvalid.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un preu vàlid, per exemple 12,50.'**
  String get createPriceInvalid;

  /// No description provided for @createTitleRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix el títol.'**
  String get createTitleRequired;

  /// No description provided for @createMaxChars.
  ///
  /// In ca, this message translates to:
  /// **'Màxim {max} caràcters.'**
  String createMaxChars(int max);

  /// No description provided for @createDescriptionRequired.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix una descripció.'**
  String get createDescriptionRequired;

  /// No description provided for @createStartRequired.
  ///
  /// In ca, this message translates to:
  /// **'Tria la data i l’hora d’inici.'**
  String get createStartRequired;

  /// No description provided for @navHome.
  ///
  /// In ca, this message translates to:
  /// **'Inici'**
  String get navHome;

  /// No description provided for @navAgenda.
  ///
  /// In ca, this message translates to:
  /// **'Agenda'**
  String get navAgenda;

  /// No description provided for @navDiscover.
  ///
  /// In ca, this message translates to:
  /// **'Descobreix'**
  String get navDiscover;

  /// No description provided for @navNotifications.
  ///
  /// In ca, this message translates to:
  /// **'Avisos'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In ca, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @shareDialogBody.
  ///
  /// In ca, this message translates to:
  /// **'Comparteix el teu nom d’usuari d’AProp!'**
  String get shareDialogBody;

  /// No description provided for @shareCancel.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·lar'**
  String get shareCancel;

  /// No description provided for @shareCopied.
  ///
  /// In ca, this message translates to:
  /// **'Nom d’usuari copiat'**
  String get shareCopied;

  /// No description provided for @shareCopyError.
  ///
  /// In ca, this message translates to:
  /// **'No hem pogut copiar el nom d’usuari.'**
  String get shareCopyError;

  /// No description provided for @shareCopying.
  ///
  /// In ca, this message translates to:
  /// **'Copiant…'**
  String get shareCopying;

  /// No description provided for @shareCopy.
  ///
  /// In ca, this message translates to:
  /// **'Copiar nom d’usuari'**
  String get shareCopy;

  /// No description provided for @assistantOpenTooltip.
  ///
  /// In ca, this message translates to:
  /// **'Obrir l’assistent'**
  String get assistantOpenTooltip;

  /// No description provided for @apiTimeout.
  ///
  /// In ca, this message translates to:
  /// **'El servidor està despertant o triga massa a respondre. Torna-ho a provar.'**
  String get apiTimeout;

  /// No description provided for @apiNetwork.
  ///
  /// In ca, this message translates to:
  /// **'No s’ha pogut connectar amb el servidor.'**
  String get apiNetwork;

  /// No description provided for @createFieldCategories.
  ///
  /// In ca, this message translates to:
  /// **'Categories'**
  String get createFieldCategories;

  /// No description provided for @createCategoriesHint.
  ///
  /// In ca, this message translates to:
  /// **'Tria’n fins a {max}. La primera és la que es veu a les targetes.'**
  String createCategoriesHint(int max);

  /// No description provided for @createCategoriesMax.
  ///
  /// In ca, this message translates to:
  /// **'Pots triar fins a {max} categories.'**
  String createCategoriesMax(int max);

  /// No description provided for @createScheduleNoteLabel.
  ///
  /// In ca, this message translates to:
  /// **'Més sobre l’horari (opcional)'**
  String get createScheduleNoteLabel;

  /// No description provided for @createScheduleNoteHint.
  ///
  /// In ca, this message translates to:
  /// **'Per exemple: durada aproximada d’1 hora'**
  String get createScheduleNoteHint;

  /// No description provided for @createScheduleNoteHelper.
  ///
  /// In ca, this message translates to:
  /// **'L’hora d’inici i de fi ja s’hi afegeix sola.'**
  String get createScheduleNoteHelper;

  /// No description provided for @createModality.
  ///
  /// In ca, this message translates to:
  /// **'Modalitat'**
  String get createModality;

  /// No description provided for @createModalityBoth.
  ///
  /// In ca, this message translates to:
  /// **'Les dues'**
  String get createModalityBoth;

  /// No description provided for @createOnlineUrlLabel.
  ///
  /// In ca, this message translates to:
  /// **'Enllaç per connectar-s’hi (opcional)'**
  String get createOnlineUrlLabel;

  /// No description provided for @createOnlineUrlInvalid.
  ///
  /// In ca, this message translates to:
  /// **'Introdueix un enllaç que comenci per https://.'**
  String get createOnlineUrlInvalid;

  /// No description provided for @createPermanentHint.
  ///
  /// In ca, this message translates to:
  /// **'Per exemple, una exposició fixa.'**
  String get createPermanentHint;

  /// No description provided for @actPermanent.
  ///
  /// In ca, this message translates to:
  /// **'Activitat permanent'**
  String get actPermanent;

  /// No description provided for @modalityInPerson.
  ///
  /// In ca, this message translates to:
  /// **'Presencial'**
  String get modalityInPerson;

  /// No description provided for @modalityOnline.
  ///
  /// In ca, this message translates to:
  /// **'En línia'**
  String get modalityOnline;

  /// No description provided for @modalityMixed.
  ///
  /// In ca, this message translates to:
  /// **'Presencial i en línia'**
  String get modalityMixed;

  /// No description provided for @actUntil.
  ///
  /// In ca, this message translates to:
  /// **'Fins al {date}'**
  String actUntil(String date);

  /// No description provided for @actLinks.
  ///
  /// In ca, this message translates to:
  /// **'Enllaços'**
  String get actLinks;

  /// No description provided for @actLinkJoin.
  ///
  /// In ca, this message translates to:
  /// **'Enllaç per connectar-s’hi'**
  String get actLinkJoin;

  /// No description provided for @actLinkWebsite.
  ///
  /// In ca, this message translates to:
  /// **'Web de l’activitat'**
  String get actLinkWebsite;

  /// No description provided for @actLinkAccess.
  ///
  /// In ca, this message translates to:
  /// **'Informació d’accés'**
  String get actLinkAccess;

  /// No description provided for @actLinkCopy.
  ///
  /// In ca, this message translates to:
  /// **'Copia l’enllaç: {name}'**
  String actLinkCopy(String name);

  /// No description provided for @actLinkCopied.
  ///
  /// In ca, this message translates to:
  /// **'Enllaç copiat.'**
  String get actLinkCopied;

  /// No description provided for @actLinkOpenError.
  ///
  /// In ca, this message translates to:
  /// **'No s’ha pogut obrir l’enllaç.'**
  String get actLinkOpenError;

  /// No description provided for @actMoreCategories.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, one{1 categoria més} other{{count} categories més}}'**
  String actMoreCategories(int count);
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
      <String>['ca', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
