import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/controllers/auth_controller.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/outlet/presentation/pages/outlet_page.dart';
import '../../features/services/presentation/pages/service_page.dart';
import '../../features/customers/presentation/pages/customer_page.dart';
import '../../features/transactions/presentation/pages/transaction_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/expenses/presentation/pages/expense_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/reports/presentation/pages/report_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Jika state autentikasi sedang dimuat, biarkan di halaman saat ini atau splash
      if (authStateAsync.isLoading) return null;

      final isAuthenticated = authStateAsync.value?.session != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isGoingToLogin) {
        return '/login'; // Belum login, arahkan ke login
      }

      if (isAuthenticated && isGoingToLogin) {
        return '/dashboard'; // Sudah login tapi mencoba ke halaman login, arahkan ke dashboard
      }

      return null; // Tidak perlu redirect
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
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
        path: '/transactions',
        builder: (context, state) => const TransactionPage(),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensePage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
