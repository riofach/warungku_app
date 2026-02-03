import 'dart:async'; // Tambahkan ini
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../models/order_model.dart';

/// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderRepository {
  final SupabaseClient _supabase;
  final Duration _timeout;

  OrderRepository({
    SupabaseClient? supabase,
    Duration timeout = const Duration(seconds: 10),
  })  : _supabase = supabase ?? Supabase.instance.client,
        _timeout = timeout;

  /// Get new orders (pending or paid)
  Future<List<Order>> getNewOrders({int limit = 5}) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tableOrders)
          .select('''
            *,
            housing_block:housing_blocks(id, name)
          ''')
          .inFilter('status', ['pending', 'paid'])
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      
      return (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
    } catch (e) {
      // Allow specific error handling if needed, but here we just rethrow with message
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  /// Get order by ID with full details (items, housing block)
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from(SupabaseConstants.tableOrders)
          .select('''
            *,
            housing_block:housing_blocks(id, name),
            order_items:order_items(
              *,
              items:items(name, image_url)
            )
          ''')
          .eq(SupabaseConstants.colId, orderId)
          .single()
          .timeout(_timeout);
      
      return Order.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: ${e.toString()}');
    }
  }

  /// Get orders stream with server-side join for housing blocks
  /// Uses periodic refresh with server-side join instead of realtime stream
  /// to ensure housing block data is always available
  Stream<List<Order>> getOrdersStream() async* {
    // Initial fetch with server-side join
    final initialOrders = await _supabase
        .from(SupabaseConstants.tableOrders)
        .select('''
          *,
          housing_block:housing_blocks(id, name)
        ''')
        .order('created_at', ascending: false)
        .timeout(_timeout);

    yield (initialOrders as List)
        .map((json) => Order.fromJson(json))
        .toList();

    // Listen to realtime changes for updates
    await for (final payload in getOrdersRealtimeStream()) {
      // On any change, re-fetch with join to get complete data
      final refreshedOrders = await _supabase
          .from(SupabaseConstants.tableOrders)
          .select('''
            *,
            housing_block:housing_blocks(id, name)
          ''')
          .order('created_at', ascending: false)
          .timeout(_timeout);

      yield (refreshedOrders as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
  }

  /// Listens to real-time changes (INSERT and UPDATE) on the 'orders' table
  /// using Postgres Changes with auto-retry on token expiration.
  Stream<PostgresChangePayload> getOrdersRealtimeStream() {
    debugPrint('[ORDER_REPOSITORY] Setting up realtime stream with retry...');
    final StreamController<PostgresChangePayload> controller = StreamController.broadcast();
    
    // Retry configuration
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);
    int retryCount = 0;
    RealtimeChannel? currentChannel;
    bool isSubscribed = false;

    Future<void> setupSubscription() async {
      try {
        // Clean up existing channel if any
        if (currentChannel != null) {
          debugPrint('[ORDER_REPOSITORY] 🧹 Cleaning up old channel...');
          await currentChannel!.unsubscribe();
          currentChannel = null;
        }

        // Check and refresh session if needed
        final session = _supabase.auth.currentSession;
        if (session == null || session.isExpired) {
          debugPrint('[ORDER_REPOSITORY] 🔄 Session expired or missing, attempting refresh...');
          try {
            await _supabase.auth.refreshSession();
            debugPrint('[ORDER_REPOSITORY] ✅ Session refreshed successfully');
          } catch (refreshError) {
            debugPrint('[ORDER_REPOSITORY] ⚠️ Could not refresh session: $refreshError');
            // Continue anyway - maybe we're using anon key
          }
        }

        // Create new channel
        currentChannel = _supabase.channel('orders_channel_${DateTime.now().millisecondsSinceEpoch}');

        currentChannel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.tableOrders,
          callback: (payload) {
            debugPrint('[ORDER_REPOSITORY] 🔔 Realtime event received: ${payload.eventType}');
            if (!controller.isClosed) {
              controller.add(payload);
              debugPrint('[ORDER_REPOSITORY] ✅ Payload added to controller');
            }
          },
        );

        await currentChannel!.subscribe((status, error) {
          debugPrint('[ORDER_REPOSITORY] 📡 Subscription status: $status');
          
          if (error != null) {
            debugPrint('[ORDER_REPOSITORY] ❌ Subscription error: $error');
            
            // Handle token expiration with retry
            final errorStr = error.toString();
            if (errorStr.contains('InvalidJWTToken') || errorStr.contains('expired')) {
              if (retryCount < maxRetries) {
                retryCount++;
                final delay = baseDelay * retryCount;
                debugPrint('[ORDER_REPOSITORY] 🔄 Token expired. Retrying in ${delay.inSeconds}s (attempt $retryCount/$maxRetries)...');
                
                Future.delayed(delay, () {
                  if (!controller.isClosed && !isSubscribed) {
                    setupSubscription();
                  }
                });
              } else {
                debugPrint('[ORDER_REPOSITORY] ❌ Max retries reached. Giving up.');
                if (!controller.isClosed) {
                  controller.addError(Exception('Failed to subscribe after $maxRetries attempts: Token expired'));
                }
              }
            } else {
              // Other errors
              if (!controller.isClosed) {
                controller.addError(error);
              }
            }
          } else {
            // Success!
            isSubscribed = true;
            retryCount = 0; // Reset on success
            debugPrint('[ORDER_REPOSITORY] ✅ Successfully subscribed to realtime changes');
          }
        });

      } catch (e) {
        debugPrint('[ORDER_REPOSITORY] ❌ Error setting up subscription: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Initial setup
    setupSubscription();

    // Cleanup
    controller.onCancel = () async {
      debugPrint('[ORDER_REPOSITORY] 🧹 Cancelling subscription...');
      if (currentChannel != null) {
        await currentChannel!.unsubscribe();
      }
      await controller.close();
    };

    return controller.stream;
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from(SupabaseConstants.tableOrders)
          .update({
            SupabaseConstants.colStatus: newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq(SupabaseConstants.colId, orderId)
          .timeout(_timeout);
    } catch (e) {
      throw Exception('Gagal memperbarui status: ${e.toString()}');
    }
  }

  /// Create a dummy order for testing/simulation
  Future<void> createDummyOrder() async {
    // 1. Fetch a real item to ensure FK constraint
    final itemResponse = await _supabase
        .from(SupabaseConstants.tableItems)
        .select('${SupabaseConstants.colId}, ${SupabaseConstants.colSellPrice}, ${SupabaseConstants.colName}')
        .limit(1)
        .maybeSingle();

    if (itemResponse == null) {
      throw Exception('Tidak ada item di database. Tambahkan item terlebih dahulu.');
    }

    final itemId = itemResponse[SupabaseConstants.colId] as String;
    final itemPrice = itemResponse[SupabaseConstants.colSellPrice] as int;
    final itemName = itemResponse[SupabaseConstants.colName] as String;

    // 2. Fetch a random housing block for valid FK constraint
    final housingBlockResponse = await _supabase
        .from(SupabaseConstants.tableHousingBlocks)
        .select(SupabaseConstants.colId)
        .limit(1)
        .maybeSingle();

    if (housingBlockResponse == null) {
      throw Exception('Tidak ada housing block di database. Tambahkan housing block terlebih dahulu.');
    }

    final housingBlockId = housingBlockResponse[SupabaseConstants.colId] as String;

    // 3. Prepare dummy order data
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // WRG-SIM-12345
    final code = 'WRG-SIM-${timestamp.toString().substring(timestamp.toString().length - 6)}';
    final qty = 1 + (DateTime.now().second % 3); // 1-3 items
    final total = itemPrice * qty;

    // 4. Insert Order with valid housing_block_id
    final orderResponse = await _supabase
        .from(SupabaseConstants.tableOrders)
        .insert({
          SupabaseConstants.colCode: code,
          SupabaseConstants.colCustomerName: 'Simulated User',
          SupabaseConstants.colPaymentMethod: 'qris',
          SupabaseConstants.colDeliveryType: 'delivery',
          SupabaseConstants.colStatus: 'paid', // Trigger "New Order" flow immediately
          SupabaseConstants.colTotal: total,
          SupabaseConstants.colHousingBlockId: housingBlockId, // Valid FK to housing_blocks
        })
        .select()
        .single();

    final orderId = orderResponse[SupabaseConstants.colId] as String;

    // 5. Insert Order Items
    await _supabase.from(SupabaseConstants.tableOrderItems).insert({
      SupabaseConstants.colOrderId: orderId,
      SupabaseConstants.colItemId: itemId,
      'item_name': itemName,
      SupabaseConstants.colQuantity: qty,
      SupabaseConstants.colPrice: itemPrice,
      SupabaseConstants.colSubtotal: total,
    });
  }
}
