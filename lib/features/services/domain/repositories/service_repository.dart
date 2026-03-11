import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/service_entity.dart';
import '../../data/datasources/service_remote_datasource.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<ServiceEntity>>> getServices();
  Future<Either<Failure, List<ServiceItemOption>>> getServiceItems();
  Future<Either<Failure, ServiceEntity>> createService({
    required String categoryName,
    required String itemName,
    required String processType,
    required List<ServiceVariantEntity> variants,
  });
  Future<Either<Failure, ServiceEntity>> updateService(ServiceEntity service);
  Future<Either<Failure, Unit>> deleteService(String id);
}
