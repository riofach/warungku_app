import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_role.dart';

/// Authenticated user model for warungku_app.
///
/// Naming kept as [AdminUser] for backwards compatibility with existing
/// callers; semantically represents any authenticated user (owner or kasir).
///
/// [role] is nullable — null means role has not yet been resolved from
/// public.users (loading state). Callers MUST default-deny on null
/// (treat as "no permissions yet").
class AdminUser {
  final String id;
  final String email;
  final String? name;
  final UserRole? role;
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

  /// Build from Supabase auth User. Role parsed from
  /// `user_metadata.role` — returns null when metadata is missing or carries
  /// an unknown role; caller fetches the authoritative role from
  /// `public.users` next.
  factory AdminUser.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};

    return AdminUser(
      id: user.id,
      email: user.email ?? '',
      name: metadata['name'] as String?,
      role: UserRole.fromString(metadata['role'] as String?),
      createdAt: DateTime.parse(user.createdAt),
      lastSignInAt: user.lastSignInAt != null
          ? DateTime.parse(user.lastSignInAt!)
          : null,
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role?.value,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
    };
  }

  /// True only when role is explicitly resolved to owner.
  /// Null role returns false (default-deny).
  bool get isOwner => role == UserRole.owner;

  /// True only when role is explicitly resolved to kasir.
  bool get isKasir => role == UserRole.kasir;

  /// True when role is still loading or unresolvable — used by UI to
  /// suppress owner-only affordances during the resolution window.
  bool get isRoleUnknown => role == null;

  String get displayName => name ?? email.split('@').first;

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  String toString() => 'AdminUser(id: $id, email: $email, role: ${role?.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    bool clearRole = false,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: clearRole ? null : (role ?? this.role),
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
}
