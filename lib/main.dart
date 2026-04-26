import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TechCareApp());
}

class TechCareApp extends StatelessWidget {
  const TechCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthService(),
      child: BlocProvider(
        create: (context) => AuthBloc(context.read<AuthService>()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Center(child: Text("Home Page"))),
          },
        ),
      ),
    );
  }
}