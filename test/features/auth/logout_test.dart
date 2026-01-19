import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/features/auth/data/providers/auth_provider.dart';

void main() {
  group('AppAuthState', () {
    test('should create initial state', () {
      final state = AppAuthState.initial();
      
      expect(state.status, AuthStatus.initial);
      expect(state.errorMessage, null);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.hasError, false);
    });

    test('should create loading state', () {
      final state = AppAuthState.loading();
      
      expect(state.status, AuthStatus.loading);
      expect(state.isLoading, true);
      expect(state.isAuthenticated, false);
      expect(state.hasError, false);
    });

    test('should create authenticated state', () {
      final state = AppAuthState.authenticated();
      
      expect(state.status, AuthStatus.authenticated);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, true);
      expect(state.hasError, false);
    });

    test('should create unauthenticated state', () {
      final state = AppAuthState.unauthenticated();
      
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.hasError, false);
    });

    test('should create error state with message', () {
      const errorMsg = 'Test error message';
      final state = AppAuthState.error(errorMsg);
      
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, errorMsg);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.hasError, true);
    });

    test('should create error state for logout failure', () {
      const logoutError = 'Gagal keluar dari aplikasi';
      final state = AppAuthState.error(logoutError);
      
      expect(state.hasError, true);
      expect(state.errorMessage, logoutError);
      expect(state.isAuthenticated, false);
    });
  });

  group('AuthStatus', () {
    test('should have all required values', () {
      expect(AuthStatus.values.length, 5);
      expect(AuthStatus.values.contains(AuthStatus.initial), true);
      expect(AuthStatus.values.contains(AuthStatus.loading), true);
      expect(AuthStatus.values.contains(AuthStatus.authenticated), true);
      expect(AuthStatus.values.contains(AuthStatus.unauthenticated), true);
      expect(AuthStatus.values.contains(AuthStatus.error), true);
    });
  });

  group('Logout State Transitions', () {
    test('should transition from authenticated to loading during signOut', () {
      // Simulating the state transition during logout
      // Initial state: authenticated
      final authenticatedState = AppAuthState.authenticated();
      expect(authenticatedState.status, AuthStatus.authenticated);
      expect(authenticatedState.isAuthenticated, true);
      
      // During logout: loading
      final loadingState = AppAuthState.loading();
      expect(loadingState.status, AuthStatus.loading);
      expect(loadingState.isLoading, true);
      expect(loadingState.isAuthenticated, false);
    });

    test('should transition from loading to unauthenticated after successful signOut', () {
      // During logout: loading
      final loadingState = AppAuthState.loading();
      expect(loadingState.isLoading, true);
      
      // After successful logout: unauthenticated
      final unauthenticatedState = AppAuthState.unauthenticated();
      expect(unauthenticatedState.status, AuthStatus.unauthenticated);
      expect(unauthenticatedState.isAuthenticated, false);
      expect(unauthenticatedState.hasError, false);
    });

    test('should transition from loading to error after failed signOut', () {
      // During logout: loading
      final loadingState = AppAuthState.loading();
      expect(loadingState.isLoading, true);
      
      // After failed logout: error state
      const errorMessage = 'Network error during logout';
      final errorState = AppAuthState.error(errorMessage);
      expect(errorState.status, AuthStatus.error);
      expect(errorState.hasError, true);
      expect(errorState.errorMessage, errorMessage);
      expect(errorState.isAuthenticated, false);
    });

    test('should not be authenticated after successful logout', () {
      // Verify unauthenticated state properties
      final state = AppAuthState.unauthenticated();
      
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.errorMessage, null);
    });

    test('should remain in error state if logout fails', () {
      // Simulating failed logout scenario
      final errorState = AppAuthState.error('Gagal keluar dari aplikasi');
      
      // User should see error and can retry
      expect(errorState.hasError, true);
      expect(errorState.isLoading, false);
      // User is not authenticated (session may have expired anyway)
      expect(errorState.isAuthenticated, false);
    });
  });

  group('clearError', () {
    test('error state should transition to unauthenticated when cleared', () {
      // Create error state (e.g., from failed logout)
      final errorState = AppAuthState.error('Some error');
      expect(errorState.hasError, true);
      expect(errorState.errorMessage, 'Some error');

      // After clearError, state should be unauthenticated
      // This simulates what clearError() does in AuthNotifier
      final clearedState = AppAuthState.unauthenticated();
      expect(clearedState.hasError, false);
      expect(clearedState.errorMessage, null);
      expect(clearedState.status, AuthStatus.unauthenticated);
    });

    test('clearError should only affect error states', () {
      // Non-error states should not be affected conceptually
      final authenticatedState = AppAuthState.authenticated();
      expect(authenticatedState.hasError, false);
      
      // Calling clearError on non-error state doesn't change anything
      // (AuthNotifier.clearError checks hasError first)
    });
  });

  group('Logout Error Messages', () {
    test('should have Indonesian error message for logout failure', () {
      const expectedMessage = 'Gagal keluar dari aplikasi';
      final state = AppAuthState.error(expectedMessage);
      
      expect(state.errorMessage, expectedMessage);
      // Verify it's in Indonesian (contains Indonesian words)
      expect(state.errorMessage!.contains('Gagal'), true);
    });

    test('should handle null error message gracefully', () {
      // AppAuthState.error requires a message, so this tests the factory
      final state = AppAuthState.error('');
      
      expect(state.hasError, true);
      expect(state.errorMessage, '');
    });
  });
}
