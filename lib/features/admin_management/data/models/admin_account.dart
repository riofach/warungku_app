/// Admin account model for management
/// Represents an admin user stored in public.users table
class AdminAccount {
  final String id;
  final String email;
  final String? name;
  final String role;
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

  /// Create from Supabase JSON response
  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'admin',
      // HIGH-3 FIX: Handle null timestamps safely
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if user is owner
  bool get isOwner => role == 'owner';

  /// Get display name (name or email prefix)
  String get displayName => name ?? email.split('@').first;

  /// Get initials for avatar
  /// LOW-2 FIX: Handle empty string edge cases
  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final trimmedName = name!.trim();
      final parts = trimmedName.split(' ');
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return trimmedName[0].toUpperCase();
    }
    // Fallback to email initial, with empty check
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() => 'AdminAccount(id: $id, email: $email, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminAccount && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Create a copy with updated fields
  AdminAccount copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
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
