import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin user model for WarungKu
/// Represents an authenticated admin user
class AdminUser {
  final String id;
  final String email;
  final String? name;
  final String role;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  const AdminUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.createdAt,
    this.lastSignInAt,
  });

  /// Create AdminUser from Supabase User object
  factory AdminUser.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};
    
    return AdminUser(
      id: user.id,
      email: user.email ?? '',
      name: metadata['name'] as String?,
      role: metadata['role'] as String? ?? 'admin',
      createdAt: DateTime.parse(user.createdAt),
      lastSignInAt: user.lastSignInAt != null 
          ? DateTime.parse(user.lastSignInAt!) 
          : null,
    );
  }

  /// Create AdminUser from JSON (for API responses)
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'admin',
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignInAt: json['last_sign_in_at'] != null 
          ? DateTime.parse(json['last_sign_in_at'] as String) 
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
    };
  }

  /// Check if user is owner (can manage other admins)
  bool get isOwner => role == 'owner';

  /// Get display name (name or email)
  String get displayName => name ?? email.split('@').first;

  /// Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  String toString() => 'AdminUser(id: $id, email: $email, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
}
