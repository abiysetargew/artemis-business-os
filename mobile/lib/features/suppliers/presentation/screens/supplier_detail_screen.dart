import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  final String supplierId;
  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen> {
  Map<String, dynamic>? _supplier;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.get('/suppliers/${widget.supplierId}'),
        api
            .get(
              '/purchase-orders',
              queryParameters: {'supplierId': widget.supplierId},
            )
            .catchError((_) => _FakeResp(data: [])),
      ]);
      if (!mounted) return;
      setState(() {
        _supplier = results[0].data as Map<String, dynamic>;
        _orders = results[1].data as List<dynamic>;
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

  Future<void> _delete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Supplier?',
      message: 'Delete "${_supplier!['name']}"? This cannot be undone.',
      confirmLabel: 'Delete',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/suppliers/${widget.supplierId}');
      if (mounted) {
        showAppSnackBar(context, message: 'Supplier deleted', isSuccess: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
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
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
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
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final s = _supplier!;
    final name = s['name'] as String? ?? 'Unknown';
    final isActive = s['isActive'] == true;
    final phone = s['phone'] as String?;
    final email = s['email'] as String?;
    final city = s['city'] as String?;
    final region = s['region'] as String?;
    final address = s['address'] as String?;
    final contactName = s['contactName'] as String?;
    final tin = s['tinNumber'] as String?;
    final notes = s['notes'] as String?;
    final totalOrders = (s['totalOrders'] as num? ?? 0).toInt();
    final totalSpent = (s['totalSpent'] as num? ?? 0).toDouble();
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
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: HeroHeader(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              ),
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
                        StatusPill(
                          label: isActive ? 'ACTIVE' : 'INACTIVE',
                          color: isActive
                              ? AppTheme.successColor
                              : AppTheme.slate500,
                          small: true,
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
              // Stats
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      accentColor: AppTheme.primaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PURCHASE ORDERS',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedNumber(
                            value: totalOrders,
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
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassCard(
                      accentColor: AppTheme.warningColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL SPENT',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ETB ${NumberFormat.compactCurrency(symbol: '', decimalDigits: 0).format(totalSpent)}',
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/purchase-orders/new?supplierId=${widget.supplierId}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                      label: const Text(
                        'New PO',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/purchase-orders?supplierId=${widget.supplierId}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                        side: BorderSide(
                          color: AppTheme.warningColor.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text(
                        'All POs',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeaderPro(
                title: 'Contact Info',
                icon: Icons.contact_phone_rounded,
                accentColor: AppTheme.infoColor,
              ),
              GlassCard(
                accentColor: AppTheme.infoColor,
                child: Column(
                  children: [
                    if (contactName != null && contactName.isNotEmpty)
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Contact Person',
                        value: contactName,
                      ),
                    if (phone != null && phone.isNotEmpty)
                      _DetailRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: phone,
                      ),
                    if (email != null && email.isNotEmpty)
                      _DetailRow(
                        icon: Icons.email_rounded,
                        label: 'Email',
                        value: email,
                      ),
                    if (region != null && city != null)
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: '$city, $region',
                      ),
                    if (address != null && address.isNotEmpty)
                      _DetailRow(
                        icon: Icons.home_outlined,
                        label: 'Address',
                        value: address,
                        last: true,
                      ),
                  ],
                ),
              ),
              if (tin != null && tin.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Tax Info',
                  icon: Icons.numbers_rounded,
                  accentColor: AppTheme.warningColor,
                ),
                GlassCard(
                  accentColor: AppTheme.warningColor,
                  child: _DetailRow(
                    icon: Icons.numbers_rounded,
                    label: 'TIN Number',
                    value: tin,
                    last: true,
                  ),
                ),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Notes',
                  icon: Icons.note_rounded,
                  accentColor: AppTheme.accentColor,
                ),
                GlassCard(
                  accentColor: AppTheme.accentColor,
                  child: Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.slate700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (_orders.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Recent Purchase Orders',
                  subtitle:
                      '${_orders.length} order${_orders.length == 1 ? '' : 's'}',
                  icon: Icons.history_rounded,
                  accentColor: AppTheme.primaryColor,
                ),
                GlassCard(
                  accentColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: List.generate(_orders.take(10).length, (i) {
                      final o = _orders[i] as Map<String, dynamic>;
                      final status = o['status'] as String? ?? 'DRAFT';
                      final (color, icon, label) = switch (status) {
                        'RECEIVED' => (
                          AppTheme.successColor,
                          Icons.check_circle_rounded,
                          'RECEIVED',
                        ),
                        'PARTIALLY_RECEIVED' => (
                          AppTheme.warningColor,
                          Icons.hourglass_top_rounded,
                          'PARTIAL',
                        ),
                        'CANCELLED' => (
                          AppTheme.dangerColor,
                          Icons.block_rounded,
                          'CANCELLED',
                        ),
                        _ => (AppTheme.infoColor, Icons.send_rounded, 'SENT'),
                      };
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: i < _orders.length - 1
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
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o['poNumber'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                                  Text(
                                    o['orderDate'] != null
                                        ? DateFormat('MMM dd, yyyy').format(
                                            DateTime.parse(
                                              o['orderDate'] as String,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'ETB ${(o['total'] as num? ?? 0).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.slate900,
                                  ),
                                ),
                                StatusPill(
                                  label: label,
                                  color: color,
                                  small: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _DetailRow({
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

class _FakeResp {
  final dynamic data;
  _FakeResp({required this.data});
}
