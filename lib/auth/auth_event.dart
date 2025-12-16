part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
