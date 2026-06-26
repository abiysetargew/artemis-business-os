import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/app_logo.dart';
import 'package:artemis_business_os/core/widgets/main_shell.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:artemis_business_os/features/auth/presentation/screens/login_screen.dart';
import 'package:artemis_business_os/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:artemis_business_os/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:artemis_business_os/features/customers/presentation/screens/create_customer_screen.dart';
import 'package:artemis_business_os/features/customers/presentation/screens/edit_customer_screen.dart';
import 'package:artemis_business_os/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:artemis_business_os/features/inventory/presentation/screens/inventory_item_detail_screen.dart';
import 'package:artemis_business_os/features/inventory/presentation/screens/inventory_list_screen.dart';
import 'package:artemis_business_os/features/payments/presentation/screens/create_payment_screen.dart';
import 'package:artemis_business_os/features/payments/presentation/screens/payment_detail_screen.dart';
import 'package:artemis_business_os/features/payments/presentation/screens/payments_list_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/bom_detail_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/boms_list_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/create_bom_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/create_production_batch_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/edit_bom_screen.dart';
import 'package:artemis_business_os/features/production/presentation/screens/production_batches_screen.dart';
import 'package:artemis_business_os/features/products/presentation/screens/create_product_screen.dart';
import 'package:artemis_business_os/features/products/presentation/screens/edit_product_screen.dart';
import 'package:artemis_business_os/features/products/presentation/screens/products_list_screen.dart';
import 'package:artemis_business_os/features/reports/presentation/screens/reports_screen.dart';
import 'package:artemis_business_os/features/sales/presentation/screens/create_sales_order_screen.dart';
import 'package:artemis_business_os/features/sales/presentation/screens/sales_list_screen.dart';
import 'package:artemis_business_os/features/settings/presentation/screens/settings_screen.dart';
import 'package:artemis_business_os/features/users/presentation/screens/create_user_screen.dart';
import 'package:artemis_business_os/features/users/presentation/screens/edit_user_screen.dart';
import 'package:artemis_business_os/features/users/presentation/screens/users_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(authNotifierProvider.notifier).checkAuth();
  runApp(
    UncontrolledProviderScope(container: container, child: const ArtemisApp()),
  );
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _sub = _ref.listen<AuthState>(
      authNotifierProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      if (!auth.initialized) return null;
      final isLoggedIn = auth.user != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.matchedLocation;
          int index = 0;
          if (location.startsWith('/sales')) {
            index = 1;
          } else if (location.startsWith('/customers')) {
            index = 2;
          } else if (location.startsWith('/inventory')) {
            index = 3;
          }
          return MainShell(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesListScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/sales/create',
        builder: (context, state) => const CreateSalesOrderScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/customers/create',
        builder: (context, state) => const CreateCustomerScreen(),
      ),
      GoRoute(
        path: '/payments/create',
        builder: (context, state) => const CreatePaymentScreen(),
      ),
      GoRoute(
        path: '/payments/list',
        builder: (context, state) => const PaymentsListScreen(),
      ),
      GoRoute(
        path: '/payments/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentDetailScreen(paymentId: id);
        },
      ),
      GoRoute(
        path: '/production/create',
        builder: (context, state) => const CreateProductionBatchScreen(),
      ),
      GoRoute(
        path: '/production/batches',
        builder: (context, state) => const ProductionBatchesScreen(),
      ),
      GoRoute(
        path: '/production/boms',
        builder: (context, state) => const BomsListScreen(),
      ),
      GoRoute(
        path: '/production/boms/new',
        builder: (context, state) => const CreateBomScreen(),
      ),
      GoRoute(
        path: '/production/boms/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BomDetailScreen(bomId: id);
        },
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InventoryItemDetailScreen(inventoryItemId: id);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsListScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const CreateProductScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: '/users/new',
        builder: (context, state) => const CreateUserScreen(),
      ),
      GoRoute(
        path: '/users/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditUserScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/customers/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditCustomerScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/production/boms/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditBomScreen(bomId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class ArtemisApp extends ConsumerWidget {
  const ArtemisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Artemis Business OS',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        if (!authState.initialized) {
          return const _SplashScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.headerBar),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(child: AppLogo(size: 64)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Artemis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'BUSINESS OS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
