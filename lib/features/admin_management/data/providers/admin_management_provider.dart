import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_account.dart';
import '../repositories/admin_management_repository.dart';

/// Provider for AdminManagementRepository
final adminManagementRepositoryProvider = Provider<AdminManagementRepository>((ref) {
  return AdminManagementRepository();
});

/// State for admin management
enum AdminListStatus {
  initial,
  loading,
  loaded,
  error,
}

class AdminListState {
  final AdminListStatus status;
  final List<AdminAccount> admins;
  final String? errorMessage;

  const AdminListState({
    required this.status,
    required this.admins,
    this.errorMessage,
  });

  factory AdminListState.initial() => const AdminListState(
        status: AdminListStatus.initial,
        admins: [],
      );

  factory AdminListState.loading() => const AdminListState(
        status: AdminListStatus.loading,
        admins: [],
      );

  factory AdminListState.loaded(List<AdminAccount> admins) => AdminListState(
        status: AdminListStatus.loaded,
        admins: admins,
      );

  factory AdminListState.error(String message) => AdminListState(
        status: AdminListStatus.error,
        admins: [],
        errorMessage: message,
      );

  bool get isLoading => status == AdminListStatus.loading;
  bool get hasError => status == AdminListStatus.error;
  bool get isEmpty => status == AdminListStatus.loaded && admins.isEmpty;
}

/// State for create admin form
enum CreateAdminStatus {
  initial,
  loading,
  success,
  error,
}

class CreateAdminState {
  final CreateAdminStatus status;
  final String? errorMessage;

  const CreateAdminState({
    required this.status,
    this.errorMessage,
  });

  factory CreateAdminState.initial() => const CreateAdminState(
        status: CreateAdminStatus.initial,
      );

  factory CreateAdminState.loading() => const CreateAdminState(
        status: CreateAdminStatus.loading,
      );

  factory CreateAdminState.success() => const CreateAdminState(
        status: CreateAdminStatus.success,
      );

  factory CreateAdminState.error(String message) => CreateAdminState(
        status: CreateAdminStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == CreateAdminStatus.loading;
  bool get hasError => status == CreateAdminStatus.error;
  bool get isSuccess => status == CreateAdminStatus.success;
}

/// Generic action state for update password and delete admin
enum AdminActionStatus {
  initial,
  loading,
  success,
  error,
}

class AdminActionState {
  final AdminActionStatus status;
  final String? successMessage;
  final String? errorMessage;

  const AdminActionState({
    required this.status,
    this.successMessage,
    this.errorMessage,
  });

  factory AdminActionState.initial() => const AdminActionState(
        status: AdminActionStatus.initial,
      );

  factory AdminActionState.loading() => const AdminActionState(
        status: AdminActionStatus.loading,
      );

  factory AdminActionState.success(String message) => AdminActionState(
        status: AdminActionStatus.success,
        successMessage: message,
      );

  factory AdminActionState.error(String message) => AdminActionState(
        status: AdminActionStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == AdminActionStatus.loading;
  bool get hasError => status == AdminActionStatus.error;
  bool get isSuccess => status == AdminActionStatus.success;
}

/// Notifier for admin list
class AdminListNotifier extends Notifier<AdminListState> {
  @override
  AdminListState build() {
    return AdminListState.initial();
  }

  /// Load all admins
  Future<void> loadAdmins() async {
    state = AdminListState.loading();

    try {
      final repository = ref.read(adminManagementRepositoryProvider);
      final admins = await repository.getAdmins();
      state = AdminListState.loaded(admins);
    } catch (e) {
      state = AdminListState.error(e.toString());
    }
  }

  /// Refresh admin list
  Future<void> refresh() async {
    await loadAdmins();
  }
}

/// Notifier for create admin
class CreateAdminNotifier extends Notifier<CreateAdminState> {
  @override
  CreateAdminState build() {
    return CreateAdminState.initial();
  }

  /// Create new admin
  Future<bool> createAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    state = CreateAdminState.loading();

    final repository = ref.read(adminManagementRepositoryProvider);
    final result = await repository.createAdmin(
      email: email,
      password: password,
      name: name,
    );

    if (result.success) {
      state = CreateAdminState.success();
      // Refresh admin list
      ref.read(adminListNotifierProvider.notifier).refresh();
      return true;
    } else {
      state = CreateAdminState.error(result.errorMessage ?? 'Gagal membuat admin');
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = CreateAdminState.initial();
  }
}

/// Notifier for update password action
class UpdatePasswordNotifier extends Notifier<AdminActionState> {
  @override
  AdminActionState build() {
    return AdminActionState.initial();
  }

  /// Update admin password
  Future<bool> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    state = AdminActionState.loading();

    final repository = ref.read(adminManagementRepositoryProvider);
    final result = await repository.updateAdminPassword(
      userId: userId,
      newPassword: newPassword,
    );

    if (result.success) {
      state = AdminActionState.success(result.successMessage ?? 'Password berhasil diubah');
      return true;
    } else {
      state = AdminActionState.error(result.errorMessage ?? 'Gagal mengubah password');
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = AdminActionState.initial();
  }
}

/// Notifier for delete admin action
class DeleteAdminNotifier extends Notifier<AdminActionState> {
  @override
  AdminActionState build() {
    return AdminActionState.initial();
  }

  /// Delete admin
  Future<bool> deleteAdmin({
    required String userId,
  }) async {
    state = AdminActionState.loading();

    final repository = ref.read(adminManagementRepositoryProvider);
    final result = await repository.deleteAdmin(userId: userId);

    if (result.success) {
      state = AdminActionState.success(result.successMessage ?? 'Admin berhasil dihapus');
      // Refresh admin list
      ref.read(adminListNotifierProvider.notifier).refresh();
      return true;
    } else {
      state = AdminActionState.error(result.errorMessage ?? 'Gagal menghapus admin');
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = AdminActionState.initial();
  }
}

/// Providers
final adminListNotifierProvider = NotifierProvider<AdminListNotifier, AdminListState>(() {
  return AdminListNotifier();
});

final createAdminNotifierProvider = NotifierProvider<CreateAdminNotifier, CreateAdminState>(() {
  return CreateAdminNotifier();
});

final updatePasswordNotifierProvider = NotifierProvider<UpdatePasswordNotifier, AdminActionState>(() {
  return UpdatePasswordNotifier();
});

final deleteAdminNotifierProvider = NotifierProvider<DeleteAdminNotifier, AdminActionState>(() {
  return DeleteAdminNotifier();
});
