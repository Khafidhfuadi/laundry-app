import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/outlet_entity.dart';

abstract class OutletRepository {
  Future<Either<Failure, List<OutletEntity>>> getOutlets();
  Future<Either<Failure, OutletEntity>> getOutletById(String id);
  Future<Either<Failure, OutletEntity>> createOutlet(OutletEntity outlet);
  Future<Either<Failure, OutletEntity>> updateOutlet(OutletEntity outlet);
  Future<Either<Failure, void>> deleteOutlet(String id);
}
