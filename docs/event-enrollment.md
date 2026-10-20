# Event enrollment — Taiga #82

## Behavior and scope

The signed-in user can express an intention to attend from a list card or the event detail. The action stays on the current screen. Both surfaces show the same confirmed state:

| State | Label | Interaction |
| --- | --- | --- |
| Reading plans | Carregant… | Disabled until the initial snapshot arrives |
| Not enrolled | M’hi apunto | Outlined in the list, filled in details |
| Waiting for confirmation | Apuntant… | Spinner; repeated taps ignored |
| Confirmed | Apuntat + check icon | Soft green outlined status in both places |
| Write failure | M’hi apunto + inline error | Retry without leaving the screen |
| Read failure | Tornar-ho a provar + inline error | Reload plans before allowing a new write |

Confirmed status does not cancel enrollment when tapped. Unenrollment is a separate story. Attendance remains unknown; this operation is neither a purchase nor a reservation. Chat, reminders and the calendar screen are not implemented by #82.

The demo repository stores IDs per account in memory. Plans survive tab changes, detail navigation and sign-out/sign-in during the same run. They do not survive restarting the application. There is no invented HTTP request, backend DTO or production persistence. DP-010 tracks the API and Calendar integration agreement.

## Read the implementation in this order

### 1. Define the data contract

`lib/features/activities/repositories/enrollment_repository.dart` is independent of Flutter:

```dart
abstract interface class EnrollmentRepository {
  Stream<Set<String>> watchEnrolledActivityIds(String userId);
  Future<void> enroll({required String userId, required String activityId});
}
```

`Future<void>` completes when a write is confirmed or throws when it fails. `Stream<Set<String>>` delivers the initial set of enrolled activity IDs and later changes. A set naturally represents membership without duplicates; snapshots are immutable so callers cannot mutate repository state.

The interface describes what a repository promises, not how it stores data. A constructor parameter typed `EnrollmentRepository` receives an actual instance of a class that implements the contract.

### 2. Implement the temporary data source

`lib/features/activities/data/demo_enrollment_repository.dart` implements that interface. Its map associates each user ID with a set of activity IDs. Before adding an ID it looks up the activity through `ActivityRepository`; unknown activities fail rather than creating invalid plans.

`ids.add(activityId)` returns false if the user already has the ID. Only a new enrollment emits a change. Independent subscribers receive snapshots for their own user; this is what lets the future Calendar ViewModel consume the same confirmed data without copying list state.

### 3. Coordinate the action in the ViewModel

`lib/features/activities/presentation/view_models/enrollment_view_model.dart` owns presentation state for one account. It exposes confirmed IDs, pending IDs, read errors and per-activity write errors. It receives the interface through its constructor:

```dart
EnrollmentViewModel({required this.userId, required this._repository});
```

In Dart 3.13 this private initializing parameter is called with the public name `repository:`. The value is the concrete injected object, not an instance of the interface itself.

When `enroll(activityId)` runs, it first guards against an unknown initial state, read failure, an existing enrollment or an already pending request. Then it:

1. Adds the ID to the pending set, clears its old error and calls `notifyListeners()`.
2. Calls `await _repository.enroll(userId: userId, activityId: activityId)`.
3. After confirmation, records the confirmed ID; a failure records a Catalan error instead.
4. Removes the pending flag and notifies listeners again.

The repository stream also updates confirmed snapshots. The ViewModel makes no network requests itself and receives no `BuildContext`. Its disposal guard and subscription version prevent late callbacks from updating a closed screen. A failed refresh retains already confirmed plans.

### 4. Build one reusable action widget

`lib/features/activities/presentation/widgets/enrollment_action.dart` receives the shared ViewModel, activity ID and title. Its `ListenableBuilder` listens to `notifyListeners()` and rebuilds the button/error/helper from the current state:

```dart
ListenableBuilder(
  listenable: viewModel,
  builder: (context, child) {
    // Read state and build the corresponding button.
  },
)
```

Flutter invokes `build()` as part of rendering the widget tree; after a notification, `ListenableBuilder` requests rebuilding its builder. The widget never stores its own `isEnrolled` boolean. It uses theme colors, at least 48-pixel button height, text plus a check icon for confirmation, and a semantic live region for changes.

### 5. Inject dependencies once

`lib/app/aprop_app.dart` optionally accepts catalogue and enrollment repositories. `lib/app/navigation/auth_gate.dart` creates the default demo implementations once and keeps them while the login/signed-in screens change. It closes only the repository it created; injected repositories belong to their caller.

`lib/app/navigation/main_shell.dart` creates and loads one `EnrollmentViewModel` for `user.id`. The shell is keyed by account ID, so switching accounts disposes the old presentation state. It passes the same ViewModel to `ActivitiesScreen` and `activityDetailsRoute`.

### 6. Connect list and detail

`lib/features/activities/presentation/screens/activities_screen.dart` supplies an `EnrollmentAction` in each `ActivityCard`'s `participationAction` slot. The card only arranges a widget; it knows no enrollment business rules. Its image and title open details independently of the action.

`lib/app/navigation/activity_details_route.dart` forwards the same enrollment ViewModel to `ActivityDetailsScreen`. The detail's fixed bottom action uses `EnrollmentAction(primary: true, showHelper: true)`. Its separate `ActivityDetailsViewModel` continues to load event information; it does not duplicate enrollment state or own the shared ViewModel.

```text
User taps M’hi apunto (list or detail)
  -> EnrollmentAction.onPressed
  -> shared EnrollmentViewModel.enroll(activityId)
  -> pending state + notifyListeners -> Apuntant…
  -> EnrollmentRepository.enroll(userId, activityId)
  -> DemoEnrollmentRepository validates and stores the ID
  -> confirmed write / repository snapshot
  -> shared ViewModel + notifyListeners
  -> each visible EnrollmentAction rebuilds -> Apuntat ✓
```

## Calendar handoff

App composition must inject **the same `EnrollmentRepository` instance and signed-in user ID** into the calendar feature's own ViewModel. It subscribes to `watchEnrolledActivityIds(userId)` and resolves those IDs through the shared `ActivityRepository` to display event dates and information. An initial snapshot includes enrollments made before the calendar was opened. Cancel the subscription when its ViewModel is disposed and handle loading/errors there.

Do not instantiate another `DemoEnrollmentRepository` inside Agenda: it would be an empty, independent data source. Do not import `EnrollmentViewModel`, the detail screen or a concrete demo repository from the calendar feature. Cross-feature sharing uses repository contracts and models; app composition wires screens and routes.

The existing `onActivitySelected(id)` callback opens details from Agenda. `activityDetailsRoute` now additionally requires the shell's shared `enrollmentViewModel`; the updated call is documented in `activity-details.md`.

Backend implementation must agree authenticated identity, enrollment/list endpoints, response formats, errors and server-side uniqueness/authorization before replacing the demo adapter. A client-supplied user ID is not proof of authorization. Do not carry the demo map into production as a second authoritative data source.

## Validation and manual check

Behavior tests cover initial snapshots and updates, immutable data, duplicate prevention, independent concurrent events, failed writes and retry, failed reads and recovery, unknown event IDs, multiple subscribers, account isolation, disposal and late responses. Widget/app tests exercise list-to-detail and detail-to-list synchronization, navigation separation, sign-out/sign-in, pending requests during account changes and both button variants at 320-pixel width with doubled text.

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Local verification on 2026-10-18: formatting clean, `flutter analyze` reported no issues, all 84 repository tests passed, and the Android debug APK built successfully. Additional rendered previews confirmed the list/detail button states at 390 × 844. Device testing, peer review and backend integration remain pending.

Manual check: sign in with the README demo account. Join Jazz al parc from the list, open its title and confirm Apuntat in details. Return, open another event, join it from details and return to the list. Switch tabs and sign out/in: the same account keeps its demo plans during this run. A newly created and verified demo account starts with its own empty set. Agenda shows the same plans in its calendar (see `calendar.md`).
