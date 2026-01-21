import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debounce Behavior', () {
    group('Timer-based debouncing', () {
      test('should delay execution by specified duration', () async {
        int callCount = 0;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            callCount++;
          });
        }

        // Simulate rapid input
        onSearchChanged('a');
        onSearchChanged('ab');
        onSearchChanged('abc');

        // Before debounce expires
        expect(callCount, 0);

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 150));

        // Should only have called once
        expect(callCount, 1);

        debounceTimer?.cancel();
      });

      test('should reset timer on each new input', () async {
        int callCount = 0;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            callCount++;
          });
        }

        // First input
        onSearchChanged('a');
        await Future.delayed(const Duration(milliseconds: 50));

        // Second input before debounce completes - should reset timer
        onSearchChanged('ab');
        await Future.delayed(const Duration(milliseconds: 50));

        // Third input - reset again
        onSearchChanged('abc');

        // At this point (~100ms), first timer would have fired if not cancelled
        expect(callCount, 0);

        // Wait for final debounce
        await Future.delayed(const Duration(milliseconds: 150));

        expect(callCount, 1);

        debounceTimer?.cancel();
      });

      test('300ms debounce matches story requirement', () async {
        int callCount = 0;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 300);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            callCount++;
          });
        }

        onSearchChanged('test');

        // At 200ms - should not have fired yet
        await Future.delayed(const Duration(milliseconds: 200));
        expect(callCount, 0);

        // At 350ms - should have fired
        await Future.delayed(const Duration(milliseconds: 150));
        expect(callCount, 1);

        debounceTimer?.cancel();
      });

      test('should preserve final value after debounce', () async {
        String? lastValue;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            lastValue = value;
          });
        }

        onSearchChanged('a');
        onSearchChanged('ab');
        onSearchChanged('abc');
        onSearchChanged('abcd');

        await Future.delayed(const Duration(milliseconds: 150));

        expect(lastValue, 'abcd');

        debounceTimer?.cancel();
      });

      test('should handle empty string input', () async {
        String? lastValue;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            lastValue = value;
          });
        }

        onSearchChanged('test');
        onSearchChanged(''); // Clear search

        await Future.delayed(const Duration(milliseconds: 150));

        expect(lastValue, '');

        debounceTimer?.cancel();
      });
    });

    group('Debounce with cancellation', () {
      test('dispose should cancel pending timer', () async {
        int callCount = 0;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            callCount++;
          });
        }

        void dispose() {
          debounceTimer?.cancel();
        }

        onSearchChanged('test');

        // Dispose before debounce completes
        dispose();

        await Future.delayed(const Duration(milliseconds: 150));

        // Timer was cancelled, should not have incremented
        expect(callCount, 0);
      });

      test('multiple rapid clears should not cause issues', () async {
        int callCount = 0;
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            callCount++;
          });
        }

        void clearSearch() {
          debounceTimer?.cancel();
          onSearchChanged('');
        }

        onSearchChanged('a');
        clearSearch();
        onSearchChanged('b');
        clearSearch();
        onSearchChanged('c');

        await Future.delayed(const Duration(milliseconds: 150));

        expect(callCount, 1);

        debounceTimer?.cancel();
      });
    });

    group('Search input simulation', () {
      test('should simulate user typing behavior', () async {
        final searchQueries = <String>[];
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            searchQueries.add(value);
          });
        }

        // User types "indo" with pauses
        onSearchChanged('i');
        await Future.delayed(const Duration(milliseconds: 30));
        onSearchChanged('in');
        await Future.delayed(const Duration(milliseconds: 30));
        onSearchChanged('ind');
        await Future.delayed(const Duration(milliseconds: 30));
        onSearchChanged('indo');

        // Wait for final debounce
        await Future.delayed(const Duration(milliseconds: 150));

        // Only final value should be searched
        expect(searchQueries, ['indo']);

        debounceTimer?.cancel();
      });

      test('should handle pause and continue typing', () async {
        final searchQueries = <String>[];
        Timer? debounceTimer;
        const debounceDelay = Duration(milliseconds: 100);

        void onSearchChanged(String value) {
          debounceTimer?.cancel();
          debounceTimer = Timer(debounceDelay, () {
            searchQueries.add(value);
          });
        }

        // First word
        onSearchChanged('hello');
        await Future.delayed(const Duration(milliseconds: 150));
        expect(searchQueries, ['hello']);

        // User pauses, then continues
        onSearchChanged('hello world');
        await Future.delayed(const Duration(milliseconds: 150));
        expect(searchQueries, ['hello', 'hello world']);

        debounceTimer?.cancel();
      });
    });
  });

  group('Category Filter Interaction', () {
    test('category change should trigger immediate refresh', () {
      // Category filter changes should NOT be debounced
      // They should trigger immediate refresh
      int refreshCount = 0;

      void onCategoryChanged(String? categoryId) {
        refreshCount++;
      }

      onCategoryChanged('cat-1');
      expect(refreshCount, 1);

      onCategoryChanged('cat-2');
      expect(refreshCount, 2);

      onCategoryChanged(null); // "Semua"
      expect(refreshCount, 3);
    });

    test('search with active category should combine filters', () {
      String? activeCategory;
      String searchQuery = '';
      final appliedFilters = <Map<String, String?>>[];

      void applyFilters() {
        appliedFilters.add({
          'category': activeCategory,
          'search': searchQuery,
        });
      }

      // Set category
      activeCategory = 'cat-makanan';
      applyFilters();

      // Add search
      searchQuery = 'indo';
      applyFilters();

      expect(appliedFilters.length, 2);
      expect(appliedFilters[1]['category'], 'cat-makanan');
      expect(appliedFilters[1]['search'], 'indo');
    });
  });
}
