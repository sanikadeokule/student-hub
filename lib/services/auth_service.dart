import 'package:firebase_auth/firebase_auth.dart';

/// 🔐 Authentication Service wrapping FirebaseAuth
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📡 Stream of auth state changes (for reactive UI / auto-login)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 👤 Get currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// 📝 Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  /// 🔑 Log in with email and password
  Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// 🚪 Log out current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// ⚠️ Convert FirebaseAuthException to user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak (min 6 characters).';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
