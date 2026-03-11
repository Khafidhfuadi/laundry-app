import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/perfume_entity.dart';

abstract class PerfumeRemoteDatasource {
  Future<List<PerfumeEntity>> getPerfumes();
  Future<PerfumeEntity> createPerfume(PerfumeEntity perfume);
  Future<PerfumeEntity> updatePerfume(PerfumeEntity perfume);
  Future<void> deletePerfume(String id);
}

class PerfumeRemoteDatasourceImpl implements PerfumeRemoteDatasource {
  final SupabaseClient supabaseClient;

  PerfumeRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<List<PerfumeEntity>> getPerfumes() async {
    final response = await supabaseClient
        .from('perfumes')
        .select('*')
        .order('name');
    return (response as List).map((e) => PerfumeEntity.fromJson(e)).toList();
  }

  @override
  Future<PerfumeEntity> createPerfume(PerfumeEntity perfume) async {
    final response = await supabaseClient
        .from('perfumes')
        .insert({'name': perfume.name})
        .select()
        .single();
    return PerfumeEntity.fromJson(response);
  }

  @override
  Future<PerfumeEntity> updatePerfume(PerfumeEntity perfume) async {
    final response = await supabaseClient
        .from('perfumes')
        .update({'name': perfume.name})
        .eq('id', perfume.id)
        .select()
        .single();
    return PerfumeEntity.fromJson(response);
  }

  @override
  Future<void> deletePerfume(String id) async {
    await supabaseClient.from('perfumes').delete().eq('id', id);
  }
}
