import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/service_entity.dart';

class ServiceItemOption {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;

  const ServiceItemOption({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
  });
}

abstract class ServiceRemoteDatasource {
  Future<List<ServiceEntity>> getServices();
  Future<List<ServiceItemOption>> getServiceItems();
  Future<ServiceEntity> createService({
    required String categoryName,
    required String itemName,
    required String variant,
    required String unitType,
    required double price,
    required String serviceType,
    required int estimatedHours,
  });
  Future<ServiceEntity> updateService(ServiceEntity service);
  Future<void> deleteService(String id);
}

class ServiceRemoteDatasourceImpl implements ServiceRemoteDatasource {
  final SupabaseClient supabaseClient;

  ServiceRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<ServiceEntity>> getServices() async {
    final response = await supabaseClient.from('services').select('''
          id,
          service_item_id,
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
        ''').order('service_item_id');

    return (response as List).map((e) => ServiceEntity.fromJson(e)).toList();
  }

  @override
  Future<List<ServiceItemOption>> getServiceItems() async {
    final response = await supabaseClient.from('service_items').select('''
          id,
          name,
          service_category_id,
          service_categories (
            id,
            name
          )
        ''').order('name');

    return (response as List).map((e) {
      final cat = e['service_categories'] ?? {};
      return ServiceItemOption(
        id: e['id'] as String,
        name: e['name'] as String,
        categoryId: e['service_category_id'] as String? ?? '',
        categoryName: cat['name'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<ServiceEntity> createService({
    required String categoryName,
    required String itemName,
    required String variant,
    required String unitType,
    required double price,
    required String serviceType,
    required int estimatedHours,
  }) async {
    // 1. Upsert category
    final catResponse = await supabaseClient
        .from('service_categories')
        .upsert({'name': categoryName.trim()}, onConflict: 'name')
        .select('id')
        .single();
    final categoryId = catResponse['id'] as String;

    // 2. Upsert service_item
    final itemResponse = await supabaseClient
        .from('service_items')
        .upsert(
          {'name': itemName.trim(), 'service_category_id': categoryId},
          onConflict: 'name,service_category_id',
        )
        .select('id')
        .single();
    final serviceItemId = itemResponse['id'] as String;

    // 3. Insert service
    final response = await supabaseClient
        .from('services')
        .insert({
          'service_item_id': serviceItemId,
          'variant': variant.trim(),
          'unit_type': unitType,
          'price': price,
          'service_type': serviceType,
          'estimated_hours': estimatedHours,
        })
        .select('''
          id,
          service_item_id,
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
        ''')
        .single();

    return ServiceEntity.fromJson(response);
  }

  @override
  Future<ServiceEntity> updateService(ServiceEntity service) async {
    final response = await supabaseClient
        .from('services')
        .update({
          'variant': service.variant.trim(),
          'unit_type': service.unitType,
          'price': service.price,
          'service_type': service.serviceType,
          'estimated_hours': service.estimatedHours,
        })
        .eq('id', service.id)
        .select('''
          id,
          service_item_id,
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
        ''')
        .single();

    return ServiceEntity.fromJson(response);
  }

  @override
  Future<void> deleteService(String id) async {
    await supabaseClient.from('services').delete().eq('id', id);
  }
}
