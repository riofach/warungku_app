// StateProvider moved to legacy.dart in Riverpod 3.x - acceptable for simple state
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';

/// Provider for POS category filter
/// Stores the currently selected category ID for filtering
/// null means "All categories" (Semua)
final posCategoryFilterProvider = StateProvider<String?>((ref) => null);
