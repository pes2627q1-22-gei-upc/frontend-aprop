# Calendar — Taiga US #39, task #84

## Behavior and scope

Agenda (section 1 of `MainShell`) shows a Monday-first month calendar (`Dl`–`Dg`) of the signed-in user's own plans, i.e. confirmed enrollments. It opens on the current month with today selected.

| Element | Behavior |
| --- | --- |
| Month header | «Setembre de 2026» with previous/next month buttons («Mes anterior», «Mes següent») |
| Day with plans | Dot under the number (forest; cream on the selected day) |
| Today | Forest outline |
| Selected day | Forest (`AppTheme.forest`) background |
| Day list | Plans of the selected day ordered by start time; updates as soon as a day is tapped |
| Empty day | «No tens cap pla per a aquest dia.» |
| Loading / error | Spinner, or Catalan error with «Tornar-ho a provar»; the calendar stays usable |

Tapping a plan's image or title calls `onActivitySelected(activity.id)`. `MainShell` pushes the shared detail route onto Agenda's own navigator, so the bottom bar stays visible and returning restores the month and selected day. New enrollments made from Inici or the detail appear without reloading.

«Com va anar?» (fig. 13, #64): above the calendar, whatever day is selected, a card asks about every plan that already started and has no answer: «Sí, hi vaig anar», «No hi vaig anar» (same visual weight) and «Més tard» (hidden until the Agenda tab is opened again). Answers go through `AttendanceViewModel` (`features/attendance/`), shared with the ratings: the stars appear only after «Sí» (R10). The API cannot read back «No», so the device remembers it (DP-067).

Out of scope: the reminder row and sheet (fig. 12, removed until the reminders story), unenrollment and multi-day events (the dot uses `Activity.startsAt` only, because the model has no end date).

## Files

```text
features/agenda/presentation/formatters/agenda_date_formatter.dart
features/agenda/presentation/view_models/agenda_view_model.dart
features/agenda/presentation/screens/agenda_screen.dart
features/agenda/presentation/widgets/month_calendar.dart
features/agenda/presentation/widgets/agenda_plan_card.dart
```

`AgendaViewModel` receives the shared `EnrollmentRepository` and `ActivityRepository` contracts and the user ID, as agreed in the [enrollment handoff](event-enrollment.md#calendar-handoff). It subscribes to `watchEnrolledActivityIds(userId)`, resolves each new ID once with `getActivityById` (cached; missing activities are skipped) and groups the plans by day. Late snapshots, lookups after `dispose` and duplicate `load()` calls are ignored. It does not import `EnrollmentViewModel`: both read the same repository instance, injected by `MainShell`. An optional `now` clock makes «today» testable.

```text
EnrollmentRepository.watchEnrolledActivityIds(userId)
  -> AgendaViewModel resolves IDs via ActivityRepository.getActivityById
  -> plans grouped by day + notifyListeners
  -> MonthCalendar (dots) + selected day list
  -> plan image/title -> onActivitySelected(id) -> MainShell._openActivityDetails
```

## Backend

`api-aprop` (`feature/calendar-events`) adds `POST /events/{id}/signup` and `GET /users/{userId}/events?from=&to=`. The app still uses the demo repositories: no HTTP client has been added (DP-010). Identity is a provisional `X-User-ID` header (DP-011) and uniqueness is enforced by the query only (DP-012).

## Validation

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests: `test/features/agenda/` (ViewModel states, grouping, ordering, month navigation, live updates, errors and retry, dispose; screen rendering, semantics, empty/loading/error states, navigation callback, doubled text at 320 px) and `test/app/agenda_flow_test.dart` (join in Inici, see it in Agenda, open details and come back).

Manual check: sign in with the demo account, join Jazz al parc in Inici, open Agenda, go back to September 2026 and tap the 26th. Device testing, peer review and backend integration remain pending.
