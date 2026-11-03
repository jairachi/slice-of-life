import 'package:flutter/material.dart';

// Pitch deck palette
const coral = Color(0xFFFF4F5E);

const peach = Color(0xFFFFC09B);
const orange = Color(0xFFFF6B2C);
const sun = Color(0xFFFFD166);
const cream = Color(0xFFFFEEDA);
const ink = Color(0xFF1A1A1D);
const cocoa = Color(0xFF3B2A2C);
const lightOrange = Color(0xFFFFA86A); // the pitch deck's ring orange (sampled from the PDF)

/// Pixel "game" font (Silkscreen, bundled in assets/fonts): title, headers,
/// level/XP numbers, task XP and category.
TextStyle pixel(double size, Color color, {double height = 1.3, FontWeight weight = FontWeight.w400, TextDecoration? decoration, Color? decorationColor}) =>
    TextStyle(fontFamily: 'Silkscreen', fontSize: size, color: color, height: height, fontWeight: weight, decoration: decoration, decorationColor: decorationColor);
