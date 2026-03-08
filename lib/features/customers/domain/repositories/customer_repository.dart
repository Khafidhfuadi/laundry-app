import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers();
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id);
  Future<Either<Failure, CustomerEntity>> createCustomer(
    CustomerEntity customer,
  );
  Future<Either<Failure, CustomerEntity>> updateCustomer(
    CustomerEntity customer,
  );
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query);
}
