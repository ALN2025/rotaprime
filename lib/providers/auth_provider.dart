import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rota_prime/providers/conta_provider.dart';
import 'package:rota_prime/providers/map_settings_provider.dart';
import 'package:rota_prime/providers/rota_provider.dart';
import 'package:rota_prime/services/auth_service.dart';
import 'package:rota_prime/services/user_prefs_service.dart';

class AuthState {
  const AuthState({
    this.user,
    this.loading = false,
    this.error,
  });

  final AuthUser? user;
  final bool loading;
  final String? error;

  bool get isSignedIn => user != null;

  AuthState copyWith({AuthUser? user, bool? loading, String? error, bool clearError = false}) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;
  final _auth = AuthService();
  final _prefs = UserPrefsService();

  Future<void> restoreSession() async {
    state = state.copyWith(loading: true, clearError: true);
    final user = await _auth.signInSilently();
    state = AuthState(user: user, loading: false);
    if (user != null) {
      await _applySavedPrefs(user.email);
      _ref.invalidate(contaRotasProvider);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(loading: true, clearError: true);
    final user = await _auth.signIn();
    if (user == null) {
      state = state.copyWith(loading: false, error: 'Login cancelado ou indisponível');
      return;
    }
    state = AuthState(user: user, loading: false);
    await _applySavedPrefs(user.email);
    _ref.invalidate(contaRotasProvider);
  }

  Future<void> signOut() async {
    final email = state.user?.email;
    if (email != null) {
      await _persistCurrentPrefs(email);
    }
    await _auth.signOut();
    state = const AuthState();
    _ref.invalidate(contaRotasProvider);
  }

  Future<void> _applySavedPrefs(String email) async {
    final json = await _prefs.load(email);
    if (json == null) return;
    _ref.read(mapSettingsProvider.notifier).applyFromStorage(
          _prefs.mapSettingsFromJson(json),
        );
    final cols = json['selectedColumns'];
    if (cols is List) {
      final set = cols.map((e) => e.toString()).toSet();
      _ref.read(rotaProvider.notifier).applySelectedColumns(set);
    }
    final gps = json['useGpsOrigin'];
    if (gps is bool) {
      _ref.read(rotaProvider.notifier).setUseGpsOrigin(gps);
    }
  }

  Future<void> persistForCurrentUser() async {
    final email = state.user?.email;
    if (email == null) return;
    await _persistCurrentPrefs(email);
  }

  Future<void> _persistCurrentPrefs(String email) async {
    final map = _ref.read(mapSettingsProvider);
    final rota = _ref.read(rotaProvider);
    final data = _prefs.mapSettingsToJson(map)
      ..['selectedColumns'] = rota.selectedColumns.toList()
      ..['useGpsOrigin'] = rota.useGpsOrigin;
    await _prefs.save(email, data);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
