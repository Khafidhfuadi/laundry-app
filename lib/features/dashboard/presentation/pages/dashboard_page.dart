import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/custom_bottom_nav.dart';
import '../../../authentication/presentation/controllers/auth_controller.dart';
import '../../../outlet/presentation/controllers/active_outlet_controller.dart';
import '../../../transactions/presentation/controllers/transaction_controller.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionControllerProvider.notifier).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authControllerProvider);
    final trxState = ref.watch(transactionControllerProvider);
    final activeOutletState = ref.watch(activeOutletProvider);

    final userName = userState.value?.name ?? 'Admin';
    final outletName = activeOutletState.when(
      data: (outlet) => outlet != null
          ? outlet.name.toUpperCase()
          : 'TIDAK ADA OUTLET DIBUKA',
      loading: () => 'MEMUAT OUTLET...',
      error: (error, stack) => 'ERROR MEMUAT OUTLET',
    );

    int trxHariIni = 0;
    double pndpTotal = 0;
    int trxKemarin = 0;
    double pndpKemarin = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    List<double> dailyRevenue = List.filled(7, 0.0);

    if (trxState.hasValue && trxState.value != null) {
      final transactions = trxState.value!;

      // Get recent 3 transactions

      for (var trx in transactions) {
        final trxDate = DateTime(
          trx.createdAt.year,
          trx.createdAt.month,
          trx.createdAt.day,
        );

        // Today's metrics
        if (trxDate == today) {
          trxHariIni++;
          pndpTotal += trx.totalPrice;
        }

        // Yesterday's metrics
        if (trxDate == yesterday) {
          trxKemarin++;
          pndpKemarin += trx.totalPrice;
        }

        // 7 days revenue map
        final diff = today.difference(trxDate).inDays;
        if (diff >= 0 && diff < 7) {
          dailyRevenue[6 - diff] += (trx.totalPrice / 1000); // In thousands
        }
      }
    }

    // Hitung persentase perubahan vs kemarin
    String pctChange(num today, num yesterday) {
      if (yesterday == 0) return today > 0 ? '+100%' : '0%';
      final pct = ((today - yesterday) / yesterday * 100).round();
      return pct >= 0 ? '+$pct%' : '$pct%';
    }

    final trxChange = pctChange(trxHariIni, trxKemarin);
    final pndpChange = pctChange(pndpTotal, pndpKemarin);

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    String pndpHariIni = formatter.format(pndpTotal);

    double maxY = dailyRevenue.isNotEmpty
        ? dailyRevenue.reduce((curr, next) => curr > next ? curr : next)
        : 20.0;
    // Add 20% padding to max Y, minimum 20
    maxY = maxY < 20.0 ? 20.0 : maxY * 1.2;

    List<String> last7DaysLabels = [];
    for (int i = 6; i >= 0; i--) {
      last7DaysLabels.add(
        DateFormat('EEE', 'id_ID').format(today.subtract(Duration(days: i))),
      );
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/img/laundry-icon.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
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
                              outletName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(
                                  0xFF0F62FE,
                                ).withValues(alpha: 0.8),
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
                      change: trxChange,
                      isPositive: !trxChange.startsWith('-'),
                      icon: Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'PENDAPATAN\nHARI INI',
                      value: pndpHariIni,
                      change: pndpChange,
                      isPositive: !pndpChange.startsWith('-'),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Chart Section
              // Container(
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(20),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.02),
              //         blurRadius: 10,
              //         offset: const Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           const Text(
              //             'Pendapatan 7 Hari Terakhir',
              //             style: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //               color: Color(0xFF1E293B),
              //             ),
              //           ),
              //           const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
              //         ],
              //       ),
              //       const SizedBox(height: 24),
              //       SizedBox(
              //         height: 180,
              //         child: BarChart(
              //           BarChartData(
              //             alignment: BarChartAlignment.spaceAround,
              //             maxY: maxY,
              //             barTouchData: BarTouchData(enabled: false),
              //             titlesData: FlTitlesData(
              //               show: true,
              //               bottomTitles: AxisTitles(
              //                 sideTitles: SideTitles(
              //                   showTitles: true,
              //                   getTitlesWidget: (value, meta) {
              //                     final isToday = value.toInt() == 6;
              //                     return Padding(
              //                       padding: const EdgeInsets.only(top: 8.0),
              //                       child: Text(
              //                         last7DaysLabels[value.toInt()],
              //                         style: TextStyle(
              //                           color: isToday
              //                               ? const Color(0xFF0F62FE)
              //                               : const Color(0xFF94A3B8),
              //                           fontWeight: isToday
              //                               ? FontWeight.bold
              //                               : FontWeight.normal,
              //                           fontSize: 12,
              //                         ),
              //                       ),
              //                     );
              //                   },
              //                   reservedSize: 28,
              //                 ),
              //               ),
              //               leftTitles: const AxisTitles(
              //                 sideTitles: SideTitles(showTitles: false),
              //               ),
              //               topTitles: const AxisTitles(
              //                 sideTitles: SideTitles(showTitles: false),
              //               ),
              //               rightTitles: const AxisTitles(
              //                 sideTitles: SideTitles(showTitles: false),
              //               ),
              //             ),
              //             gridData: const FlGridData(show: false),
              //             borderData: FlBorderData(show: false),
              //             barGroups: List.generate(7, (index) {
              //               return _buildBarGroup(
              //                 index,
              //                 dailyRevenue[index],
              //                 index == 6,
              //               );
              //             }),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 24),

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
                    'Layanan',
                    Icons.layers_outlined,
                    const Color(0xFFE0E7FF),
                    () => context.push('/services'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Pelanggan',
                    Icons.people,
                    const Color(0xFFE0E7FF),
                    () => context.push('/customers'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Parfum',
                    Icons.local_florist_outlined,
                    const Color(0xFFE0E7FF),
                    () => context.push('/perfumes'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                  _buildQuickActionBtn(
                    context,
                    'Tambah Pengeluaran',
                    Icons.wallet_outlined,
                    const Color(0xFFE0E7FF),
                    () => context.push('/expenses'),
                    iconColor: const Color(0xFF0F62FE),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Recent Activities
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     const Text(
              //       'Aktivitas Terkini',
              //       style: TextStyle(
              //         fontSize: 16,
              //         fontWeight: FontWeight.bold,
              //         color: Color(0xFF1E293B),
              //       ),
              //     ),
              //     TextButton(
              //       onPressed: () => context.push('/transactions'),
              //       child: const Text(
              //         'LIHAT SEMUA',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF0F62FE),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 8),

              // Real Activities derived from state
              // if (recentTransactions.isEmpty)
              //   const Center(
              //     child: Padding(
              //       padding: EdgeInsets.all(20.0),
              //       child: Text(
              //         'Belum ada transaksi.',
              //         style: TextStyle(color: Color(0xFF94A3B8)),
              //       ),
              //     ),
              //   )
              // else
              //   ...recentTransactions.map((trx) {
              //     final String serviceSummary = trx.items.isNotEmpty
              //         ? '${trx.items.first.serviceVariant?.service?.name ?? 'Layanan'} - ${trx.items.first.quantity} ${trx.items.first.serviceVariant?.unitType ?? 'item'}${trx.items.length > 1 ? ' (+${trx.items.length - 1} lainnya)' : ''}'
              //         : 'Transaksi tanpa layanan';

              //     return Padding(
              //       padding: const EdgeInsets.only(bottom: 12.0),
              //       child: _buildActivityItem(
              //         id: trx.transactionCode,
              //         name: trx.customer?.name ?? 'Pelanggan',
              //         desc: serviceSummary,
              //         status: trx.status,
              //       ),
              //     );
              //   }),

              // const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ),

      // 7. Custom Bottom Nav Bar with FAB
      floatingActionButton: const CustomBottomNavFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
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
}
