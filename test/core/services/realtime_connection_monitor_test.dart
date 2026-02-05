import 'package:flutter_test/flutter_test.dart';
import 'package:warungku_app/core/services/realtime_connection_monitor.dart';

void main() {
  group('RealtimeConnectionMonitor', () {
    group('calculateRetryDelay', () {
      test('should return base delay for attempt 0', () {
        expect(RealtimeConnectionMonitor.calculateRetryDelay(0), equals(1000));
      });

      test('should return doubled delay for attempt 1', () {
        expect(RealtimeConnectionMonitor.calculateRetryDelay(1), equals(2000));
      });

      test('should return 4x delay for attempt 2', () {
        expect(RealtimeConnectionMonitor.calculateRetryDelay(2), equals(4000));
      });

      test('should return 16s delay for attempt 4', () {
        expect(RealtimeConnectionMonitor.calculateRetryDelay(4), equals(16000));
      });

      test('should cap delay at 30 seconds (max delay)', () {
        expect(RealtimeConnectionMonitor.calculateRetryDelay(10), equals(30000));
        expect(RealtimeConnectionMonitor.calculateRetryDelay(15), equals(30000));
      });

      test('should follow exponential backoff pattern', () {
        // Formula: min(baseDelay * 2^attempt, maxDelay)
        expect(RealtimeConnectionMonitor.calculateRetryDelay(0), equals(1000)); // 1s
        expect(RealtimeConnectionMonitor.calculateRetryDelay(1), equals(2000)); // 2s
        expect(RealtimeConnectionMonitor.calculateRetryDelay(2), equals(4000)); // 4s
        expect(RealtimeConnectionMonitor.calculateRetryDelay(3), equals(8000)); // 8s
        expect(RealtimeConnectionMonitor.calculateRetryDelay(4), equals(16000)); // 16s
        expect(RealtimeConnectionMonitor.calculateRetryDelay(5), equals(30000)); // capped at 30s
      });
    });

    group('Constants', () {
      test('should have correct max retries', () {
        expect(RealtimeConnectionMonitor.maxRetries, equals(10));
      });

      test('should have correct base delay', () {
        expect(RealtimeConnectionMonitor.baseDelayMs, equals(1000));
      });

      test('should have correct max delay', () {
        expect(RealtimeConnectionMonitor.maxDelayMs, equals(30000));
      });

      test('should have correct fallback interval', () {
        expect(RealtimeConnectionMonitor.fallbackIntervalSeconds, equals(30));
      });
    });

    group('ConnectionState', () {
      test('should have all required states', () {
        expect(ConnectionState.values, contains(ConnectionState.connected));
        expect(ConnectionState.values, contains(ConnectionState.reconnecting));
        expect(ConnectionState.values, contains(ConnectionState.polling));
        expect(ConnectionState.values, contains(ConnectionState.disconnected));
      });

      test('should have exactly 4 states', () {
        expect(ConnectionState.values.length, equals(4));
      });
    });
  });
}
