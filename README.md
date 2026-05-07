# Student Hub

A full-featured Flutter productivity app built for students. Manage tasks, take notes, track study sessions, browse media, and get AI-powered study help — all in one place, synced in real time via Firebase.

> Targets **Android** and **Web** (Chrome).

---

## Problem Statement

Students today face a fragmented academic life — deadlines are tracked on sticky notes, study materials are scattered across apps, and there is no single place to tie tasks, subjects, notes, and study habits together. Existing productivity tools are either too generic or too complex, and they rarely understand the specific rhythm of a student's day.

**Student Hub** was built to fill exactly that gap — a Flutter-based application that brings task management, subject organisation, note-taking, analytics, multimedia learning, and an AI chatbot together under one cohesive, authenticated experience backed by real-time cloud data.

---

## Features

### Authentication & Personalisation
- Email/Password sign-up and login via Firebase Authentication
- Home screen greets the user by name derived from their Firebase Auth email
- Drawer on every tab: user avatar, email, dark/light theme toggle, logout with confirmation dialog
- Theme preference persisted locally via SharedPreferences

### Task Management
- Create tasks with title, description, priority (High / Medium / Low), due date + time, subject link, and recurrence (None / Daily / Weekly)
- Quick date presets: Today, Tomorrow, Next Week
- Edit tasks in a pre-filled, dual-mode `AddTaskScreen`
- Task list grouped live into **Due Today**, **Upcoming**, and **Completed** via Firestore streams
- Live search (title + description) and priority filter chips
- Tap any task for a full-detail bottom sheet without leaving the screen
- `completedAt` timestamp recorded for analytics

### Subject Management
- Colour-coded subject cards with 8-colour swatch picker
- Live "N pending" badge on each card reflecting incomplete linked tasks
- Create, edit, and delete subjects — create/edit reuse a single dialog
- Swipe-to-delete support

### Notes
- Inline note creation with optional subject link
- Edit dialog with subject reassignment
- Pin notes — `isPinned` flag floats pinned notes to the top regardless of sort
- Copy any note to clipboard with one tap
- Three sort modes: Newest First / Oldest First / A → Z (all client-side)

### Analytics
- fl_chart bar chart of study time across the last 7 days
- Running study streak computed from sessions + completed tasks (looks back up to 30 days)
- Completed vs. pending task snapshot
- All queries scoped per authenticated user

### Study Timer
- Two modes in a tabbed layout: **Pomodoro**, **Alarm**, 
- Logs session duration to `study_sessions` collection on completion
- Optional subject link for per-subject analytics breakdown
- Alarm : Firestore persistence, watcher moved to HomeScreen (fires on any page), Web Audio beep, browser OS notifications, snooze/dismiss fixes

### Multimedia
- **Local tab**: pick audio/video files via file_picker; audio via just_audio, video via video_player
- **YouTube tab**: play any youtube video. youtube_player_iframe for proper web YouTube, Blob URL for local video, cross-platform VideoPickHelper
- Video metadata (title, URL, type, subject) saved to Firestore for later retrieval

### AI Study Chatbot
- Powered by OpenAI GPT-4o-mini
- API key stored in `lib/config/secrets.dart` (gitignored — never committed)

### Scientific Calculator
- Standard and scientific modes toggled by a switch
- Scientific mode: trigonometric, logarithmic, square root, and power functions

### Image Editor
- Brightness, contrast, rotation, scaling, flip (horizontal/vertical), grayscale
-  sample image, background isolate for Save
- Web-only download of processed images via `dart:html`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Auth | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore (real-time streams) |
| Fonts | Google Fonts — Poppins |
| Charts | fl_chart |
| YouTube | youtube_player_flutter |
| Audio | just_audio |
| Video | video_player |
| File Picker | file_picker |
| Animations | Lottie |
| AI | OpenAI API (GPT-4o-mini) |
| Theme persistence | shared_preferences |
| Image processing | image |

---

## Architecture

Student Hub uses a **Screen → Service → Model** layered architecture:

- **`lib/models/`** — Pure Dart data classes with `fromMap` / `toMap` / `copyWith`. All date fields use Firestore `Timestamp`.
- **`lib/services/`** — Firestore service classes. Each service scopes every query with `.where('userId', isEqualTo: _userId)` so no user's data is ever visible to another. Services return `Stream<List<T>>` for real-time UI or `Future<T>` for one-shot operations.
- **`lib/screens/`** — `StatefulWidget` screens that instantiate services directly. No external state management library (no Provider/Riverpod/Bloc).

Theme toggling is managed as a `StatefulWidget` callback (`toggleTheme`) passed down from `main.dart`. All `orderBy` clauses are intentionally omitted from Firestore queries — sorting is handled client-side in Dart to avoid composite index requirements.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0 (Dart ≥ 3.0)
- A Firebase project with **Email/Password** sign-in enabled
- An OpenAI API key (for the chatbot feature)

### 1. Clone & install

```bash
git clone https://github.com/sanika-deokule/student-hub.git
cd student-hub
flutter pub get
```

### 2. Firebase setup

The repo includes `lib/firebase_options.dart` pre-configured for the demo Firebase project.

To connect your **own** Firebase project:

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** under Authentication → Sign-in methods
3. Create a Firestore database (start in test mode)
4. Run FlutterFire CLI to regenerate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

**Recommended Firestore Security Rules:**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{collection}/{docId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
        && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### 3. Add your OpenAI API key

Create `lib/config/secrets.dart` (this file is in `.gitignore`):

```dart
const String openAiApiKey = 'sk-your-key-here';
```

### 4. Run

```bash
# Web (recommended for development)
flutter run -d chrome

# Android
flutter run -d android
```

---

## Project Structure

```
lib/
├── main.dart                   # App entry, theme setup, Firebase init
├── firebase_options.dart       # Firebase web config
├── config/
│   └── secrets.dart            # OpenAI API key (gitignored — create manually)
├── models/
│   ├── task_model.dart
│   ├── note_model.dart
│   ├── subject_model.dart
│   ├── video_model.dart
│   └── ...
├── services/
│   ├── auth_service.dart       # Firebase Auth wrapper
│   ├── task_service.dart
│   ├── note_service.dart
│   ├── subject_service.dart
│   ├── video_service.dart
│   └── analytics_service.dart
├── screens/
│   ├── splash_screen.dart      # Auth-aware routing (authStateChanges)
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart        # Root shell — NavigationBar with 5 tabs
│   ├── add_task_screen.dart    # Dual-mode create/edit
│   ├── task_list_screen.dart
│   ├── notes_screen.dart
│   ├── subject_list_screen.dart
│   ├── analytics_screen.dart
│   ├── time_picker_screen.dart
│   ├── multimedia_screen.dart
│   ├── chatbot_screen.dart
│   ├── calculator_screen.dart
│   └── image_transform_screen.dart
└── Widgets/
    ├── glass_card.dart          # Frosted-glass dashboard tile
    └── animated_background.dart # Animated gradient background
```

---

## Firestore Data Model

All documents include a `userId` field scoped to the authenticated user.

| Collection | Key Fields |
|---|---|
| `tasks` | title, description, deadline (Timestamp), priority, isCompleted, completedAt, subjectId, recurrence |
| `notes` | text, createdAt (Timestamp), subjectId, isPinned |
| `subjects` | name, description, color (hex string), createdAt |
| `study_sessions` | durationSeconds, createdAt (Timestamp), subjectId |
| `videos` | title, url, type (`youtube` / `local`), createdAt, subjectId |

---

## Development Commands

```bash
flutter run -d chrome        # Run on web
flutter run -d android       # Run on Android
flutter build apk --release  # Build release APK
flutter analyze              # Static analysis
flutter test                 # Run all tests
flutter pub get              # Install dependencies
```
