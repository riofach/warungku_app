import 'package:flutter/material.dart';

import '../pagination/paginated_history_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'error_widget.dart';
import 'loading_widget.dart';

/// Renders a [PaginatedState] as an infinite-scroll list: initial loading,
/// error, empty, the item cards, a bottom "loading more" spinner, and
/// pull-to-refresh. Auto-requests the next page when scrolled near the bottom.
///
/// Reused by the sales & purchase history screens.
class PaginatedListView<T> extends StatefulWidget {
  final PaginatedState<T> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget emptyState;
  final String loadingMessage;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyState,
    this.loadingMessage = 'Memuat data...',
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final threshold = _controller.position.maxScrollExtent - 300;
    if (_controller.position.pixels >= threshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // Initial load (no data yet).
    if (state.isInitialLoading && state.items.isEmpty) {
      return LoadingWidget(message: widget.loadingMessage);
    }

    // Error on first page (no data to show).
    if (state.error != null && state.items.isEmpty) {
      return AppErrorWidget(
        message: 'Gagal memuat data',
        details: state.error.toString(),
        onRetry: widget.onRefresh,
      );
    }

    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: widget.emptyState,
            ),
          ],
        ),
      );
    }

    final itemCount = state.items.length + (state.hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, state.items[index]);
        },
      ),
    );
  }
}
