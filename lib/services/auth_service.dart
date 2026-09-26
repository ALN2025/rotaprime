import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class AuthService {
  AuthService() : _google = GoogleSignIn(scopes: const ['email', 'profile']);

  final GoogleSignIn _google;

  Future<AuthUser?> signInSilently() async {
    try {
      final account = await _google.signInSilently();
      return _map(account);
    } catch (_) {
      return null;
    }
  }

  Future<AuthUser?> signIn() async {
    try {
      final account = await _google.signIn();
      return _map(account);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() => _google.signOut();

  AuthUser? _map(GoogleSignInAccount? account) {
    if (account == null) return null;
    return AuthUser(
      id: account.id,
      displayName: account.displayName?.trim().isNotEmpty == true
          ? account.displayName!.trim()
          : account.email.split('@').first,
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }
}
