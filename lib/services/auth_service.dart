import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.disconnect();
  }

  User? get currentUser => _auth.currentUser;
}
