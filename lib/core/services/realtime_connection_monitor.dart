import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider moved to legacy.dart in Riverpod 3.x
// ignore: deprecated_member_use
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connection states for realtime monitoring
enum ConnectionState {
  /// Realtime connection is active and working
  connected,

  /// Attempting to reconnect after disconnect
  reconnecting,

  /// Fallback polling mode when realtime unavailable
  polling,

  /// Connection is closed/maxed out retries
  disconnected,
}

/// Provider for connection state
final connectionStateProvider = StateProvider<ConnectionState>(
  (ref) => ConnectionState.connected,
);

/// Provider for connection monitor instance
final connectionMonitorProvider = Provider<RealtimeConnectionMonitor>((ref) {
  return RealtimeConnectionMonitor(ref);
});

/// Provider for retry attempt count
final retryAttemptProvider = StateProvider<int>((ref) => 0);

/// Service that monitors Supabase Realtime connection state
/// and handles auto-reconnect with exponential backoff
class RealtimeConnectionMonitor {
  final Ref _ref;
  final SupabaseClient _supabase;

  RealtimeChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _fallbackTimer;

  int _retryCount = 0;
  bool _isMonitoring = false;
  bool _isFallbackActive = false;
  bool _isReconnectInProgress = false;

  static const int maxRetries = 10;
  static const int baseDelayMs = 1000; // 1 second
  static const int maxDelayMs = 30000; // 30 seconds
  static const int fallbackIntervalSeconds = 30;

  /// Stream controller for connection state changes
  final _connectionStateController = StreamController<ConnectionState>.broadcast();

  RealtimeConnectionMonitor(this._ref, {SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// Current connection state
  ConnectionState get currentState => _ref.read(connectionStateProvider);

  /// Whether monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Whether fallback polling is active
  bool get isFallbackActive => _isFallbackActive;

  /// Calculate retry delay using exponential backoff
  /// Formula: min(baseDelay * 2^attempt, maxDelay)
  static int calculateRetryDelay(int attempt) {
    final delay = baseDelayMs * pow(2, attempt).toInt();
    return min(delay, maxDelayMs);
  }

  /// Initialize monitoring
  void startMonitoring() {
    if (_isMonitoring) {
      debugPrint('[CONNECTION_MONITOR] Already monitoring, skipping start');
      return;
    }

    debugPrint('[CONNECTION_MONITOR] Starting connection monitoring...');
    _isMonitoring = true;
    _retryCount = 0;
    _isReconnectInProgress = false;
    _ref.read(retryAttemptProvider.notifier).state = 0;

    // Setup Supabase realtime listeners
    _setupRealtimeListeners();

    // Initial connection check via test subscription
    _tryConnect();
  }

  /// Stop monitoring and cleanup
  void stopMonitoring() {
    debugPrint('[CONNECTION_MONITOR] Stopping connection monitoring...');
    _isMonitoring = false;

    _reconnectTimer?.cancel();
    _fallbackTimer?.cancel();

    if (_channel != null) {
      _channel!.unsubscribe();
      _channel = null;
    }

    _connectionStateController.close();
  }

  /// Setup Supabase realtime event listeners
  void _setupRealtimeListeners() {
    debugPrint('[CONNECTION_MONITOR] Setting up realtime listeners...');

    // Listen to realtime open/close events
    // Note: onOpen takes void Function() callback in Supabase 2.x
    _supabase.realtime.onOpen(() {
      debugPrint('[CONNECTION_MONITOR] ✅ Realtime connection opened');
      _onConnected();
    });

    // onClose takes void Function(String?) callback in Supabase 2.x
    _supabase.realtime.onClose((event) {
      debugPrint('[CONNECTION_MONITOR] ⚠️ Realtime connection closed: $event');
      _onDisconnected();
    });

    // onError takes void Function(dynamic) callback
    _supabase.realtime.onError((error) {
      debugPrint('[CONNECTION_MONITOR] ❌ Realtime error: $error');
      _onDisconnected();
    });
  }

  /// Handle connected state
  void _onConnected() {
    debugPrint('[CONNECTION_MONITOR] Connection established');

    // Cancel any pending reconnect/fallback timers
    _reconnectTimer?.cancel();
    _fallbackTimer?.cancel();

    // Reset retry count and flags
    _retryCount = 0;
    _isFallbackActive = false;
    _isReconnectInProgress = false;

    _ref.read(retryAttemptProvider.notifier).state = 0;

    // Update state
    _updateState(ConnectionState.connected);
  }

  /// Handle disconnected state - start reconnect process
  void _onDisconnected() {
    if (!_isMonitoring) return;

    final current = _ref.read(connectionStateProvider);
    
    // If already in fallback mode, don't do anything
    if (current == ConnectionState.polling) {
      return;
    }

    // If already reconnecting and timer is active, don't restart
    if (current == ConnectionState.reconnecting && _isReconnectInProgress) {
      return;
    }

    debugPrint('[CONNECTION_MONITOR] Connection lost, starting reconnect...');
    _updateState(ConnectionState.reconnecting);

    _attemptReconnect();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (!_isMonitoring) return;

    if (_retryCount >= maxRetries) {
      debugPrint('[CONNECTION_MONITOR] Max retries ($maxRetries) reached, switching to fallback');
      _startFallbackPolling();
      return;
    }

    _isReconnectInProgress = true;
    final delayMs = calculateRetryDelay(_retryCount);
    final delaySeconds = (delayMs / 1000).ceil();

    debugPrint('[CONNECTION_MONITOR] Reconnect attempt ${_retryCount + 1}/$maxRetries in ${delaySeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_isMonitoring) return;

      // Increment retry count before attempting
      _retryCount++;
      _ref.read(retryAttemptProvider.notifier).state = _retryCount;
      
      debugPrint('[CONNECTION_MONITOR] Executing reconnect attempt $_retryCount/$maxRetries');

      // Try to connect
      _tryConnect();
    });
  }

  /// Try to establish connection
  Future<void> _tryConnect() async {
    debugPrint('[CONNECTION_MONITOR] Attempting to connect...');

    try {
      // Clean up existing channel
      if (_channel != null) {
        await _channel!.unsubscribe();
        _channel = null;
      }

      // Create a test channel to verify connection
      _channel = _supabase.channel('connection_test_${DateTime.now().millisecondsSinceEpoch}');

      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          debugPrint('[CONNECTION_MONITOR] Test channel received event: ${payload.eventType}');
        },
      );

      _channel!.subscribe((status, error) {
        debugPrint('[CONNECTION_MONITOR] Subscribe callback - status: $status, error: $error');

        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('[CONNECTION_MONITOR] ✅ Successfully subscribed');
          _onConnected();
        } else if (error != null) {
          debugPrint('[CONNECTION_MONITOR] ❌ Subscribe error: $error');
          _handleConnectionFailure();
        } else if (status == RealtimeSubscribeStatus.closed ||
                   status == RealtimeSubscribeStatus.channelError) {
          debugPrint('[CONNECTION_MONITOR] ⚠️ Subscribe failed with status: $status');
          _handleConnectionFailure();
        }
      });
    } catch (e) {
      debugPrint('[CONNECTION_MONITOR] ❌ Connection attempt failed: $e');
      _handleConnectionFailure();
    }
  }

  /// Handle connection failure safely
  void _handleConnectionFailure() {
    // If we are already scheduling a reconnect (timer active), don't do it again
    // This prevents multiple error callbacks from resetting the timer
    if (_isReconnectInProgress && _reconnectTimer != null && _reconnectTimer!.isActive) {
      debugPrint('[CONNECTION_MONITOR] Reconnect already scheduled, ignoring duplicate failure event');
      return;
    }

    _isReconnectInProgress = false;
    _attemptReconnect();
  }

  /// Start fallback polling when realtime is unavailable
  void _startFallbackPolling() {
    if (_isFallbackActive) return;

    debugPrint('[CONNECTION_MONITOR] Starting fallback polling mode');
    _isFallbackActive = true;
    _isReconnectInProgress = false;
    _updateState(ConnectionState.polling);

    // Cancel reconnect timer
    _reconnectTimer?.cancel();

    // Start periodic polling
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: fallbackIntervalSeconds),
      (_) => _onFallbackTick(),
    );

    // Also try to reconnect realtime in background
    _backgroundReconnect();
  }

  /// Handle fallback polling tick
  void _onFallbackTick() {
    debugPrint('[CONNECTION_MONITOR] Fallback polling tick - triggering data refresh');

    // Notify listeners to refresh data
    _connectionStateController.add(ConnectionState.polling);
  }

  /// Background reconnect attempt while in fallback mode
  void _backgroundReconnect() {
    if (!_isFallbackActive || !_isMonitoring) return;

    // Try to reconnect every 2 minutes even in fallback mode
    Timer(const Duration(minutes: 2), () {
      if (_isFallbackActive && _isMonitoring) {
        debugPrint('[CONNECTION_MONITOR] Background reconnect attempt from fallback mode');
        _retryCount = 0; // Reset for background attempts
        _ref.read(retryAttemptProvider.notifier).state = 0;
        _isFallbackActive = false;
        _updateState(ConnectionState.reconnecting);
        _attemptReconnect();
      }
    });
  }

  /// Manually trigger a reconnect attempt
  Future<void> manualReconnect() async {
    debugPrint('[CONNECTION_MONITOR] Manual reconnect triggered');

    // Reset state
    _retryCount = 0;
    _isFallbackActive = false;
    _isReconnectInProgress = false;
    _ref.read(retryAttemptProvider.notifier).state = 0;

    // Cancel timers
    _reconnectTimer?.cancel();
    _fallbackTimer?.cancel();

    // Force disconnect first
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
    }

    // Try to connect
    _updateState(ConnectionState.reconnecting);
    _attemptReconnect();
  }

  /// Update connection state
  void _updateState(ConnectionState state) {
    final previous = _ref.read(connectionStateProvider);
    if (previous != state) {
      debugPrint('[CONNECTION_MONITOR] State change: $previous → $state');
      _ref.read(connectionStateProvider.notifier).state = state;
      _connectionStateController.add(state);
    }
  }

  /// Get human-readable status message
  String getStatusMessage() {
    final state = currentState;
    final attempt = _ref.read(retryAttemptProvider);

    switch (state) {
      case ConnectionState.connected:
        return 'Live Updates';
      case ConnectionState.reconnecting:
        return 'Reconnecting... (${attempt}/${RealtimeConnectionMonitor.maxRetries})';
      case ConnectionState.polling:
        return 'Polling Mode (${fallbackIntervalSeconds}s)';
      case ConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  /// Dispose and cleanup
  void dispose() {
    stopMonitoring();
  }
}
