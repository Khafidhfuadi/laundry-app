import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

final customerRemoteDatasourceProvider = Provider<CustomerRemoteDatasource>((
  ref,
) {
  return CustomerRemoteDatasourceImpl(ref.watch(supabaseClientProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(customerRemoteDatasourceProvider));
});

class CustomerController extends AsyncNotifier<List<CustomerEntity>> {
  late CustomerRepository _repository;
  String _currentQuery = '';

  @override
  FutureOr<List<CustomerEntity>> build() async {
    _repository = ref.watch(customerRepositoryProvider);
    return _fetchCustomers();
  }

  Future<List<CustomerEntity>> _fetchCustomers() async {
    final result = _currentQuery.isEmpty
        ? await _repository.getCustomers()
        : await _repository.searchCustomers(_currentQuery);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (customers) => customers,
    );
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCustomers());
  }

  void search(String query) {
    _currentQuery = query;
    loadCustomers();
  }

  Future<bool> createCustomer(CustomerEntity customer) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCustomer(customer);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (created) {
        loadCustomers();
        return true;
      },
    );
  }

  Future<bool> updateCustomer(CustomerEntity customer) async {
    final result = await _repository.updateCustomer(customer);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        loadCustomers();
        return true;
      },
    );
  }

  Future<bool> deleteCustomer(String id) async {
    final result = await _repository.deleteCustomer(id);

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        loadCustomers();
        return true;
      },
    );
  }
}

final customerControllerProvider =
    AsyncNotifierProvider<CustomerController, List<CustomerEntity>>(
      CustomerController.new,
    );
