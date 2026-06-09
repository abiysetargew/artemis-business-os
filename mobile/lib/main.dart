import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:artemis_business_os/features/auth/presentation/screens/login_screen.dart';
import 'package:artemis_business_os/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:artemis_business_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:artemis_business_os/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:artemis_business_os/features/payments/presentation/screens/create_payment_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/production_batches_screen.dart';
import 'package:artemis_business_os/features/reports/presentation/screens/reports_screen.dart';
import 'package:artemis_business_os/features/sales/presentation/screens/create_sales_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const ProviderScope(child: ArtemisApp()));
}

class ArtemisApp extends ConsumerWidget {
  const ArtemisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    final router = GoRouter(
      initialLocation: authState.user != null ? '/dashboard' : '/login',
      redirect: (context, state) {
        final isLoggedIn = authState.user != null;
        final isGoingToLogin = state.matchedLocation == '/login';

        if (!isLoggedIn && !isGoingToLogin) return '/login';
        if (isLoggedIn && isGoingToLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryListScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) => const CustomerListScreen(),
        ),
        GoRoute(
          path: '/sales/create',
          builder: (context, state) => const CreateSalesOrderScreen(),
        ),
        GoRoute(
          path: '/payments/create',
          builder: (context, state) => const CreatePaymentScreen(),
        ),
        GoRoute(
          path: '/production/batches',
          builder: (context, state) => const ProductionBatchesScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Artemis Business OS',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
