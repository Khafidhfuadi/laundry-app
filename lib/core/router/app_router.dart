import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/outlet/presentation/controllers/active_outlet_controller.dart';
import '../../features/outlet/presentation/pages/outlet_selection_page.dart';
import '../../features/outlet/presentation/pages/outlet_page.dart';
import '../../features/services/presentation/pages/service_page.dart';
import '../../features/customers/presentation/pages/customer_page.dart';
import '../../features/perfumes/presentation/pages/perfume_page.dart';
import '../../features/transactions/presentation/pages/transaction_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/expenses/presentation/pages/expense_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/report_page.dart';
import '../../features/reports/presentation/pages/report_detail_page.dart';
import '../../features/reports/domain/entities/report_detail.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  final activeOutletAsync = ref.watch(activeOutletProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Jika state autentikasi sedang dimuat, biarkan
      if (authStateAsync.isLoading) return null;

      final isAuthenticated = authStateAsync.value?.session != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSelectOutlet = state.matchedLocation == '/select-outlet';

      if (!isAuthenticated && !isGoingToLogin) {
        return '/login'; // Belum login, arahkan ke login
      }

      if (isAuthenticated) {
        // Wait for outlet state to load before forcing redirects to avoid flickering
        if (activeOutletAsync.isLoading) return null;

        final hasSelectedOutlet = activeOutletAsync.value != null;

        if (!hasSelectedOutlet && !isGoingToSelectOutlet) {
          return '/select-outlet';
        }

        if (hasSelectedOutlet && (isGoingToLogin || isGoingToSelectOutlet)) {
          return '/dashboard'; // Sudah pilih outlet, jangan biarkan balik ke login/select-outlet sembarangan
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/select-outlet',
        builder: (context, state) => const OutletSelectionPage(),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: DashboardPage()),
      ),
      GoRoute(
        path: '/outlets',
        builder: (context, state) => const OutletPage(),
      ),
      GoRoute(
        path: '/services',
        builder: (context, state) => const ServicePage(),
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomerPage(),
      ),
      GoRoute(
        path: '/perfumes',
        builder: (context, state) => const PerfumePage(),
      ),
      GoRoute(
        path: '/transactions',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TransactionPage()),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailPage(transactionId: id);
        },
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensePage(),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ReportPage()),
      ),
      GoRoute(
        path: '/reports/income',
        builder: (context, state) =>
            const ReportDetailPage(type: ReportDetailType.income),
      ),
      GoRoute(
        path: '/reports/expense',
        builder: (context, state) =>
            const ReportDetailPage(type: ReportDetailType.expense),
      ),
      GoRoute(
        path: '/reports/net-profit',
        builder: (context, state) =>
            const ReportDetailPage(type: ReportDetailType.netProfit),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProfilePage()),
      ),
    ],
  );
});
