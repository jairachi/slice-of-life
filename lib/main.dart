import 'package:flutter/material.dart';
import 'core/palette.dart';
import 'screens/home_screen.dart';

void main() => runApp(const SolApp());

class SolApp extends StatelessWidget {
  const SolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Slice of Life',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: coral, primary: coral, onPrimary: cream, surface: cream, onSurface: ink),
          scaffoldBackgroundColor: cream,
          dialogTheme: const DialogThemeData(backgroundColor: cream, surfaceTintColor: Colors.transparent),
          popupMenuTheme: const PopupMenuThemeData(color: cream, surfaceTintColor: Colors.transparent),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? coral : Colors.transparent),
            checkColor: const WidgetStatePropertyAll(cream),
            side: const BorderSide(color: ink, width: 2),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(foregroundColor: cream, backgroundColor: coral, side: const BorderSide(color: ink, width: 1.5)),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: ink, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: coral, width: 2)),
          ),
        ),
        home: const HomeScreen(),
      );
}
