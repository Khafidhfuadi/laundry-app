import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionControllerProvider.notifier).loadTransactions();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // In a real shell routing scenario, this would navigate to different branches.
    // Here we handle basic navigation or visual state.
    if (index == 1) {
      context.push('/transactions');
    } else if (index == 2) {
      context.push('/customers');
    } else if (index == 3) {
      context.push('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authControllerProvider);
    final trxState = ref.watch(transactionControllerProvider);
    final userName = userState.value?.name ?? 'Admin Budi';

    // Default dummy data if empty
    int trxHariIni = 42;
    String pndpHariIni = "Rp 1.250k";

    // In real app, calculate from trxState if available
    if (trxState.hasValue && trxState.value!.isNotEmpty) {
      // If we want to really show transaction count from state:
      // trxHariIni = trxState.value!.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Bar Area
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_laundry_service,
                          color: Color(0xFF0F62FE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Laundry Hub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Profile Area
              Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF38BDF8),
                    child: Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat datang,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFF0F62FE),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'OUTLET SUDIRMAN - JAKARTA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F62FE).withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'TRANSAKSI\nHARI INI',
                      value: trxHariIni.toString(),
                      change: '+12%',
                      isPositive: true,
                      icon: Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'PENDAPATAN\nHARI INI',
                      value: pndpHariIni,
                      change: '+5%',
                      isPositive: true,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Chart Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pendapatan 7 Hari Terakhir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 20,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const titles = [
                                    'Sen',
                                    'Sel',
                                    'Rab',
                                    'Kam',
                                    'Jum',
                                    'Sab',
                                    'Min',
                                  ];
                                  final isSab =
                                      value.toInt() == 5; // Highlight Sab
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      titles[value.toInt()],
                                      style: TextStyle(
                                        color: isSab
                                            ? const Color(0xFF0F62FE)
                                            : const Color(0xFF94A3B8),
                                        fontWeight: isSab
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 28,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _buildBarGroup(0, 8, false),
                            _buildBarGroup(1, 13, false),
                            _buildBarGroup(2, 10, false),
                            _buildBarGroup(3, 15, false),
                            _buildBarGroup(
                              4,
                              0,
                              false,
                            ), // Jum is empty in dummy like reference
                            _buildBarGroup(5, 18, true), // Sab is highlighted
                            _buildBarGroup(6, 7, false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Quick Actions
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionBtn(
                    context,
                    'Transaksi Baru',
                    Icons.add,
                    const Color(0xFF0F62FE),
                    () => context.push('/transactions/add'),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Cek Status',
                    Icons.search,
                    const Color(0xFFE0E7FF),
                    () => context.push('/transactions'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Data Pelanggan',
                    Icons.people,
                    const Color(0xFFE0E7FF),
                    () => context.push('/customers'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Laporan',
                    Icons.bar_chart,
                    const Color(0xFFE0E7FF),
                    () {},
                    iconColor: const Color(0xFF0F62FE),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Recent Activities
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aktivitas Terkini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text(
                      'LIHAT SEMUA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F62FE),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dummy Activities (To match Design)
              _buildActivityItem(
                id: '#TRX-9821',
                name: 'Siska Pratiwi',
                desc: 'Cuci Kering Lipat - 3.5kg',
                status: 'PROCESS',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                id: '#TRX-9820',
                name: 'Andi Wijaya',
                desc: 'Cuci Setrika - 5.0kg',
                status: 'READY',
              ),
              const SizedBox(height: 12),
              _buildActivityItem(
                id: '#TRX-9819',
                name: 'Bu Rina',
                desc: 'Bedcover King Size',
                status: 'READY',
                defaultIcon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFDBEAFE),
              ),

              const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ),

      // 7. Custom Bottom Nav Bar with FAB
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
                _buildBottomNavItem(Icons.home, 'Beranda', 0),
                _buildBottomNavItem(Icons.receipt_long, 'Pesanan', 1),
                const SizedBox(width: 48), // Space for FAB
                _buildBottomNavItem(Icons.people_outline, 'Pelanggan', 2),
                _buildBottomNavItem(Icons.person_outline, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              Icon(icon, color: const Color(0xFF0F62FE), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                change,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPositive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'vs kemarin',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, bool isHighlighted) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHighlighted
              ? const Color(0xFF0F62FE)
              : const Color(0xFFBFD4FF),
          width: 28,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context,
    String title,
    IconData icon,
    Color iconBgColor,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String id,
    required String name,
    required String desc,
    required String status,
    IconData defaultIcon = Icons.group_work_outlined,
    Color iconColor = const Color(0xFFF97316),
    Color iconBgColor = const Color(0xFFFFEDD5),
  }) {
    if (status == 'READY' && defaultIcon == Icons.group_work_outlined) {
      defaultIcon = Icons.check_circle_outline;
      iconColor = const Color(0xFF10B981);
      iconBgColor = const Color(0xFFD1FAE5);
    } else if (status == 'PROCESS' &&
        defaultIcon == Icons.group_work_outlined) {
      defaultIcon = Icons.sync;
      iconColor = const Color(0xFFF97316);
      iconBgColor = const Color(0xFFFFEDD5);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(defaultIcon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                    children: [
                      TextSpan(
                        text: '$id - ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'PROCESS'
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status == 'PROCESS'
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
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
