import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warungku_app/core/services/realtime_connection_monitor.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockRealtimeClient extends Mock implements RealtimeClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockRealtimeClient mockRealtime;
  late MockRealtimeChannel mockChannel;
  late ProviderContainer container;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockRealtime = MockRealtimeClient();
    mockChannel = MockRealtimeChannel();

    when(() => mockSupabase.realtime).thenReturn(mockRealtime);
    when(() => mockSupabase.channel(any())).thenReturn(mockChannel);
    // subscribe returns RealtimeChannel synchronously in 2.x? No, it returns RealtimeChannel.
    when(() => mockChannel.subscribe(any())).thenReturn(mockChannel); 
    // unsubscribe returns Future<String>
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
    
    // Mock realtime listeners - they return void or String subscription ID
    when(() => mockRealtime.onOpen(any())).thenReturn(null);
    when(() => mockRealtime.onClose(any())).thenReturn('sub_id');
    when(() => mockRealtime.onError(any())).thenReturn('sub_id');

    // Create a container with overridden provider
    container = ProviderContainer(
      overrides: [
        connectionMonitorProvider.overrideWith((ref) {
           return RealtimeConnectionMonitor(ref, supabase: mockSupabase);
        }),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RealtimeConnectionMonitor Logic', () {
    test('calculateRetryDelay follows exponential backoff', () {
      expect(RealtimeConnectionMonitor.calculateRetryDelay(0), equals(1000));
      expect(RealtimeConnectionMonitor.calculateRetryDelay(1), equals(2000));
      expect(RealtimeConnectionMonitor.calculateRetryDelay(2), equals(4000));
      expect(RealtimeConnectionMonitor.calculateRetryDelay(10), equals(30000));
    });

    test('Initializes and sets up listeners', () {
      final monitor = container.read(connectionMonitorProvider);
      
      monitor.startMonitoring();
      
      verify(() => mockRealtime.onOpen(any())).called(1);
      verify(() => mockRealtime.onClose(any())).called(1);
      verify(() => mockRealtime.onError(any())).called(1);
    });

    test('manualReconnect resets retry count and tries to connect', () async {
      final monitor = container.read(connectionMonitorProvider);
      monitor.startMonitoring();
      
      await monitor.manualReconnect();
      
      expect(monitor.currentState, equals(ConnectionState.reconnecting));
      // Should try to create channel
      verify(() => mockSupabase.channel(any())).called(greaterThan(0));
    });
  });
}
