import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/theme_bloc/theme_bloc.dart';
import 'theme/medical_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedScribeApp());
}

class MedScribeApp extends StatelessWidget {
  const MedScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. INJECT THE BLOC AT THE TOP LEVEL
    return BlocProvider(
      create: (context) => ThemeBloc()..add(LoadTheme()),

      // 2. LISTEN TO STATE CHANGES
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'MedScribe Pro',
            debugShowCheckedModeBanner: false,

            // 3. CONNECT THE THEMES
            theme: MedicalTheme.lightTheme,
            darkTheme: MedicalTheme.darkTheme,

            // 4. DYNAMICALLY SWITCH MODE
            themeMode: state.themeMode,

            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
