import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../../data/datasources/service_remote_datasource.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

final serviceRemoteDatasourceProvider = Provider<ServiceRemoteDatasource>((
  ref,
) {
  return ServiceRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.watch(serviceRemoteDatasourceProvider));
});

class ServiceController extends AsyncNotifier<List<ServiceEntity>> {
  late ServiceRepository _repository;

  @override
  FutureOr<List<ServiceEntity>> build() async {
    _repository = ref.watch(serviceRepositoryProvider);
    return _fetchServices();
  }

  Future<List<ServiceEntity>> _fetchServices() async {
    final result = await _repository.getServices();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (services) => services,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchServices());
  }
}

final serviceControllerProvider =
    AsyncNotifierProvider<ServiceController, List<ServiceEntity>>(
      ServiceController.new,
    );
