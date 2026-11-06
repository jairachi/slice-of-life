import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'core/palette.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // reminder notifications (Android/iOS)
  runApp(const SolApp());
}

class SolApp extends StatelessWidget {
  const SolApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Slice of Life',
        debugShowCheckedModeBanner: false,
        // lets a mouse drag-scroll lists too (the web version on a desktop browser)
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus
          },
        ),
        // on wide screens (desktop browsers) keep the app a phone-sized column in the middle
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final w = math.min(mq.size.width, 520.0);
          return ColoredBox(
            color: cocoa,
            child: Center(
              // ClipRect: anything drawn past the column edge (rings, circles) stays out of the side margins
              child: SizedBox(
                  width: w,
                  child: ClipRect(
                      child: MediaQuery(
                          data: mq.copyWith(size: Size(w, mq.size.height)),
                          child: child!))),
            ),
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: coral,
              primary: coral,
              onPrimary: cream,
              surface: cream,
              onSurface: ink),
          scaffoldBackgroundColor: cream,
          dialogTheme: const DialogThemeData(
              backgroundColor: cream, surfaceTintColor: Colors.transparent),
          popupMenuTheme: const PopupMenuThemeData(
              color: cream, surfaceTintColor: Colors.transparent),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? coral : Colors.transparent),
            checkColor: const WidgetStatePropertyAll(cream),
            side: const BorderSide(color: ink, width: 2),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                foregroundColor: cream,
                backgroundColor: coral,
                side: const BorderSide(color: ink, width: 1.5)),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: ink, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: coral, width: 2)),
          ),
        ),
        home: const HomeScreen(),
      );
}
