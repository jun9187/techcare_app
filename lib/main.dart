import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const TechCareApp());
}

class TechCareApp extends StatelessWidget {
  const TechCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthService(),
      child: BlocProvider(
        create: (context) => AuthBloc(RepositoryProvider.of<AuthService>(context)),
        child: MaterialApp(
          title: 'TechCare',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF800000),
          ),
          home: LoginScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/home': (context) => const ProfileScreen(), // Redirecting home to profile for now
          },
        ),
      ),
    );
  }
}
