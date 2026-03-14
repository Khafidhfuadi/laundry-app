import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDatasource remoteDatasource;

  CustomerRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers() async {
    try {
      final customers = await remoteDatasource.getCustomers();
      return right(customers);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id) async {
    try {
      final customer = await remoteDatasource.getCustomerById(id);
      return right(customer);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(
    CustomerEntity customer,
  ) async {
    try {
      final created = await remoteDatasource.createCustomer(customer);
      return right(created);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  ) async {
    try {
      final updated = await remoteDatasource.updateCustomer(customer);
      return right(updated);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await remoteDatasource.deleteCustomer(id);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(
    String query,
  ) async {
    try {
      final results = await remoteDatasource.searchCustomers(query);
      return right(results);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
