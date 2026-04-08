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

/// Provider untuk daftar service items (untuk dropdown di form)
final serviceItemsProvider = FutureProvider<List<ServiceItemOption>>((
  ref,
) async {
  final repo = ref.watch(serviceRepositoryProvider);
  final result = await repo.getServiceItems();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
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

  Future<bool> createService({
    required String categoryName,
    required String itemName,
    required String processType,
    required List<ServiceVariantEntity> variants,
  }) async {
    final result = await _repository.createService(
      categoryName: categoryName,
      itemName: itemName,
      processType: processType,
      variants: variants,
    );

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (created) {
        refresh();
        // Refresh service items cache
        ref.invalidate(serviceItemsProvider);
        return true;
      },
    );
  }

  Future<bool> updateService(ServiceEntity service) async {
    final result = await _repository.updateService(service);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> reorderServices(List<ServiceEntity> orderedServices) async {
    final optimistic = orderedServices
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(sortOrder: entry.key))
        .toList();
    state = AsyncValue.data(optimistic);

    final result = await _repository.reorderServices(optimistic);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        refresh();
        return false;
      },
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> deleteService(String id) async {
    final result = await _repository.deleteService(id);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        refresh();
        return true;
      },
    );
  }
}

final serviceControllerProvider =
    AsyncNotifierProvider<ServiceController, List<ServiceEntity>>(
      ServiceController.new,
    );
