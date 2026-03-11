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
    required String processType,
    required List<ServiceVariantEntity> variants,
  });
  Future<ServiceEntity> updateService(ServiceEntity service);
  Future<void> deleteService(String id);
}

class ServiceRemoteDatasourceImpl implements ServiceRemoteDatasource {
  final SupabaseClient supabaseClient;

  ServiceRemoteDatasourceImpl(this.supabaseClient);

  static const _serviceSelect = '''
    id,
    name,
    category_id,
    process_type,
    service_categories (
      name
    ),
    service_variants (
      id,
      service_id,
      variant,
      unit_type,
      price,
      service_type,
      estimated_hours,
      notes
    )
  ''';

  @override
  Future<List<ServiceEntity>> getServices() async {
    final response = await supabaseClient
        .from('services')
        .select(_serviceSelect)
        .order('name');
    final mapped = (response as List).map((e) => ServiceEntity.fromJson(e)).toList();
    // Sort variants by name for consistency
    for (var s in mapped) {
      s.variants.sort((a, b) => a.variantName.compareTo(b.variantName));
    }
    return mapped;
  }

  @override
  Future<List<ServiceItemOption>> getServiceItems() async {
    final response = await supabaseClient
        .from('services')
        .select('''
          id,
          name,
          category_id,
          service_categories (
            id,
            name
          )
        ''')
        .order('name');

    return (response as List).map((e) {
      final cat = e['service_categories'] ?? {};
      return ServiceItemOption(
        id: e['id'] as String,
        name: e['name'] as String,
        categoryId: e['category_id'] as String? ?? '',
        categoryName: cat['name'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<ServiceEntity> createService({
    required String categoryName,
    required String itemName,
    required String processType,
    required List<ServiceVariantEntity> variants,
  }) async {
    // 1. Get or Create category
    String categoryId;
    final catName = categoryName.trim();
    final existingCat = await supabaseClient
        .from('service_categories')
        .select('id')
        .ilike('name', catName)
        .maybeSingle();
        
    if (existingCat != null) {
      categoryId = existingCat['id'] as String;
    } else {
      final newCat = await supabaseClient
          .from('service_categories')
          .insert({'name': catName})
          .select('id')
          .single();
      categoryId = newCat['id'] as String;
    }

    // 2. Insert services (Master)
    final serviceResponse = await supabaseClient
        .from('services')
        .insert({
          'name': itemName.trim(),
          'category_id': categoryId,
          'process_type': processType.trim(),
        })
        .select('id')
        .single();
    final serviceId = serviceResponse['id'] as String;

    // 3. Insert service variants (Detail)
    if (variants.isNotEmpty) {
      final variantsData = variants.map((v) {
        return {
          'service_id': serviceId,
          'variant': v.variantName.trim(),
          'unit_type': v.unitType,
          'price': v.price,
          'service_type': v.serviceType,
          'estimated_hours': v.estimatedHours,
          'notes': v.notes.trim(),
        };
      }).toList();
      
      await supabaseClient.from('service_variants').insert(variantsData);
    }

    // 4. Return updated entity
    final response = await supabaseClient
        .from('services')
        .select(_serviceSelect)
        .eq('id', serviceId)
        .single();

    return ServiceEntity.fromJson(response);
  }

  @override
  Future<ServiceEntity> updateService(ServiceEntity service) async {
    // 1. Get or Create Category
    String categoryId;
    final catName = service.categoryName.trim();
    final existingCat = await supabaseClient
        .from('service_categories')
        .select('id')
        .ilike('name', catName)
        .maybeSingle();

    if (existingCat != null) {
      categoryId = existingCat['id'] as String;
    } else {
      final newCat = await supabaseClient
          .from('service_categories')
          .insert({'name': catName})
          .select('id')
          .single();
      categoryId = newCat['id'] as String;
    }

    // 2. Update Master (services)
    await supabaseClient
        .from('services')
        .update({
          'name': service.name.trim(),
          'category_id': categoryId,
          'process_type': service.processType.trim(),
        })
        .eq('id', service.id);

    // 3. Update or Insert Details
    // Safe way: Upsert by ID if exists, Insert if no ID.
    // For simplicity with Supabase, upsert without onConflict works on PK.
    for (var v in service.variants) {
      final map = {
        'service_id': service.id,
        'variant': v.variantName.trim(),
        'unit_type': v.unitType,
        'price': v.price,
        'service_type': v.serviceType,
        'estimated_hours': v.estimatedHours,
        'notes': v.notes.trim(),
      };
      // If it's an existing variant, we must include its ID to trigger update instead of insert
      if (v.id.isNotEmpty && !v.id.startsWith('temp_')) {
        map['id'] = v.id;
      }
      await supabaseClient.from('service_variants').upsert(map);
    }

    // 4. Return updated entity
    final response = await supabaseClient
        .from('services')
        .select(_serviceSelect)
        .eq('id', service.id)
        .single();

    return ServiceEntity.fromJson(response);
  }

  @override
  Future<void> deleteService(String id) async {
    // Delete variants first (if not cascading) then delete service
    await supabaseClient.from('service_variants').delete().eq('service_id', id);
    await supabaseClient.from('services').delete().eq('id', id);
  }
}
