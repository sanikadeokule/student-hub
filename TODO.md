# Firebase Email/Password Authentication Implementation Plan

## Information Gathered
- Firebase (`firebase_core`) is already initialized in `main.dart` with `DefaultFirebaseOptions.web`.
- `pubspec.yaml` does **not** yet include `firebase_auth`.
- `SplashScreen` currently hard-codes a 3-second delay then pushes `HomeScreen`.
- `HomeScreen` / `DashboardScreen` has no user profile display or logout mechanism.
- Project follows a clean modular structure (`services/`, `screens/`, `models/`).

---

## Plan

### Step 1: Add Dependency
- **File:** `pubspec.yaml`
- **Action:** Add `firebase_auth: ^5.5.2` under `dependencies`.

### Step 2: Create AuthService
- **File:** `lib/services/auth_service.dart` *(new)*
- **Action:** Create a clean `AuthService` class wrapping `FirebaseAuth.instance` with:
  - `signUp(email, password)`
  - `login(email, password)`
  - `logout()`
  - `User? get currentUser`
  - `Stream<User?> authStateChanges()` (for reactive auto-login)

### Step 3: Create Login Screen
- **File:** `lib/screens/login_screen.dart` *(new)*
- **Action:** Build Material Design login UI:
  - Email & Password `TextFormField`s (with validation)
  - Login button calling `AuthService.login()`
  - Link to navigate to `SignupScreen`
  - `SnackBar` error handling for invalid credentials / network errors

### Step 4: Create Signup Screen
- **File:** `lib/screens/signup_screen.dart` *(new)*
- **Action:** Build Material Design signup UI:
  - Email & Password `TextFormField`s (with validation)
  - Signup button calling `AuthService.signUp()`
  - Link to navigate back to `LoginScreen`
  - `SnackBar` error handling for weak password / email-in-use

### Step 5: Update SplashScreen for Auth Routing
- **File:** `lib/screens/splash_screen.dart` *(edit)*
- **Action:** Replace hard-coded 3-second `Navigator.pushReplacement` with a listener on `FirebaseAuth.instance.authStateChanges()`.
  - If `user != null` → `HomeScreen`
  - If `user == null` → `LoginScreen`

### Step 6: Update HomeScreen with Logout & User Info
- **File:** `lib/screens/home_screen.dart` *(edit)*
- **Action:**
  - Add an `AppBar` (or menu) in `DashboardScreen` showing the current user's email.
  - Add a **Logout** button that calls `AuthService.logout()`.
  - On logout, the auth stream will automatically redirect to `LoginScreen`.

### Step 7: Run `flutter pub get`
- **Action:** Install the new `firebase_auth` package.

---

## Dependent Files to Edit
1. `pubspec.yaml`
2. `lib/services/auth_service.dart` *(new)*
3. `lib/screens/login_screen.dart` *(new)*
4. `lib/screens/signup_screen.dart` *(new)*
5. `lib/screens/splash_screen.dart` *(edit)*
6. `lib/screens/home_screen.dart` *(edit)*

---

## Follow-up Steps
- Ensure **Email/Password** sign-in provider is enabled in the Firebase Console for project `student-companion-899d7`.
- Test signup → auto-login → home screen → logout → login flow.
- Verify error SnackBars appear for invalid credentials.

