import '../../../auth/data/models/user_role.dart';

/// Admin account model used by the account-management screen.
///
/// Represents a row in `public.users`. Distinct from [AdminUser] (which is
/// the *currently authenticated* user) because this is used in lists where
/// roles, emails, and timestamps of OTHER users are shown.
class AdminAccount {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminAccount({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      // DB check constraint enforces 'owner' | 'kasir'. Defensive fallback
      // to kasir if a legacy row sneaks through (least-privilege default).
      role: UserRole.fromString(json['role'] as String?) ?? UserRole.kasir,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOwner => role == UserRole.owner;
  bool get isKasir => role == UserRole.kasir;

  String get displayName => name ?? email.split('@').first;

  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final trimmedName = name!.trim();
      final parts = trimmedName.split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return trimmedName[0].toUpperCase();
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() => 'AdminAccount(id: $id, email: $email, role: ${role.value})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  AdminAccount copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
