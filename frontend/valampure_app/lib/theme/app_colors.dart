import 'package:flutter/material.dart';

// USE: Centralized color palette for Valampure ERP.
// WHEN: Used across all widgets to maintain a consistent brand identity.
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(
    0xFF2C3E50,
  ); // Deep Slate (Professional & Grounded)
  static const Color accent = Color(
    0xFF3498DB,
  ); // Bright Blue (Action items/Buttons)

  // Backgrounds (Crucial for Desktop/Laptop view)
  static const Color background = Color(
    0xFFF8F9FA,
  ); // Very Light Grey (Reduces eye strain)
  static const Color surface = Colors.white; // Card/Table backgrounds

  // Status Colors (For ERP logic)
  static const Color success = Color(0xFF27AE60); // Paid Bills / Stock In
  static const Color warning = Color(
    0xFFF39C12,
  ); // Pending / Expiry approaching
  static const Color error = Color(
    0xFFE74C3C,
  ); // Overdue / Deleted / Account Blocked

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436); // Main headings
  static const Color textSecondary = Color(0xFF636E72); // Labels and subtitles
}
