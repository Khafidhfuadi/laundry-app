import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDatasource {
  Future<UserEntity> login(String email, String password);
  Future<void> logout();
  Future<UserEntity> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient supabaseClient;

  AuthRemoteDatasourceImpl(this.supabaseClient);

  @override
  Future<UserEntity> login(String email, String password) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login gagal, user tidak ditemukan.');
    }
    return _getUserData(response.user!.id, response.user!.email!);
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('Tidak ada sesi tersimpan.');
    return _getUserData(user.id, user.email ?? '');
  }

  Future<UserEntity> _getUserData(String uid, String email) async {
    // Membaca data dari tabel users (metadata)
    try {
      final data = await supabaseClient
          .from('users')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (data != null) {
        return UserEntity.fromJson(data);
      }

      // Fallback jika tidak ada data di tabel users
      return UserEntity(
        id: uid,
        email: email,
        role: 'staf',
        name: 'Staf Laundry',
      );
    } catch (e) {
      return UserEntity(
        id: uid,
        email: email,
        role: 'staf',
        name: 'Staf Laundry',
      );
    }
  }
}
