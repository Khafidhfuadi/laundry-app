import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/outlet_entity.dart';
import 'outlet_controller.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';

class ActiveOutletController extends AsyncNotifier<OutletEntity?> {
  static const String _activeOutletKey = 'active_outlet_id';

  @override
  FutureOr<OutletEntity?> build() async {
    // Rebuild dependent on auth state so when user logs out, active outlet is cleared as well
    ref.watch(authControllerProvider); 
    return _fetchActiveOutlet();
  }

  Future<OutletEntity?> _fetchActiveOutlet() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedId = prefs.getString(_activeOutletKey);

    if (savedId == null || savedId.isEmpty) {
      return null;
    }

    try {
      final repository = ref.read(outletRepositoryProvider);
      final outletEither = await repository.getOutletById(savedId);
      return outletEither.fold(
        (l) => null,
        (outlet) => outlet,
      );
    } catch (e) {
      // If fetching fails (e.g., outlet deleted), clear the preference
      await prefs.remove(_activeOutletKey);
      return null;
    }
  }

  Future<void> setActiveOutlet(OutletEntity outlet) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_activeOutletKey, outlet.id);
    state = AsyncValue.data(outlet);
  }

  Future<void> clearActiveOutlet() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_activeOutletKey);
    state = const AsyncValue.data(null);
  }
}

final activeOutletProvider = AsyncNotifierProvider<ActiveOutletController, OutletEntity?>(
  ActiveOutletController.new,
);
