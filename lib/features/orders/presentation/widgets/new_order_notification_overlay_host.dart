import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../data/providers/order_realtime_events_provider.dart';
import '../../data/models/order_model.dart';

/// A widget that listens for new order events and displays an animated notification banner as an overlay.
/// The banner slides in from top with animation and auto-dismisses after 5 seconds.
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
  Timer? _autoDismissTimer;

  void _showNewOrderNotification(Order order) {
    debugPrint('[NOTIFICATION_OVERLAY] 🔔 Showing notification for: ${order.code}');
    
    // Cancel any existing timer
    _autoDismissTimer?.cancel();
    
    // Remove existing overlay first (create "flash" effect)
    if (_overlayEntry != null) {
      debugPrint('[NOTIFICATION_OVERLAY] 🗑️ Removing old notification first');
      _overlayEntry?.remove();
      _overlayEntry = null;
      
      // Small delay to create "flash" effect between old and new
      Future.delayed(const Duration(milliseconds: 100), () {
        _createAndShowOverlay(order);
      });
    } else {
      _createAndShowOverlay(order);
    }
    
    // TODO: Play sound effect here
  }

  void _createAndShowOverlay(Order order) {
    if (!mounted) return;
    
    debugPrint('[NOTIFICATION_OVERLAY] 📦 Creating animated overlay for: ${order.code}');
    
    _overlayEntry = OverlayEntry(
      maintainState: false,
      builder: (context) => AnimatedNotificationBanner(
        key: ValueKey(order.id), // Key berbeda = animasi baru
        order: order,
        onTap: () => _navigateToOrder(order),
      ),
    );

    // Insert overlay
    final navigatorState = rootNavigatorKey.currentState;
    if (navigatorState != null && navigatorState.overlay != null) {
      navigatorState.overlay!.insert(_overlayEntry!);
      debugPrint('[NOTIFICATION_OVERLAY] ✅ Overlay inserted with animation');
    } else {
      debugPrint('[NOTIFICATION_OVERLAY] ❌ Error: Could not find NavigatorState or Overlay');
      return;
    }

    // Start auto-dismiss timer
    _startAutoDismissTimer();
  }

  void _navigateToOrder(Order order) {
    debugPrint('[NOTIFICATION_OVERLAY] 👆 Notification tapped for: ${order.code}');
    
    // Cancel timer and dismiss
    _autoDismissTimer?.cancel();
    _dismissNotification();
    
    // Navigate to order detail screen
    final navContext = rootNavigatorKey.currentContext;
    if (navContext != null) {
      GoRouter.of(navContext).go('${AppRoutes.orderDetail}/${order.id}');
    }
  }

  void _startAutoDismissTimer() {
    debugPrint('[NOTIFICATION_OVERLAY] ⏱️ Starting 5-second auto-dismiss timer');
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint('[NOTIFICATION_OVERLAY] ⏰ Auto-dismissing notification');
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() {
    if (_overlayEntry != null) {
      debugPrint('[NOTIFICATION_OVERLAY] 🗑️ Dismissing notification');
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    debugPrint('[NOTIFICATION_OVERLAY] 🧹 Disposing...');
    _autoDismissTimer?.cancel();
    _dismissNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[NOTIFICATION_OVERLAY] 🏗️ Building widget, setting up listener...');
    
    ref.listen<AsyncValue<PostgresChangePayload>>(newOrderEventsProvider,
        (previous, next) {
      debugPrint('[NOTIFICATION_OVERLAY] 📡 Listener triggered! State: ${next.runtimeType}');
      next.when(
        data: (payload) {
          debugPrint('[NOTIFICATION_OVERLAY] 📥 Data received! EventType: ${payload.eventType}');
          final newOrderData = payload.newRecord;
          if (newOrderData != null) {
            try {
              debugPrint('[NOTIFICATION_OVERLAY] 🔍 Parsing new order data...');
              final order = Order.fromJson(newOrderData);
              debugPrint('[NOTIFICATION_OVERLAY] ✅ Order parsed successfully: ${order.code}');
              _showNewOrderNotification(order);
            } catch (e, stackTrace) {
              debugPrint('[NOTIFICATION_OVERLAY] ❌ Error parsing order: $e');
              debugPrint('[NOTIFICATION_OVERLAY] Stack trace: $stackTrace');
            }
          } else {
            debugPrint('[NOTIFICATION_OVERLAY] ⚠️ Received event but newRecord is null');
          }
        },
        loading: () {
          debugPrint('[NOTIFICATION_OVERLAY] ⏳ Loading new order event...');
        },
        error: (err, stack) {
          debugPrint('[NOTIFICATION_OVERLAY] ❌ Error listening to new orders: $err');
          debugPrint('[NOTIFICATION_OVERLAY] Stack trace: $stack');
        },
      );
    });

    debugPrint('[NOTIFICATION_OVERLAY] ✨ Listener setup complete');
    return widget.child;
  }
}

/// Animated notification banner with slide-in and slide-out effects
class AnimatedNotificationBanner extends StatefulWidget {
  final Order order;
  final VoidCallback onTap;

  const AnimatedNotificationBanner({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedNotificationBanner> createState() => _AnimatedNotificationBannerState();
}

class _AnimatedNotificationBannerState extends State<AnimatedNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('[ANIMATED_BANNER] 🎬 Initializing animation for: ${widget.order.code}');
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0), // Start from above (off screen)
      end: Offset.zero, // End at normal position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Bouncy effect
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    debugPrint('[ANIMATED_BANNER] 🧹 Disposing animation for: ${widget.order.code}');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _NotificationContent(
            order: widget.order,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// The actual notification content with order details
class _NotificationContent extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _NotificationContent({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[600]!,
                Colors.green[400]!,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Baru!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            order.code,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Customer info
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
