import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for an infinite-scroll list with an optional date range.
@immutable
class PaginatedState<T> {
  final List<T> items;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final DateTime? fromDate;
  final DateTime? toDate;

  const PaginatedState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.fromDate,
    this.toDate,
  });

  /// True when the (filtered) list has finished loading and is empty.
  bool get isEmpty =>
      items.isEmpty && !isInitialLoading && error == null;

  bool get hasDateFilter => fromDate != null || toDate != null;

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

/// Reusable infinite-scroll controller for history lists.
///
/// Subclasses only implement [fetchPage]; this base handles page accumulation,
/// the "load more" guard, date-range changes, and refresh. The first page is
/// loaded automatically when the provider is first read.
///
/// Used by both sales (transactions) and purchase history lists.
abstract class PaginatedHistoryNotifier<T>
    extends Notifier<PaginatedState<T>> {
  /// Rows fetched per page.
  static const int pageSize = 20;

  /// Fetch a single page. Must honor [limit]/[offset] and the date range.
  Future<List<T>> fetchPage({
    required int limit,
    required int offset,
    DateTime? fromDate,
    DateTime? toDate,
  });

  @override
  PaginatedState<T> build() {
    // Kick off the first page after the initial state is returned.
    Future.microtask(loadInitial);
    return PaginatedState<T>();
  }

  Future<void> loadInitial() async {
    if (state.isInitialLoading) return;
    state = state.copyWith(isInitialLoading: true, clearError: true);
    try {
      final page = await fetchPage(
        limit: pageSize,
        offset: 0,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      state = state.copyWith(
        items: page,
        isInitialLoading: false,
        hasMore: page.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isInitialLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isInitialLoading || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await fetchPage(
        limit: pageSize,
        offset: state.items.length,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );
      state = state.copyWith(
        items: [...state.items, ...page],
        isLoadingMore: false,
        hasMore: page.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  /// Apply a new date range (null/null clears it) and reload from page one.
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    state = state.copyWith(
      fromDate: from,
      toDate: to,
      clearDates: from == null && to == null,
      items: const [],
      hasMore: true,
      clearError: true,
    );
    await loadInitial();
  }

  /// Reload from page one, keeping the current date range.
  Future<void> refresh() async {
    state = state.copyWith(items: const [], hasMore: true, clearError: true);
    await loadInitial();
  }
}
