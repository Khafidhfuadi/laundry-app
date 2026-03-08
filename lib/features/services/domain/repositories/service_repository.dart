import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/service_entity.dart';

abstract class ServiceRepository {
  Future<Either<Failure, List<ServiceEntity>>> getServices();
}
