import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/outlet_entity.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../datasources/outlet_remote_datasource.dart';

class OutletRepositoryImpl implements OutletRepository {
  final OutletRemoteDatasource remoteDatasource;

  OutletRepositoryImpl(this.remoteDatasource);

  @override
  Future<Either<Failure, List<OutletEntity>>> getOutlets() async {
    try {
      final outlets = await remoteDatasource.getOutlets();
      return right(outlets);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OutletEntity>> getOutletById(String id) async {
    try {
      final outlet = await remoteDatasource.getOutletById(id);
      return right(outlet);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OutletEntity>> createOutlet(
    OutletEntity outlet,
  ) async {
    try {
      final created = await remoteDatasource.createOutlet(outlet);
      return right(created);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OutletEntity>> updateOutlet(
    OutletEntity outlet,
  ) async {
    try {
      final updated = await remoteDatasource.updateOutlet(outlet);
      return right(updated);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOutlet(String id) async {
    try {
      await remoteDatasource.deleteOutlet(id);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
