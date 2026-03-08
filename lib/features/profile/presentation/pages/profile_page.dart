import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../authentication/presentation/controllers/auth_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final int _selectedIndex = 3; // 3 for Profil in Bottom Nav

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/transactions');
    } else if (index == 2) {
      // route to Laporan if available
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authControllerProvider);
    final userName = userState.value?.name ?? 'Admin Laundry';
    // Dummy outlet data matching design since we might not have it strictly bound to auth right now
    final outletName = 'Outlet Maju Jaya';
    final roleName = 'SUPER ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: const Color(0xFFF1F5F9), height: 1), // Top border
            // 1. User Header Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
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
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F62FE).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/transactions/add'),
          backgroundColor: const Color(0xFF0F62FE),
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.home_outlined, 'Beranda', 0),
                _buildBottomNavItem(Icons.receipt_long_outlined, 'Pesanan', 1),
                const SizedBox(width: 48), // Space for FAB
                _buildBottomNavItem(Icons.bar_chart_outlined, 'Laporan', 2),
                _buildBottomNavItem(
                  Icons.person,
                  'Profil',
                  3,
                ), // Solid icon for active
              ],
            ),
          ),
        ),
      ),
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
  }) {
    return Container(
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
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 72),
      child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? const Color(0xFF0F62FE)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
