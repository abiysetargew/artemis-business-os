import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
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
    final currencyFormat = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    user?.name ?? 'User',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (user?.isAdmin == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
