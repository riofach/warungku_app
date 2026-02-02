import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart'; // Import rootNavigatorKey
import '../../data/providers/order_realtime_events_provider.dart';
import '../../data/models/order_model.dart';
import 'new_order_notification_banner.dart';

/// A widget that listens for new order events and displays a notification banner as an overlay.
class NewOrderNotificationOverlayHost extends ConsumerStatefulWidget {
  final Widget child;

  const NewOrderNotificationOverlayHost({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<NewOrderNotificationOverlayHost> createState() =>
      _NewOrderNotificationOverlayHostState();
}

class _NewOrderNotificationOverlayHostState
    extends ConsumerState<NewOrderNotificationOverlayHost> {
  OverlayEntry? _overlayEntry;
  // TODO: Add sound player here if sound effect is implemented

  void _showNewOrderNotification(Order order) {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: NewOrderNotificationBanner(
          customerName: order.customerName ?? 'Pelanggan Tidak Dikenal', // Asumsi ada customerName
          onTap: () {
            // Remove the overlay when tapped
            _overlayEntry?.remove();
            _overlayEntry = null;
            // Navigate to order detail screen
            final navContext = rootNavigatorKey.currentContext;
            if (navContext != null) {
              GoRouter.of(navContext).go('${AppRoutes.orderDetail}/${order.id}');
            }
          },
        ),
      ),
    );

    // Use rootNavigatorKey to access the overlay directly from the NavigatorState
    final navigatorState = rootNavigatorKey.currentState;
    if (navigatorState != null && navigatorState.overlay != null) {
      navigatorState.overlay!.insert(_overlayEntry!);
    } else {
      debugPrint('Error: Could not find NavigatorState or Overlay from rootNavigatorKey');
    }

    // Automatically remove after a duration (e.g., 5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      if (_overlayEntry != null && mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });

    // TODO: Play sound effect here
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PostgresChangePayload>>(newOrderEventsProvider,
        (previous, next) {
      next.when(
        data: (payload) {
          final newOrderData = payload.newRecord;
          if (newOrderData != null) {
            final order = Order.fromJson(newOrderData); // Asumsi Order.fromJson bisa menangani payload
            _showNewOrderNotification(order);
          }
        },
        loading: () {
          // Do nothing
        },
        error: (err, stack) {
          // Log or handle error
          debugPrint('Error listening to new orders: $err');
        },
      );
    });

    return widget.child;
  }
}
