import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;

  void startListening() {
    _sub ??= _auth.authStateChanges().listen((_) => notifyListeners());
  }

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  bool get isSignedIn => _auth.currentUser != null;

  String? get email => _auth.currentUser?.email;
  bool get isGuest => _extractGuestId(_auth.currentUser?.email) != null;
  String? get guestId => _extractGuestId(_auth.currentUser?.email);

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signInWithGuestId(String guestId) async {
    final email = _guestEmail(guestId);
    await signIn(email, guestId);
  }

  Future<String> continueAsGuest() async {
    final guestId = _generateGuestId();
    final email = _guestEmail(guestId);

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: guestId);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await signInWithGuestId(guestId);
      } else {
        rethrow;
      }
    }

    return guestId;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _guestEmail(String guestId) => 'guest-$guestId@guest.local';

  String _generateGuestId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String? _extractGuestId(String? email) {
    if (email == null) return null;
    const suffix = '@guest.local';
    if (!email.endsWith(suffix) || !email.startsWith('guest-')) return null;
    final withoutPrefix = email.replaceFirst('guest-', '');
    return withoutPrefix.substring(0, withoutPrefix.length - suffix.length);
  }
}
