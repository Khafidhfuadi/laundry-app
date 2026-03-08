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
}
