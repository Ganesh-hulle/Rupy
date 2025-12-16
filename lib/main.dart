import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/auth/auth_bloc.dart';
import 'package:morpheus/auth/auth_repository.dart';
import 'package:morpheus/navigation_bar.dart';
import 'package:morpheus/services/auth_service.dart';
import 'package:morpheus/splash_page.dart';
import 'package:morpheus/theme/app_theme.dart';

import 'firebase_options.dart'; // created by flutterfire configure
import 'signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService.initializeGoogle(
    serverClientId:
        "842775331840-gsso7qkcb8mmi0sj97b63upejevbku48.apps.googleusercontent.com",
    clientId: (Platform.isIOS || Platform.isMacOS)
        ? "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com"
        : null,
  );

  final authRepository = AuthRepository();
  runApp(MorpheusApp(authRepository: authRepository));
}

class MorpheusApp extends StatelessWidget {
  const MorpheusApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository)..add(const AppStarted()),
        child: MaterialApp(
          title: 'Morpheus',
          theme: AppTheme.light(),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return SplashPage(
            message: state.message,
            onRetry: () => context.read<AuthBloc>().add(const AppStarted()),
          );
        }

        if (state is AuthAuthenticated) {
          return const AppNavShell();
        }

        if (state is AuthFailure) {
          return SplashPage(
            message: state.message,
            onRetry: () => context.read<AuthBloc>().add(const AppStarted()),
          );
        }

        return const SignUpPage();
      },
    );
  }
}
