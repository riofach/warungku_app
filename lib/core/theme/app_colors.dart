import 'package:flutter/material.dart';

/// Color palette for WarungKu Digital
/// Shared tokens between Flutter and Laravel (Tailwind)
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF60A5FA); // Blue-400
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700

  // Secondary Colors
  static const Color secondary = Color(0xFF10B981); // Emerald-500
  static const Color secondaryLight = Color(0xFF34D399); // Emerald-400
  static const Color secondaryDark = Color(0xFF059669); // Emerald-600

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successLight = Color(0xFF34D399); // Emerald-400
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFBBF24); // Amber-400
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0x80EF4444); // Red-500 with 50% opacity
  static const Color info = Color(0xFF3B82F6); // Blue-500

  // Neutral Colors
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color background = Color(0xFFF1F5F9); // Slate-100
  static const Color backgroundDark = Color(0xFFE2E8F0); // Slate-200

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate-400
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // Border Colors
  static const Color border = Color(0xFFE2E8F0); // Slate-200
  static const Color borderLight = Color(0xFFF1F5F9); // Slate-100

  // Stock Status Colors
  static const Color stockSafe = Color(0xFF10B981); // Green
  static const Color stockWarning = Color(0xFFF59E0B); // Yellow/Amber
  static const Color stockCritical = Color(0xFFEF4444); // Red

  // Order Status Colors
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusPaid = Color(0xFF10B981); // Green
  static const Color statusProcessing = Color(0xFF3B82F6); // Blue
  static const Color statusCompleted = Color(0xFF10B981); // Green
  static const Color statusCancelled = Color(0xFFEF4444); // Red
}
