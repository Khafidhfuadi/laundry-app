import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/service_entity.dart';

abstract class ServiceRemoteDatasource {
  Future<List<ServiceEntity>> getServices();
}

class ServiceRemoteDatasourceImpl implements ServiceRemoteDatasource {
  final SupabaseClient supabaseClient;

  ServiceRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<ServiceEntity>> getServices() async {
    // Menggunakan query inner join Supabase:
    // GET services yang melakukan inner join ke service_items dan service_categories
    final response = await supabaseClient.from('services').select('''
          id,
          variant,
          unit_type,
          price,
          service_type,
          estimated_hours,
          service_items (
            name,
            service_categories (
              name
            )
          )
        ''');

    return (response as List).map((e) => ServiceEntity.fromJson(e)).toList();
  }
}
