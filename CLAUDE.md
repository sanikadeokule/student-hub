# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (web)
flutter run -d chrome

# Run the app (Android)
flutter run -d android

# Build APK
flutter build apk --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Get dependencies
flutter pub get
```

## Architecture Overview

**Student Companion** is a Flutter productivity app for students, backed by Firebase Auth + Cloud Firestore. The app targets Android and Web.

### Entry Point & Theme
`lib/main.dart` initializes Firebase, reads a `isDarkMode` preference from `SharedPreferences`, and mounts `StudentHubApp`. Theme toggling is managed as a `StatefulWidget` callback (`toggleTheme`) passed down the widget tree — it is **not** managed by a state management package (no Provider/Riverpod/Bloc). Dark/light preference is persisted via `SharedPreferences`.

### Navigation Structure
`HomeScreen` (in `home_screen.dart`) is the root shell. It holds a `NavigationBar` with five tabs: Home (Dashboard), Media, Timer, Notes, Subjects. The `DashboardScreen` (nested inside `home_screen.dart`) renders a 2-column grid of `GlassCard` tiles that push to full screens via `Navigator.push`. The `AppBar` greets the user by name derived from the Firebase Auth email.

### Screen–Service–Model Pattern
Every feature follows the same structure:
- `lib/models/` — pure Dart data classes with `fromMap` / `toMap` / `copyWith`. All models use Firestore `Timestamp` for date fields.
- `lib/services/` — Firestore service classes. Each service gets the current user's UID via `FirebaseAuth.instance.currentUser?.uid` and scopes all queries with `.where('userId', isEqualTo: _userId)`. Services expose either `Stream<List<T>>` (for real-time UI) or `Future<T>` (for one-shot operations).
- `lib/screens/` — StatefulWidget screens that instantiate services directly (no DI container).

### Firestore Collections
| Collection | Model | Key fields |
|---|---|---|
| `tasks` | `TaskModel` | title, description, deadline (Timestamp), priority (string), isCompleted, completedAt, subjectId, recurrence, userId |
| `notes` | `NoteModel` | text, createdAt, subjectId, isPinned, userId |
| `subjects` | `SubjectModel` | name, description, color (hex string), createdAt, userId |
| `study_sessions` | `StudySessionModel` | durationSeconds, createdAt, subjectId, userId |
| `videos` | `VideoModel` | title, url, type ('youtube'/'local'), createdAt, subjectId |
| `alarms` | `AlarmModel` | name, dateTime (Timestamp), isActive, hasFired, userId |

**Important:** `orderBy` is intentionally omitted from most Firestore queries in `task_service.dart`, `note_service.dart`, and `subject_service.dart` to avoid composite index requirements. All sorting is done client-side in Dart.

### Key Screens
- `add_task_screen.dart` — dual-mode create/edit screen. Pass `existingTask: TaskModel` to enter edit mode; null = create mode.
- `task_list_screen.dart` — real-time StreamBuilder list with live search, priority filter chips, grouping into Due Today / Upcoming / Completed, and task detail bottom sheet.
- `notes_screen.dart` — inline add, edit dialog, pin toggle, copy-to-clipboard, three sort modes, subject filter.
- `subject_list_screen.dart` — reuses a single `_showSubjectDialog` for both create and edit; shows pending task count badge per card.
- `analytics_screen.dart` — fl_chart bar chart for last 7 days' study time; study streak computed from combined study_sessions + completed tasks.
- `time_picker_screen.dart` — three-tab screen (Pomodoro / Stopwatch / Countdown) that calls `AnalyticsService.logStudySession` on completion.
- `multimedia_screen.dart` — tabbed: YouTube (youtube_player_flutter) + local audio/video (just_audio / video_player).
- `chatbot_screen.dart` — calls OpenAI GPT-4o-mini. API key loaded from `lib/config/secrets.dart` (gitignored).
- `image_transform_screen.dart` — client-side image manipulation (brightness, contrast, rotation, flip, grayscale) using the `image` package; web-only download via `dart:html`.

### Shared Widgets
`lib/Widgets/glass_card.dart` — frosted-glass card used on the dashboard grid, takes a `Color` and `child`.  
`lib/Widgets/animated_background.dart` — animated gradient background used behind the dashboard.

### API Key
`lib/config/secrets.dart` exports `openAiApiKey`. This file is in `.gitignore` and must be created manually when setting up locally:
```dart
const String openAiApiKey = 'sk-...';
```
