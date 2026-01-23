// StateProvider moved to legacy.dart in Riverpod 3.x - acceptable for simple state
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';

/// Provider for POS search query
/// Simple StateProvider for the search text input
/// Used for real-time filtering as user types
final posSearchQueryProvider = StateProvider<String>((ref) => '');
