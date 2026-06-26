import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  List<dynamic> _ledger = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/customers/${widget.customerId}'),
        api.get('/customers/${widget.customerId}/ledger'),
      ]);
      if (!mounted) return;
      setState(() {
        _customer = results[0].data as Map<String, dynamic>;
        _ledger = results[1].data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = parseApiError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF22D3EE)],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(width: 200, height: 18),
                    SizedBox(height: 12),
                    Skeleton(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    Skeleton(width: double.infinity, height: 14),
                  ],
                ),
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
            const Icon(Icons.error_outline, size: 64, color: AppTheme.slate400),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCustomer,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = _customer!;
    final name = c['name'] as String? ?? 'Unknown';
    final balance = (c['outstandingBalance'] as num? ?? 0).toDouble();
    final creditLimit = (c['creditLimit'] as num? ?? 0).toDouble();
    final availableCredit = creditLimit - balance;
    final owes = balance > 0;
    final phone = c['phone'] as String?;
    final region = c['region'] as String?;
    final city = c['city'] as String?;
    final address = c['address'] as String?;
    final contact = c['contactPerson'] as String?;
    final accountStatus = c['accountStatus'] as String?;

    final (gradient, accent) = owes
        ? (AppTheme.gradientWarning, AppTheme.warningColor)
        : balance < 0
        ? (AppTheme.gradientSuccess, AppTheme.successColor)
        : (
            const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF22D3EE)],
            ),
            AppTheme.infoColor,
          );

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: AppTheme.slate900,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadCustomer,
              tooltip: 'Refresh',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: HeroHeader(
              gradient: gradient,
              height: 220,
              glow: true,
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
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
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (phone != null && phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        if (accountStatus != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: Text(
                              accountStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Balance card
              GlassCard(
                accentColor: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owes
                          ? 'OWES'
                          : balance < 0
                          ? 'CREDIT'
                          : 'CLEAR',
                      style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'ETB',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          NumberFormat.decimalPattern().format(balance.abs()),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: accent,
                            letterSpacing: -0.8,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/sales/create'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text(
                        'New Sale',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await context.push('/payments/create');
                        _loadCustomer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text(
                        'Collect',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Financial
              SectionHeaderPro(
                title: 'Financial Summary',
                icon: Icons.account_balance_rounded,
                accentColor: AppTheme.primaryColor,
              ),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'Credit Limit',
                      value: 'ETB ${creditLimit.toStringAsFixed(0)}',
                      icon: Icons.account_balance_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBox(
                      label: 'Available',
                      value:
                          'ETB ${availableCredit.clamp(0, double.infinity).toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: availableCredit > 0
                          ? AppTheme.successColor
                          : AppTheme.dangerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Contact info
              SectionHeaderPro(
                title: 'Contact Info',
                icon: Icons.contact_phone_rounded,
                accentColor: AppTheme.infoColor,
              ),
              GlassCard(
                accentColor: AppTheme.infoColor,
                child: Column(
                  children: [
                    if (contact != null && contact.isNotEmpty)
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Contact Person',
                        value: contact,
                      ),
                    if (phone != null && phone.isNotEmpty)
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: phone,
                      ),
                    if (region != null && city != null)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: '$city, $region',
                      ),
                    if (address != null && address.isNotEmpty)
                      _InfoRow(
                        icon: Icons.home_outlined,
                        label: 'Address',
                        value: address,
                        last: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Ledger
              SectionHeaderPro(
                title: 'Recent Transactions',
                subtitle: '${_ledger.length} entries',
                icon: Icons.history_rounded,
                accentColor: AppTheme.warningColor,
              ),
              if (_ledger.isEmpty)
                const EmptyStatePro(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions yet',
                  subtitle: 'Sales and payments will appear here',
                )
              else
                GlassCard(
                  accentColor: AppTheme.warningColor,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List.generate(_ledger.take(15).length, (i) {
                      final entry = _ledger[i] as Map<String, dynamic>;
                      final isDebit = (entry['type'] as String?) == 'DEBIT';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: i < _ledger.length - 1
                                ? const BorderSide(color: AppTheme.slate100)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    (isDebit
                                            ? AppTheme.dangerColor
                                            : AppTheme.successColor)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isDebit
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: isDebit
                                    ? AppTheme.dangerColor
                                    : AppTheme.successColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry['description'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slate900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    entry['date'] != null
                                        ? DateFormat('MMM dd, yyyy').format(
                                            DateTime.parse(
                                              entry['date'] as String,
                                            ).toLocal(),
                                          )
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isDebit ? '+' : '-'}${((entry['amount'] as num?) ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDebit
                                    ? AppTheme.dangerColor
                                    : AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.slate900,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(color: AppTheme.slate100),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.slate500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
