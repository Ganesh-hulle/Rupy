import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:morpheus/auth/auth_repository.dart';
import 'package:morpheus/auth/auth_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc that owns the splash-token check and user session state.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthLoading()) {
    on<AppStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<SignOutRequested>(_onSignOutRequested);

    _authSub = _repository.authChanges().listen(
      (user) => add(AuthUserChanged(user)),
    );
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _authSub;

  Future<void> _onStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.restoreSession();
      emit(
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      );
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
