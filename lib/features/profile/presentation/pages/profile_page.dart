import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/widgets/custom_bottom_nav.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authControllerProvider);
    final activeOutletState = ref.watch(activeOutletProvider);

    final userName = userState.value?.name ?? 'Admin Laundry';
    final outletName = activeOutletState.value?.name ?? 'Memuat Cabang...';
    final roleName = 'SUPER ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: const Color(0xFFF1F5F9), height: 1), // Top border
            // 1. User Header Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F62FE),
                            width: 2,
                          ),
                          color: const Color(0xFFE2E8F0),
                        ),
                        // Mimicking the photo with an Icon since we don't have the user image asset
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F62FE),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outletName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F62FE),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Account Settings Section
            _buildSectionHeader('PENGATURAN AKUN'),
            _buildMenuItem(
              icon: Icons.person,
              iconColor: const Color(0xFF0F62FE),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Edit Profil',
              subtitle: 'Ubah detail nama dan email',
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.lock,
              iconColor: const Color(0xFF0F62FE),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Ganti Kata Sandi',
              subtitle: 'Perbarui keamanan akun Anda',
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.store,
              iconColor: const Color(0xFF0F62FE),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Informasi Outlet',
              subtitle: 'Atur alamat dan jam operasional',
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.swap_horiz,
              iconColor: const Color(0xFF0F62FE),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Ganti Cabang Utama',
              subtitle: 'Pilih cabang lain untuk dikelola',
              onTap: () {
                context.push('/select-outlet');
              },
            ),

            // 3. Others Section
            _buildSectionHeader('LAINNYA'),
            _buildMenuItem(
              icon: Icons.notifications,
              iconColor: const Color(0xFF475569),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Notifikasi',
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              icon: Icons.help_outline,
              iconColor: const Color(0xFF475569),
              iconBg: const Color(0xFFF1F5F9),
              title: 'Pusat Bantuan',
            ),

            const SizedBox(height: 32),

            // 4. Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Keluar Sesi',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Version Footer
            const Text(
              'Versi 2.4.0 (Build 102)',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),

            const SizedBox(height: 48), // Padding for bottom nav
          ],
        ),
      ),

      // 5. Custom Bottom Nav Bar with FAB
      floatingActionButton: const CustomBottomNavFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA), // Slightly darker grey
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 72),
      child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }
}
