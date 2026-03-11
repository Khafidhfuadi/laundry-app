import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/perfume_remote_datasource.dart';
import '../../domain/entities/perfume_entity.dart';

final perfumeDatasourceProvider = Provider<PerfumeRemoteDatasource>((ref) {
  return PerfumeRemoteDatasourceImpl(Supabase.instance.client);
});

class PerfumeController extends AsyncNotifier<List<PerfumeEntity>> {
  late PerfumeRemoteDatasource _datasource;

  @override
  FutureOr<List<PerfumeEntity>> build() async {
    _datasource = ref.watch(perfumeDatasourceProvider);
    return _fetchPerfumes();
  }

  Future<List<PerfumeEntity>> _fetchPerfumes() async {
     return await _datasource.getPerfumes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPerfumes());
  }

  Future<bool> createPerfume(PerfumeEntity perfume) async {
    try {
      await _datasource.createPerfume(perfume);
      refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePerfume(PerfumeEntity perfume) async {
    try {
      await _datasource.updatePerfume(perfume);
      refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePerfume(String id) async {
    try {
      await _datasource.deletePerfume(id);
      refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final perfumeControllerProvider =
    AsyncNotifierProvider<PerfumeController, List<PerfumeEntity>>(
      PerfumeController.new,
    );

