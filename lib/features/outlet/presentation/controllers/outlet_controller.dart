import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/outlet_entity.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../../data/datasources/outlet_remote_datasource.dart';
import '../../data/repositories/outlet_repository_impl.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart'; // import supabaseClientProvider

// Dependency Injection Providers
final outletRemoteDatasourceProvider = Provider<OutletRemoteDatasource>((ref) {
  return OutletRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

final outletRepositoryProvider = Provider<OutletRepository>((ref) {
  return OutletRepositoryImpl(ref.watch(outletRemoteDatasourceProvider));
});

// StateNotifier / AsyncNotifier untuk Data Outlets
class OutletController extends AsyncNotifier<List<OutletEntity>> {
  late OutletRepository _repository;

  @override
  FutureOr<List<OutletEntity>> build() async {
    _repository = ref.watch(outletRepositoryProvider);
    return _fetchOutlets();
  }

  Future<List<OutletEntity>> _fetchOutlets() async {
    final result = await _repository.getOutlets();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (outlets) => outlets,
    );
  }

  Future<void> loadOutlets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOutlets());
  }

  Future<bool> createOutlet(OutletEntity outlet) async {
    state = const AsyncValue.loading();
    final result = await _repository.createOutlet(outlet);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (created) {
        // Refresh daftar setelah berhasil buat
        loadOutlets();
        return true;
      },
    );
  }
}

final outletControllerProvider =
    AsyncNotifierProvider<OutletController, List<OutletEntity>>(
      OutletController.new,
    );
