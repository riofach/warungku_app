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

  // Daftarkan fallback value agar mocktail bisa match tipe PostgresChangeEvent
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
  });

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

    // Mock onPostgresChanges — WAJIB agar _tryConnect() tidak crash dengan 'Null' error
    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(mockChannel);

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
  }); // end 'RealtimeConnectionMonitor Logic'

  group('Story 7.7 - No Double Subscription Fix', () {
    test('_tryConnect() creates channel with settings table, not orders', () async {
      // Capture semua channel names yang dibuat
      final List<String> capturedChannelNames = [];
      final List<Map<String, dynamic>> capturedPostgresArgs = [];

      when(() => mockSupabase.channel(any())).thenAnswer((invocation) {
        capturedChannelNames.add(
          invocation.positionalArguments.first as String,
        );
        return mockChannel;
      });

      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) {
        capturedPostgresArgs.add({
          'table': invocation.namedArguments[const Symbol('table')],
          'schema': invocation.namedArguments[const Symbol('schema')],
        });
        return mockChannel;
      });

      final monitor = container.read(connectionMonitorProvider);
      monitor.startMonitoring();

      // Tunggu async _tryConnect() dipanggil
      await Future.delayed(const Duration(milliseconds: 50));

      // Verifikasi channel name menggunakan prefix 'connection_monitor_settings_' (bukan 'connection_test_')
      expect(
        capturedChannelNames.any(
          (name) => name.startsWith('connection_monitor_settings_'),
        ),
        isTrue,
        reason:
            'RealtimeConnectionMonitor HARUS membuat channel dengan prefix '
            '"connection_monitor_settings_", bukan "connection_test_" atau lainnya',
      );

      // Verifikasi TIDAK ada channel yang subscribe ke tabel 'orders'
      expect(
        capturedPostgresArgs.any((args) => args['table'] == 'orders'),
        isFalse,
        reason:
            'RealtimeConnectionMonitor TIDAK BOLEH subscribe ke tabel "orders" '
            '— harus menggunakan "settings" untuk menghindari double subscription',
      );

      // Verifikasi ada channel yang subscribe ke tabel 'settings'
      expect(
        capturedPostgresArgs.any((args) => args['table'] == 'settings'),
        isTrue,
        reason:
            'RealtimeConnectionMonitor HARUS subscribe ke tabel "settings" '
            'sebagai test channel koneksi',
      );
    });

    test('Channel name for connection monitor uses unique timestamp', () async {
      final List<String> capturedChannelNames = [];

      when(() => mockSupabase.channel(any())).thenAnswer((invocation) {
        capturedChannelNames.add(
          invocation.positionalArguments.first as String,
        );
        return mockChannel;
      });
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);

      final monitor = container.read(connectionMonitorProvider);
      monitor.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 50));

      // Channel name harus mengandung timestamp (angka di akhir nama)
      final monitorChannelNames = capturedChannelNames
          .where((name) => name.startsWith('connection_monitor_settings_'))
          .toList();

      expect(monitorChannelNames, isNotEmpty);

      // Timestamp adalah bagian akhir dari nama channel
      for (final name in monitorChannelNames) {
        final suffix = name.replaceFirst('connection_monitor_settings_', '');
        expect(
          int.tryParse(suffix),
          isNotNull,
          reason:
              'Nama channel "$name" harus diakhiri dengan timestamp berupa angka',
        );
      }
    });
  });
}
