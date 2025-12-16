import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight, serializable representation of the signed-in user.
class AuthUser extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String idToken;

  const AuthUser({
    required this.uid,
    required this.idToken,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  factory AuthUser.fromFirebase(User user, String token) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      idToken: token,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, idToken];
}
