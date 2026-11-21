// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'AProp!';

  @override
  String get profileTitleFallback => 'Perfil';

  @override
  String get profilePeopleSearchSoon =>
      'Cerca de persones disponible properament';

  @override
  String get settingsTooltip => 'Configuració';

  @override
  String get profileLoading => 'Carregant el perfil';

  @override
  String get retry => 'Tornar-ho a provar';

  @override
  String get profileTabCompletedPlans => 'Plans fets';

  @override
  String get profileTabCreatedByMe => 'Creats per mi';

  @override
  String get profileCreatedLoading => 'Carregant les activitats creades';

  @override
  String get profileNoCompletedPlans => 'Encara no tens plans fets';

  @override
  String get profileCompletedHistorySoon =>
      'Historial d’assistència disponible properament';

  @override
  String get profileNoCreated => 'Encara no has creat cap activitat';

  @override
  String get profileCompletedHint =>
      'Aquí veuràs les activitats amb assistència confirmada.';

  @override
  String get profileSavedPlansHint =>
      'Pots consultar els plans guardats a l’Agenda.';

  @override
  String get profileCreateHint => 'Pots crear-ne una des d’Inici.';

  @override
  String get profileLoadError =>
      'No hem pogut carregar el perfil. Torna-ho a provar.';

  @override
  String get profileCreatedLoadError =>
      'No hem pogut carregar les activitats creades.';

  @override
  String get publicProfileLoadError => 'No hem pogut carregar el perfil.';

  @override
  String get publicProfileNotFound =>
      'Aquest perfil no existeix o ja no està disponible.';

  @override
  String get publicProfileTabCreated => 'Creats';

  @override
  String get friendAdd => 'Afegeix com a amic';

  @override
  String get friendSending => 'Enviant…';

  @override
  String get friendRequestSent => 'Sol·licitud enviada';

  @override
  String get friendAlready => 'Amiga/Amic';

  @override
  String get friendRejecting => 'Rebutjant…';

  @override
  String get friendRejectError =>
      'No hem pogut rebutjar la sol·licitud. Torna-ho a provar.';

  @override
  String get friendAccepting => 'Acceptant…';

  @override
  String get friendAcceptError =>
      'No hem pogut acceptar la sol·licitud. Torna-ho a provar.';

  @override
  String get friendStatusError =>
      'No hem pogut consultar les sol·licituds. Torna-ho a provar.';

  @override
  String get friendRequestError =>
      'No hem pogut enviar la sol·licitud. Torna-ho a provar.';

  @override
  String get friendRequestBlocked =>
      'No pots enviar una sol·licitud d’amistat a aquesta persona.';

  @override
  String get friendsTitle => 'Amics';

  @override
  String get friendsLoading => 'Carregant els amics';

  @override
  String get friendsLoadError => 'No hem pogut carregar els amics.';

  @override
  String get friendsEmptyOwn => 'Encara no tens amics.';

  @override
  String friendsEmptyOther(String name) {
    return '$name encara no té amics.';
  }

  @override
  String get friendsOpenList => 'Veure els amics';

  @override
  String get publicProfilePlansLoadError => 'No hem pogut carregar els plans.';

  @override
  String publicProfilePlansFriendsOnly(String name) {
    return 'Els plans de $name només els poden veure els seus amics.';
  }

  @override
  String publicProfilePlansHidden(String name) {
    return '$name no comparteix els seus plans.';
  }

  @override
  String publicProfileNoPlans(String name) {
    return '$name encara no té plans fets.';
  }

  @override
  String publicProfileNoCreated(String name) {
    return '$name encara no ha creat cap activitat.';
  }

  @override
  String get profileBiographyTooLong =>
      'La biografia és massa llarga. Prova de fer-la més curta.';

  @override
  String get profileMunicipalityTooLong => 'Escriu com a màxim 80 caràcters.';

  @override
  String get profileNameRequired => 'Escriu el teu nom.';

  @override
  String get profileNameTooLong => 'El nom és massa llarg.';

  @override
  String get profileUsernameInvalid =>
      'Fes servir entre 3 i 30 lletres, números o guions baixos.';

  @override
  String get profileUsernameTaken =>
      'El nom d’usuari ja està ocupat. Tria’n un altre.';

  @override
  String get profileSaveError =>
      'No hem pogut desar el perfil. Torna-ho a provar.';

  @override
  String get profileAvatarError =>
      'No hem pogut canviar la foto. Torna-ho a provar.';

  @override
  String get profileAvatarInterrupted =>
      'S’ha interromput una selecció de foto. Torna-la a triar.';

  @override
  String get avatarTooBig => 'Tria una foto de menys de 5 MB.';

  @override
  String get avatarNameUnreadable => 'No hem pogut llegir el nom de la foto.';

  @override
  String get avatarWrongFormat => 'Tria una foto JPG, PNG o WebP.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get close => 'Tancar';

  @override
  String get fieldName => 'Nom';

  @override
  String get fieldUsername => 'Nom d’usuari';

  @override
  String get fieldBiography => 'Biografia';

  @override
  String get fieldMunicipality => 'Municipi';

  @override
  String get municipalityEditSoon =>
      'L’edició del municipi estarà disponible properament.';

  @override
  String get saving => 'Desant…';

  @override
  String get save => 'Desar';

  @override
  String profileActivityViewLabel(String title) {
    return 'Veure activitat: $title';
  }

  @override
  String profileActivityRatingSuffix(int rating) {
    return 'Valoració: $rating de 5';
  }

  @override
  String get statPlans => 'Plans';

  @override
  String get statFriends => 'Amics';

  @override
  String get statRating => 'Valoració';

  @override
  String get reliabilityNone =>
      'Fiabilitat com a organitzador: sense valoracions';

  @override
  String reliabilityOutOfFive(String value) {
    return 'Fiabilitat com a organitzador: $value sobre 5';
  }

  @override
  String get changing => 'Canviant…';

  @override
  String get changePhoto => 'Canviar foto';

  @override
  String get shareProfile => 'Compartir perfil';

  @override
  String get shareNeedsUsername =>
      'Cal un nom d’usuari per compartir el perfil';

  @override
  String get shareUsername => 'Compartir el nom d’usuari';

  @override
  String photoOf(String name) {
    return 'Foto de $name';
  }

  @override
  String xpValue(int xp) {
    return '$xp XP';
  }

  @override
  String xpOfTarget(int xp, int target) {
    return '$xp / $target XP';
  }

  @override
  String get xpMaxLevel => 'Has assolit el nivell màxim';

  @override
  String get xpStart => 'El teu recorregut cultural comença aquí';

  @override
  String xpRemainingForLevel(int remaining, String level) {
    return '$remaining XP per a $level';
  }

  @override
  String xpProgressSemantics(int xp) {
    return 'Progrés d’experiència: $xp XP';
  }

  @override
  String xpProgressOfSemantics(int xp, int target) {
    return 'Progrés d’experiència: $xp de $target XP';
  }

  @override
  String get levelStateCurrent => 'nivell actual';

  @override
  String get levelStateReached => 'assolit';

  @override
  String get levelStatePending => 'pendent';

  @override
  String get levelCurious => 'Curiós/a';

  @override
  String get levelExplorer => 'Explorador/a';

  @override
  String get levelAdventurer => 'Aventurer/a';

  @override
  String get levelDiscoverer => 'Descobridor/a';

  @override
  String get levelAmbassador => 'Ambaixador/a';

  @override
  String levelCultural(String label) {
    return '$label cultural';
  }

  @override
  String get comingSoon => 'Disponible properament';

  @override
  String comingSoonTitled(String title) {
    return '$title: disponible properament';
  }

  @override
  String get settingsTitle => 'Configuració';

  @override
  String get goBack => 'Tornar enrere';

  @override
  String get settingsLoading => 'Carregant la configuració';

  @override
  String get settingsSavingChange => 'Desant el canvi…';

  @override
  String get settingsGroupPreferences => 'PREFERÈNCIES';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageNameCa => 'Català';

  @override
  String get languageNameEs => 'Castellano';

  @override
  String get languageNameEn => 'English';

  @override
  String get settingsLanguageSyncError =>
      'L’idioma s’ha canviat, però no l’hem pogut desar al teu compte. Torna-ho a provar.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Clar';

  @override
  String get themeDark => 'Fosc';

  @override
  String get settingsDarkThemeSoon => 'Tema fosc disponible properament';

  @override
  String get settingsGroupPrivacy => 'PRIVACITAT';

  @override
  String get settingsShowMyPlans => 'Mostrar els meus plans';

  @override
  String get settingsShowMyPlansHint => 'Els amics veuen a què t’apuntes';

  @override
  String get settingsBlockedUsers => 'Usuaris bloquejats';

  @override
  String get settingsGroupNotifications => 'NOTIFICACIONS';

  @override
  String get settingsReminders => 'Recordatoris';

  @override
  String get settingsRemindersHint => 'Avisos dels plans de la teva agenda';

  @override
  String get settingsFriendActivity => 'Activitat dels amics';

  @override
  String get settingsFriendActivityHint => 'Quan un amic s’apunta a un pla';

  @override
  String get settingsRecommendations => 'Recomanacions';

  @override
  String get settingsFriendRequests => 'Sol·licituds d’amistat';

  @override
  String get settingsPersistsAccount =>
      'Els canvis disponibles es desen al teu compte.';

  @override
  String get settingsPersistsSession =>
      'Les preferències es conserven durant aquesta sessió de l’app.';

  @override
  String get settingsGroupAccount => 'COMPTE';

  @override
  String get settingsGoogleCalendar => 'Google Calendar';

  @override
  String get settingsGoogleCalendarHint => 'Exportació disponible properament';

  @override
  String get settingsNotConnected => 'No connectat';

  @override
  String get settingsRetakeInterestTest => 'Tornar a fer el test d’interessos';

  @override
  String get settingsSigningOut => 'Tancant sessió…';

  @override
  String get settingsSignOut => 'Tancar sessió';

  @override
  String get settingsDeleteAccount => 'Eliminar compte';

  @override
  String get settingsLoadError =>
      'No hem pogut carregar la configuració. Torna-ho a provar.';

  @override
  String get settingsSaveError =>
      'No hem pogut desar el canvi. Torna-ho a provar.';

  @override
  String get settingsSignOutError =>
      'No hem pogut tancar la sessió. Torna-ho a provar.';

  @override
  String authGreetingNamed(String name) {
    return 'Hola, $name!';
  }

  @override
  String get authGreeting => 'Hola!';

  @override
  String get authChooseUsernameTitle => 'Tria el teu nom d\'usuari';

  @override
  String authChooseUsernameBody(String greeting) {
    return '$greeting Tria el nom amb què et trobaran a l\'app.';
  }

  @override
  String authUsernameTaken(String username) {
    return 'El nom «$username» ja és d\'una altra persona. Tria\'n un altre.';
  }

  @override
  String get authUsernameLabel => 'Nom d\'usuari';

  @override
  String get authUsernameHelper =>
      'Minúscules, números, punt o guió baix (3-20).';

  @override
  String get authContinue => 'Continua';

  @override
  String get authNotYourAccount => 'No és el teu compte?';

  @override
  String get authSignOutLink => 'Tanca la sessió';

  @override
  String get authLoginTitle => 'Inicia sessió';

  @override
  String get authLoginSubtitle => 'Troba plans culturals a prop teu.';

  @override
  String get authUsernameOrEmail => 'Nom d\'usuari o correu';

  @override
  String get authPassword => 'Contrasenya';

  @override
  String get authSignIn => 'Entra';

  @override
  String get authNoAccount => 'Encara no tens compte?';

  @override
  String get authCreateAccountLink => 'Crea un compte';

  @override
  String get authRegisterIntro =>
      'Uneix-te a AProp! per apuntar-te a activitats i crear-ne de noves.';

  @override
  String get authFirstName => 'Nom';

  @override
  String get authLastName => 'Cognoms';

  @override
  String get authEmail => 'Correu electrònic';

  @override
  String get authPasswordHelper =>
      'Mínim 8 caràcters, amb majúscula, minúscula, número i caràcter especial.';

  @override
  String get authRepeatPassword => 'Repeteix la contrasenya';

  @override
  String get authCreateAccountButton => 'Crea el compte';

  @override
  String get authHaveAccount => 'Ja tens compte?';

  @override
  String get authVerifyTitle => 'Verifica el teu correu';

  @override
  String get authVerifySentTo => 'T\'hem enviat un enllaç a';

  @override
  String get authVerifyOpenIt =>
      '. Obre\'l per activar el compte i després torna aquí.';

  @override
  String get authAlreadyVerified => 'Ja l\'he verificat';

  @override
  String authResendEmailIn(int seconds) {
    return 'Torna a enviar el correu ($seconds s)';
  }

  @override
  String get authResendEmail => 'Torna a enviar el correu';

  @override
  String get authWrongEmail => 'T\'has equivocat de correu?';

  @override
  String get authUnexpectedError =>
      'No hem pogut completar l\'operació. Torna-ho a provar.';

  @override
  String get authInvalidCredentials =>
      'L\'usuari o la contrasenya no són correctes.';

  @override
  String get authEmailInUse => 'Ja hi ha un compte amb aquest correu.';

  @override
  String get authUsernameInUse =>
      'Aquest nom d\'usuari ja està agafat. Prova\'n un altre.';

  @override
  String get authNetworkError =>
      'No hi ha connexió. Comprova la xarxa i torna-ho a provar.';

  @override
  String get authTooManyRequests =>
      'Massa intents seguits. Espera una mica i torna-ho a provar.';

  @override
  String get authEmailRequired =>
      'De moment només pots entrar amb el correu electrònic.';

  @override
  String get authPopupBlocked =>
      'El navegador ha bloquejat la finestra de Google. Permet les finestres emergents i torna-ho a provar.';

  @override
  String get authEmailRequiredField => 'Introdueix el correu.';

  @override
  String get authEmailInvalid => 'El correu no és vàlid.';

  @override
  String get forgotTitle => 'Recupera la contrasenya';

  @override
  String get forgotLink => 'Has oblidat la contrasenya?';

  @override
  String get forgotIntro =>
      'Escriu el correu del teu compte i t’enviarem un enllaç per triar-ne una de nova.';

  @override
  String get forgotEmailLabel => 'Correu';

  @override
  String get forgotSend => 'Envia l’enllaç';

  @override
  String forgotResendIn(int seconds) {
    return 'Torna a enviar l’enllaç ($seconds s)';
  }

  @override
  String get forgotResend => 'Torna a enviar l’enllaç';

  @override
  String get forgotRemember => 'Ja la recordes?';

  @override
  String get forgotBackToLogin => 'Torna a l’inici de sessió';

  @override
  String get forgotSent =>
      'Si hi ha un compte amb aquest correu, t’hi hem enviat un enllaç per triar una contrasenya nova. Si no el trobes, mira el correu brossa.';

  @override
  String get authUsernameRequired => 'Introdueix un nom d\'usuari.';

  @override
  String get authUsernameRules =>
      'Entre 3 i 20 caràcters: minúscules, números, punt o guió baix.';

  @override
  String get authPasswordRequired => 'Introdueix una contrasenya.';

  @override
  String authPasswordMissingLength(int min) {
    return 'almenys $min caràcters';
  }

  @override
  String get authPasswordMissingUpper => 'una majúscula';

  @override
  String get authPasswordMissingLower => 'una minúscula';

  @override
  String get authPasswordMissingDigit => 'un número';

  @override
  String get authPasswordMissingSpecial => 'un caràcter especial';

  @override
  String authPasswordMustHave(String requirements) {
    return 'Ha de tenir $requirements.';
  }

  @override
  String authListAnd(String list, String last) {
    return '$list i $last';
  }

  @override
  String get authRepeatPasswordRequired => 'Repeteix la contrasenya.';

  @override
  String get authPasswordsDiffer => 'Les contrasenyes no coincideixen.';

  @override
  String get authUsernameOrEmailRequired =>
      'Introdueix el nom d\'usuari o el correu.';

  @override
  String get authFirstNameRequired => 'Introdueix el nom.';

  @override
  String get authLastNameRequired => 'Introdueix els cognoms.';

  @override
  String get authEmailNotVerified =>
      'Encara no consta que hagis verificat el correu. Obre l\'enllaç que t\'hem enviat i torna-ho a provar.';

  @override
  String get authVerificationSent => 'T\'hem tornat a enviar el correu.';

  @override
  String get loading => 'Carregant';

  @override
  String get authOr => 'o';

  @override
  String get authContinueWithGoogle => 'Continua amb Google';

  @override
  String get authShowPassword => 'Mostra la contrasenya';

  @override
  String get authHidePassword => 'Amaga la contrasenya';

  @override
  String get authLoginPasswordRequired => 'Introdueix la contrasenya.';

  @override
  String get assistantTitle => 'Assistent';

  @override
  String assistantAnnouncement(String text) {
    return 'Assistent: $text';
  }

  @override
  String assistantSuggestedQuestion(String text) {
    return 'Pregunta suggerida: $text';
  }

  @override
  String get assistantSearching => 'Cercant recomanacions';

  @override
  String get assistantGoToLast => 'Anar a l’últim missatge';

  @override
  String get assistantWelcome =>
      'Hola! Sóc l’assistent d’AProp!. Digue’m quin tipus d’activitat busques, a quin municipi i per a quines dates, i et proposaré plans culturals.';

  @override
  String get assistantRateError =>
      'No hem pogut desar la valoració. Torna-ho a provar.';

  @override
  String get assistantTooManyMessages => 'Massa missatges, espera un minut';

  @override
  String get assistantReplyError =>
      'No hem pogut obtenir les recomanacions de l’assistent. Torna-ho a provar.';

  @override
  String assistantViewActivity(String title) {
    return 'Veure activitat: $title';
  }

  @override
  String get assistantVoiceSoon => 'Entrada per veu disponible properament';

  @override
  String get assistantInputHint => 'Escriu una consulta…';

  @override
  String get assistantSend => 'Enviar';

  @override
  String assistantChipType(String value) {
    return 'Tipus: $value';
  }

  @override
  String assistantChipMunicipality(String value) {
    return 'Municipi: $value';
  }

  @override
  String assistantChipDates(String value) {
    return 'Dates: $value';
  }

  @override
  String get assistantOpenHome => 'Obre Inici';

  @override
  String get assistantOpenAgenda => 'Obre Agenda';

  @override
  String get assistantOpenDiscover => 'Obre Descobreix';

  @override
  String get assistantOpenNotifications => 'Obre Avisos';

  @override
  String get assistantOpenProfile => 'Obre Perfil';

  @override
  String get assistantOpenSettings => 'Obre Configuració';

  @override
  String get assistantOpenInterestTest => 'Obre el test d’interessos';

  @override
  String get assistantHelpful => 'Resposta útil';

  @override
  String get assistantNotHelpful => 'Resposta poc útil';

  @override
  String get selected => 'Seleccionat';

  @override
  String get assistantYou => 'Tu';

  @override
  String monthName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'gener',
      '2': 'febrer',
      '3': 'març',
      '4': 'abril',
      '5': 'maig',
      '6': 'juny',
      '7': 'juliol',
      '8': 'agost',
      '9': 'setembre',
      '10': 'octubre',
      '11': 'novembre',
      '12': 'desembre',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String monthOf(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'de gener',
      '2': 'de febrer',
      '3': 'de març',
      '4': 'd’abril',
      '5': 'de maig',
      '6': 'de juny',
      '7': 'de juliol',
      '8': 'd’agost',
      '9': 'de setembre',
      '10': 'd’octubre',
      '11': 'de novembre',
      '12': 'de desembre',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Dilluns',
      '2': 'Dimarts',
      '3': 'Dimecres',
      '4': 'Dijous',
      '5': 'Divendres',
      '6': 'Dissabte',
      '7': 'Diumenge',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayAbbr(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Dl',
      '2': 'Dt',
      '3': 'Dc',
      '4': 'Dj',
      '5': 'Dv',
      '6': 'Ds',
      '7': 'Dg',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String timeOfDay(String hour, String minute) {
    return '$hour.$minute h';
  }

  @override
  String dateLong(String weekday, int day, String monthOf, int year) {
    return '$weekday $day $monthOf de $year';
  }

  @override
  String dateWithYear(int day, String monthOf, int year) {
    return '$day $monthOf de $year';
  }

  @override
  String dateNoYear(int day, String monthOf) {
    return '$day $monthOf';
  }

  @override
  String monthHeader(String month, int year) {
    return '$month de $year';
  }

  @override
  String monthYear(String month, int year) {
    return '$month $year';
  }

  @override
  String weekdayDay(String weekday, int day, String monthOf) {
    return '$weekday, $day $monthOf';
  }

  @override
  String scheduleJoin(String day, String time) {
    return '$day · $time';
  }

  @override
  String get dateUnknown => 'Data no informada';

  @override
  String get rangeAll => 'Totes les dates';

  @override
  String rangeFromTo(String start, String end) {
    return 'Del $start al $end';
  }

  @override
  String rangeFromDayTo(int startDay, String start, String end) {
    return 'Del $startDay al $end';
  }

  @override
  String get today => 'Avui';

  @override
  String get yesterday => 'Ahir';

  @override
  String get notifCategorySocial => 'Social';

  @override
  String get notifCategoryReminder => 'Recordatori';

  @override
  String get notifCategoryRecommendation => 'Recomanació';

  @override
  String get notifCategoryNotice => 'Avís';

  @override
  String get notifFilterAll => 'Tots';

  @override
  String get notifFilterReminders => 'Recordatoris';

  @override
  String get notifFilterRecommendations => 'Recomanacions';

  @override
  String get notifMessageReminder => 'Tens un recordatori cultural.';

  @override
  String get notifMessageRecommendation => 'Tens una recomanació cultural.';

  @override
  String notifMessageRecommendationFor(String title) {
    return '“$title” et pot interessar.';
  }

  @override
  String notifMessageSocialAbout(String title) {
    return 'Avís social sobre “$title”.';
  }

  @override
  String notifMessageSocialPerson(String name) {
    return 'Tens un avís social relacionat amb $name.';
  }

  @override
  String get notifMessageSocial => 'Tens un nou avís social.';

  @override
  String get notifMessageOther => 'Tens un nou avís.';

  @override
  String notifMessageCancelledFor(String title) {
    return 'S’ha cancel·lat «$title».';
  }

  @override
  String get notifMessageCancelled =>
      'S’ha cancel·lat una activitat on t’havies apuntat.';

  @override
  String notifMessagePublished(String name, String title) {
    return '$name ha publicat “$title”.';
  }

  @override
  String notifMessageEnrolled(String name, String title) {
    return '$name s’ha apuntat a “$title”.';
  }

  @override
  String notifMessageFriendRequest(String name) {
    return '$name t’ha enviat una sol·licitud d’amistat.';
  }

  @override
  String notifMessageFriendAccepted(String name) {
    return '$name ha acceptat la teva sol·licitud d’amistat.';
  }

  @override
  String get notifLoading => 'Carregant els avisos';

  @override
  String get notifEmptyAll => 'Encara no tens cap avís';

  @override
  String get notifEmptySocial => 'Encara no tens avisos socials';

  @override
  String get notifEmptyReminders => 'Encara no has rebut cap recordatori';

  @override
  String get notifEmptyRecommendations => 'Encara no has rebut recomanacions';

  @override
  String get notifEmptyRemindersHint =>
      'Els recordatoris que configuris a l’agenda apareixeran aquí quan arribi l’hora de l’avís.';

  @override
  String get notifEmptySocialHint =>
      'Aquí trobaràs les sol·licituds d’amistat i les novetats dels teus amics.';

  @override
  String get notifEmptyRecommendationsHint =>
      'Aquí trobaràs avisos d’activitats que et poden interessar.';

  @override
  String get notifEmptyAllHint =>
      'Aquí trobaràs els avisos socials, els recordatoris i les recomanacions que rebis.';

  @override
  String get notifSeeAll => 'Veure tots els avisos';

  @override
  String get notifLoadError =>
      'No hem pogut carregar els avisos. Torna-ho a provar.';

  @override
  String get notifMarkReadError =>
      'No hem pogut marcar l’avís com a llegit. Torna-ho a provar.';

  @override
  String get notifRespondError =>
      'No hem pogut respondre la sol·licitud. Torna-ho a provar.';

  @override
  String get notifRead => 'Llegit';

  @override
  String get notifUnread => 'Sense llegir';

  @override
  String get notifHintProfileUnavailable =>
      'Marca l’avís com a llegit. El perfil encara no està disponible.';

  @override
  String get notifHintOpenActivity => 'Obre l’activitat';

  @override
  String get notifHintOpenProfile => 'Obre el perfil';

  @override
  String get notifHintMarkRead => 'Marca l’avís com a llegit';

  @override
  String notifReceivedAt(String time) {
    return 'Rebut a les $time';
  }

  @override
  String get notifProfileSoon => 'Perfil disponible properament';

  @override
  String get notifActivityGone => 'L’activitat ja no està disponible.';

  @override
  String get notifActivityLoadError =>
      'No s’ha pogut carregar la informació de l’activitat. Pots provar d’obrir-la.';

  @override
  String get notifSendingResponse => 'Enviant la resposta';

  @override
  String notifAcceptRequestFrom(String name) {
    return 'Acceptar la sol·licitud d’amistat de $name';
  }

  @override
  String notifDeclineRequestFrom(String name) {
    return 'Rebutjar la sol·licitud d’amistat de $name';
  }

  @override
  String notifViewFriendProfile(String name) {
    return 'Veure el perfil de $name';
  }

  @override
  String get notifAccept => 'Acceptar';

  @override
  String get notifDecline => 'Rebutjar';

  @override
  String get notifRequestAccepted => 'Sol·licitud acceptada';

  @override
  String get notifRequestDeclined => 'Sol·licitud rebutjada';

  @override
  String get interestTestTitle => 'Test d’interessos';

  @override
  String get interestTestLoading => 'Carregant el test';

  @override
  String get interestTestEmpty => 'Ara mateix no hi ha activitats per al test.';

  @override
  String get interestTestBack => 'Tornar';

  @override
  String get interestTestDone =>
      'Hem actualitzat els teus interessos. Les recomanacions de «Per a tu» els tindran en compte.';

  @override
  String get interestTestBackToSettings => 'Tornar a la configuració';

  @override
  String get interestTestSaving => 'Desant les respostes';

  @override
  String interestTestProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get interestTestProgressSemantics => 'Progrés del test';

  @override
  String get interestTestSwipeHint =>
      'Llisca cap a la dreta si t’interessa i cap a l’esquerra si no.';

  @override
  String get interestTestLike => 'M’interessa';

  @override
  String get interestTestDislike => 'No m’interessa';

  @override
  String get interestTestLoadError =>
      'No hem pogut carregar el test. Torna-ho a provar.';

  @override
  String get interestTestSaveError =>
      'No hem pogut desar les respostes. Torna-ho a provar.';

  @override
  String get interestTestSkip => 'Ara no';

  @override
  String get interestTestContinue => 'Continua';

  @override
  String get ratingDeleteTitle => 'Eliminar la valoració?';

  @override
  String get ratingDeleteBody =>
      'La teva valoració s’eliminarà i podràs tornar a valorar l’activitat.';

  @override
  String get cancel => 'Cancel·la';

  @override
  String get delete => 'Elimina';

  @override
  String get ratingEdit => 'Modifica la valoració';

  @override
  String ratingOrganizerRated(String name) {
    return 'Ja has valorat $name';
  }

  @override
  String ratingOrganizerAsk(String name) {
    return 'Com ha anat l’organitzador/a $name?';
  }

  @override
  String get ratingActivityRated => 'Ja has valorat aquesta activitat';

  @override
  String get ratingAsk => 'Com t’ha anat?';

  @override
  String get ratingCancelEdit => 'Cancel·la la modificació';

  @override
  String get ratingEditShort => 'Modifica';

  @override
  String get ratingDelete => 'Elimina la valoració';

  @override
  String ratingScore(int score) {
    return 'Valoració: $score de 5';
  }

  @override
  String ratingStarLabel(int star) {
    String _temp0 = intl.Intl.pluralLogic(
      star,
      locale: localeName,
      other: 'Valora amb $star estrelles',
      one: 'Valora amb $star estrella',
    );
    return '$_temp0';
  }

  @override
  String ratingStarValue(int star) {
    return '$star de 5';
  }

  @override
  String get ratingSaving => 'Desant la valoració';

  @override
  String get ratingSaveError =>
      'No hem pogut desar la valoració. Torna-ho a provar.';

  @override
  String get ratingEditError =>
      'No hem pogut modificar la valoració. Torna-ho a provar.';

  @override
  String get ratingDeleteError =>
      'No hem pogut eliminar la valoració. Torna-ho a provar.';

  @override
  String get ratingGone => 'La valoració ja no existeix.';

  @override
  String get agendaLoading => 'Carregant la teva agenda';

  @override
  String get agendaEmptyDay => 'No tens cap pla per a aquest dia.';

  @override
  String get agendaEmptyHint =>
      'Apunta’t a activitats des d’Inici i les veuràs aquí.';

  @override
  String get agendaLoadError =>
      'No hem pogut carregar la teva agenda. Torna-ho a provar.';

  @override
  String get attendanceQuestion => 'Com va anar?';

  @override
  String get attendanceHint =>
      'Digues-nos si hi vas anar. Només qui hi va anar pot valorar l’activitat.';

  @override
  String get attendanceYes => 'Sí, hi vaig anar';

  @override
  String get attendanceNo => 'No hi vaig anar';

  @override
  String get attendanceLater => 'Més tard';

  @override
  String get attendanceSaveError =>
      'No hem pogut desar la resposta. Torna-ho a provar.';

  @override
  String agendaPublishedBy(String name) {
    return 'Publicat per $name';
  }

  @override
  String get agendaSourceOfficial => 'Font: Agenda Cultural · Generalitat';

  @override
  String get agendaPreviousMonth => 'Mes anterior';

  @override
  String get agendaNextMonth => 'Mes següent';

  @override
  String get agendaDayToday => 'avui';

  @override
  String get agendaDayWithPlans => 'amb plans';

  @override
  String get agendaDayWithoutPlans => 'sense plans';

  @override
  String get actCloseFilter => 'Tancar el filtre';

  @override
  String get actUpdating => 'Actualitzant les activitats';

  @override
  String get actNoneAvailable => 'No hi ha activitats disponibles.';

  @override
  String get actLoadingZone => 'Carregant les activitats de la zona';

  @override
  String get actFilterDates => 'Dates';

  @override
  String get actFilterCategories => 'Categories';

  @override
  String get actClearAllFilters => 'Netejar tots els filtres';

  @override
  String get actCreate => 'Crear activitat';

  @override
  String get actDetailsTitle => 'Activitat';

  @override
  String get actEdit => 'Edita l’activitat';

  @override
  String get activityCancel => 'Cancel·lar l’activitat';

  @override
  String get activityCancelling => 'Cancel·lant…';

  @override
  String get activityCancelTitle => 'Vols cancel·lar l’activitat?';

  @override
  String activityCancelBody(String title) {
    return 'Avisarem les persones apuntades a «$title» i ja no s’hi podrà apuntar ningú. No es pot desfer.';
  }

  @override
  String get activityCancelKeep => 'Tornar';

  @override
  String get activityCancelConfirm => 'Cancel·la-la';

  @override
  String get activityCancelledBadge => 'Cancel·lada';

  @override
  String get activityCancelDone =>
      'Has cancel·lat l’activitat. Hem avisat les persones apuntades.';

  @override
  String get activityCancelFinished =>
      'L’activitat ja ha començat o ha acabat: no es pot cancel·lar.';

  @override
  String get activityCancelNotAllowed =>
      'Només qui ha creat l’activitat la pot cancel·lar.';

  @override
  String get activityCancelError =>
      'No hem pogut cancel·lar l’activitat. Torna-ho a provar.';

  @override
  String get actNotFound => 'No hem trobat aquesta activitat.';

  @override
  String get actAbout => 'Sobre l’activitat';

  @override
  String get actNoDescription => 'Encara no hi ha una descripció disponible.';

  @override
  String get actPracticalInfo => 'Informació pràctica';

  @override
  String get actOriginalLinkSoon => 'Enllaç original disponible properament';

  @override
  String get actOriginalLink => 'Consultar informació original';

  @override
  String get actChatNeedsEnrollment =>
      'Apunta’t a l’activitat per poder parlar al xat.';

  @override
  String get actChat => 'Xat de l’activitat';

  @override
  String get actChatHint =>
      'Parla amb les persones que també s’hi han apuntat.';

  @override
  String get chatEmpty =>
      'Encara no hi ha missatges. Saluda les persones que hi aniran!';

  @override
  String get chatLoadError =>
      'No hem pogut carregar els missatges. Torna-ho a provar.';

  @override
  String get chatNotEnrolled =>
      'Només les persones apuntades a l’activitat poden fer servir el xat.';

  @override
  String get chatOlder => 'Veure missatges anteriors';

  @override
  String get chatInputHint => 'Escriu un missatge';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSendError =>
      'No s’ha pogut enviar el missatge. Torna-ho a provar.';

  @override
  String get chatMessageTooLong =>
      'El missatge és massa llarg. Fes-lo més curt.';

  @override
  String get chatBackToActivity => 'Tornar a la fitxa';

  @override
  String get chatYou => 'Tu';

  @override
  String get actPublishedBy => 'Publicat per';

  @override
  String get actReliabilityNone =>
      'Fiabilitat de l’organitzador: sense valoracions';

  @override
  String actReliabilityOutOfFive(String value) {
    return 'Fiabilitat de l’organitzador: $value sobre 5';
  }

  @override
  String actReliabilityChip(String value) {
    return 'Fiabilitat $value';
  }

  @override
  String get actViewProfile => 'Veure perfil';

  @override
  String get actSearchTitle => 'Cerca';

  @override
  String get actSearchHint => 'Cerca activitats…';

  @override
  String get actSearchLabel => 'Cerca activitats';

  @override
  String get actClearSearch => 'Esborrar la cerca';

  @override
  String get actSegActivities => 'Activitats';

  @override
  String get actSegPeople => 'Persones';

  @override
  String get actSearchPromptTitle => 'Quina activitat busques?';

  @override
  String get actSearchPromptBody =>
      'Escriu el nom d’una activitat o un municipi.';

  @override
  String get actSearching => 'Cercant activitats';

  @override
  String actFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activitats trobades',
      one: '1 activitat trobada',
    );
    return '$_temp0';
  }

  @override
  String get actNoResultsTitle => 'No hem trobat activitats';

  @override
  String get actNoResultsBody => 'Prova amb altres paraules.';

  @override
  String get actMapLabel => 'Mapa d’activitats';

  @override
  String get actLegend => 'Llegenda';

  @override
  String get actLegendOfficial => 'Activitat de l’Agenda Cultural';

  @override
  String get actLegendCommunity => 'Publicada per un usuari';

  @override
  String get actLegendFriend => 'Publicada per una amistat';

  @override
  String get actLegendCluster =>
      'Diverses activitats a prop: toca per veure-les';

  @override
  String actWithoutLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activitats no tenen ubicació i només surten a la llista.',
      one: '1 activitat no té ubicació i només surt a la llista.',
    );
    return '$_temp0';
  }

  @override
  String get mapMyLocation => 'La meva ubicació';

  @override
  String get mapYouAreHere => 'On ets tu';

  @override
  String get mapLocateError => 'No hem pogut trobar on ets. Torna-ho a provar.';

  @override
  String get mapLocateDenied =>
      'Per veure on ets, cal que permetis que AProp! faci servir la teva ubicació.';

  @override
  String get mapLocateDeniedForever =>
      'Has denegat l’accés a la ubicació. Pots activar-lo a la configuració.';

  @override
  String get mapLocateSettings => 'Configuració';

  @override
  String get mapLocateBrowserDenied =>
      'El navegador no deixa veure on ets. Pots permetre-ho des de la icona del costat de l’adreça.';

  @override
  String get mapLocationDisabled =>
      'La ubicació del dispositiu està desactivada.';

  @override
  String get mapLocationEnable => 'Activar';

  @override
  String actInThisPlace(int count) {
    return '$count activitats en aquest lloc';
  }

  @override
  String actPublishedByName(String name) {
    return 'Publicat per $name';
  }

  @override
  String get actViewActivity => 'Veure activitat';

  @override
  String get actFriendBadge => 'Amiga';

  @override
  String get actCategoriesTitle => 'Categories';

  @override
  String get actCategoriesSubtitle => 'Pots triar més d’una categoria';

  @override
  String get categoriesAll => 'Totes les categories';

  @override
  String categoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories seleccionades',
      one: '1 categoria seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get actCategoriesLoading => 'Carregant categories';

  @override
  String get actCategoriesEmpty =>
      'No hi ha categories disponibles. Pots consultar totes les activitats.';

  @override
  String get actDatesTitle => 'Dates';

  @override
  String get actDatesSubtitle => 'Tria un dia o un interval';

  @override
  String get actPresetToday => 'Avui';

  @override
  String get actPresetTomorrow => 'Demà';

  @override
  String get actPresetWeekend => 'Aquest cap de setmana';

  @override
  String get actDayToday => 'avui';

  @override
  String get actClearFilters => 'Netejar filtres';

  @override
  String get actNoMatchLoaded =>
      'Cap coincidència entre les activitats carregades';

  @override
  String get actNoMatchFilters => 'No hi ha activitats amb aquests filtres';

  @override
  String get actTryOther => 'Prova unes altres dates o categories.';

  @override
  String get actNoMatchZone =>
      'No hi ha activitats amb aquests filtres en aquesta zona.';

  @override
  String actUncategorised(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count activitats sense categoria informada no s’inclouen en aquest filtre.',
      one:
          '1 activitat sense categoria informada no s’inclou en aquest filtre.',
    );
    return '$_temp0';
  }

  @override
  String get actClear => 'Netejar';

  @override
  String get actApply => 'Aplicar';

  @override
  String actLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activitats carregades',
      one: '1 activitat carregada',
    );
    return '$_temp0';
  }

  @override
  String get actLoadingMore => 'Carregant més activitats';

  @override
  String get actLoadMore => 'Carregar més activitats';

  @override
  String get enrollLeaving => 'Desapuntant…';

  @override
  String get enrollLeave => 'Desapunta’m';

  @override
  String get enrollSigningUp => 'Apuntant…';

  @override
  String get enrollLoading => 'Carregant…';

  @override
  String get enrollSignUp => 'M’hi apunto';

  @override
  String get enrollLeavingSemantics => 'Desapuntant-te de l’activitat';

  @override
  String get enrollSigningUpSemantics => 'Apuntant-te a l’activitat';

  @override
  String get enrollCheckingSemantics => 'Consultant els teus plans';

  @override
  String enrollLeaveTooltip(String title) {
    return 'Desapuntar-me de $title';
  }

  @override
  String get enrollRecheckTooltip => 'Tornar a consultar els teus plans';

  @override
  String enrollSignUpTooltip(String title) {
    return 'Apuntar-me a $title';
  }

  @override
  String get enrollHelperEnrolled => 'Aquest pla ja és a la teva agenda.';

  @override
  String get enrollHelperNot => 'Afegeix aquest pla a la teva agenda.';

  @override
  String enrollLeftSnack(String title) {
    return 'T’has desapuntat de «$title».';
  }

  @override
  String get enrollUndo => 'Desfer';

  @override
  String get enrollBadge => 'Apuntat';

  @override
  String get enrollLoadError =>
      'No hem pogut consultar els teus plans. Torna-ho a provar.';

  @override
  String get enrollSignUpError =>
      'No t’hi hem pogut apuntar. Torna-ho a provar.';

  @override
  String get enrollLeaveError =>
      'No t’hem pogut desapuntar. Torna-ho a provar.';

  @override
  String get pickerMapLabel => 'Mapa per marcar el lloc de l’activitat';

  @override
  String get pickerTapToAdjust => 'Toca per ajustar el punt';

  @override
  String get startSheetTitle => 'Data i hora d’inici';

  @override
  String get startSheetError => 'L’inici ha de ser posterior a ara.';

  @override
  String get endSheetTitle => 'Data i hora de fi';

  @override
  String get endSheetError => 'La fi ha de ser posterior a l’inici.';

  @override
  String get wheelDay => 'Dia';

  @override
  String get wheelMonth => 'Mes';

  @override
  String get wheelYear => 'Any';

  @override
  String get wheelTime => 'Hora';

  @override
  String get done => 'Fet';

  @override
  String get priceFree => 'Gratuït';

  @override
  String get actLoadCategoriesError => 'No hem pogut carregar les categories.';

  @override
  String get actLoadError =>
      'No hem pogut carregar les activitats. Torna-ho a provar.';

  @override
  String get actLoadMoreError =>
      'No hem pogut carregar més activitats. Torna-ho a provar.';

  @override
  String get actLoadZoneError =>
      'No hem pogut carregar les activitats d’aquesta zona. Torna-ho a provar.';

  @override
  String get actLoadDetailError =>
      'No hem pogut carregar l’activitat. Torna-ho a provar.';

  @override
  String get actSearchError =>
      'No hem pogut cercar les activitats. Torna-ho a provar.';

  @override
  String get discoverSearchField => 'Cerca activitats o persones';

  @override
  String get discoverLoading => 'Carregant propostes';

  @override
  String get discoverEmptyTitle => 'Encara no hi ha propostes';

  @override
  String get discoverEmptyBody =>
      'Pots cercar activitats o tornar-ho a provar més tard.';

  @override
  String get discoverForYou => 'Per a tu';

  @override
  String get discoverByInterests => 'Segons els teus interessos';

  @override
  String get discoverStarter => 'Una selecció per començar';

  @override
  String get discoverNoRecommendations => 'No hi ha recomanacions disponibles.';

  @override
  String get discoverRecommendationsAfterTest =>
      'Les recomanacions estaran disponibles quan hagis completat el test d’interessos.';

  @override
  String get discoverRecommendationsError =>
      'No hem pogut carregar les recomanacions.';

  @override
  String get discoverFeatured => 'Destacats';

  @override
  String get discoverNoFeatured => 'No hi ha activitats destacades.';

  @override
  String get discoverFeaturedError =>
      'No hem pogut carregar les activitats destacades.';

  @override
  String get discoverGetToKnowYou => 'Coneguem els teus gustos';

  @override
  String get discoverLoadError =>
      'No hem pogut carregar les propostes. Torna-ho a provar.';

  @override
  String get createLocationEmpty =>
      'Escriu el municipi o toca el mapa per marcar el lloc.';

  @override
  String get createLocationApproximate =>
      'Marcador al centre del municipi: toca el lloc exacte.';

  @override
  String get createLocationMarked =>
      'Lloc marcat. Pots tornar a tocar el mapa per canviar-lo.';

  @override
  String get createTitleEdit => 'Edita l’activitat';

  @override
  String get createTitleNew => 'Crea una activitat';

  @override
  String get createFieldTitle => 'Títol';

  @override
  String get createFieldDescription => 'Descripció';

  @override
  String get createFieldCategory => 'Categoria';

  @override
  String get createCategoriesLoading => 'Carregant les categories';

  @override
  String get createFieldStart => 'Data i hora d’inici';

  @override
  String get createPickStart => 'Tria la data i l’hora';

  @override
  String get createFieldEnd => 'Data i hora de fi (opcional)';

  @override
  String get createRemoveEnd => 'Treu la data de fi';

  @override
  String get createPickStartFirst => 'Tria primer l’inici';

  @override
  String get createNoEnd => 'Sense data de fi';

  @override
  String get createFieldMunicipality => 'Municipi (opcional)';

  @override
  String get createFieldDirections => 'Indicacions (opcional)';

  @override
  String get createDirectionsHint => 'Per exemple: entrada pel pati, 2n pis';

  @override
  String get createFieldPrice => 'Preu (opcional)';

  @override
  String get createPriceHelperUnknown =>
      'Si el deixes buit, no es canvia. Escriu 0 si és gratuïta.';

  @override
  String get createPriceHelper => 'Deixa-ho buit si és gratuïta.';

  @override
  String get createPublishing => 'Publicant';

  @override
  String get createSaveChanges => 'Desa els canvis';

  @override
  String get createPublish => 'Publica';

  @override
  String get createCoverSemantics => 'Imatge de portada. Canvia la imatge';

  @override
  String get createChangeImage => 'Canvia la imatge';

  @override
  String get createCoverTitle => 'Imatge de portada';

  @override
  String get createUploadSoonTooltip =>
      'Pujar fotos estarà disponible properament';

  @override
  String get createUploadSoon => 'Puja una foto (properament)';

  @override
  String get createOrPickOurs => 'O tria una de les nostres';

  @override
  String createImageOption(int number) {
    return 'Imatge $number';
  }

  @override
  String get createPublishError =>
      'No hem pogut publicar l’activitat. Torna-ho a provar.';

  @override
  String get createUpdateError =>
      'No hem pogut desar els canvis. Torna-ho a provar.';

  @override
  String get createCategoryRequired => 'Tria una categoria.';

  @override
  String get createPriceInvalid =>
      'Introdueix un preu vàlid, per exemple 12,50.';

  @override
  String get createTitleRequired => 'Introdueix el títol.';

  @override
  String createMaxChars(int max) {
    return 'Màxim $max caràcters.';
  }

  @override
  String get createDescriptionRequired => 'Introdueix una descripció.';

  @override
  String get createStartRequired => 'Tria la data i l’hora d’inici.';

  @override
  String get navHome => 'Inici';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navDiscover => 'Descobreix';

  @override
  String get navMap => 'Mapa';

  @override
  String get navNotifications => 'Avisos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get shareDialogBody => 'Comparteix el teu nom d’usuari d’AProp!';

  @override
  String get shareCancel => 'Cancel·lar';

  @override
  String get shareCopied => 'Nom d’usuari copiat';

  @override
  String get shareCopyError => 'No hem pogut copiar el nom d’usuari.';

  @override
  String get shareCopying => 'Copiant…';

  @override
  String get shareCopy => 'Copiar nom d’usuari';

  @override
  String get assistantOpenTooltip => 'Obrir l’assistent';

  @override
  String get apiTimeout =>
      'El servidor està despertant o triga massa a respondre. Torna-ho a provar.';

  @override
  String get apiNetwork => 'No s’ha pogut connectar amb el servidor.';

  @override
  String get createFieldCategories => 'Categories';

  @override
  String createCategoriesHint(int max) {
    return 'Tria’n fins a $max. La primera és la que es veu a les targetes.';
  }

  @override
  String createCategoriesMax(int max) {
    return 'Pots triar fins a $max categories.';
  }

  @override
  String get createScheduleNoteLabel => 'Més sobre l’horari (opcional)';

  @override
  String get createScheduleNoteHint =>
      'Per exemple: durada aproximada d’1 hora';

  @override
  String get createScheduleNoteHelper =>
      'L’hora d’inici i de fi ja s’hi afegeix sola.';

  @override
  String get createModality => 'Modalitat';

  @override
  String get createModalityBoth => 'Les dues';

  @override
  String get createOnlineUrlLabel => 'Enllaç per connectar-s’hi (opcional)';

  @override
  String get createOnlineUrlInvalid =>
      'Introdueix un enllaç que comenci per https://.';

  @override
  String get createPermanentHint => 'Per exemple, una exposició fixa.';

  @override
  String get actPermanent => 'Activitat permanent';

  @override
  String get modalityInPerson => 'Presencial';

  @override
  String get modalityOnline => 'En línia';

  @override
  String get modalityMixed => 'Presencial i en línia';

  @override
  String actUntil(String date) {
    return 'Fins al $date';
  }

  @override
  String get actLinks => 'Enllaços';

  @override
  String get actLinkJoin => 'Enllaç per connectar-s’hi';

  @override
  String get actLinkWebsite => 'Web de l’activitat';

  @override
  String get actLinkAccess => 'Informació d’accés';

  @override
  String actLinkCopy(String name) {
    return 'Copia l’enllaç: $name';
  }

  @override
  String get actLinkCopied => 'Enllaç copiat.';

  @override
  String get actLinkOpenError => 'No s’ha pogut obrir l’enllaç.';

  @override
  String actMoreCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories més',
      one: '1 categoria més',
    );
    return '$_temp0';
  }

  @override
  String get userSearchHint => 'Nom o nom d’usuari';

  @override
  String get userSearchLabel => 'Cerca persones';

  @override
  String get userSearchPromptTitle => 'A qui vols trobar?';

  @override
  String get userSearchPromptBody => 'Escriu un nom o un nom d’usuari.';

  @override
  String get userSearchSearching => 'Cercant persones';

  @override
  String get userSearchError =>
      'No hem pogut cercar persones. Torna-ho a provar.';

  @override
  String get userSearchNoResultsTitle => 'No hem trobat cap persona';

  @override
  String get userSearchNoResultsBody => 'Prova un altre nom o nom d’usuari.';

  @override
  String userSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones trobades',
      one: '1 persona trobada',
    );
    return '$_temp0';
  }

  @override
  String userSearchLoaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persones carregades',
      one: '1 persona carregada',
    );
    return '$_temp0';
  }

  @override
  String get userSearchLoadMore => 'Carregar més persones';

  @override
  String get userSearchMoreError =>
      'No hem pogut carregar més persones. Torna-ho a provar.';

  @override
  String userSearchTooLong(int limit) {
    return 'La cerca pot tenir com a màxim $limit caràcters.';
  }
}
