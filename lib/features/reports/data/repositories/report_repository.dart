import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/top_item_model.dart';

class ReportRepository {
  final SupabaseClient _supabase;

  ReportRepository(this._supabase);

  Future<List<TopItem>> getTopSellingItems(DateTime start, DateTime end) async {
    try {
      final response = await _supabase.rpc(
        'get_top_selling_items',
        params: {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
          'limit_count': 5,
        },
      );
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => TopItem.fromJson(e as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat item terlaris: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
