// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AProp!';

  @override
  String get profileTitleFallback => 'Profile';

  @override
  String get profilePeopleSearchSoon => 'People search coming soon';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get profileLoading => 'Loading profile';

  @override
  String get retry => 'Try again';

  @override
  String get profileTabCompletedPlans => 'Plans done';

  @override
  String get profileTabCreatedByMe => 'Created by me';

  @override
  String get profileCreatedLoading => 'Loading created activities';

  @override
  String get profileNoCompletedPlans => 'You have no plans done yet';

  @override
  String get profileCompletedHistorySoon => 'Attendance history coming soon';

  @override
  String get profileNoCreated => 'You haven’t created any activity yet';

  @override
  String get profileCompletedHint =>
      'Here you’ll see the activities with confirmed attendance.';

  @override
  String get profileSavedPlansHint =>
      'You can check your saved plans in the Agenda.';

  @override
  String get profileCreateHint => 'You can create one from Home.';

  @override
  String get profileLoadError =>
      'We couldn’t load your profile. Please try again.';

  @override
  String get profileCreatedLoadError =>
      'We couldn’t load the activities you created.';

  @override
  String get publicProfileLoadError => 'We couldn’t load the profile.';

  @override
  String get publicProfileNotFound =>
      'This profile doesn’t exist or is no longer available.';

  @override
  String get publicProfileTabCreated => 'Created';

  @override
  String get friendAdd => 'Add friend';

  @override
  String get friendSending => 'Sending…';

  @override
  String get friendRequestSent => 'Request sent';

  @override
  String get friendAlready => 'Friend';

  @override
  String get friendRejecting => 'Declining…';

  @override
  String get friendRejectError => 'We couldn’t decline the request. Try again.';

  @override
  String get friendAccepting => 'Accepting…';

  @override
  String get friendAcceptError => 'We couldn’t accept the request. Try again.';

  @override
  String get friendStatusError =>
      'We couldn’t load friend requests. Try again.';

  @override
  String get friendRequestError =>
      'We couldn’t send the request. Please try again.';

  @override
  String get friendRequestBlocked =>
      'You can’t send a friend request to this person.';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsLoading => 'Loading friends';

  @override
  String get friendsLoadError => 'We couldn’t load the friends.';

  @override
  String get friendsEmptyOwn => 'You don’t have any friends yet.';

  @override
  String friendsEmptyOther(String name) {
    return '$name doesn’t have any friends yet.';
  }

  @override
  String get friendsOpenList => 'See friends';

  @override
  String get publicProfilePlansLoadError => 'We couldn’t load the plans.';

  @override
  String publicProfilePlansFriendsOnly(String name) {
    return 'Only $name’s friends can see their plans.';
  }

  @override
  String publicProfilePlansHidden(String name) {
    return '$name doesn’t share their plans.';
  }

  @override
  String publicProfileNoPlans(String name) {
    return '$name has no past plans yet.';
  }

  @override
  String publicProfileNoCreated(String name) {
    return '$name hasn’t created any activity yet.';
  }

  @override
  String get profileBiographyTooLong =>
      'Your bio is too long. Try making it shorter.';

  @override
  String get profileMunicipalityTooLong => 'Write 80 characters at most.';

  @override
  String get profileNameRequired => 'Write your name.';

  @override
  String get profileNameTooLong => 'The name is too long.';

  @override
  String get profileUsernameInvalid =>
      'Use 3 to 30 letters, numbers or underscores.';

  @override
  String get profileUsernameTaken =>
      'That username is already taken. Pick another one.';

  @override
  String get profileSaveError =>
      'We couldn’t save your profile. Please try again.';

  @override
  String get profileAvatarError =>
      'We couldn’t change your photo. Please try again.';

  @override
  String get profileAvatarInterrupted =>
      'A photo selection was interrupted. Please pick it again.';

  @override
  String get avatarTooBig => 'Pick a photo smaller than 5 MB.';

  @override
  String get avatarNameUnreadable => 'We couldn’t read the photo’s file name.';

  @override
  String get avatarWrongFormat => 'Pick a JPG, PNG or WebP photo.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get close => 'Close';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldBiography => 'Bio';

  @override
  String get fieldMunicipality => 'Municipality';

  @override
  String get municipalityEditSoon =>
      'Editing your municipality will be available soon.';

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String profileActivityViewLabel(String title) {
    return 'View activity: $title';
  }

  @override
  String profileActivityRatingSuffix(int rating) {
    return 'Rating: $rating out of 5';
  }

  @override
  String get statPlans => 'Plans';

  @override
  String get statFriends => 'Friends';

  @override
  String get statRating => 'Rating';

  @override
  String get reliabilityNone => 'Reliability as an organiser: no ratings yet';

  @override
  String reliabilityOutOfFive(String value) {
    return 'Reliability as an organiser: $value out of 5';
  }

  @override
  String get changing => 'Changing…';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get shareProfile => 'Share profile';

  @override
  String get shareNeedsUsername => 'You need a username to share your profile';

  @override
  String get shareUsername => 'Share your username';

  @override
  String photoOf(String name) {
    return 'Photo of $name';
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
  String get xpMaxLevel => 'You’ve reached the top level';

  @override
  String get xpStart => 'Your cultural journey starts here';

  @override
  String xpRemainingForLevel(int remaining, String level) {
    return '$remaining XP to $level';
  }

  @override
  String xpProgressSemantics(int xp) {
    return 'Experience progress: $xp XP';
  }

  @override
  String xpProgressOfSemantics(int xp, int target) {
    return 'Experience progress: $xp of $target XP';
  }

  @override
  String get levelStateCurrent => 'current level';

  @override
  String get levelStateReached => 'reached';

  @override
  String get levelStatePending => 'pending';

  @override
  String get levelCurious => 'Curious';

  @override
  String get levelExplorer => 'Explorer';

  @override
  String get levelAdventurer => 'Adventurer';

  @override
  String get levelDiscoverer => 'Discoverer';

  @override
  String get levelAmbassador => 'Ambassador';

  @override
  String levelCultural(String label) {
    return 'Cultural $label';
  }

  @override
  String get comingSoon => 'Coming soon';

  @override
  String comingSoonTitled(String title) {
    return '$title: coming soon';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get goBack => 'Go back';

  @override
  String get settingsLoading => 'Loading settings';

  @override
  String get settingsSavingChange => 'Saving the change…';

  @override
  String get settingsGroupPreferences => 'PREFERENCES';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageNameCa => 'Català';

  @override
  String get languageNameEs => 'Castellano';

  @override
  String get languageNameEn => 'English';

  @override
  String get settingsLanguageSyncError =>
      'The language was changed, but we couldn’t save it to your account. Please try again.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsDarkThemeSoon => 'Dark theme coming soon';

  @override
  String get settingsGroupPrivacy => 'PRIVACY';

  @override
  String get settingsShowMyPlans => 'Show my plans';

  @override
  String get settingsShowMyPlansHint => 'Friends can see what you sign up for';

  @override
  String get settingsBlockedUsers => 'Blocked users';

  @override
  String get settingsGroupNotifications => 'NOTIFICATIONS';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get settingsRemindersHint => 'Alerts for the plans in your agenda';

  @override
  String get settingsFriendActivity => 'Friends’ activity';

  @override
  String get settingsFriendActivityHint => 'When a friend signs up for a plan';

  @override
  String get settingsRecommendations => 'Recommendations';

  @override
  String get settingsFriendRequests => 'Friend requests';

  @override
  String get settingsPersistsAccount =>
      'Available changes are saved to your account.';

  @override
  String get settingsPersistsSession =>
      'Preferences are kept during this app session.';

  @override
  String get settingsGroupAccount => 'ACCOUNT';

  @override
  String get settingsGoogleCalendar => 'Google Calendar';

  @override
  String get settingsGoogleCalendarHint => 'Export coming soon';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsRetakeInterestTest => 'Retake the interests test';

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsLoadError =>
      'We couldn’t load your settings. Please try again.';

  @override
  String get settingsSaveError =>
      'We couldn’t save the change. Please try again.';

  @override
  String get settingsSignOutError =>
      'We couldn’t sign you out. Please try again.';

  @override
  String authGreetingNamed(String name) {
    return 'Hi, $name!';
  }

  @override
  String get authGreeting => 'Hi!';

  @override
  String get authChooseUsernameTitle => 'Choose your username';

  @override
  String authChooseUsernameBody(String greeting) {
    return '$greeting Pick the name people will find you by in the app.';
  }

  @override
  String authUsernameTaken(String username) {
    return 'The name “$username” already belongs to someone else. Pick another one.';
  }

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameHelper =>
      'Lowercase letters, numbers, dots or underscores (3-20).';

  @override
  String get authContinue => 'Continue';

  @override
  String get authNotYourAccount => 'Not your account?';

  @override
  String get authSignOutLink => 'Sign out';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle => 'Find cultural plans near you.';

  @override
  String get authUsernameOrEmail => 'Username or email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account yet?';

  @override
  String get authCreateAccountLink => 'Create an account';

  @override
  String get authRegisterIntro =>
      'Join AProp! to sign up for activities and create new ones.';

  @override
  String get authFirstName => 'First name';

  @override
  String get authLastName => 'Last name';

  @override
  String get authEmail => 'Email';

  @override
  String get authPasswordHelper =>
      'At least 8 characters, with an uppercase letter, a lowercase letter, a number and a special character.';

  @override
  String get authRepeatPassword => 'Repeat the password';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String get authVerifySentTo => 'We sent a link to';

  @override
  String get authVerifyOpenIt =>
      '. Open it to activate your account, then come back here.';

  @override
  String get authAlreadyVerified => 'I\'ve verified it';

  @override
  String authResendEmailIn(int seconds) {
    return 'Resend the email ($seconds s)';
  }

  @override
  String get authResendEmail => 'Resend the email';

  @override
  String get authWrongEmail => 'Wrong email address?';

  @override
  String get authUnexpectedError =>
      'We couldn\'t complete the operation. Please try again.';

  @override
  String get authInvalidCredentials => 'The username or password is incorrect.';

  @override
  String get authEmailInUse => 'An account with this email already exists.';

  @override
  String get authUsernameInUse =>
      'This username is already taken. Try another one.';

  @override
  String get authNetworkError =>
      'No connection. Check your network and try again.';

  @override
  String get authTooManyRequests =>
      'Too many attempts in a row. Wait a moment and try again.';

  @override
  String get authEmailRequired =>
      'For now you can only sign in with your email.';

  @override
  String get authPopupBlocked =>
      'The browser blocked the Google window. Allow pop-ups and try again.';

  @override
  String get authEmailRequiredField => 'Enter your email.';

  @override
  String get authEmailInvalid => 'The email isn\'t valid.';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotLink => 'Forgot your password?';

  @override
  String get forgotIntro =>
      'Enter your account email and we’ll send you a link to choose a new one.';

  @override
  String get forgotEmailLabel => 'Email';

  @override
  String get forgotSend => 'Send the link';

  @override
  String forgotResendIn(int seconds) {
    return 'Send the link again ($seconds s)';
  }

  @override
  String get forgotResend => 'Send the link again';

  @override
  String get forgotRemember => 'Remember it?';

  @override
  String get forgotBackToLogin => 'Back to sign in';

  @override
  String get forgotSent =>
      'If there is an account with this email, we’ve sent it a link to choose a new password. If you can’t find it, check your spam folder.';

  @override
  String get authUsernameRequired => 'Enter a username.';

  @override
  String get authUsernameRules =>
      '3 to 20 characters: lowercase letters, numbers, dots or underscores.';

  @override
  String get authPasswordRequired => 'Enter a password.';

  @override
  String authPasswordMissingLength(int min) {
    return 'at least $min characters';
  }

  @override
  String get authPasswordMissingUpper => 'an uppercase letter';

  @override
  String get authPasswordMissingLower => 'a lowercase letter';

  @override
  String get authPasswordMissingDigit => 'a number';

  @override
  String get authPasswordMissingSpecial => 'a special character';

  @override
  String authPasswordMustHave(String requirements) {
    return 'It must have $requirements.';
  }

  @override
  String authListAnd(String list, String last) {
    return '$list and $last';
  }

  @override
  String get authRepeatPasswordRequired => 'Repeat the password.';

  @override
  String get authPasswordsDiffer => 'The passwords don\'t match.';

  @override
  String get authUsernameOrEmailRequired => 'Enter your username or email.';

  @override
  String get authFirstNameRequired => 'Enter your first name.';

  @override
  String get authLastNameRequired => 'Enter your last name.';

  @override
  String get authEmailNotVerified =>
      'We can\'t see that you\'ve verified your email yet. Open the link we sent you and try again.';

  @override
  String get authVerificationSent => 'We\'ve sent the email again.';

  @override
  String get loading => 'Loading';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authLoginPasswordRequired => 'Enter your password.';

  @override
  String get assistantTitle => 'Assistant';

  @override
  String assistantAnnouncement(String text) {
    return 'Assistant: $text';
  }

  @override
  String assistantSuggestedQuestion(String text) {
    return 'Suggested question: $text';
  }

  @override
  String get assistantSearching => 'Looking for recommendations';

  @override
  String get assistantGoToLast => 'Go to the latest message';

  @override
  String get assistantWelcome =>
      'Hi! I’m the AProp! assistant. Tell me what kind of activity you’re after, in which town and for which dates, and I’ll suggest cultural plans.';

  @override
  String get assistantRateError =>
      'We couldn’t save your rating. Please try again.';

  @override
  String get assistantTooManyMessages => 'Too many messages, wait a minute';

  @override
  String get assistantReplyError =>
      'We couldn’t get the assistant’s recommendations. Please try again.';

  @override
  String assistantViewActivity(String title) {
    return 'View activity: $title';
  }

  @override
  String get assistantVoiceSoon => 'Voice input coming soon';

  @override
  String get assistantInputHint => 'Type a query…';

  @override
  String get assistantSend => 'Send';

  @override
  String assistantChipType(String value) {
    return 'Type: $value';
  }

  @override
  String assistantChipMunicipality(String value) {
    return 'Town: $value';
  }

  @override
  String assistantChipDates(String value) {
    return 'Dates: $value';
  }

  @override
  String get assistantOpenHome => 'Open Home';

  @override
  String get assistantOpenAgenda => 'Open Agenda';

  @override
  String get assistantOpenDiscover => 'Open Discover';

  @override
  String get assistantOpenNotifications => 'Open Alerts';

  @override
  String get assistantOpenProfile => 'Open Profile';

  @override
  String get assistantOpenSettings => 'Open Settings';

  @override
  String get assistantOpenInterestTest => 'Open the interests test';

  @override
  String get assistantHelpful => 'Helpful answer';

  @override
  String get assistantNotHelpful => 'Unhelpful answer';

  @override
  String get selected => 'Selected';

  @override
  String get assistantYou => 'You';

  @override
  String monthName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String monthOf(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayName(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'Monday',
      '2': 'Tuesday',
      '3': 'Wednesday',
      '4': 'Thursday',
      '5': 'Friday',
      '6': 'Saturday',
      '7': 'Sunday',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayAbbr(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'M',
      '2': 'T',
      '3': 'W',
      '4': 'T',
      '5': 'F',
      '6': 'S',
      '7': 'S',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String timeOfDay(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String dateLong(String weekday, int day, String monthOf, int year) {
    return '$weekday, $monthOf $day, $year';
  }

  @override
  String dateWithYear(int day, String monthOf, int year) {
    return '$monthOf $day, $year';
  }

  @override
  String dateNoYear(int day, String monthOf) {
    return '$monthOf $day';
  }

  @override
  String monthHeader(String month, int year) {
    return '$month $year';
  }

  @override
  String monthYear(String month, int year) {
    return '$month $year';
  }

  @override
  String weekdayDay(String weekday, int day, String monthOf) {
    return '$weekday, $monthOf $day';
  }

  @override
  String scheduleJoin(String day, String time) {
    return '$day · $time';
  }

  @override
  String get dateUnknown => 'Date not available';

  @override
  String get rangeAll => 'All dates';

  @override
  String rangeFromTo(String start, String end) {
    return '$start – $end';
  }

  @override
  String rangeFromDayTo(int startDay, String start, String end) {
    return '$start – $end';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get notifCategorySocial => 'Social';

  @override
  String get notifCategoryReminder => 'Reminder';

  @override
  String get notifCategoryRecommendation => 'Recommendation';

  @override
  String get notifCategoryNotice => 'Alert';

  @override
  String get notifFilterAll => 'All';

  @override
  String get notifFilterReminders => 'Reminders';

  @override
  String get notifFilterRecommendations => 'Recommendations';

  @override
  String get notifMessageReminder => 'You have a cultural reminder.';

  @override
  String get notifMessageRecommendation =>
      'You have a cultural recommendation.';

  @override
  String notifMessageRecommendationFor(String title) {
    return '“$title” might interest you.';
  }

  @override
  String notifMessageSocialAbout(String title) {
    return 'Social alert about “$title”.';
  }

  @override
  String notifMessageSocialPerson(String name) {
    return 'You have a social alert related to $name.';
  }

  @override
  String get notifMessageSocial => 'You have a new social alert.';

  @override
  String get notifMessageOther => 'You have a new alert.';

  @override
  String notifMessagePublished(String name, String title) {
    return '$name published “$title”.';
  }

  @override
  String notifMessageEnrolled(String name, String title) {
    return '$name signed up for “$title”.';
  }

  @override
  String notifMessageFriendRequest(String name) {
    return '$name sent you a friend request.';
  }

  @override
  String notifMessageFriendAccepted(String name) {
    return '$name accepted your friend request.';
  }

  @override
  String get notifLoading => 'Loading alerts';

  @override
  String get notifEmptyAll => 'You have no alerts yet';

  @override
  String get notifEmptySocial => 'You have no social alerts yet';

  @override
  String get notifEmptyReminders => 'You haven’t received any reminders yet';

  @override
  String get notifEmptyRecommendations =>
      'You haven’t received any recommendations yet';

  @override
  String get notifEmptyRemindersHint =>
      'Reminders you set in your agenda will show up here when it’s time.';

  @override
  String get notifEmptySocialHint =>
      'Here you’ll find friend requests and news from your friends.';

  @override
  String get notifEmptyRecommendationsHint =>
      'Here you’ll find alerts about activities you might like.';

  @override
  String get notifEmptyAllHint =>
      'Here you’ll find the social alerts, reminders and recommendations you receive.';

  @override
  String get notifSeeAll => 'See all alerts';

  @override
  String get notifLoadError =>
      'We couldn’t load your alerts. Please try again.';

  @override
  String get notifMarkReadError =>
      'We couldn’t mark the alert as read. Please try again.';

  @override
  String get notifRespondError =>
      'We couldn’t answer the request. Please try again.';

  @override
  String get notifRead => 'Read';

  @override
  String get notifUnread => 'Unread';

  @override
  String get notifHintProfileUnavailable =>
      'Marks the alert as read. The profile isn’t available yet.';

  @override
  String get notifHintOpenActivity => 'Opens the activity';

  @override
  String get notifHintOpenProfile => 'Opens the profile';

  @override
  String get notifHintMarkRead => 'Marks the alert as read';

  @override
  String notifReceivedAt(String time) {
    return 'Received at $time';
  }

  @override
  String get notifProfileSoon => 'Profile coming soon';

  @override
  String get notifActivityGone => 'The activity is no longer available.';

  @override
  String get notifActivityLoadError =>
      'We couldn’t load the activity’s details. You can try opening it.';

  @override
  String get notifSendingResponse => 'Sending your answer';

  @override
  String notifAcceptRequestFrom(String name) {
    return 'Accept the friend request from $name';
  }

  @override
  String notifDeclineRequestFrom(String name) {
    return 'Decline the friend request from $name';
  }

  @override
  String notifViewFriendProfile(String name) {
    return 'View the profile of $name';
  }

  @override
  String get notifAccept => 'Accept';

  @override
  String get notifDecline => 'Decline';

  @override
  String get notifRequestAccepted => 'Request accepted';

  @override
  String get notifRequestDeclined => 'Request declined';

  @override
  String get interestTestTitle => 'Interests test';

  @override
  String get interestTestLoading => 'Loading the test';

  @override
  String get interestTestEmpty =>
      'There are no activities for the test right now.';

  @override
  String get interestTestBack => 'Back';

  @override
  String get interestTestDone =>
      'We’ve updated your interests. The “For you” recommendations will take them into account.';

  @override
  String get interestTestBackToSettings => 'Back to settings';

  @override
  String get interestTestSaving => 'Saving your answers';

  @override
  String interestTestProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get interestTestProgressSemantics => 'Test progress';

  @override
  String get interestTestSwipeHint =>
      'Swipe right if you’re interested and left if you’re not.';

  @override
  String get interestTestLike => 'I’m interested';

  @override
  String get interestTestDislike => 'Not interested';

  @override
  String get interestTestLoadError =>
      'We couldn’t load the test. Please try again.';

  @override
  String get interestTestSaveError =>
      'We couldn’t save your answers. Please try again.';

  @override
  String get ratingDeleteTitle => 'Delete your rating?';

  @override
  String get ratingDeleteBody =>
      'Your rating will be deleted and you’ll be able to rate the activity again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ratingEdit => 'Edit your rating';

  @override
  String ratingOrganizerRated(String name) {
    return 'You’ve already rated $name';
  }

  @override
  String ratingOrganizerAsk(String name) {
    return 'How was the organiser $name?';
  }

  @override
  String get ratingActivityRated => 'You’ve already rated this activity';

  @override
  String get ratingAsk => 'How did it go?';

  @override
  String get ratingCancelEdit => 'Cancel the edit';

  @override
  String get ratingEditShort => 'Edit';

  @override
  String get ratingDelete => 'Delete your rating';

  @override
  String ratingScore(int score) {
    return 'Rating: $score out of 5';
  }

  @override
  String ratingStarLabel(int star) {
    String _temp0 = intl.Intl.pluralLogic(
      star,
      locale: localeName,
      other: 'Rate with $star stars',
      one: 'Rate with $star star',
    );
    return '$_temp0';
  }

  @override
  String ratingStarValue(int star) {
    return '$star out of 5';
  }

  @override
  String get ratingSaving => 'Saving your rating';

  @override
  String get ratingSaveError =>
      'We couldn’t save your rating. Please try again.';

  @override
  String get ratingEditError =>
      'We couldn’t edit your rating. Please try again.';

  @override
  String get ratingDeleteError =>
      'We couldn’t delete your rating. Please try again.';

  @override
  String get ratingGone => 'This rating no longer exists.';

  @override
  String get agendaLoading => 'Loading your agenda';

  @override
  String get agendaEmptyDay => 'You have no plans for this day.';

  @override
  String get agendaEmptyHint =>
      'Sign up for activities from Home and you’ll see them here.';

  @override
  String get agendaLoadError =>
      'We couldn’t load your agenda. Please try again.';

  @override
  String get attendanceQuestion => 'How did it go?';

  @override
  String get attendanceHint =>
      'Tell us whether you went. Only people who went can rate the activity.';

  @override
  String get attendanceYes => 'Yes, I went';

  @override
  String get attendanceNo => 'I didn’t go';

  @override
  String get attendanceLater => 'Later';

  @override
  String get attendanceSaveError =>
      'We couldn’t save your answer. Please try again.';

  @override
  String agendaPublishedBy(String name) {
    return 'Published by $name';
  }

  @override
  String get agendaSourceOfficial => 'Source: Agenda Cultural · Generalitat';

  @override
  String get agendaPreviousMonth => 'Previous month';

  @override
  String get agendaNextMonth => 'Next month';

  @override
  String get agendaDayToday => 'today';

  @override
  String get agendaDayWithPlans => 'with plans';

  @override
  String get agendaDayWithoutPlans => 'no plans';

  @override
  String get actCloseFilter => 'Close the filter';

  @override
  String get actUpdating => 'Updating activities';

  @override
  String get actNoneAvailable => 'No activities available.';

  @override
  String get actLoadingZone => 'Loading activities in this area';

  @override
  String get actFilterDates => 'Dates';

  @override
  String get actFilterCategories => 'Categories';

  @override
  String get actClearAllFilters => 'Clear all filters';

  @override
  String get actCreate => 'Create activity';

  @override
  String get actDetailsTitle => 'Activity';

  @override
  String get actEdit => 'Edit activity';

  @override
  String get activityCancel => 'Cancel the activity';

  @override
  String get activityCancelling => 'Cancelling…';

  @override
  String get activityCancelTitle => 'Cancel the activity?';

  @override
  String activityCancelBody(String title) {
    return 'We will tell the people signed up for «$title», and nobody else will be able to sign up. This can’t be undone.';
  }

  @override
  String get activityCancelKeep => 'Go back';

  @override
  String get activityCancelConfirm => 'Cancel it';

  @override
  String get activityCancelledBadge => 'Cancelled';

  @override
  String get activityCancelDone =>
      'You cancelled the activity. We told the people signed up.';

  @override
  String get activityCancelFinished =>
      'The activity has already started or finished: it can’t be cancelled.';

  @override
  String get activityCancelNotAllowed =>
      'Only the person who created the activity can cancel it.';

  @override
  String get activityCancelError =>
      'We couldn’t cancel the activity. Please try again.';

  @override
  String get actNotFound => 'We couldn’t find this activity.';

  @override
  String get actAbout => 'About the activity';

  @override
  String get actNoDescription => 'There’s no description available yet.';

  @override
  String get actPracticalInfo => 'Practical information';

  @override
  String get actOriginalLinkSoon => 'Original link coming soon';

  @override
  String get actOriginalLink => 'View original information';

  @override
  String get actChatNeedsEnrollment =>
      'Sign up for the activity to use its chat.';

  @override
  String get actChat => 'Activity chat';

  @override
  String get actChatHint => 'Talk to the people who have also signed up.';

  @override
  String get chatEmpty =>
      'No messages yet. Say hello to the people who are going!';

  @override
  String get chatLoadError => 'We couldn’t load the messages. Try again.';

  @override
  String get chatNotEnrolled =>
      'Only people signed up for the activity can use the chat.';

  @override
  String get chatOlder => 'See earlier messages';

  @override
  String get chatInputHint => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String get chatSendError => 'The message couldn’t be sent. Try again.';

  @override
  String get chatMessageTooLong => 'The message is too long. Make it shorter.';

  @override
  String get chatBackToActivity => 'Back to the activity';

  @override
  String get chatYou => 'You';

  @override
  String get actPublishedBy => 'Published by';

  @override
  String get actReliabilityNone => 'Organiser reliability: no ratings yet';

  @override
  String actReliabilityOutOfFive(String value) {
    return 'Organiser reliability: $value out of 5';
  }

  @override
  String actReliabilityChip(String value) {
    return 'Reliability $value';
  }

  @override
  String get actViewProfile => 'View profile';

  @override
  String get actSearchTitle => 'Search';

  @override
  String get actSearchHint => 'Search activities…';

  @override
  String get actSearchLabel => 'Search activities';

  @override
  String get actClearSearch => 'Clear search';

  @override
  String get actSegActivities => 'Activities';

  @override
  String get actSegPeople => 'People';

  @override
  String get actSearchPromptTitle => 'Which activity are you looking for?';

  @override
  String get actSearchPromptBody => 'Type the name of an activity or a town.';

  @override
  String get actSearching => 'Searching activities';

  @override
  String actFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities found',
      one: '1 activity found',
    );
    return '$_temp0';
  }

  @override
  String get actNoResultsTitle => 'We found no activities';

  @override
  String get actNoResultsBody => 'Try different words.';

  @override
  String get actMapLabel => 'Activities map';

  @override
  String get actLegend => 'Legend';

  @override
  String get actLegendOfficial => 'Activity from the Cultural Agenda';

  @override
  String get actLegendCommunity => 'Published by a user';

  @override
  String get actLegendFriend => 'Published by a friend';

  @override
  String get actLegendCluster => 'Several activities nearby: tap to see them';

  @override
  String actWithoutLocation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities have no location and only appear in the list.',
      one: '1 activity has no location and only appears in the list.',
    );
    return '$_temp0';
  }

  @override
  String get mapMyLocation => 'My location';

  @override
  String get mapYouAreHere => 'You are here';

  @override
  String get mapLocateError =>
      'We couldn’t find where you are. Please try again.';

  @override
  String get mapLocateDenied =>
      'To see where you are, allow AProp! to use your location.';

  @override
  String get mapLocateDeniedForever =>
      'You denied access to your location. You can turn it on in settings.';

  @override
  String get mapLocateSettings => 'Settings';

  @override
  String get mapLocateBrowserDenied =>
      'The browser doesn’t allow showing where you are. You can allow it from the icon next to the address.';

  @override
  String get mapLocationDisabled => 'Device location is turned off.';

  @override
  String get mapLocationEnable => 'Turn on';

  @override
  String actInThisPlace(int count) {
    return '$count activities in this place';
  }

  @override
  String actPublishedByName(String name) {
    return 'Published by $name';
  }

  @override
  String get actViewActivity => 'View activity';

  @override
  String get actFriendBadge => 'Friend';

  @override
  String get actCategoriesTitle => 'Categories';

  @override
  String get actCategoriesSubtitle => 'You can choose more than one category';

  @override
  String get categoriesAll => 'All categories';

  @override
  String categoriesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories selected',
      one: '1 category selected',
    );
    return '$_temp0';
  }

  @override
  String get actCategoriesLoading => 'Loading categories';

  @override
  String get actCategoriesEmpty =>
      'No categories available. You can browse all activities.';

  @override
  String get actDatesTitle => 'Dates';

  @override
  String get actDatesSubtitle => 'Pick a day or a range';

  @override
  String get actPresetToday => 'Today';

  @override
  String get actPresetTomorrow => 'Tomorrow';

  @override
  String get actPresetWeekend => 'This weekend';

  @override
  String get actDayToday => 'today';

  @override
  String get actClearFilters => 'Clear filters';

  @override
  String get actNoMatchLoaded => 'No matches among the loaded activities';

  @override
  String get actNoMatchFilters => 'No activities match these filters';

  @override
  String get actTryOther => 'Try other dates or categories.';

  @override
  String get actNoMatchZone =>
      'No activities match these filters in this area.';

  @override
  String actUncategorised(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count activities with no category are not included in this filter.',
      one: '1 activity with no category is not included in this filter.',
    );
    return '$_temp0';
  }

  @override
  String get actClear => 'Clear';

  @override
  String get actApply => 'Apply';

  @override
  String actLoadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities loaded',
      one: '1 activity loaded',
    );
    return '$_temp0';
  }

  @override
  String get actLoadingMore => 'Loading more activities';

  @override
  String get actLoadMore => 'Load more activities';

  @override
  String get enrollLeaving => 'Leaving…';

  @override
  String get enrollLeave => 'Leave';

  @override
  String get enrollSigningUp => 'Signing up…';

  @override
  String get enrollLoading => 'Loading…';

  @override
  String get enrollSignUp => 'I’m in';

  @override
  String get enrollLeavingSemantics => 'Leaving the activity';

  @override
  String get enrollSigningUpSemantics => 'Signing you up for the activity';

  @override
  String get enrollCheckingSemantics => 'Checking your plans';

  @override
  String enrollLeaveTooltip(String title) {
    return 'Leave $title';
  }

  @override
  String get enrollRecheckTooltip => 'Check your plans again';

  @override
  String enrollSignUpTooltip(String title) {
    return 'Sign up for $title';
  }

  @override
  String get enrollHelperEnrolled => 'This plan is already in your agenda.';

  @override
  String get enrollHelperNot => 'Add this plan to your agenda.';

  @override
  String enrollLeftSnack(String title) {
    return 'You left “$title”.';
  }

  @override
  String get enrollUndo => 'Undo';

  @override
  String get enrollBadge => 'Signed up';

  @override
  String get enrollLoadError =>
      'We couldn’t check your plans. Please try again.';

  @override
  String get enrollSignUpError => 'We couldn’t sign you up. Please try again.';

  @override
  String get enrollLeaveError => 'We couldn’t remove you. Please try again.';

  @override
  String get pickerMapLabel => 'Map to mark the activity’s location';

  @override
  String get pickerTapToAdjust => 'Tap to adjust the point';

  @override
  String get startSheetTitle => 'Start date and time';

  @override
  String get startSheetError => 'The start must be later than now.';

  @override
  String get endSheetTitle => 'End date and time';

  @override
  String get endSheetError => 'The end must be later than the start.';

  @override
  String get wheelDay => 'Day';

  @override
  String get wheelMonth => 'Month';

  @override
  String get wheelYear => 'Year';

  @override
  String get wheelTime => 'Time';

  @override
  String get done => 'Done';

  @override
  String get priceFree => 'Free';

  @override
  String get actLoadCategoriesError => 'We couldn’t load the categories.';

  @override
  String get actLoadError =>
      'We couldn’t load the activities. Please try again.';

  @override
  String get actLoadMoreError =>
      'We couldn’t load more activities. Please try again.';

  @override
  String get actLoadZoneError =>
      'We couldn’t load the activities in this area. Please try again.';

  @override
  String get actLoadDetailError =>
      'We couldn’t load the activity. Please try again.';

  @override
  String get actSearchError =>
      'We couldn’t search the activities. Please try again.';

  @override
  String get discoverSearchField => 'Search activities or people';

  @override
  String get discoverLoading => 'Loading suggestions';

  @override
  String get discoverEmptyTitle => 'No suggestions yet';

  @override
  String get discoverEmptyBody =>
      'You can search for activities or try again later.';

  @override
  String get discoverForYou => 'For you';

  @override
  String get discoverByInterests => 'Based on your interests';

  @override
  String get discoverStarter => 'A selection to get you started';

  @override
  String get discoverNoRecommendations => 'No recommendations available.';

  @override
  String get discoverRecommendationsAfterTest =>
      'Recommendations will be available once you’ve completed the interests test.';

  @override
  String get discoverRecommendationsError =>
      'We couldn’t load the recommendations.';

  @override
  String get discoverFeatured => 'Featured';

  @override
  String get discoverNoFeatured => 'No featured activities.';

  @override
  String get discoverFeaturedError =>
      'We couldn’t load the featured activities.';

  @override
  String get discoverGetToKnowYou => 'Let’s get to know your tastes';

  @override
  String get discoverLoadError =>
      'We couldn’t load the suggestions. Please try again.';

  @override
  String get createLocationEmpty =>
      'Type the town or tap the map to mark the place.';

  @override
  String get createLocationApproximate =>
      'Marker at the centre of the town: tap the exact spot.';

  @override
  String get createLocationMarked =>
      'Place marked. You can tap the map again to change it.';

  @override
  String get createTitleEdit => 'Edit activity';

  @override
  String get createTitleNew => 'Create an activity';

  @override
  String get createFieldTitle => 'Title';

  @override
  String get createFieldDescription => 'Description';

  @override
  String get createFieldCategory => 'Category';

  @override
  String get createCategoriesLoading => 'Loading categories';

  @override
  String get createFieldStart => 'Start date and time';

  @override
  String get createPickStart => 'Pick the date and time';

  @override
  String get createFieldEnd => 'End date and time (optional)';

  @override
  String get createRemoveEnd => 'Remove the end date';

  @override
  String get createPickStartFirst => 'Pick the start first';

  @override
  String get createNoEnd => 'No end date';

  @override
  String get createFieldMunicipality => 'Town (optional)';

  @override
  String get createFieldDirections => 'Directions (optional)';

  @override
  String get createDirectionsHint =>
      'For example: entrance through the courtyard, 2nd floor';

  @override
  String get createFieldPrice => 'Price (optional)';

  @override
  String get createPriceHelperUnknown =>
      'If you leave it empty, it won’t change. Enter 0 if it’s free.';

  @override
  String get createPriceHelper => 'Leave it empty if it’s free.';

  @override
  String get createPublishing => 'Publishing';

  @override
  String get createSaveChanges => 'Save changes';

  @override
  String get createPublish => 'Publish';

  @override
  String get createCoverSemantics => 'Cover image. Change the image';

  @override
  String get createChangeImage => 'Change the image';

  @override
  String get createCoverTitle => 'Cover image';

  @override
  String get createUploadSoonTooltip =>
      'Uploading photos will be available soon';

  @override
  String get createUploadSoon => 'Upload a photo (coming soon)';

  @override
  String get createOrPickOurs => 'Or pick one of ours';

  @override
  String createImageOption(int number) {
    return 'Image $number';
  }

  @override
  String get createPublishError =>
      'We couldn’t publish the activity. Please try again.';

  @override
  String get createUpdateError =>
      'We couldn’t save the changes. Please try again.';

  @override
  String get createCategoryRequired => 'Pick a category.';

  @override
  String get createPriceInvalid => 'Enter a valid price, for example 12.50.';

  @override
  String get createTitleRequired => 'Enter a title.';

  @override
  String createMaxChars(int max) {
    return '$max characters at most.';
  }

  @override
  String get createDescriptionRequired => 'Enter a description.';

  @override
  String get createStartRequired => 'Pick the start date and time.';

  @override
  String get navHome => 'Home';

  @override
  String get navAgenda => 'Agenda';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMap => 'Map';

  @override
  String get navNotifications => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get shareDialogBody => 'Share your AProp! username';

  @override
  String get shareCancel => 'Cancel';

  @override
  String get shareCopied => 'Username copied';

  @override
  String get shareCopyError => 'We couldn’t copy the username.';

  @override
  String get shareCopying => 'Copying…';

  @override
  String get shareCopy => 'Copy username';

  @override
  String get assistantOpenTooltip => 'Open the assistant';

  @override
  String get apiTimeout =>
      'The server is waking up or taking too long to respond. Please try again.';

  @override
  String get apiNetwork => 'We couldn’t connect to the server.';

  @override
  String get createFieldCategories => 'Categories';

  @override
  String createCategoriesHint(int max) {
    return 'Choose up to $max. The first one is shown on the cards.';
  }

  @override
  String createCategoriesMax(int max) {
    return 'You can choose up to $max categories.';
  }

  @override
  String get createScheduleNoteLabel => 'More about the schedule (optional)';

  @override
  String get createScheduleNoteHint => 'For example: about 1 hour long';

  @override
  String get createScheduleNoteHelper =>
      'The start and end times are added automatically.';

  @override
  String get createModality => 'Format';

  @override
  String get createModalityBoth => 'Both';

  @override
  String get createOnlineUrlLabel => 'Link to join (optional)';

  @override
  String get createOnlineUrlInvalid =>
      'Enter a link that starts with https://.';

  @override
  String get createPermanentHint => 'For example, a permanent exhibition.';

  @override
  String get actPermanent => 'Permanent activity';

  @override
  String get modalityInPerson => 'In person';

  @override
  String get modalityOnline => 'Online';

  @override
  String get modalityMixed => 'In person and online';

  @override
  String actUntil(String date) {
    return 'Until $date';
  }

  @override
  String get actLinks => 'Links';

  @override
  String get actLinkJoin => 'Link to join';

  @override
  String get actLinkWebsite => 'Activity website';

  @override
  String get actLinkAccess => 'Access information';

  @override
  String actLinkCopy(String name) {
    return 'Copy link: $name';
  }

  @override
  String get actLinkCopied => 'Link copied.';

  @override
  String get actLinkOpenError => 'The link could not be opened.';

  @override
  String actMoreCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more categories',
      one: '1 more category',
    );
    return '$_temp0';
  }

  @override
  String get userSearchHint => 'Name or username';

  @override
  String get userSearchLabel => 'Search people';

  @override
  String get userSearchPromptTitle => 'Who are you looking for?';

  @override
  String get userSearchPromptBody => 'Enter a name or username.';

  @override
  String get userSearchSearching => 'Searching people';

  @override
  String get userSearchError => 'We couldn’t search for people. Try again.';

  @override
  String get userSearchNoResultsTitle => 'No people found';

  @override
  String get userSearchNoResultsBody => 'Try another name or username.';

  @override
  String userSearchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people found',
      one: '1 person found',
    );
    return '$_temp0';
  }

  @override
  String userSearchLoaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people loaded',
      one: '1 person loaded',
    );
    return '$_temp0';
  }

  @override
  String get userSearchLoadMore => 'Load more people';

  @override
  String get userSearchMoreError => 'We couldn’t load more people. Try again.';

  @override
  String userSearchTooLong(int limit) {
    return 'Search can contain up to $limit characters.';
  }
}
