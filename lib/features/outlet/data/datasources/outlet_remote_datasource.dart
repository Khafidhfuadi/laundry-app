import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/outlet_entity.dart';

abstract class OutletRemoteDatasource {
  Future<List<OutletEntity>> getOutlets();
  Future<OutletEntity> getOutletById(String id);
  Future<OutletEntity> createOutlet(OutletEntity outlet);
  Future<OutletEntity> updateOutlet(OutletEntity outlet);
  Future<void> deleteOutlet(String id);
}

class OutletRemoteDatasourceImpl implements OutletRemoteDatasource {
  final SupabaseClient supabaseClient;

  OutletRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<OutletEntity>> getOutlets() async {
    final response = await supabaseClient
        .from('outlets')
        .select()
        .order('name');

    return (response as List).map((e) => OutletEntity.fromJson(e)).toList();
  }

  @override
  Future<OutletEntity> getOutletById(String id) async {
    final response = await supabaseClient
        .from('outlets')
        .select()
        .eq('id', id)
        .single();

    return OutletEntity.fromJson(response);
  }

  @override
  Future<OutletEntity> createOutlet(OutletEntity outlet) async {
    final response = await supabaseClient
        .from('outlets')
        .insert(outlet.toJson())
        .select()
        .single();

    return OutletEntity.fromJson(response);
  }

  @override
  Future<OutletEntity> updateOutlet(OutletEntity outlet) async {
    final response = await supabaseClient
        .from('outlets')
        .update(outlet.toJson())
        .eq('id', outlet.id)
        .select()
        .single();

    return OutletEntity.fromJson(response);
  }

  @override
  Future<void> deleteOutlet(String id) async {
    await supabaseClient.from('outlets').delete().eq('id', id);
  }
}
