import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/realtime_connection_monitor.dart';

/// Widget that displays the current realtime connection status
/// Shows different visual states based on connection state:
/// - 🟢 Realtime: "Live Updates"
/// - 🟡 Reconnecting: "Reconnecting..."
/// - 🔴 Polling: "Polling Mode (30s)"
class ConnectionStatusIndicator extends ConsumerWidget {
  /// Optional callback when the indicator is tapped (for manual reconnect)
  final VoidCallback? onTap;

  /// Whether to show the indicator in compact mode (icon only)
  final bool compact;

  /// Background color for the indicator container
  final Color? backgroundColor;

  /// Border radius for the container
  final double borderRadius;

  /// Padding inside the container
  final EdgeInsets padding;

  const ConnectionStatusIndicator({
    super.key,
    this.onTap,
    this.compact = false,
    this.backgroundColor,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);
    final retryAttempt = ref.watch(retryAttemptProvider);

    return GestureDetector(
      onTap: onTap ?? () => _handleManualReconnect(ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? _getBackgroundColor(connectionState).withAlpha(25),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: _getBorderColor(connectionState),
            width: 1.5,
          ),
        ),
        child: compact
            ? _buildCompactView(connectionState, retryAttempt)
            : _buildFullView(connectionState, retryAttempt),
      ),
    );
  }

  /// Build compact view (icon only with tooltip)
  Widget _buildCompactView(ConnectionState state, int retryAttempt) {
    final iconData = _getIconData(state);
    final color = _getIconColor(state);

    return Tooltip(
      message: _getStatusMessage(state, retryAttempt),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          iconData,
          key: ValueKey(state),
          color: color,
          size: 20,
        ),
      ),
    );
  }

  /// Build full view with icon and text
  Widget _buildFullView(ConnectionState state, int retryAttempt) {
    final iconData = _getIconData(state);
    final color = _getIconColor(state);
    final message = _getStatusMessage(state, retryAttempt);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Row(
        key: ValueKey(state),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedIcon(iconData, color, state),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build animated icon based on state
  Widget _buildAnimatedIcon(IconData iconData, Color color, ConnectionState state) {
    // Add rotation animation for reconnecting state
    if (state == ConnectionState.reconnecting) {
      return _AnimatedRotatingIcon(
        icon: iconData,
        color: color,
        size: 16,
      );
    }

    // Add pulse animation for polling state
    if (state == ConnectionState.polling) {
      return _AnimatedPulseIcon(
        icon: iconData,
        color: color,
        size: 16,
      );
    }

    return Icon(iconData, color: color, size: 16);
  }

  /// Get background color based on state
  Color _getBackgroundColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.reconnecting:
        return Colors.orange;
      case ConnectionState.polling:
        return Colors.red;
      case ConnectionState.disconnected:
        return Colors.grey;
    }
  }

  /// Get border color based on state
  Color _getBorderColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Colors.green.shade300;
      case ConnectionState.reconnecting:
        return Colors.orange.shade300;
      case ConnectionState.polling:
        return Colors.red.shade300;
      case ConnectionState.disconnected:
        return Colors.grey.shade300;
    }
  }

  /// Get icon data based on state
  IconData _getIconData(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Icons.wifi_rounded;
      case ConnectionState.reconnecting:
        return Icons.sync_rounded;
      case ConnectionState.polling:
        return Icons.refresh_rounded;
      case ConnectionState.disconnected:
        return Icons.wifi_off_rounded;
    }
  }

  /// Get icon color based on state
  Color _getIconColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connected:
        return Colors.green.shade700;
      case ConnectionState.reconnecting:
        return Colors.orange.shade700;
      case ConnectionState.polling:
        return Colors.red.shade700;
      case ConnectionState.disconnected:
        return Colors.grey.shade700;
    }
  }

  /// Get status message based on state
  String _getStatusMessage(ConnectionState state, int retryAttempt) {
    switch (state) {
      case ConnectionState.connected:
        return 'Live Updates';
      case ConnectionState.reconnecting:
        return 'Reconnecting... (${retryAttempt}/${RealtimeConnectionMonitor.maxRetries})';
      case ConnectionState.polling:
        return 'Polling Mode (${RealtimeConnectionMonitor.fallbackIntervalSeconds}s)';
      case ConnectionState.disconnected:
        return 'Disconnected - Tap to retry';
    }
  }

  /// Handle manual reconnect attempt
  void _handleManualReconnect(WidgetRef ref) async {
    final monitor = ref.read(connectionMonitorProvider);
    await monitor.manualReconnect();
  }
}

/// Animated rotating icon for reconnecting state
class _AnimatedRotatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedRotatingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedRotatingIcon> createState() => _AnimatedRotatingIconState();
}

class _AnimatedRotatingIconState extends State<_AnimatedRotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}

/// Animated pulsing icon for polling state
class _AnimatedPulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedPulseIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedPulseIcon> createState() => _AnimatedPulseIconState();
}

class _AnimatedPulseIconState extends State<_AnimatedPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        );
      },
    );
  }
}
