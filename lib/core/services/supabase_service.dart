import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing Supabase connection
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase connection
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception(
        'Missing Supabase credentials. Please check your .env file.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true, // Set to false in production
    );

    debugPrint('✅ Supabase initialized successfully');
  }

  /// Get current authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Get Supabase storage bucket
  static SupabaseStorageClient get storage => client.storage;

  /// Upload image to storage
  static Future<String> uploadImage({
    required String bucket,
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    await storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType),
        );

    return storage.from(bucket).getPublicUrl(path);
  }
}
