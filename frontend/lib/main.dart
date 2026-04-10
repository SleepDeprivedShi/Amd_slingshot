import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/firebase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try initializing Firebase, but catch errors if not configured yet (Hackathon mode)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase not configured. Running in Mock Mode. Run 'flutterfire configure' later.");
    FirebaseService.isMockMode = true;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirebaseService()),
      ],
      child: const NutriLensApp(),
    ),
  );
}

class NutriLensApp extends StatelessWidget {
  const NutriLensApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: Consumer<FirebaseService>(
        builder: (context, authService, _) {
          return authService.isAuthenticated ? const MainNavigation() : const AuthScreen();
        },
      ),
    );
  }
}
