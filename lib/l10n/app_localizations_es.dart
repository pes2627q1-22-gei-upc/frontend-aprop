// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'AProp!';

  @override
  String get profileTitleFallback => 'Perfil';

  @override
  String get profilePeopleSearchSoon =>
      'Búsqueda de personas disponible próximamente';

  @override
  String get settingsTooltip => 'Configuración';

  @override
  String get profileLoading => 'Cargando el perfil';

  @override
  String get retry => 'Volver a intentarlo';

  @override
  String get profileTabCompletedPlans => 'Planes realizados';

  @override
  String get profileTabCreatedByMe => 'Creados por mí';

  @override
  String get profileCreatedLoading => 'Cargando las actividades creadas';

  @override
  String get profileNoCompletedPlans => 'Aún no tienes planes realizados';

  @override
  String get profileCompletedHistorySoon =>
      'Historial de asistencia disponible próximamente';

  @override
  String get profileNoCreated => 'Aún no has creado ninguna actividad';

  @override
  String get profileCompletedHint =>
      'Aquí verás las actividades con asistencia confirmada.';

  @override
  String get profileSavedPlansHint =>
      'Puedes consultar los planes guardados en la Agenda.';

  @override
  String get profileCreateHint => 'Puedes crear una desde Inicio.';

  @override
  String get profileLoadError =>
      'No hemos podido cargar el perfil. Vuelve a intentarlo.';

  @override
  String get profileCreatedLoadError =>
      'No hemos podido cargar las actividades creadas.';

  @override
  String get publicProfileLoadError => 'No hemos podido cargar el perfil.';

  @override
  String get publicProfileNotFound =>
      'Este perfil no existe o ya no está disponible.';

  @override
  String get publicProfileTabCreated => 'Creados';

  @override
  String get friendAdd => 'Añadir como amigo';

  @override
  String get friendSending => 'Enviando…';

  @override
  String get friendRequestSent => 'Solicitud enviada';

  @override
  String get friendAlready => 'Amigos';

  @override
  String get friendRequestError =>
      'No hemos podido enviar la solicitud. Vuelve a intentarlo.';

  @override
  String get friendRequestBlocked =>
      'No puedes enviar una solicitud de amistad a esta persona.';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsLoading => 'Cargando los amigos';

  @override
  String get friendsLoadError => 'No hemos podido cargar los amigos.';

  @override
  String get friendsEmptyOwn => 'Todavía no tienes amigos.';

  @override
  String friendsEmptyOther(String name) {
    return '$name todavía no tiene amigos.';
  }

  @override
  String get friendsOpenList => 'Ver los amigos';

  @override
  String get publicProfilePlansLoadError =>
      'No hemos podido cargar los planes.';

  @override
  String publicProfilePlansFriendsOnly(String name) {
    return 'Los planes de $name solo los pueden ver sus amigos.';
  }

  @override
  String publicProfilePlansHidden(String name) {
    return '$name no comparte sus planes.';
  }

  @override
  String publicProfileNoPlans(String name) {
    return '$name todavía no tiene planes hechos.';
  }

  @override
  String publicProfileNoCreated(String name) {
    return '$name todavía no ha creado ninguna actividad.';
  }

  @override
  String get profileBiographyTooLong =>
      'La biografía es demasiado larga. Prueba a acortarla.';

  @override
  String get profileMunicipalityTooLong => 'Escribe como máximo 80 caracteres.';

  @override
  String get profileNameRequired => 'Escribe tu nombre.';

  @override
  String get profileNameTooLong => 'El nombre es demasiado largo.';

  @override
  String get profileUsernameInvalid =>
      'Usa entre 3 y 30 letras, números o guiones bajos.';

  @override
  String get profileUsernameTaken =>
      'El nombre de usuario ya está en uso. Elige otro.';

  @override
  String get profileSaveError =>
      'No hemos podido guardar el perfil. Vuelve a intentarlo.';

  @override
  String get profileAvatarError =>
      'No hemos podido cambiar la foto. Vuelve a intentarlo.';

  @override
  String get profileAvatarInterrupted =>
      'Se ha interrumpido una selección de foto. Vuelve a elegirla.';

  @override
  String get avatarTooBig => 'Elige una foto de menos de 5 MB.';

  @override
  String get avatarNameUnreadable =>
      'No hemos podido leer el nombre de la foto.';

  @override
  String get avatarWrongFormat => 'Elige una foto JPG, PNG o WebP.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get close => 'Cerrar';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldUsername => 'Nombre de usuario';

  @override
  String get fieldBiography => 'Biografía';

  @override
  String get fieldMunicipality => 'Municipio';

  @override
  String get municipalityEditSoon =>
      'La edición del municipio estará disponible próximamente.';

  @override
  String get saving => 'Guardando…';

  @override
  String get save => 'Guardar';

  @override
  String profileActivityViewLabel(String title) {
    return 'Ver actividad: $title';
  }

  @override
  String profileActivityRatingSuffix(int rating) {
    return 'Valoración: $rating de 5';
  }

  @override
  String get statPlans => 'Planes';

  @override
  String get statFriends => 'Amigos';

  @override
  String get statRating => 'Valoración';

  @override
  String get reliabilityNone => 'Fiabilidad como organizador: sin valoraciones';

  @override
  String reliabilityOutOfFive(String value) {
    return 'Fiabilidad como organizador: $value sobre 5';
  }

  @override
  String get changing => 'Cambiando…';

  @override
  String get changePhoto => 'Cambiar foto';

  @override
  String get shareProfile => 'Compartir perfil';

  @override
  String get shareNeedsUsername =>
      'Hace falta un nombre de usuario para compartir el perfil';

  @override
  String get shareUsername => 'Compartir el nombre de usuario';

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
  String get xpMaxLevel => 'Has alcanzado el nivel máximo';

  @override
  String get xpStart => 'Tu recorrido cultural empieza aquí';

  @override
  String xpRemainingForLevel(int remaining, String level) {
    return '$remaining XP para $level';
  }

  @override
  String xpProgressSemantics(int xp) {
    return 'Progreso de experiencia: $xp XP';
  }

  @override
  String xpProgressOfSemantics(int xp, int target) {
    return 'Progreso de experiencia: $xp de $target XP';
  }

  @override
  String get levelStateCurrent => 'nivel actual';

  @override
  String get levelStateReached => 'alcanzado';

  @override
  String get levelStatePending => 'pendiente';

  @override
  String get levelCurious => 'Curioso/a';

  @override
  String get levelExplorer => 'Explorador/a';

  @override
  String get levelAdventurer => 'Aventurero/a';

  @override
  String get levelDiscoverer => 'Descubridor/a';

  @override
  String get levelAmbassador => 'Embajador/a';

  @override
  String levelCultural(String label) {
    return '$label cultural';
  }

  @override
  String get comingSoon => 'Disponible próximamente';

  @override
  String comingSoonTitled(String title) {
    return '$title: disponible próximamente';
  }

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get goBack => 'Volver atrás';

  @override
  String get settingsLoading => 'Cargando la configuración';

  @override
  String get settingsSavingChange => 'Guardando el cambio…';

  @override
  String get settingsGroupPreferences => 'PREFERENCIAS';

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
      'El idioma se ha cambiado, pero no lo hemos podido guardar en tu cuenta. Vuelve a intentarlo.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsDarkThemeSoon => 'Tema oscuro disponible próximamente';

  @override
  String get settingsGroupPrivacy => 'PRIVACIDAD';

  @override
  String get settingsShowMyPlans => 'Mostrar mis planes';

  @override
  String get settingsShowMyPlansHint => 'Tus amigos ven a qué te apuntas';

  @override
  String get settingsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get settingsGroupNotifications => 'NOTIFICACIONES';

  @override
  String get settingsReminders => 'Recordatorios';

  @override
  String get settingsRemindersHint => 'Avisos de los planes de tu agenda';

  @override
  String get settingsFriendActivity => 'Actividad de los amigos';

  @override
  String get settingsFriendActivityHint =>
      'Cuando un amigo se apunta a un plan';

  @override
  String get settingsRecommendations => 'Recomendaciones';

  @override
  String get settingsFriendRequests => 'Solicitudes de amistad';

  @override
  String get settingsPersistsAccount =>
      'Los cambios disponibles se guardan en tu cuenta.';

  @override
  String get settingsPersistsSession =>
      'Las preferencias se conservan durante esta sesión de la app.';

  @override
  String get settingsGroupAccount => 'CUENTA';

  @override
  String get settingsGoogleCalendar => 'Google Calendar';

  @override
  String get settingsGoogleCalendarHint =>
      'Exportación disponible próximamente';

  @override
  String get settingsNotConnected => 'No conectado';

  @override
  String get settingsRetakeInterestTest =>
      'Volver a hacer el test de intereses';

  @override
  String get settingsSigningOut => 'Cerrando sesión…';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsLoadError =>
      'No hemos podido cargar la configuración. Vuelve a intentarlo.';

  @override
  String get settingsSaveError =>
      'No hemos podido guardar el cambio. Vuelve a intentarlo.';

  @override
  String get settingsSignOutError =>
      'No hemos podido cerrar la sesión. Vuelve a intentarlo.';

  @override
  String authGreetingNamed(String name) {
    return '¡Hola, $name!';
  }

  @override
  String get authGreeting => '¡Hola!';

  @override
  String get authChooseUsernameTitle => 'Elige tu nombre de usuario';

  @override
  String authChooseUsernameBody(String greeting) {
    return '$greeting Elige el nombre con el que te encontrarán en la app.';
  }

  @override
  String authUsernameTaken(String username) {
    return 'El nombre «$username» ya es de otra persona. Elige otro.';
  }

  @override
  String get authUsernameLabel => 'Nombre de usuario';

  @override
  String get authUsernameHelper =>
      'Minúsculas, números, punto o guion bajo (3-20).';

  @override
  String get authContinue => 'Continuar';

  @override
  String get authNotYourAccount => '¿No es tu cuenta?';

  @override
  String get authSignOutLink => 'Cierra la sesión';

  @override
  String get authLoginTitle => 'Inicia sesión';

  @override
  String get authLoginSubtitle => 'Encuentra planes culturales cerca de ti.';

  @override
  String get authUsernameOrEmail => 'Nombre de usuario o correo';

  @override
  String get authPassword => 'Contraseña';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authNoAccount => '¿Aún no tienes cuenta?';

  @override
  String get authCreateAccountLink => 'Crea una cuenta';

  @override
  String get authRegisterIntro =>
      'Únete a AProp! para apuntarte a actividades y crear otras nuevas.';

  @override
  String get authFirstName => 'Nombre';

  @override
  String get authLastName => 'Apellidos';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authPasswordHelper =>
      'Mínimo 8 caracteres, con mayúscula, minúscula, número y carácter especial.';

  @override
  String get authRepeatPassword => 'Repite la contraseña';

  @override
  String get authCreateAccountButton => 'Crear la cuenta';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get authVerifyTitle => 'Verifica tu correo';

  @override
  String get authVerifySentTo => 'Te hemos enviado un enlace a';

  @override
  String get authVerifyOpenIt =>
      '. Ábrelo para activar la cuenta y después vuelve aquí.';

  @override
  String get authAlreadyVerified => 'Ya lo he verificado';

  @override
  String authResendEmailIn(int seconds) {
    return 'Volver a enviar el correo ($seconds s)';
  }

  @override
  String get authResendEmail => 'Volver a enviar el correo';

  @override
  String get authWrongEmail => '¿Te has equivocado de correo?';

  @override
  String get authUnexpectedError =>
      'No hemos podido completar la operación. Vuelve a intentarlo.';

  @override
  String get authInvalidCredentials =>
      'El usuario o la contraseña no son correctos.';

  @override
  String get authEmailInUse => 'Ya existe una cuenta con este correo.';

  @override
  String get authUsernameInUse =>
      'Este nombre de usuario ya está cogido. Prueba con otro.';

  @override
  String get authNetworkError =>
      'No hay conexión. Comprueba la red y vuelve a intentarlo.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos seguidos. Espera un poco y vuelve a intentarlo.';

  @override
  String get authEmailRequired =>
      'De momento solo puedes entrar con el correo electrónico.';

  @override
  String get authPopupBlocked =>
      'El navegador ha bloqueado la ventana de Google. Permite las ventanas emergentes y vuelve a intentarlo.';

  @override
  String get authEmailRequiredField => 'Escribe el correo.';

  @override
  String get authEmailInvalid => 'El correo no es válido.';

  @override
  String get forgotTitle => 'Recupera la contraseña';

  @override
  String get forgotLink => '¿Has olvidado la contraseña?';

  @override
  String get forgotIntro =>
      'Escribe el correo de tu cuenta y te enviaremos un enlace para elegir una nueva.';

  @override
  String get forgotEmailLabel => 'Correo';

  @override
  String get forgotSend => 'Envía el enlace';

  @override
  String forgotResendIn(int seconds) {
    return 'Vuelve a enviar el enlace ($seconds s)';
  }

  @override
  String get forgotResend => 'Vuelve a enviar el enlace';

  @override
  String get forgotRemember => '¿Ya la recuerdas?';

  @override
  String get forgotBackToLogin => 'Vuelve al inicio de sesión';

  @override
  String get forgotSent =>
      'Si hay una cuenta con este correo, te hemos enviado un enlace para elegir una contraseña nueva. Si no lo encuentras, mira la carpeta de spam.';

  @override
  String get authUsernameRequired => 'Escribe un nombre de usuario.';

  @override
  String get authUsernameRules =>
      'Entre 3 y 20 caracteres: minúsculas, números, punto o guion bajo.';

  @override
  String get authPasswordRequired => 'Escribe una contraseña.';

  @override
  String authPasswordMissingLength(int min) {
    return 'al menos $min caracteres';
  }

  @override
  String get authPasswordMissingUpper => 'una mayúscula';

  @override
  String get authPasswordMissingLower => 'una minúscula';

  @override
  String get authPasswordMissingDigit => 'un número';

  @override
  String get authPasswordMissingSpecial => 'un carácter especial';

  @override
  String authPasswordMustHave(String requirements) {
    return 'Debe tener $requirements.';
  }

  @override
  String authListAnd(String list, String last) {
    return '$list y $last';
  }

  @override
  String get authRepeatPasswordRequired => 'Repite la contraseña.';

  @override
  String get authPasswordsDiffer => 'Las contraseñas no coinciden.';

  @override
  String get authUsernameOrEmailRequired =>
      'Escribe el nombre de usuario o el correo.';

  @override
  String get authFirstNameRequired => 'Escribe el nombre.';

  @override
  String get authLastNameRequired => 'Escribe los apellidos.';

  @override
  String get authEmailNotVerified =>
      'Todavía no consta que hayas verificado el correo. Abre el enlace que te hemos enviado y vuelve a intentarlo.';

  @override
  String get authVerificationSent => 'Te hemos vuelto a enviar el correo.';

  @override
  String get loading => 'Cargando';

  @override
  String get authOr => 'o';

  @override
  String get authContinueWithGoogle => 'Continuar con Google';

  @override
  String get authShowPassword => 'Mostrar la contraseña';

  @override
  String get authHidePassword => 'Ocultar la contraseña';

  @override
  String get authLoginPasswordRequired => 'Escribe la contraseña.';

  @override
  String get assistantTitle => 'Asistente';

  @override
  String assistantAnnouncement(String text) {
    return 'Asistente: $text';
  }

  @override
  String assistantSuggestedQuestion(String text) {
    return 'Pregunta sugerida: $text';
  }

  @override
  String get assistantSearching => 'Buscando recomendaciones';

  @override
  String get assistantGoToLast => 'Ir al último mensaje';

  @override
  String get assistantWelcome =>
      '¡Hola! Soy el asistente de AProp!. Dime qué tipo de actividad buscas, en qué municipio y para qué fechas, y te propondré planes culturales.';

  @override
  String get assistantRateError =>
      'No hemos podido guardar la valoración. Vuelve a intentarlo.';

  @override
  String get assistantTooManyMessages =>
      'Demasiados mensajes, espera un minuto';

  @override
  String get assistantReplyError =>
      'No hemos podido obtener las recomendaciones del asistente. Vuelve a intentarlo.';

  @override
  String assistantViewActivity(String title) {
    return 'Ver actividad: $title';
  }

  @override
  String get assistantVoiceSoon => 'Entrada por voz disponible próximamente';

  @override
  String get assistantInputHint => 'Escribe una consulta…';

  @override
  String get assistantSend => 'Enviar';

  @override
  String assistantChipType(String value) {
    return 'Tipo: $value';
  }

  @override
  String assistantChipMunicipality(String value) {
    return 'Municipio: $value';
  }

  @override
  String assistantChipDates(String value) {
    return 'Fechas: $value';
  }

  @override
  String get assistantOpenHome => 'Abrir Inicio';

  @override
  String get assistantOpenAgenda => 'Abrir Agenda';

  @override
  String get assistantOpenDiscover => 'Abrir Descubre';

  @override
  String get assistantOpenNotifications => 'Abrir Avisos';

  @override
  String get assistantOpenProfile => 'Abrir Perfil';

  @override
  String get assistantOpenSettings => 'Abrir Configuración';

  @override
  String get assistantOpenInterestTest => 'Abrir el test de intereses';

  @override
  String get assistantHelpful => 'Respuesta útil';

  @override
  String get assistantNotHelpful => 'Respuesta poco útil';

  @override
  String get selected => 'Seleccionado';

  @override
  String get assistantYou => 'Tú';

  @override
  String monthName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'enero',
      '2': 'febrero',
      '3': 'marzo',
      '4': 'abril',
      '5': 'mayo',
      '6': 'junio',
      '7': 'julio',
      '8': 'agosto',
      '9': 'septiembre',
      '10': 'octubre',
      '11': 'noviembre',
      '12': 'diciembre',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String monthOf(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'de enero',
      '2': 'de febrero',
      '3': 'de marzo',
      '4': 'de abril',
      '5': 'de mayo',
      '6': 'de junio',
      '7': 'de julio',
      '8': 'de agosto',
      '9': 'de septiembre',
      '10': 'de octubre',
      '11': 'de noviembre',
      '12': 'de diciembre',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Lunes',
      '2': 'Martes',
      '3': 'Miércoles',
      '4': 'Jueves',
      '5': 'Viernes',
      '6': 'Sábado',
      '7': 'Domingo',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayAbbr(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'L',
      '2': 'M',
      '3': 'X',
      '4': 'J',
      '5': 'V',
      '6': 'S',
      '7': 'D',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String timeOfDay(String hour, String minute) {
    return '$hour:$minute h';
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
  String get dateUnknown => 'Fecha no informada';

  @override
  String get rangeAll => 'Todas las fechas';

  @override
  String rangeFromTo(String start, String end) {
    return 'Del $start al $end';
  }

  @override
  String rangeFromDayTo(int startDay, String start, String end) {
    return 'Del $startDay al $end';
  }

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get notifCategorySocial => 'Social';

  @override
  String get notifCategoryReminder => 'Recordatorio';

  @override
  String get notifCategoryRecommendation => 'Recomendación';

  @override
  String get notifCategoryNotice => 'Aviso';

  @override
  String get notifFilterAll => 'Todos';

  @override
  String get notifFilterReminders => 'Recordatorios';

  @override
  String get notifFilterRecommendations => 'Recomendaciones';

  @override
  String get notifMessageReminder => 'Tienes un recordatorio cultural.';

  @override
  String get notifMessageRecommendation => 'Tienes una recomendación cultural.';

  @override
  String notifMessageRecommendationFor(String title) {
    return '“$title” te puede interesar.';
  }

  @override
  String notifMessageSocialAbout(String title) {
    return 'Aviso social sobre “$title”.';
  }

  @override
  String notifMessageSocialPerson(String name) {
    return 'Tienes un aviso social relacionado con $name.';
  }

  @override
  String get notifMessageSocial => 'Tienes un nuevo aviso social.';

  @override
  String get notifMessageOther => 'Tienes un nuevo aviso.';

  @override
  String notifMessagePublished(String name, String title) {
    return '$name ha publicado “$title”.';
  }

  @override
  String notifMessageEnrolled(String name, String title) {
    return '$name se ha apuntado a “$title”.';
  }

  @override
  String notifMessageFriendRequest(String name) {
    return '$name te ha enviado una solicitud de amistad.';
  }

  @override
  String notifMessageFriendAccepted(String name) {
    return '$name ha aceptado tu solicitud de amistad.';
  }

  @override
  String get notifLoading => 'Cargando los avisos';

  @override
  String get notifEmptyAll => 'Aún no tienes ningún aviso';

  @override
  String get notifEmptySocial => 'Aún no tienes avisos sociales';

  @override
  String get notifEmptyReminders => 'Aún no has recibido ningún recordatorio';

  @override
  String get notifEmptyRecommendations => 'Aún no has recibido recomendaciones';

  @override
  String get notifEmptyRemindersHint =>
      'Los recordatorios que configures en la agenda aparecerán aquí cuando llegue la hora del aviso.';

  @override
  String get notifEmptySocialHint =>
      'Aquí encontrarás las solicitudes de amistad y las novedades de tus amigos.';

  @override
  String get notifEmptyRecommendationsHint =>
      'Aquí encontrarás avisos de actividades que te pueden interesar.';

  @override
  String get notifEmptyAllHint =>
      'Aquí encontrarás los avisos sociales, los recordatorios y las recomendaciones que recibas.';

  @override
  String get notifSeeAll => 'Ver todos los avisos';

  @override
  String get notifLoadError =>
      'No hemos podido cargar los avisos. Vuelve a intentarlo.';

  @override
  String get notifMarkReadError =>
      'No hemos podido marcar el aviso como leído. Vuelve a intentarlo.';

  @override
  String get notifRespondError =>
      'No hemos podido responder a la solicitud. Vuelve a intentarlo.';

  @override
  String get notifRead => 'Leído';

  @override
  String get notifUnread => 'Sin leer';

  @override
  String get notifHintProfileUnavailable =>
      'Marca el aviso como leído. El perfil aún no está disponible.';

  @override
  String get notifHintOpenActivity => 'Abre la actividad';

  @override
  String get notifHintOpenProfile => 'Abre el perfil';

  @override
  String get notifHintMarkRead => 'Marca el aviso como leído';

  @override
  String notifReceivedAt(String time) {
    return 'Recibido a las $time';
  }

  @override
  String get notifProfileSoon => 'Perfil disponible próximamente';

  @override
  String get notifActivityGone => 'La actividad ya no está disponible.';

  @override
  String get notifActivityLoadError =>
      'No se ha podido cargar la información de la actividad. Puedes probar a abrirla.';

  @override
  String get notifSendingResponse => 'Enviando la respuesta';

  @override
  String get notifAccept => 'Aceptar';

  @override
  String get notifDecline => 'Rechazar';

  @override
  String get notifRequestAccepted => 'Solicitud aceptada';

  @override
  String get notifRequestDeclined => 'Solicitud rechazada';

  @override
  String get interestTestTitle => 'Test de intereses';

  @override
  String get interestTestLoading => 'Cargando el test';

  @override
  String get interestTestEmpty =>
      'Ahora mismo no hay actividades para el test.';

  @override
  String get interestTestBack => 'Volver';

  @override
  String get interestTestDone =>
      'Hemos actualizado tus intereses. Las recomendaciones de «Para ti» los tendrán en cuenta.';

  @override
  String get interestTestBackToSettings => 'Volver a la configuración';

  @override
  String get interestTestSaving => 'Guardando las respuestas';

  @override
  String interestTestProgress(int current, int total) {
    return '$current de $total';
  }

  @override
  String get interestTestProgressSemantics => 'Progreso del test';

  @override
  String get interestTestSwipeHint =>
      'Desliza a la derecha si te interesa y a la izquierda si no.';

  @override
  String get interestTestLike => 'Me interesa';

  @override
  String get interestTestDislike => 'No me interesa';

  @override
  String get interestTestLoadError =>
      'No hemos podido cargar el test. Vuelve a intentarlo.';

  @override
  String get interestTestSaveError =>
      'No hemos podido guardar las respuestas. Vuelve a intentarlo.';

  @override
  String get interestTestSkip => 'Ahora no';

  @override
  String get interestTestContinue => 'Continuar';

  @override
  String get ratingDeleteTitle => '¿Eliminar la valoración?';

  @override
  String get ratingDeleteBody =>
      'Tu valoración se eliminará y podrás volver a valorar la actividad.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get ratingEdit => 'Modificar la valoración';

  @override
  String ratingOrganizerRated(String name) {
    return 'Ya has valorado a $name';
  }

  @override
  String ratingOrganizerAsk(String name) {
    return '¿Qué tal ha ido el organizador/a $name?';
  }

  @override
  String get ratingActivityRated => 'Ya has valorado esta actividad';

  @override
  String get ratingAsk => '¿Qué tal te ha ido?';

  @override
  String get ratingCancelEdit => 'Cancelar la modificación';

  @override
  String get ratingEditShort => 'Modificar';

  @override
  String get ratingDelete => 'Eliminar la valoración';

  @override
  String ratingScore(int score) {
    return 'Valoración: $score de 5';
  }

  @override
  String ratingStarLabel(int star) {
    String _temp0 = intl.Intl.pluralLogic(
      star,
      locale: localeName,
      other: 'Valora con $star estrellas',
      one: 'Valora con $star estrella',
    );
    return '$_temp0';
  }

  @override
  String ratingStarValue(int star) {
    return '$star de 5';
  }

  @override
  String get ratingSaving => 'Guardando la valoración';

  @override
  String get ratingSaveError =>
      'No hemos podido guardar la valoración. Vuelve a intentarlo.';

  @override
  String get ratingEditError =>
      'No hemos podido modificar la valoración. Vuelve a intentarlo.';

  @override
  String get ratingDeleteError =>
      'No hemos podido eliminar la valoración. Vuelve a intentarlo.';

  @override
  String get ratingGone => 'La valoración ya no existe.';

  @override
  String get agendaLoading => 'Cargando tu agenda';

  @override
  String get agendaEmptyDay => 'No tienes ningún plan para este día.';

  @override
  String get agendaEmptyHint =>
      'Apúntate a actividades desde Inicio y las verás aquí.';

  @override
  String get agendaLoadError =>
      'No hemos podido cargar tu agenda. Vuelve a intentarlo.';

  @override
  String agendaPublishedBy(String name) {
    return 'Publicado por $name';
  }

  @override
  String get agendaSourceOfficial => 'Fuente: Agenda Cultural · Generalitat';

  @override
  String get agendaPreviousMonth => 'Mes anterior';

  @override
  String get agendaNextMonth => 'Mes siguiente';

  @override
  String get agendaDayToday => 'hoy';

  @override
  String get agendaDayWithPlans => 'con planes';

  @override
  String get agendaDayWithoutPlans => 'sin planes';

  @override
  String get actCloseFilter => 'Cerrar el filtro';

  @override
  String get actUpdating => 'Actualizando las actividades';

  @override
  String get actNoneAvailable => 'No hay actividades disponibles.';

  @override
  String get actLoadingZone => 'Cargando las actividades de la zona';

  @override
  String get actFilterDates => 'Fechas';

  @override
  String get actFilterCategories => 'Categorías';

  @override
  String get actClearAllFilters => 'Limpiar todos los filtros';

  @override
  String get actCreate => 'Crear actividad';

  @override
  String get actDetailsTitle => 'Actividad';

  @override
  String get actEdit => 'Edita la actividad';

  @override
  String get actNotFound => 'No hemos encontrado esta actividad.';

  @override
  String get actAbout => 'Sobre la actividad';

  @override
  String get actNoDescription => 'Aún no hay una descripción disponible.';

  @override
  String get actPracticalInfo => 'Información práctica';

  @override
  String get actOriginalLinkSoon => 'Enlace original disponible próximamente';

  @override
  String get actOriginalLink => 'Consultar información original';

  @override
  String get actChatNeedsEnrollment =>
      'Apúntate a la actividad para poder hablar en el chat.';

  @override
  String get actChat => 'Chat de la actividad';

  @override
  String get actChatHint =>
      'Habla con las personas que también se han apuntado.';

  @override
  String get chatEmpty =>
      'Todavía no hay mensajes. ¡Saluda a las personas que irán!';

  @override
  String get chatLoadError =>
      'No hemos podido cargar los mensajes. Vuelve a intentarlo.';

  @override
  String get chatNotEnrolled =>
      'Solo las personas apuntadas a la actividad pueden usar el chat.';

  @override
  String get chatOlder => 'Ver mensajes anteriores';

  @override
  String get chatInputHint => 'Escribe un mensaje';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSendError =>
      'No se ha podido enviar el mensaje. Vuelve a intentarlo.';

  @override
  String get chatMessageTooLong =>
      'El mensaje es demasiado largo. Hazlo más corto.';

  @override
  String get chatBackToActivity => 'Volver a la ficha';

  @override
  String get chatYou => 'Tú';

  @override
  String get actPublishedBy => 'Publicado por';

  @override
  String get actReliabilityNone =>
      'Fiabilidad del organizador: sin valoraciones';

  @override
  String actReliabilityOutOfFive(String value) {
    return 'Fiabilidad del organizador: $value sobre 5';
  }

  @override
  String actReliabilityChip(String value) {
    return 'Fiabilidad $value';
  }

  @override
  String get actViewProfile => 'Ver perfil';

  @override
  String get actSearchTitle => 'Búsqueda';

  @override
  String get actSearchHint => 'Busca actividades…';

  @override
  String get actSearchLabel => 'Busca actividades';

  @override
  String get actClearSearch => 'Borrar la búsqueda';

  @override
  String get actSegActivities => 'Actividades';

  @override
  String get actSegPeople => 'Personas';

  @override
  String get actSearchPromptTitle => '¿Qué actividad buscas?';

  @override
  String get actSearchPromptBody =>
      'Escribe el nombre de una actividad o un municipio.';

  @override
  String get actSearching => 'Buscando actividades';

  @override
  String actFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades encontradas',
      one: '1 actividad encontrada',
    );
    return '$_temp0';
  }

  @override
  String get actNoResultsTitle => 'No hemos encontrado actividades';

  @override
  String get actNoResultsBody => 'Prueba con otras palabras.';

  @override
  String get actMapLabel => 'Mapa de actividades';

  @override
  String get actLegend => 'Leyenda';

  @override
  String get actLegendOfficial => 'Actividad de la Agenda Cultural';

  @override
  String get actLegendCommunity => 'Publicada por un usuario';

  @override
  String get actLegendFriend => 'Publicada por una amistad';

  @override
  String get actLegendCluster => 'Varias actividades cerca: toca para verlas';

  @override
  String actWithoutLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count actividades no tienen ubicación y solo aparecen en la lista.',
      one: '1 actividad no tiene ubicación y solo aparece en la lista.',
    );
    return '$_temp0';
  }

  @override
  String get mapMyLocation => 'Mi ubicación';

  @override
  String get mapYouAreHere => 'Dónde estás';

  @override
  String get mapLocateError =>
      'No hemos podido encontrar dónde estás. Vuelve a intentarlo.';

  @override
  String get mapLocateDenied =>
      'Para ver dónde estás, tienes que permitir que AProp! use tu ubicación.';

  @override
  String get mapLocateDeniedForever =>
      'Has denegado el acceso a la ubicación. Puedes activarlo en los ajustes.';

  @override
  String get mapLocateSettings => 'Ajustes';

  @override
  String get mapLocateBrowserDenied =>
      'El navegador no deja ver dónde estás. Puedes permitirlo desde el icono junto a la dirección.';

  @override
  String get mapLocationDisabled =>
      'La ubicación del dispositivo está desactivada.';

  @override
  String get mapLocationEnable => 'Activar';

  @override
  String actInThisPlace(int count) {
    return '$count actividades en este lugar';
  }

  @override
  String actPublishedByName(String name) {
    return 'Publicado por $name';
  }

  @override
  String get actViewActivity => 'Ver actividad';

  @override
  String get actFriendBadge => 'Amiga';

  @override
  String get actCategoriesTitle => 'Categorías';

  @override
  String get actCategoriesSubtitle => 'Puedes elegir más de una categoría';

  @override
  String get categoriesAll => 'Todas las categorías';

  @override
  String categoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías seleccionadas',
      one: '1 categoría seleccionada',
    );
    return '$_temp0';
  }

  @override
  String get actCategoriesLoading => 'Cargando categorías';

  @override
  String get actCategoriesEmpty =>
      'No hay categorías disponibles. Puedes consultar todas las actividades.';

  @override
  String get actDatesTitle => 'Fechas';

  @override
  String get actDatesSubtitle => 'Elige un día o un intervalo';

  @override
  String get actPresetToday => 'Hoy';

  @override
  String get actPresetTomorrow => 'Mañana';

  @override
  String get actPresetWeekend => 'Este fin de semana';

  @override
  String get actDayToday => 'hoy';

  @override
  String get actClearFilters => 'Limpiar filtros';

  @override
  String get actNoMatchLoaded =>
      'Ninguna coincidencia entre las actividades cargadas';

  @override
  String get actNoMatchFilters => 'No hay actividades con estos filtros';

  @override
  String get actTryOther => 'Prueba con otras fechas o categorías.';

  @override
  String get actNoMatchZone =>
      'No hay actividades con estos filtros en esta zona.';

  @override
  String actUncategorised(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count actividades sin categoría informada no se incluyen en este filtro.',
      one: '1 actividad sin categoría informada no se incluye en este filtro.',
    );
    return '$_temp0';
  }

  @override
  String get actClear => 'Limpiar';

  @override
  String get actApply => 'Aplicar';

  @override
  String actLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actividades cargadas',
      one: '1 actividad cargada',
    );
    return '$_temp0';
  }

  @override
  String get actLoadingMore => 'Cargando más actividades';

  @override
  String get actLoadMore => 'Cargar más actividades';

  @override
  String get enrollLeaving => 'Desapuntando…';

  @override
  String get enrollLeave => 'Desapúntame';

  @override
  String get enrollSigningUp => 'Apuntando…';

  @override
  String get enrollLoading => 'Cargando…';

  @override
  String get enrollSignUp => 'Me apunto';

  @override
  String get enrollLeavingSemantics => 'Desapuntándote de la actividad';

  @override
  String get enrollSigningUpSemantics => 'Apuntándote a la actividad';

  @override
  String get enrollCheckingSemantics => 'Consultando tus planes';

  @override
  String enrollLeaveTooltip(String title) {
    return 'Desapuntarme de $title';
  }

  @override
  String get enrollRecheckTooltip => 'Volver a consultar tus planes';

  @override
  String enrollSignUpTooltip(String title) {
    return 'Apuntarme a $title';
  }

  @override
  String get enrollHelperEnrolled => 'Este plan ya está en tu agenda.';

  @override
  String get enrollHelperNot => 'Añade este plan a tu agenda.';

  @override
  String enrollLeftSnack(String title) {
    return 'Te has desapuntado de «$title».';
  }

  @override
  String get enrollUndo => 'Deshacer';

  @override
  String get enrollBadge => 'Apuntado';

  @override
  String get enrollLoadError =>
      'No hemos podido consultar tus planes. Vuelve a intentarlo.';

  @override
  String get enrollSignUpError =>
      'No hemos podido apuntarte. Vuelve a intentarlo.';

  @override
  String get enrollLeaveError =>
      'No hemos podido desapuntarte. Vuelve a intentarlo.';

  @override
  String get pickerMapLabel => 'Mapa para marcar el lugar de la actividad';

  @override
  String get pickerTapToAdjust => 'Toca para ajustar el punto';

  @override
  String get startSheetTitle => 'Fecha y hora de inicio';

  @override
  String get startSheetError => 'El inicio debe ser posterior a ahora.';

  @override
  String get endSheetTitle => 'Fecha y hora de fin';

  @override
  String get endSheetError => 'El fin debe ser posterior al inicio.';

  @override
  String get wheelDay => 'Día';

  @override
  String get wheelMonth => 'Mes';

  @override
  String get wheelYear => 'Año';

  @override
  String get wheelTime => 'Hora';

  @override
  String get done => 'Hecho';

  @override
  String get priceFree => 'Gratis';

  @override
  String get actLoadCategoriesError => 'No hemos podido cargar las categorías.';

  @override
  String get actLoadError =>
      'No hemos podido cargar las actividades. Vuelve a intentarlo.';

  @override
  String get actLoadMoreError =>
      'No hemos podido cargar más actividades. Vuelve a intentarlo.';

  @override
  String get actLoadZoneError =>
      'No hemos podido cargar las actividades de esta zona. Vuelve a intentarlo.';

  @override
  String get actLoadDetailError =>
      'No hemos podido cargar la actividad. Vuelve a intentarlo.';

  @override
  String get actSearchError =>
      'No hemos podido buscar las actividades. Vuelve a intentarlo.';

  @override
  String get discoverSearchField => 'Busca actividades o personas';

  @override
  String get discoverLoading => 'Cargando propuestas';

  @override
  String get discoverEmptyTitle => 'Aún no hay propuestas';

  @override
  String get discoverEmptyBody =>
      'Puedes buscar actividades o volver a intentarlo más tarde.';

  @override
  String get discoverForYou => 'Para ti';

  @override
  String get discoverByInterests => 'Según tus intereses';

  @override
  String get discoverStarter => 'Una selección para empezar';

  @override
  String get discoverNoRecommendations => 'No hay recomendaciones disponibles.';

  @override
  String get discoverRecommendationsAfterTest =>
      'Las recomendaciones estarán disponibles cuando hayas completado el test de intereses.';

  @override
  String get discoverRecommendationsError =>
      'No hemos podido cargar las recomendaciones.';

  @override
  String get discoverFeatured => 'Destacadas';

  @override
  String get discoverNoFeatured => 'No hay actividades destacadas.';

  @override
  String get discoverFeaturedError =>
      'No hemos podido cargar las actividades destacadas.';

  @override
  String get discoverGetToKnowYou => 'Conozcamos tus gustos';

  @override
  String get discoverLoadError =>
      'No hemos podido cargar las propuestas. Vuelve a intentarlo.';

  @override
  String get createLocationEmpty =>
      'Escribe el municipio o toca el mapa para marcar el lugar.';

  @override
  String get createLocationApproximate =>
      'Marcador en el centro del municipio: toca el lugar exacto.';

  @override
  String get createLocationMarked =>
      'Lugar marcado. Puedes volver a tocar el mapa para cambiarlo.';

  @override
  String get createTitleEdit => 'Edita la actividad';

  @override
  String get createTitleNew => 'Crea una actividad';

  @override
  String get createFieldTitle => 'Título';

  @override
  String get createFieldDescription => 'Descripción';

  @override
  String get createFieldCategory => 'Categoría';

  @override
  String get createCategoriesLoading => 'Cargando las categorías';

  @override
  String get createFieldStart => 'Fecha y hora de inicio';

  @override
  String get createPickStart => 'Elige la fecha y la hora';

  @override
  String get createFieldEnd => 'Fecha y hora de fin (opcional)';

  @override
  String get createRemoveEnd => 'Quita la fecha de fin';

  @override
  String get createPickStartFirst => 'Elige primero el inicio';

  @override
  String get createNoEnd => 'Sin fecha de fin';

  @override
  String get createFieldMunicipality => 'Municipio (opcional)';

  @override
  String get createFieldDirections => 'Indicaciones (opcional)';

  @override
  String get createDirectionsHint =>
      'Por ejemplo: entrada por el patio, 2.º piso';

  @override
  String get createFieldPrice => 'Precio (opcional)';

  @override
  String get createPriceHelperUnknown =>
      'Si lo dejas vacío, no cambia. Escribe 0 si es gratuita.';

  @override
  String get createPriceHelper => 'Déjalo vacío si es gratuita.';

  @override
  String get createPublishing => 'Publicando';

  @override
  String get createSaveChanges => 'Guardar los cambios';

  @override
  String get createPublish => 'Publicar';

  @override
  String get createCoverSemantics => 'Imagen de portada. Cambia la imagen';

  @override
  String get createChangeImage => 'Cambia la imagen';

  @override
  String get createCoverTitle => 'Imagen de portada';

  @override
  String get createUploadSoonTooltip =>
      'Subir fotos estará disponible próximamente';

  @override
  String get createUploadSoon => 'Sube una foto (próximamente)';

  @override
  String get createOrPickOurs => 'O elige una de las nuestras';

  @override
  String createImageOption(int number) {
    return 'Imagen $number';
  }

  @override
  String get createPublishError =>
      'No hemos podido publicar la actividad. Vuelve a intentarlo.';

  @override
  String get createUpdateError =>
      'No hemos podido guardar los cambios. Vuelve a intentarlo.';

  @override
  String get createCategoryRequired => 'Elige una categoría.';

  @override
  String get createPriceInvalid =>
      'Escribe un precio válido, por ejemplo 12,50.';

  @override
  String get createTitleRequired => 'Escribe el título.';

  @override
  String createMaxChars(int max) {
    return 'Máximo $max caracteres.';
  }

  @override
  String get createDescriptionRequired => 'Escribe una descripción.';

  @override
  String get createStartRequired => 'Elige la fecha y la hora de inicio.';

  @override
  String get navHome => 'Inicio';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navDiscover => 'Descubre';

  @override
  String get navMap => 'Mapa';

  @override
  String get navNotifications => 'Avisos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get shareDialogBody => 'Comparte tu nombre de usuario de AProp!';

  @override
  String get shareCancel => 'Cancelar';

  @override
  String get shareCopied => 'Nombre de usuario copiado';

  @override
  String get shareCopyError => 'No hemos podido copiar el nombre de usuario.';

  @override
  String get shareCopying => 'Copiando…';

  @override
  String get shareCopy => 'Copiar nombre de usuario';

  @override
  String get assistantOpenTooltip => 'Abrir el asistente';

  @override
  String get apiTimeout =>
      'El servidor se está despertando o tarda demasiado en responder. Vuelve a intentarlo.';

  @override
  String get apiNetwork => 'No se ha podido conectar con el servidor.';

  @override
  String get createFieldCategories => 'Categorías';

  @override
  String createCategoriesHint(int max) {
    return 'Elige hasta $max. La primera es la que se ve en las tarjetas.';
  }

  @override
  String createCategoriesMax(int max) {
    return 'Puedes elegir hasta $max categorías.';
  }

  @override
  String get createScheduleNoteLabel => 'Más sobre el horario (opcional)';

  @override
  String get createScheduleNoteHint =>
      'Por ejemplo: duración aproximada de 1 hora';

  @override
  String get createScheduleNoteHelper =>
      'La hora de inicio y de fin ya se añade sola.';

  @override
  String get createModality => 'Modalidad';

  @override
  String get createModalityBoth => 'Las dos';

  @override
  String get createOnlineUrlLabel => 'Enlace para conectarse (opcional)';

  @override
  String get createOnlineUrlInvalid =>
      'Introduce un enlace que empiece por https://.';

  @override
  String get createPermanentHint => 'Por ejemplo, una exposición fija.';

  @override
  String get actPermanent => 'Actividad permanente';

  @override
  String get modalityInPerson => 'Presencial';

  @override
  String get modalityOnline => 'En línea';

  @override
  String get modalityMixed => 'Presencial y en línea';

  @override
  String actUntil(String date) {
    return 'Hasta el $date';
  }

  @override
  String get actLinks => 'Enlaces';

  @override
  String get actLinkJoin => 'Enlace para conectarse';

  @override
  String get actLinkWebsite => 'Web de la actividad';

  @override
  String get actLinkAccess => 'Información de acceso';

  @override
  String actLinkCopy(String name) {
    return 'Copiar el enlace: $name';
  }

  @override
  String get actLinkCopied => 'Enlace copiado.';

  @override
  String get actLinkOpenError => 'No se ha podido abrir el enlace.';

  @override
  String actMoreCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías más',
      one: '1 categoría más',
    );
    return '$_temp0';
  }

  @override
  String get userSearchHint => 'Nombre o nombre de usuario';

  @override
  String get userSearchLabel => 'Buscar personas';

  @override
  String get userSearchPromptTitle => '¿A quién quieres encontrar?';

  @override
  String get userSearchPromptBody =>
      'Escribe un nombre o un nombre de usuario.';

  @override
  String get userSearchSearching => 'Buscando personas';

  @override
  String get userSearchError =>
      'No hemos podido buscar personas. Vuelve a intentarlo.';

  @override
  String get userSearchNoResultsTitle => 'No hemos encontrado a nadie';

  @override
  String get userSearchNoResultsBody =>
      'Prueba otro nombre o nombre de usuario.';

  @override
  String userSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas encontradas',
      one: '1 persona encontrada',
    );
    return '$_temp0';
  }

  @override
  String userSearchLoaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas cargadas',
      one: '1 persona cargada',
    );
    return '$_temp0';
  }

  @override
  String get userSearchLoadMore => 'Cargar más personas';

  @override
  String get userSearchMoreError =>
      'No hemos podido cargar más personas. Vuelve a intentarlo.';

  @override
  String userSearchTooLong(int limit) {
    return 'La búsqueda puede tener como máximo $limit caracteres.';
  }
}
