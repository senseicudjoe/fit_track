# FitTrack Application — System Design Report

**Project:** FitTrack (Flutter / Firebase fitness tracker)
**Document type:** Technical design report with UML and flow diagrams
**Prepared for:** Engineering, product, and QA stakeholders
**Date:** 20 April 2026
**Source of truth:** `lib/` directory of the `fit_track` repository

---

## Executive Summary

FitTrack is a cross-platform Flutter application that helps users log
workouts, track daily step counts, set fitness goals, and receive local
reminders. The application uses Firebase Authentication and Cloud Firestore
as its primary backend, augmented by on-device services for step counting,
local notifications, and interval timing.

This report documents the application's behaviour from six complementary
angles. Section three presents a UML use case diagram that enumerates every
meaningful user-facing capability. Section four walks through the five
essential runtime flows in the system, using a mix of flowchart, sequence,
and state-machine diagrams to expose both the user journey and the
inter-component collaborations. Section five captures the complete
navigation graph produced by the declarative `GoRouter` configuration in
`lib/utils/routes.dart`, including the redirect rules that enforce
authentication and onboarding invariants. Section six identifies the key
external APIs and internal services that power the application. Section
seven catalogues every local device resource the app touches — system
clock, timezone, pedometer, notifications, SQLite, key-value preferences,
haptics, audio, and permissions — and shows the actual code that
integrates each one. Section eight presents a story-driven end-to-end
demo walkthrough that a presenter can use as a live script.

Together these artefacts give any new engineer the mental model needed to
make safe changes, give product the vocabulary to discuss new capabilities,
and give sales and customer-success a ready-made narrative for stakeholder
demos.

---

## 1. Introduction

### 1.1 Purpose

The purpose of this report is to consolidate, in a single document, the
behavioural and navigational design of the FitTrack mobile application. It
is intended to serve three audiences. New contributors can use it as an
orientation map before opening the codebase. Product managers can use it to
confirm that every intended user capability has a home in the design. QA
engineers can use it to derive test scenarios from the use case catalogue
and the flow diagrams.

### 1.2 Scope

The report covers the end-user application surface only: authentication,
onboarding, dashboard, workout logging, goals, progress and insights,
reminders, and profile management. Backend infrastructure (Firestore
security rules, Cloud Functions, CI/CD) and platform-specific build
configuration are out of scope.

### 1.3 Conventions

All diagrams in this report are expressed in Mermaid syntax so that they
render natively in GitHub, VS Code, Obsidian, and most modern Markdown
viewers. Route paths and code identifiers are rendered in fixed width,
for example `/dashboard` or `AuthProvider`. References to screen classes
match the filenames in `lib/screens/`.

---

## 2. System Overview

FitTrack is structured as a conventional Flutter application using the
`provider` package for state management and `go_router` for declarative
navigation. The `main.dart` entry point initialises Firebase and the local
notification service, then mounts a tree of `ChangeNotifierProvider`s and
`ChangeNotifierProxyProvider`s around a `MaterialApp.router`. The proxy
providers ensure that workout, goal, and stats data are automatically
refreshed whenever the authenticated user changes.

Persistence is split across two stores. Cloud Firestore holds the
cross-device data — the user profile, workouts, goals, and aggregated daily
statistics. The on-device SQLite database (via `sqflite`) holds reminders,
which are intentionally device-local. Real-time device signals — step
counts from the `pedometer` plugin and fired notifications from
`flutter_local_notifications` — feed back into the providers so that the
UI stays reactive.

The remainder of this report explores the behaviour this architecture
enables.

---

## 3. Use Case Analysis

### 3.1 Overview

The use case diagram below captures the complete catalogue of capabilities
exposed to the end user, together with the supporting system actors that
make each capability possible. The primary actor is the human **User**.
Two supporting actors stand in for external or platform services: the
**Firebase** actor covers authentication, Firestore reads and writes, and
Google Sign-In federation, while the **Device** actor covers the step
counter, local notification scheduler, timezone resolution, and runtime
permission prompts.

### 3.2 Diagram

```mermaid
flowchart LR
    User((User))
    Firebase((Firebase))
    Device((Device))

    subgraph FitTrack["FitTrack System"]
        direction TB

        UC1(["Register / Sign In"])
        UC2(["Sign In with Google"])
        UC3(["Complete Onboarding Profile"])
        UC4(["Grant Permissions"])
        UC5(["View Dashboard"])
        UC6(["Log Workout"])
        UC7(["Use Workout Timer"])
        UC8(["View Workout Details"])
        UC9(["Create / Edit Goals"])
        UC10(["Track Daily Steps"])
        UC11(["View Progress Charts"])
        UC12(["View Insights"])
        UC13(["Manage Reminders"])
        UC14(["Edit Profile"])
        UC15(["Sign Out"])

        UC6 -. include .-> UC7
        UC5 -. include .-> UC10
        UC11 -. extend .-> UC12
        UC3 -. include .-> UC4
    end

    User --- UC1
    User --- UC2
    User --- UC3
    User --- UC5
    User --- UC6
    User --- UC7
    User --- UC8
    User --- UC9
    User --- UC11
    User --- UC12
    User --- UC13
    User --- UC14
    User --- UC15

    UC1 --- Firebase
    UC2 --- Firebase
    UC6 --- Firebase
    UC9 --- Firebase
    UC14 --- Firebase
    UC15 --- Firebase

    UC4 --- Device
    UC7 --- Device
    UC10 --- Device
    UC13 --- Device
```

### 3.3 Discussion

Several relationships in the diagram merit explicit commentary because
they shape how features compose at runtime. The *Complete Onboarding
Profile* use case includes *Grant Permissions*, which means the first-run
flow is deliberately non-skippable: the router keeps a freshly registered
user pinned inside the onboarding path until both a profile has been saved
and notification and activity-recognition permissions have been addressed.
The *Log Workout* use case includes *Use Workout Timer* because any
workout that involves interval rounds re-uses the timer screen and
deposits its captured splits back into the resulting workout record. The
inverse relationship, *View Progress Charts* extended by *View Insights*,
reflects the fact that Insights is an optional analytical deep-dive rather
than a mandatory step on the progress path — a user who only wants the
weekly summary never has to open it. Finally, *View Dashboard* includes
*Track Daily Steps*: opening the home tab implicitly subscribes to the
pedometer stream, which is why step counts appear without any explicit
action.

A legend for the relationship arrows is as follows. The `include` label
denotes a mandatory sub-activity: whenever the base use case fires, the
included one fires too. The `extend` label denotes a conditional
extension: the extending use case only participates when a specific
precondition is met.

---

## 4. Essential Application Flows

This section walks through five runtime flows that together exercise most
of the application surface. Each subsection opens with a short narrative,
presents the diagram, and closes with a commentary that highlights the
design rationale and any subtleties a reader might otherwise miss.

### 4.1 Authentication and Startup

The following flowchart captures the decision tree executed by the
`redirect` callback on `AppRouter.router` every time the router's location
changes or `AuthProvider` notifies its listeners. Because the same
callback handles cold launches, hot restarts, token expirations, and
explicit sign-outs, the diagram doubles as both a startup flow and a
long-running runtime guard.

```mermaid
flowchart TD
    Start([App Launch]) --> Splash[/"/  Splash"/]
    Splash --> InitFB{Firebase<br/>initialized?}
    InitFB -- No --> Splash
    InitFB -- Yes --> Logged{isLoggedIn?}

    Logged -- No --> Intro[/"/intro"/]
    Intro --> LoginChoice{Action?}
    LoginChoice -- Sign In --> Login[/"/login"/]
    LoginChoice -- Create Account --> Register[/"/register"/]

    Login --> AuthAttempt{Auth OK?}
    Register --> AuthAttempt
    AuthAttempt -- No --> Login
    AuthAttempt -- Yes --> Onboarded{isOnboarded?}

    Logged -- Yes --> Onboarded
    Onboarded -- No --> Onboarding[/"/onboarding"/]
    Onboarding --> SaveProfile[(Save profile to<br/>Firestore)]
    SaveProfile --> Permissions[/"/permissions"/]

    Onboarded -- Yes --> Permissions
    Permissions --> Dashboard[/"/dashboard"/]
```

The flow begins on the splash screen, which exists primarily to absorb the
asynchronous Firebase initialisation that happens in `main.dart`. While
`AuthProvider.isInitialized` remains false, the redirect returns `null`
and the user stays on the splash, which prevents the "flash of wrong
screen" problem that otherwise appears on cold starts. Once
initialisation completes, two booleans drive the rest of the decisions.
The `isLoggedIn` flag is derived from Firebase's auth state stream and
restricts unauthenticated users to the four auth routes. The `isOnboarded`
flag is persisted on the user's Firestore profile document and traps the
user inside `/onboarding` until it flips true. A returning, fully
onboarded user still lands briefly on `/permissions` before being
forwarded to the dashboard, which gives the app one reliable chance per
session to re-prompt for notification or activity permissions that may
have been revoked from the system settings.

### 4.2 Workout Logging

The sequence diagram below traces a single "save workout" operation from
the UI tap through to the persisted Firestore document and the cascaded
stats refresh. Time flows downward; each vertical line is a participant.

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant UI as LogWorkoutScreen
    participant TS as TimerScreen
    participant WP as WorkoutProvider
    participant SP as StatsProvider
    participant FS as FirestoreService
    participant DB as (Firestore)

    U->>UI: Open "/log"
    U->>UI: Select type, duration, calories, distance
    opt HIIT / Strength
        U->>TS: Tap "Use Timer"
        TS-->>U: Round splits captured
        TS->>UI: Return List<int> timerSplits
    end
    U->>UI: Tap "Save Workout"
    UI->>WP: addWorkout(WorkoutModel)
    WP->>FS: createWorkout(uid, data)
    FS->>DB: add(workouts)
    DB-->>FS: workoutId
    FS-->>WP: WorkoutModel
    WP->>SP: refreshDailyStats()
    SP->>FS: incrementDailyStats(uid, today)
    FS->>DB: update(daily_stats/{uid}/{date})
    SP-->>UI: notifyListeners()
    UI-->>U: Toast "Workout saved"
```

A few design decisions stand out in this sequence. First, the
`opt` block around the timer excursion makes clear that interval data is
optional: a user logging a simple "Running" entry bypasses `TimerScreen`
entirely. Second, saving a workout triggers a double write — one document
is appended to the `workouts` collection, and one aggregate is upserted
into `daily_stats/{uid}/{date}`. Keeping these separate is what allows
the dashboard to render today's totals without scanning every historical
workout on every load. Finally, the `notifyListeners()` call at the end of
the sequence is the mechanism by which the dashboard rebuilds automatically
as soon as the user navigates back; no imperative refresh call is required.

### 4.3 Goal Lifecycle

Goals in FitTrack are modelled as long-lived documents that progress
through several well-defined states. The state machine below captures
those states and the events that transition between them.

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Creating: Tap "+"
    Creating --> Validating: Submit
    Validating --> Creating: Invalid input
    Validating --> Active: Saved to Firestore
    Active --> Editing: Tap goal card
    Editing --> Active: Save changes
    Active --> Progressing: Stats update each day
    Progressing --> Active
    Progressing --> Achieved: target met
    Achieved --> [*]: Archive
    Active --> Deleted: Swipe delete
    Deleted --> [*]
```

The *Idle* state represents the Goals tab with no in-flight operation; it
is the state most users see most of the time. *Creating* and *Editing*
both mutate a local draft inside a bottom sheet, and both transition
through a *Validating* checkpoint that enforces the non-empty name,
positive target, and sensible-deadline rules on the client before
involving the network. The most interesting transition is the transient
loop through *Progressing*: every time `StatsProvider` recomputes, the
goal's current value is compared against its target, and if the target has
been met the goal moves to *Achieved* and waits to be archived. This
design keeps the goal card reactive without any polling.

### 4.4 Reminders and Notifications

Reminders are deliberately handled differently from the rest of the
application data. They live in an on-device SQLite database rather than
Firestore, because a user may reasonably want different reminders on
different devices. The diagram below shows both the scheduling path and
the later delivery of a fired notification.

```mermaid
flowchart LR
    A[User opens<br/>Reminders] --> B[Tap "New Reminder"]
    B --> C{Permission<br/>granted?}
    C -- No --> D[Request via<br/>permission_handler]
    D --> C
    C -- Yes --> E[Pick time,<br/>repeat days,<br/>sound]
    E --> F[Save to SQLite<br/>via DatabaseService]
    F --> G[Schedule with<br/>flutter_local_<br/>notifications]
    G --> H[(OS alarm manager)]
    H -. fires at time .-> I[Local notification]
    I --> J{User taps?}
    J -- Yes --> K[Deep link to<br/>/dashboard]
    J -- No --> L[Dismissed]
```

Three design choices are worth drawing attention to. Permissions are
requested lazily, only when the user first opens the Reminders screen,
because bundling every permission prompt into the onboarding flow leads
to higher denial rates. Scheduling is then delegated to
`flutter_local_notifications`, which in turn uses the OS alarm manager,
so reminders continue to fire even when the application is backgrounded
or killed entirely. When a fired notification is tapped, the deep link
routes the user back to `/dashboard` rather than the reminders editor,
which keeps the post-tap experience aligned with what the reminder was
probably prodding the user to do.

### 4.5 Step Tracking Pipeline

The final flow is a continuous background pipeline that transforms raw
step-counter events from the device into the number rendered on the
dashboard's "Steps" card.

```mermaid
flowchart TD
    Boot([App foreground]) --> Sub[PedometerService<br/>subscribes to stepCountStream]
    Sub --> Stream{{pedometer event}}
    Stream --> Delta[Compute delta<br/>since last reading]
    Delta --> Store[Update DailyStats<br/>in Firestore]
    Store --> UI[StatsProvider<br/>notifies Dashboard]
    UI --> Widget[StatCard re-renders<br/>step count + progress bar]
```

The non-obvious step is the delta calculation. The platform pedometer
reports a monotonically increasing cumulative count since the device was
last rebooted, not a per-session count, so the service stores each reading
and subtracts the previously-stored one to derive how many steps belong
to the current day. That delta is upserted into
`daily_stats/{uid}/{today}`, which causes `StatsProvider` to emit a change
notification, which rebuilds the step card on the dashboard. The reactive
chain means the user sees the step count tick upward without any explicit
refresh action.

---

## 5. Navigation Architecture

### 5.1 Overview

This section documents the complete set of routes registered with
`GoRouter` in `lib/utils/routes.dart` and describes how they are composed
into the three architectural tiers that the user experiences.

### 5.2 Navigation Map

```mermaid
flowchart TD
    Splash["/ Splash"]
    Intro["/intro"]
    Login["/login"]
    Register["/register"]

    Onboarding["/onboarding"]
    Permissions["/permissions"]

    subgraph Shell["MainShell — Bottom Navigation"]
        direction LR
        Dashboard["/dashboard<br/><i>Home</i>"]
        Log["/log<br/><i>Log</i>"]
        Goals["/goals<br/><i>Goals</i>"]
        Progress["/progress<br/><i>Progress</i>"]
        Insights["/insights"]
        Settings["/settings<br/><i>Profile</i>"]
        Reminders["/reminders"]
    end

    EditProfile["/edit-profile"]
    Timer["/timer"]
    WorkoutDetail["/workout/:id"]

    Splash -- not logged in --> Intro
    Intro --> Login
    Intro --> Register
    Login -- success --> Onboarding
    Register -- success --> Onboarding
    Login -- already onboarded --> Permissions
    Onboarding --> Permissions
    Permissions --> Dashboard
    Splash -- logged in + onboarded --> Permissions

    Dashboard <--> Log
    Dashboard <--> Goals
    Dashboard <--> Progress
    Dashboard <--> Settings
    Log <--> Goals
    Goals <--> Progress
    Progress <--> Settings
    Dashboard --> Insights
    Progress --> Insights

    Log --> Timer
    Dashboard --> Timer
    Dashboard --> WorkoutDetail
    Progress --> WorkoutDetail
    Settings --> EditProfile
    Settings --> Reminders
    Dashboard --> Reminders

    Settings -- sign out --> Splash

    classDef auth fill:#1e293b,stroke:#6366f1,color:#fff
    classDef onboarding fill:#312e81,stroke:#818cf8,color:#fff
    classDef shell fill:#0f172a,stroke:#22c55e,color:#fff
    classDef fullscreen fill:#3f1d38,stroke:#f472b6,color:#fff

    class Splash,Intro,Login,Register auth
    class Onboarding,Permissions onboarding
    class Dashboard,Log,Goals,Progress,Insights,Settings,Reminders shell
    class EditProfile,Timer,WorkoutDetail fullscreen
```

### 5.3 Tier Discussion

The colour of each node in the diagram indicates which of four tiers it
belongs to, and the tier fundamentally determines both the visual chrome
around the screen and the allowed transitions into and out of it. The
authentication tier, shown with indigo borders, contains the splash,
intro, login, and register routes; unauthenticated users are constrained
to this tier by the redirect rules. The onboarding tier, shown in
lavender, is a one-way gate between sign-up and the main application —
once a user sets `isOnboarded` to true they can never re-enter it. The
shell tier, shown in green, contains the five bottom-navigation tabs plus
`/insights` and `/reminders`; every route in this tier is nested inside
the `ShellRoute` so that the bottom bar remains visible. The full-screen
tier, shown in pink, contains `/edit-profile`, `/timer`, and
`/workout/:id`; these are pushed on the root navigator so that the bottom
bar is hidden for a focused, modal-like experience.

Arrow direction encodes intent. Double-headed arrows between shell
screens reflect the fact that the bottom-navigation bar lets the user jump
directly in either direction. Single-headed arrows into the full-screen
tier represent one-way pushes — the user returns via the system back
gesture or an explicit close action. The sign-out arrow from `/settings`
back to `/` mirrors what `AuthProvider.signOut()` effectively triggers
through the router's `refreshListenable` wiring.

### 5.4 Route Reference Table

The following table lists every route registered with `GoRouter`, the
screen widget that renders it, whether it lives inside the bottom-navigation
shell, and a short description of its purpose.

| Path             | Screen                | Shell | Purpose                                                |
|------------------|-----------------------|:-----:|--------------------------------------------------------|
| `/`              | SplashScreen          |  No   | Entry point; executes the redirect logic.              |
| `/intro`         | IntroScreen           |  No   | Marketing and "get started" pitch.                     |
| `/login`         | LoginScreen           |  No   | Email and Google Sign-In.                              |
| `/register`      | RegisterScreen        |  No   | Account creation.                                      |
| `/onboarding`    | OnboardingScreen      |  No   | Captures age, weight, height, and initial targets.     |
| `/permissions`   | PermissionsScreen     |  No   | Requests notification and activity-recognition access. |
| `/dashboard`     | DashboardScreen       |  Yes  | Today's stats, step count, and quick actions.          |
| `/log`           | LogWorkoutScreen      |  Yes  | Manual workout entry form.                             |
| `/goals`         | GoalsScreen           |  Yes  | Create, edit, and archive goals.                       |
| `/progress`      | ProgressScreen        |  Yes  | Historical workout list and summary charts.            |
| `/insights`      | InsightsScreen        |  Yes  | Deep-dive analytics rendered with fl_chart.            |
| `/settings`      | SettingsScreen        |  Yes  | Profile summary, preferences, and sign-out.            |
| `/reminders`     | RemindersScreen       |  Yes  | Schedule and manage local notifications.               |
| `/edit-profile`  | EditProfileScreen     |  No   | Full-screen push from Settings.                        |
| `/timer`         | TimerScreen           |  No   | Interval timer capturing per-round splits.             |
| `/workout/:id`   | WorkoutDetailScreen   |  No   | Detailed view of a single logged workout.              |

### 5.5 Redirect Invariants

The router enforces four invariants that the rest of the application can
safely assume on every screen entry. First, an unauthenticated user can
only be on `/`, `/intro`, `/login`, or `/register`. Second, a logged-in
but unonboarded user is pinned to `/onboarding`. Third, a logged-in,
onboarded user who lands on an auth route is forwarded to `/permissions`
once per session. Fourth, an onboarded user can never re-enter
`/onboarding`; any such attempt bounces to `/dashboard`. Because the
router listens to `AuthProvider` via its `refreshListenable` parameter,
any change to `isLoggedIn` or `isOnboarded` causes these rules to be
re-evaluated immediately, which is why sign-in and sign-out do not
require any imperative navigation calls from the widget layer.

---

## 6. Key APIs and Services

### 6.1 Overview

FitTrack relies on a small but carefully chosen set of external APIs and a
matching set of in-process services that wrap those APIs behind a clean
domain interface. This section enumerates each one, identifies the
responsibility it owns, and points to the code where the integration
lives. The diagram below shows how the layers stack: UI screens never
call platform APIs directly; they always go through a `Provider`, which
goes through a service, which then calls Firebase, the OS, or SQLite.

```mermaid
flowchart TD
    subgraph UI["UI Layer (lib/screens, lib/widgets)"]
        Screens[Screens]
        Widgets[Widgets]
    end

    subgraph State["State Layer (lib/providers)"]
        AuthP[AuthProvider]
        WorkoutP[WorkoutProvider]
        GoalP[GoalProvider]
        StatsP[StatsProvider]
        TimerP[TimerProvider]
    end

    subgraph Services["Service Layer (lib/services)"]
        AuthS[AuthService]
        FsS[FirestoreService]
        DbS[DatabaseService]
        NotifS[NotificationService]
        PedS[PedometerService]
        TimerS[TimerService]
    end

    subgraph External["External APIs and Platform"]
        FbAuth[(Firebase Auth)]
        Firestore[(Cloud Firestore)]
        Google[(Google Sign-In)]
        SQLite[(SQLite)]
        OS_Notif[OS Notification<br/>Scheduler]
        OS_Ped[OS Step Counter]
        OS_TZ[OS Timezone]
    end

    Screens --> AuthP
    Screens --> WorkoutP
    Screens --> GoalP
    Screens --> StatsP
    Screens --> TimerP

    AuthP --> AuthS
    WorkoutP --> FsS
    GoalP --> FsS
    StatsP --> FsS
    StatsP --> DbS
    StatsP --> PedS
    TimerP --> TimerS

    AuthS --> FbAuth
    AuthS --> Firestore
    AuthS --> Google
    FsS --> Firestore
    DbS --> SQLite
    NotifS --> OS_Notif
    NotifS --> OS_TZ
    PedS --> OS_Ped
    PedS --> SQLite
```

### 6.2 External APIs

The application integrates with three categories of external services:
the Firebase platform, Google's sign-in federation, and a handful of
operating-system capabilities exposed through Flutter plugins.

**Firebase Authentication** is reached through the
`firebase_auth` package and is wrapped by `AuthService`. The service uses
`createUserWithEmailAndPassword` and `signInWithEmailAndPassword` for the
email path, exposes the `authStateChanges` stream that ultimately drives
the router's `refreshListenable`, and offers `sendPasswordResetEmail` for
the forgot-password flow.

**Cloud Firestore** is reached through the `cloud_firestore` package and
is wrapped by `FirestoreService`. The data model is a per-user document
tree rooted at `users/{uid}` with four sub-collections: `workouts`,
`goals`, `dailyStats`, and `reminders`. Reads use `snapshots()` streams
so the UI updates reactively, and the daily-stats aggregate is updated
with `SetOptions(merge: true)` so concurrent writes from different
sources (workout save, step delta) compose safely.

**Google Sign-In** is reached through the `google_sign_in` package. After
the user grants consent, the Google ID token is forwarded to Firebase
through `GoogleAuthProvider.credential`, which gives FitTrack a unified
`User` object regardless of whether the user signed up with email or
with Google.

**OS notification scheduler** is reached through
`flutter_local_notifications` and its sister package `flutter_timezone`.
The notification service initialises the timezone database at startup,
configures `AndroidInitializationSettings` and `DarwinInitializationSettings`
for both platforms, and uses `zonedSchedule` with
`DateTimeComponents.dayOfWeekAndTime` to set up weekly recurring
reminders. On Android the service prefers exact-while-idle alarms and
falls back to inexact alarms when the `SCHEDULE_EXACT_ALARM` permission
is unavailable.

**OS step counter** is reached through the `pedometer` package, which
exposes `Pedometer.stepCountStream` and `Pedometer.pedestrianStatusStream`.
Both streams are subscribed to in `PedometerService.start` and
unsubscribed in `stop` to avoid leaks across user sessions.

**Runtime permissions** are requested through `permission_handler`, which
brokers the platform-specific dialogues for notification and
activity-recognition grants on the `/permissions` screen.

### 6.3 Internal Services

The internal service layer translates the external APIs above into
domain operations that the rest of the application can call without
worrying about plugin contracts.

`AuthService` is a singleton that owns Firebase Auth, Firestore writes
to the `users` collection, and Google Sign-In federation. Its public
surface is `register`, `login`, `signInWithGoogle`, `signOut`,
`fetchUser`, `updateUser`, and `resetPassword`. It also exposes
`currentUser` and the `authStateChanges` stream for the provider layer.

`FirestoreService` is the data-access layer for everything except the
user profile. It exposes one method group per sub-collection — for
example `saveWorkout` and `workoutsStream` for workouts, `saveGoal` and
`goalsStream` for goals, and `fetchTodayStats`, `updateTodayStats`, and
`fetchStatRange` for the daily-stats aggregate. The service also owns
the `_todayKey` helper that produces the canonical `YYYY-MM-DD` document
ID used to key daily stats.

`DatabaseService` is the on-device SQLite cache. It backs two tables:
`step_cache`, which buffers pedometer deltas before they are flushed to
Firestore, and `workout_drafts`, which preserves an in-progress workout
form across an app kill so that a partially typed entry survives a phone
call interruption. Buffering steps locally is what keeps Firestore costs
bounded — the pedometer fires every few seconds, but only one daily
summary is written to the cloud per day.

`NotificationService` schedules and cancels local notifications. It is
initialised once from `main.dart` so that timezone data is loaded before
any UI code runs. Its `scheduleReminder` method expands a single
`ReminderModel` into one OS-level scheduled notification per repeat day,
using a deterministic ID so cancellation is idempotent.

`PedometerService` subscribes to the device step stream and computes
per-event deltas. It persists the last cumulative reading in
`SharedPreferences` and the running daily total in SQLite, so that step
counts survive both backgrounding and full app restarts. It exposes two
callbacks — `onStepUpdate` and `onStatusUpdate` — that `StatsProvider`
hooks into to drive the dashboard.

`TimerService` is a pure in-memory state machine that drives the
interval timer. It models four phases (work, rest, cooldown, idle),
records per-round splits, and emits `onTick`, `onPhaseChange`, and
`onComplete` callbacks. Because it is fully in-memory, it is also the
only service that does not touch persistence — splits travel out of the
service inside the resulting `WorkoutModel` rather than as a side
effect.

### 6.4 Service-to-API Quick Reference

| Service               | External API / package                            | Primary responsibility                       |
|-----------------------|---------------------------------------------------|----------------------------------------------|
| `AuthService`         | `firebase_auth`, `google_sign_in`, `cloud_firestore` | Sign-up, sign-in, profile CRUD, password reset |
| `FirestoreService`    | `cloud_firestore`                                 | Workouts, goals, daily stats, reminders      |
| `DatabaseService`     | `sqflite`, `path`                                 | Local step buffer and workout drafts         |
| `NotificationService` | `flutter_local_notifications`, `flutter_timezone`, `timezone` | Schedule and cancel local reminders          |
| `PedometerService`    | `pedometer`, `shared_preferences`                 | Stream device steps, compute daily delta     |
| `TimerService`        | `dart:async` (no external API)                    | Interval timer state machine                 |

---

## 7. Local Device Resources

### 7.1 Overview

In addition to the cloud APIs catalogued in section six, FitTrack relies
heavily on resources that live on the user's device. These resources are
what make the application *feel* native: notifications fire even when
the app is closed, the step counter keeps incrementing while the screen
is locked, the timer ticks down with the system clock, and a short beep
plus a haptic buzz mark the end of every interval. This section
identifies each local resource the app touches, explains why it is
needed, and presents the actual integration code.

The code blocks below are excerpts from the live source tree; the file
path is given above each snippet so a reader can jump to the full
implementation if needed.

### 7.2 System Clock

The system clock is consumed in two distinct ways. The interval timer
uses `Timer.periodic` from `dart:async` to drive a one-second ticker
that decrements `secondsRemaining` and emits an `onTick` callback on
every beat. Elsewhere in the app, `DateTime.now()` is read to derive the
canonical `YYYY-MM-DD` document key used for daily-stats aggregates and
to stamp every `loggedAt` field on a workout.

*From `lib/services/timer_service.dart`:*

```dart
void _tick() {
  _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
    _secondsRemaining--;
    _totalElapsedSeconds++;
    onTick?.call(_secondsRemaining);

    if (_secondsRemaining <= 0) {
      _ticker?.cancel();
      _advance();
    }
  });
}
```

*From `lib/services/firestore_service.dart`:*

```dart
String _todayKey() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
}
```

### 7.3 Local Timezone

Reminders fire at a wall-clock time on a specific weekday — for example
"every Monday at 18:30 local time". For that to be correct after a user
travels across timezones, FitTrack must know the device's current
timezone, not just its UTC offset. The `flutter_timezone` plugin returns
the IANA identifier (for example `Europe/Lisbon`), and the `timezone`
package's `tz.local` is set to the matching `Location` object before any
notification is scheduled. Without this step, `tz.local` would stay on
UTC, scheduled times and weekdays would be wrong, and alarms might
never match.

*From `lib/services/notification_service.dart`:*

```dart
Future<void> _setLocalTimeZone() async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (_) {
    // Rare: unknown identifier; stay on UTC so behaviour is at least consistent.
    tz.setLocalLocation(tz.UTC);
  }
}
```

### 7.4 Local Notifications

Local notifications are how the application reaches the user when the
app is closed. The `flutter_local_notifications` plugin is initialised
once from `main.dart`, after which `scheduleReminder` expands a single
`ReminderModel` into one OS-level scheduled notification per repeat
day. On Android the service prefers exact-while-idle alarms (which are
more reliable on aggressive vendor power-management) and falls back to
inexact alarms when the `SCHEDULE_EXACT_ALARM` permission is not
granted.

*From `lib/services/notification_service.dart`:*

```dart
Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android == null) return AndroidScheduleMode.inexactAllowWhileIdle;

  if (await android.canScheduleExactNotifications() != true) {
    await android.requestExactAlarmsPermission();
  }
  if (await android.canScheduleExactNotifications() == true) {
    return AndroidScheduleMode.exactAllowWhileIdle;
  }
  return AndroidScheduleMode.inexactAllowWhileIdle;
}

Future<void> scheduleReminder(ReminderModel reminder) async {
  if (!reminder.isActive || reminder.repeatDays.isEmpty) return;
  await requestPermissions();
  final androidMode = await _resolveAndroidScheduleMode();

  final parts  = reminder.timeOfDay.split(':');
  final hour   = int.parse(parts[0]);
  final minute = int.parse(parts[1]);

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'workout_reminders',
      'Workout Reminders',
      channelDescription: 'Daily workout reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  for (final day in reminder.repeatDays) {
    final id = reminder.notificationId + day;
    await _plugin.zonedSchedule(
      id,
      'FitTrack Reminder',
      reminder.label,
      _nextInstanceOfDayTime(day + 1, hour, minute),
      details,
      androidScheduleMode: androidMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
```

### 7.5 Pedometer (Step Counter)

The `pedometer` plugin exposes two streams: `stepCountStream`, which
emits the cumulative step count since the last device reboot, and
`pedestrianStatusStream`, which emits `walking` or `stopped`. Because
the step count is *cumulative* — not per session and not per day —
`PedometerService` subtracts the previously stored reading on every
event to derive a delta, then adds that delta to today's running
total. The previous reading is persisted in `SharedPreferences` so the
delta calculation survives an app kill, and the running total is
buffered to SQLite so the dashboard can render instantly on cold start
without a Firestore round trip.

*From `lib/services/pedometer_service.dart`:*

```dart
Future<void> start(String uid, {int? initialSteps}) async {
  await stop();
  _uid = uid;
  _prefs ??= await SharedPreferences.getInstance();

  // Last cumulative reading from a previous run on this device
  _lastTotalSteps = _prefs?.getInt('last_total_steps_$_uid');

  // Today's running total from the SQLite cache
  final today = _todayKey();
  final cachedSteps = await DatabaseService.instance.getStepsForDate(uid, today);

  if (cachedSteps == 0 && initialSteps != null && initialSteps > 0) {
    _stepsToday = initialSteps;
    await DatabaseService.instance.upsertSteps(uid, today, _stepsToday);
  } else {
    _stepsToday = cachedSteps;
  }
  onStepUpdate?.call(_stepsToday);

  _stepSub = Pedometer.stepCountStream.listen(
    _onStepCount,
    onError: _onStepError,
    cancelOnError: false,
  );
  _statusSub = Pedometer.pedestrianStatusStream.listen(
    _onPedestrianStatus,
    onError: _onStatusError,
    cancelOnError: false,
  );
}

void _onStepCount(StepCount event) {
  if (_uid == null) return;

  if (_lastTotalSteps == null) {
    // First event this session — establish the baseline
    _lastTotalSteps = event.steps;
    _prefs?.setInt('last_total_steps_$_uid', _lastTotalSteps!);
    return;
  }

  final int delta = event.steps - _lastTotalSteps!;
  if (delta == 0) return;

  // Negative delta ⇒ device rebooted, hardware counter reset to 0
  int actualDelta = delta < 0 ? event.steps : delta;

  if (actualDelta > 0) {
    _stepsToday += actualDelta;
    _lastTotalSteps = event.steps;
    onStepUpdate?.call(_stepsToday);

    _prefs?.setInt('last_total_steps_$_uid', _lastTotalSteps!);
    DatabaseService.instance.upsertSteps(_uid!, _todayKey(), _stepsToday);
  }
}
```

### 7.6 SQLite Local Database

The `sqflite` plugin backs an on-device SQLite database used for two
distinct workloads. The `step_cache` table buffers pedometer deltas so
they can be flushed to Firestore as a single daily summary instead of
one write per stride. The `workout_drafts` table preserves an
in-progress workout form across an app kill, so a partially typed
entry survives interruptions like a phone call or a low-memory
termination.

*From `lib/services/database_service.dart`:*

```dart
Future<Database> _initDb() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'fittrack.db');
  return openDatabase(path, version: 1, onCreate: _onCreate);
}

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE step_cache (
      id      INTEGER PRIMARY KEY AUTOINCREMENT,
      uid     TEXT NOT NULL,
      date    TEXT NOT NULL,
      steps   INTEGER NOT NULL DEFAULT 0,
      synced  INTEGER NOT NULL DEFAULT 0,
      UNIQUE(uid, date)
    )
  ''');

  await db.execute('''
    CREATE TABLE workout_drafts (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      uid           TEXT NOT NULL,
      type          TEXT NOT NULL,
      duration_min  INTEGER NOT NULL DEFAULT 0,
      calories      REAL NOT NULL DEFAULT 0,
      distance_km   REAL NOT NULL DEFAULT 0,
      sets          INTEGER,
      reps          INTEGER,
      notes         TEXT NOT NULL DEFAULT '',
      updated_at    TEXT NOT NULL
    )
  ''');
}

Future<void> upsertSteps(String uid, String date, int steps) async {
  final db = await database;
  await db.insert(
    'step_cache',
    {'uid': uid, 'date': date, 'steps': steps, 'synced': 0},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

### 7.7 Shared Preferences (Key-Value Store)

`SharedPreferences` is used for two small pieces of per-device state
that do not justify a row in SQLite: the last cumulative pedometer
reading (consumed in section 7.5) and a `permissions_handled` flag set
once the user clears the permissions screen, which prevents the same
prompts from firing on every cold start.

*From `lib/screens/onboarding/permissions_screen.dart`:*

```dart
Future<void> _complete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('permissions_handled', true);
  if (mounted) context.go('/dashboard');
}
```

### 7.8 Haptic Feedback

Short vibrations punctuate the interval timer: one buzz when the phase
transitions from work to rest (or rest to work), and one final buzz on
session completion. Haptics come from Flutter's built-in
`HapticFeedback` API in `package:flutter/services.dart`, which means no
extra plugin is required.

*From `lib/providers/timer_provider.dart`:*

```dart
TimerProvider() {
  _timer.onTick = (_) => notifyListeners();

  _timer.onPhaseChange = (phase, round) {
    if (phase != TimerPhase.idle) {
      HapticFeedback.vibrate();
    }
    notifyListeners();
  };

  _timer.onComplete = (splits) {
    HapticFeedback.vibrate();
    _playCompletionSound();
    notifyListeners();
  };
}
```

### 7.9 Audio Playback

A short `beep.mp3` asset, bundled with the app, plays at the end of an
interval session. The `audioplayers` package handles platform audio on
both iOS and Android. The error path is intentionally silent — a
missing or busy audio output should never break the workout flow — and
is logged with `debugPrint` in development.

*From `lib/providers/timer_provider.dart`:*

```dart
final _audioPlayer = AudioPlayer();

Future<void> _playCompletionSound() async {
  try {
    await _audioPlayer.play(AssetSource('audios/beep.mp3'));
  } catch (e) {
    debugPrint('Error playing completion sound: $e');
  }
}
```

### 7.10 Runtime Permissions

Before the application can read steps from the pedometer or post a
notification, the user must grant the corresponding OS permission.
FitTrack uses `permission_handler` to inspect and request both
`Permission.activityRecognition` (which gates the pedometer on Android
10+ and Wear-equivalent platforms) and `Permission.notification`. The
permissions screen requests both as a batch, then writes the
`permissions_handled` flag described above.

*From `lib/screens/onboarding/permissions_screen.dart`:*

```dart
Future<void> _checkCurrentStatus() async {
  final motion = await Permission.activityRecognition.status;
  final notif  = await Permission.notification.status;
  if (mounted) {
    setState(() {
      _motionGranted = motion.isGranted;
      _notifGranted  = notif.isGranted;
    });
  }
}

Future<void> _requestAll() async {
  setState(() => _loading = true);

  final notif        = await NotificationService.instance.requestPermissions();
  final motionStatus = await Permission.activityRecognition.request();

  if (mounted) {
    setState(() {
      _notifGranted  = notif;
      _motionGranted = motionStatus.isGranted;
      _loading       = false;
    });
  }
}
```

### 7.11 Local Resource Quick Reference

The table below collapses this section into a single look-up: every
local resource, the package or API that exposes it, the service or
screen that owns the integration, and what the resource is used for.

| Local resource         | Package / API                              | Owned by                       | Purpose                                     |
|------------------------|--------------------------------------------|--------------------------------|---------------------------------------------|
| System clock (ticker)  | `dart:async` `Timer.periodic`              | `TimerService`                 | One-second interval timer                   |
| System clock (now)     | `DateTime.now()`                           | `FirestoreService`, `WorkoutModel` | Daily-stats keys, `loggedAt` stamps         |
| Local timezone         | `flutter_timezone`, `timezone`             | `NotificationService`          | Correct weekly recurring schedules          |
| Local notifications    | `flutter_local_notifications`              | `NotificationService`          | Reminder alerts, completion alerts          |
| Pedometer              | `pedometer`                                | `PedometerService`             | Real-time step counting                     |
| SQLite database        | `sqflite`, `path`                          | `DatabaseService`              | Step buffer, workout drafts                 |
| Key-value preferences  | `shared_preferences`                       | `PedometerService`, permissions screen | Last step reading, permissions flag |
| Haptic feedback        | `flutter/services.dart` `HapticFeedback`   | `TimerProvider`                | Phase-change and completion buzzes          |
| Audio playback         | `audioplayers`                             | `TimerProvider`                | Completion beep                             |
| Runtime permissions    | `permission_handler`                       | `PermissionsScreen`            | Activity-recognition and notification grants |

---


## 8. Conclusion

The three views presented in this report — the use case catalogue, the
five runtime flows, and the navigation graph — are intended to be read as
a single composite model of the FitTrack application. The use case
diagram answers the question "what can the user do?" The flow diagrams
answer the question "how does a given capability actually play out at
runtime, and which components collaborate?" The navigation map answers
the question "which screens exist, and how does the user reach them?"

Taken together, these artefacts reduce the cost of onboarding a new
engineer, give QA a structured inventory from which to derive test plans,
and give product a shared vocabulary for discussing changes. The diagrams
are generated directly from the current source tree and should be
regenerated whenever routes, providers, or the `AuthProvider` redirect
logic change materially.

---


