import 'package:artemis_business_os/core/i18n/locale_provider.dart';
import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _openCommandPalette() async {
    final api = ref.read(apiClientProvider);
    await CommandPalette.show(
      context,
      onSearch: (query) async {
        try {
          final results = await Future.wait([
            api.get(
              '/customers',
              queryParameters: {'search': query, 'limit': 5},
            ),
            api.get(
              '/products',
              queryParameters: {'search': query, 'limit': 5},
            ),
            api.get('/sales', queryParameters: {'search': query, 'limit': 5}),
          ]);
          final items = <CommandItem>[];
          for (final c in (results[0].data as List)) {
            items.add(
              CommandItem(
                id: 'customer-${c['id']}',
                title: c['name'] as String,
                subtitle: c['phone'] as String? ?? '',
                icon: Icons.person_rounded,
                category: 'CUSTOMER',
                color: AppTheme.infoColor,
              ),
            );
          }
          for (final p in (results[1].data as List)) {
            items.add(
              CommandItem(
                id: 'product-${p['id']}',
                title: p['name'] as String,
                subtitle: p['sku'] as String,
                icon: Icons.inventory_2_rounded,
                category: 'PRODUCT',
                color: AppTheme.warningColor,
              ),
            );
          }
          for (final s in (results[2].data as List)) {
            items.add(
              CommandItem(
                id: 'sale-${s['id']}',
                title: s['orderNumber'] as String,
                subtitle:
                    '${s['customerName']} Â· ETB ${(s['totalAmount'] as num).toStringAsFixed(0)}',
                icon: Icons.receipt_long_rounded,
                category: 'SALE',
                color: AppTheme.primaryColor,
              ),
            );
          }
          return items;
        } catch (_) {
          return [];
        }
      },
      onSelect: (item) {
        if (item.id.startsWith('customer-')) {
          context.push('/customers/${item.id.substring(9)}');
        } else if (item.id.startsWith('product-')) {
          context.push('/products/${item.id.substring(8)}/edit');
        } else if (item.id.startsWith('sale-')) {
          context.push('/sales/${item.id.substring(5)}');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: _loadDashboard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeroAppBar(context, user, greeting),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildQuickActions(user),
                        const SizedBox(height: 20),
                        SectionHeaderPro(
                          title: "Today's Pulse",
                          subtitle: 'Real-time snapshot of your business',

                          accentColor: AppTheme.cyanColor,
                        ),
                        _buildBentoKPIs(currencyFormat: _moneyFmt()),
                        const SizedBox(height: 24),
                        _buildAlerts(),
                        const SizedBox(height: 24),
                        _buildRecentSales(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  NumberFormat _moneyFmt() =>
      NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  Widget _buildHeroAppBar(BuildContext context, User? user, String greeting) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.slate900,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: HeroHeader(
          gradient: AppTheme.gradientHeader,
          height: 200,
          glow: true,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (user?.isAdmin == true)
                    StatusPill(
                      label: 'ADMIN',
                      color: AppTheme.cyanColor,
                      icon: Icons.shield_rounded,
                      small: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: _openCommandPalette,
          tooltip: 'Search (Ctrl+K)',
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadDashboard,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildQuickActions(User? user) {
    final isAdmin = user?.isAdmin ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderPro(
          title: 'Quick Actions',
          subtitle: 'Common tasks in one tap',

          accentColor: AppTheme.primaryColor,
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            children: [
              _QuickAction(
                label: 'New Sale',
                icon: Icons.point_of_sale_rounded,
                gradient: AppTheme.gradientPrimary,
                onTap: () => context.push('/sales/create'),
              ),
              _QuickAction(
                label: 'Collect',
                icon: Icons.payments_rounded,
                gradient: AppTheme.gradientSuccess,
                onTap: () => context.push('/payments/create'),
              ),
              _QuickAction(
                label: 'New Batch',
                icon: Icons.factory_rounded,
                gradient: AppTheme.gradientWarning,
                onTap: () => context.push('/production/create'),
              ),
              _QuickAction(
                label: 'Customers',
                icon: Icons.people_alt_rounded,
                gradient: AppTheme.gradientCyan,
                onTap: () => context.go('/customers'),
              ),
              _QuickAction(
                label: 'Reports',
                icon: Icons.insights_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                ),
                onTap: () => context.push('/reports'),
              ),
              if (isAdmin)
                _QuickAction(
                  label: 'Products',
                  icon: Icons.inventory_2_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                  onTap: () => context.push('/products'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBentoKPIs({required NumberFormat currencyFormat}) {
    final data = _dashboardData ?? {};
    final dailySales = (data['dailySales'] as num?) ?? 0;
    final monthlySales = (data['monthlySales'] as num?) ?? 0;
    final receivables = (data['totalOutstandingReceivables'] as num?) ?? 0;
    final inventoryValue = (data['totalInventoryValue'] as num?) ?? 0;
    final customers = (data['totalCustomers'] as num?) ?? 0;
    final lowStock = (data['lowStockAlertsCount'] as num?) ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedKPI(
                label: 'TODAY',
                value: dailySales,
                prefix: 'ETB ',
                icon: Icons.bolt_rounded,
                color: AppTheme.primaryColor,
                sparklineData: _generateSparkline(8, dailySales.toDouble()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedKPI(
                label: 'THIS MONTH',
                value: monthlySales,
                prefix: 'ETB ',
                icon: Icons.trending_up_rounded,
                color: AppTheme.successColor,
                sparklineData: _generateSparkline(8, monthlySales.toDouble()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedKPI(
                label: 'RECEIVABLES',
                value: receivables,
                prefix: 'ETB ',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.warningColor,
                sparklineData: _generateSparkline(8, receivables.toDouble()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedKPI(
                label: 'INVENTORY VALUE',
                value: inventoryValue,
                prefix: 'ETB ',
                icon: Icons.inventory_rounded,
                color: AppTheme.cyanColor,
                sparklineData: _generateSparkline(8, inventoryValue.toDouble()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: GlassCard(
                accentColor: AppTheme.infoColor,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.infoColor.withValues(alpha: 0.18),
                            AppTheme.infoColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: AppTheme.infoColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CUSTOMERS',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedNumber(
                            value: customers,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.slate900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GlassCard(
                accentColor: lowStock > 0
                    ? AppTheme.dangerColor
                    : AppTheme.successColor,
                padding: const EdgeInsets.all(16),
                onTap: () => context.go('/inventory'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (lowStock > 0
                                    ? AppTheme.dangerColor
                                    : AppTheme.successColor)
                                .withValues(alpha: 0.18),
                            (lowStock > 0
                                    ? AppTheme.dangerColor
                                    : AppTheme.successColor)
                                .withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        lowStock > 0
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        color: lowStock > 0
                            ? AppTheme.dangerColor
                            : AppTheme.successColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LOW STOCK',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedNumber(
                            value: lowStock,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: lowStock > 0
                                  ? AppTheme.dangerColor
                                  : AppTheme.slate900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<num> _generateSparkline(int n, double value) {
    final base = value / n;
    return List.generate(n, (i) {
      final wobble = (i.isEven ? 1.1 : 0.9) + (i % 3) * 0.05;
      return (base * wobble).round();
    });
  }

  Widget _buildAlerts() {
    final lowStock = (_dashboardData?['lowStockItems'] as List?) ?? [];
    if (lowStock.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderPro(
          title: 'Action Required',
          subtitle:
              '${lowStock.length} item${lowStock.length == 1 ? '' : 's'} need attention',

          accentColor: AppTheme.dangerColor,
        ),
        GlassCard(
          accentColor: AppTheme.dangerColor,
          child: Column(
            children: (lowStock.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppTheme.dangerColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Only ${item['currentQuantity']} ${item['unitOfMeasure']} left',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.slate400,
                    ),
                  ],
                ),
              );
            }).toList()),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    final recent = (_dashboardData?['recentSales'] as List?) ?? [];
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderPro(
          title: 'Recent Sales',
          subtitle: 'Latest orders',

          accentColor: AppTheme.accentColor,
        ),
        GlassCard(
          accentColor: AppTheme.accentColor,
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(recent.take(5).length, (i) {
              final s = recent[i] as Map<String, dynamic>;
              final isPaid = s['paymentStatus'] == 'PAID';
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i < recent.length - 1
                        ? const BorderSide(color: AppTheme.slate100)
                        : BorderSide.none,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          (isPaid
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor)
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: isPaid
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    s['orderNumber'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    s['customerName'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate500,
                    ),
                  ),
                  trailing: Text(
                    'ETB ${(s['totalAmount'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  onTap: () => context.push('/sales/${s['id']}'),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppTheme.gradientHeader),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(child: Skeleton(height: 120, radius: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Skeleton(height: 120, radius: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Skeleton(height: 120, radius: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Skeleton(height: 120, radius: 18)),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppTheme.slate400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.slate600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 0.05,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(scale: 1 - _ctrl.value, child: child);
        },
        child: Container(
          width: 88,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.slate200),
            boxShadow: AppTheme.elevationXs,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
