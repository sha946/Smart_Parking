import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Simple admin check based on email
  static bool isAdmin(User user) {
    const adminEmails = [
      'admin@example.com',
      'admin@smartparking.com',
      'chaima@gmail.com',
    ]; // Add your admin emails
    return adminEmails.contains(user.email);
  }

  // Get user display name
  String? get userDisplayName => _auth.currentUser?.displayName;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Create user with display name
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Update display name if provided
      if (user != null && displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
        user = _auth.currentUser; // Get updated user data
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName}) async {
    if (displayName != null && displayName.isNotEmpty) {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
