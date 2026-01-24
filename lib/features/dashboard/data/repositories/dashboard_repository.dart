import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_summary.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<DashboardSummary> getTodaySummary() async {
    try {
      final response = await _supabase.rpc('get_dashboard_summary');
      return DashboardSummary.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }
}
