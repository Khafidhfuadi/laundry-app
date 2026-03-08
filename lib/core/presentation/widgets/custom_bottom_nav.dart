import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavFab extends StatelessWidget {
  const CustomBottomNavFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/transactions');
    } else if (index == 2) {
      // route to Laporan if available
    } else if (index == 3) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _buildBottomNavItem(
                context,
                Icons.home_outlined,
                Icons.home,
                'Beranda',
                0,
              ),
              _buildBottomNavItem(
                context,
                Icons.receipt_long_outlined,
                Icons.receipt_long,
                'Pesanan',
                1,
              ),
              const SizedBox(width: 48), // Space for FAB
              _buildBottomNavItem(
                context,
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                'Laporan',
                2,
              ),
              _buildBottomNavItem(
                context,
                Icons.person_outline,
                Icons.person,
                'Profil',
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    IconData outlinedIcon,
    IconData solidIcon,
    String label,
    int index,
  ) {
    final isSelected = selectedIndex == index;
    final color = isSelected
        ? const Color(0xFF0F62FE)
        : const Color(0xFF94A3B8);
    final icon = isSelected ? solidIcon : outlinedIcon;

    return InkWell(
      onTap: () => _onItemTapped(context, index),
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
