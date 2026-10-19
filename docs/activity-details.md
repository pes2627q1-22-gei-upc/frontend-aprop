# Event details — Taiga #75

## Implemented behavior

Tapping an event image or title opens the matching event by its stable ID. The screen shows its image, category, title, complete date and time, municipality and description. Official events identify the Agenda Cultural as their data source; community events identify the creator and, when applicable, friendship. The date formatter is shared with list cards; it formats the supplied `DateTime` without guessing an API time zone. Since #82, the enrollment action is separate from navigation and shares its state with the list.

Loading, repository failure with retry, missing events, unavailable descriptions and image-load failure have separate UI states. A response received after the ViewModel is disposed cannot update the closed screen. Repeated requests while loading are ignored.

The approved Inception 2 flow keeps bottom navigation visible. Each section therefore has its own nested Navigator inside MainShell's IndexedStack. Opening details pushes onto the active section; the back arrow and Android back action pop that route. Switching tabs preserves their stacks. Returning to a list preserves its scroll position.

## File and execution order

1. `features/activities/models/activity.dart`: optional description belongs to the activity data. It contains no Flutter code.
2. `features/activities/repositories/activity_repository.dart`: the contract adds `Future<Activity?> getActivityById(String id)`. Null means not found; exceptions represent request failures.
3. `features/activities/data/demo_activity_repository.dart`: resolves IDs using the same demo catalogue used by the list. Descriptions are fictional demo content; jazz and theatre reuse the approved mockup text.
4. `features/activities/presentation/view_models/activity_details_view_model.dart`: loads data, owns loading/error/result state and notifies listeners. It knows neither widgets nor navigation.
5. `features/activities/presentation/formatters/activity_date_formatter.dart` and `widgets/activity_information_row.dart`: shared presentation utilities used by list and details.
6. `features/activities/presentation/screens/activity_details_screen.dart`: owns its ViewModel lifecycle and renders the current state. Its internal content, creator, participation and message widgets stay private to this screen.
7. `app/navigation/activity_details_route.dart`: constructs a route from an activity ID, catalogue repository and shared enrollment ViewModel. Routing belongs to app composition, not to the feature widgets.
8. `ActivityCard` calls `onTap`; `ActivitiesScreen` forwards `onActivitySelected(activity.id)`; MainShell pushes the shared detail route with the existing repository.

```text
Card tap
  -> ActivitiesScreen.onActivitySelected(activity.id)
  -> MainShell._openActivityDetails(id)
  -> activityDetailsRoute(id, repository, enrollmentViewModel)
  -> ActivityDetailsScreen.initState()
  -> ActivityDetailsViewModel.load()
  -> ActivityRepository.getActivityById(id)
  -> DemoActivityRepository
  -> ViewModel result + notifyListeners()
  -> ListenableBuilder renders the event
```

## Calendar integration contract

The calendar feature should accept a callback with this type:

```dart
final ValueChanged<String> onActivitySelected;
```

On the event image/title, call:

```dart
onTap: () => onActivitySelected(activity.id)
```

When the calendar screen exists, wire it in MainShell's section 1 root:

```dart
// Wiring example only: AgendaScreen is implemented by the calendar teammate.
AgendaScreen(onActivitySelected: _openActivityDetails)
```

Agenda must not import MainShell, the detail screen, the detail ViewModel or the demo repository. App composition supplies the callback. The ID must be a real catalogue ID; do not derive it from the title or date.

The route can also be used directly by app-level navigation code:

```dart
navigator.push<void>(
  activityDetailsRoute(
    activityId: id,
    repository: sharedActivityRepository,
    enrollmentViewModel: sharedEnrollmentViewModel,
  ),
);
```

No prior call to `getActivities()` is needed to open an event. Any future backend implementation or test fake implementing `ActivityRepository` must implement both repository methods.

## Scope boundaries

Enrollment was outside #75 and is now implemented by #82 through the shared repository and ViewModel; see `event-enrollment.md`. Unenrollment, attendance, chat, profiles and original-source URL opening remain outside this change. Their existing unavailable controls stay disabled. No enrollment state is stored locally in the detail widget. The agenda remains the calendar teammate's responsibility.

The backend repository will replace the demo implementation when its actual API contract is available; this change does not invent endpoints or credentials. Demo dates intentionally match the approved September 2026 mockups rather than claiming to be current live events.

## Validation

The feature tests cover detail lookup without a list, loading, missing IDs, retry after error, duplicate request prevention, disposal during a request, both event sources, absent descriptions/images, enlarged text and fixed participation placement. App tests cover persistent bottom navigation, independent tab history, Android back and list scroll restoration. Existing authentication tests remain part of the full suite.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Manual check: sign in with the documented demo account, tap Jazz al parc or Teatre sota les estrelles, scroll the detail, switch tabs, return and press back. Enrollment can now be tested using the #82 guide. The implementation still needs peer review and backend integration before it represents a connected production feature.
