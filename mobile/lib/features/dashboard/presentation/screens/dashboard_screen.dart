import 'package:artemis_business_os/core/i18n/locale_provider.dart';
import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/app_logo.dart';
import 'package:artemis_business_os/core/widgets/main_shell.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:artemis_business_os/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/reports/dashboard');
      if (!mounted) return;
      setState(() {
        _dashboardData = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = parseApiError(e);
      setState(() {
        _error = msg;
        _isLoading = false;
      });
      if (msg.toLowerCase().contains('session has expired') ||
          msg.toLowerCase().contains('log in again')) {
        await ref.read(authNotifierProvider.notifier).logout();
        if (mounted) context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final s = AppStrings.of(context);
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: BrandedAppBar(
        title: s.headingDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboard,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
            tooltip: s.headingSettings,
          ),
        ],
      ),
      body: _buildBody(currencyFormat, user),
    );
  }

  Widget _buildBody(NumberFormat currencyFormat, User? user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(user),
            const SizedBox(height: 16),
            Text(
              "Today's Overview",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildKPISection(currencyFormat),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSectionIfData(
              title: 'Top Products',
              items: _dashboardData?['topProducts'] as List?,
              itemBuilder: _buildTopProductTile,
            ),
            _buildSectionIfData(
              title: 'Recent Sales',
              items: _dashboardData?['recentSales'] as List?,
              itemBuilder: _buildRecentSaleTile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionIfData({
    required String title,
    required List? items,
    required Widget Function(dynamic) itemBuilder,
  }) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: items.take(5).map<Widget>(itemBuilder).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTopProductTile(dynamic p) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.shade100,
        child: const Icon(Icons.local_drink, color: Colors.orange, size: 20),
      ),
      title: Text(
        p['productName'] as String,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${p['totalQuantity']} units sold'),
      trailing: Text(
        'ETB ${(p['totalRevenue'] as num).toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildRecentSaleTile(dynamic s) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            (s['paymentStatus'] == 'PAID' ? Colors.green : Colors.orange)
                .withValues(alpha: 0.1),
        child: Icon(
          Icons.shopping_cart,
          color: s['paymentStatus'] == 'PAID' ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        s['orderNumber'] as String,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(s['customerName'] as String),
      trailing: Text(
        'ETB ${(s['totalAmount'] as num).toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.headerBar,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (user?.isAdmin == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKPISection(NumberFormat currencyFormat) {
    final data = _dashboardData!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Daily Sales',
                value: currencyFormat.format(data['dailySales'] ?? 0),
                icon: Icons.trending_up,
                color: AppTheme.successColor,
                subtitle: 'Today',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Monthly Sales',
                value: currencyFormat.format(data['monthlySales'] ?? 0),
                icon: Icons.calendar_month,
                color: AppTheme.primaryColor,
                subtitle: 'This month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Receivables',
                value: currencyFormat.format(
                  data['totalOutstandingReceivables'] ?? 0,
                ),
                icon: Icons.account_balance_wallet,
                color: AppTheme.warningColor,
                subtitle: '${data['totalCustomers'] ?? 0} customers',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Inventory',
                value: currencyFormat.format(data['totalInventoryValue'] ?? 0),
                icon: Icons.inventory_2,
                color: Colors.blue,
                subtitle: '${data['lowStockAlertsCount'] ?? 0} low stock',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _ActionCard(
          icon: Icons.point_of_sale,
          label: 'New Sale',
          color: AppTheme.primaryColor,
          onTap: () => context.push('/sales/create'),
        ),
        _ActionCard(
          icon: Icons.payment,
          label: 'Collect',
          color: AppTheme.successColor,
          onTap: () => context.push('/payments/create'),
        ),
        _ActionCard(
          icon: Icons.factory,
          label: 'New Batch',
          color: Colors.orange,
          onTap: () => context.push('/production/create'),
        ),
        _ActionCard(
          icon: Icons.science,
          label: 'BOMs',
          color: Colors.deepPurple,
          onTap: () => context.push('/production/boms'),
        ),
        _ActionCard(
          icon: Icons.receipt_long,
          label: 'Payments',
          color: Colors.teal,
          onTap: () => context.push('/payments/list'),
        ),
        _ActionCard(
          icon: Icons.assessment,
          label: 'Reports',
          color: Colors.indigo,
          onTap: () => context.push('/reports'),
        ),
        if (isAdmin) ...[
          _ActionCard(
            icon: Icons.inventory_2,
            label: 'Products',
            color: Colors.cyan,
            onTap: () => context.push('/products'),
          ),
          _ActionCard(
            icon: Icons.history,
            label: 'Batches',
            color: Colors.deepOrange,
            onTap: () => context.push('/production/batches'),
          ),
          _ActionCard(
            icon: Icons.people,
            label: 'Users',
            color: Colors.brown,
            onTap: () => context.push('/users'),
          ),
        ] else
          _ActionCard(
            icon: Icons.history,
            label: 'Batches',
            color: Colors.deepOrange,
            onTap: () => context.push('/production/batches'),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: AppShadows.xs,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.slate900,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
