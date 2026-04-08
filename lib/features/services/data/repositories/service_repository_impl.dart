import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDatasource remoteDatasource;

  ServiceRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices() async {
    try {
      final services = await remoteDatasource.getServices();
      return right(services);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceItemOption>>> getServiceItems() async {
    try {
      final items = await remoteDatasource.getServiceItems();
      return right(items);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> createService({
    required String categoryName,
    required String itemName,
    required String processType,
    required List<ServiceVariantEntity> variants,
  }) async {
    try {
      final service = await remoteDatasource.createService(
        categoryName: categoryName,
        itemName: itemName,
        processType: processType,
        variants: variants,
      );
      return right(service);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> updateService(
    ServiceEntity service,
  ) async {
    try {
      final updated = await remoteDatasource.updateService(service);
      return right(updated);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderServices(
    List<ServiceEntity> orderedServices,
  ) async {
    try {
      await remoteDatasource.reorderServices(orderedServices);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteService(String id) async {
    try {
      await remoteDatasource.deleteService(id);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
