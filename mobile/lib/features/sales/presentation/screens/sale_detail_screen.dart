import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SaleDetailScreen extends ConsumerStatefulWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  Map<String, dynamic>? _sale;
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
      final res = await api.get('/sales/${widget.saleId}');
      if (!mounted) return;
      setState(() {
        _sale = res.data as Map<String, dynamic>;
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

  Future<void> _cancelOrder() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel Order?',
      message:
          'Cancel ${_sale!['orderNumber']}? This reverses inventory deduction. Cannot be undone.',
      confirmLabel: 'Cancel Order',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/sales/${widget.saleId}');
      if (mounted) {
        showAppSnackBar(context, message: 'Order cancelled', isSuccess: true);
        _load();
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
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppTheme.gradientHeader),
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
    final sale = _sale!;
    final isPaid = sale['paymentStatus'] == 'PAID';
    final isCancelled = sale['isCancelled'] == true;
    final isCash = sale['orderType'] == 'CASH_SALE';

    final (gradient, accent, statusLabel, statusIcon) = isCancelled
        ? (
            AppTheme.gradientDanger,
            AppTheme.dangerColor,
            'CANCELLED',
            Icons.block_rounded,
          )
        : isPaid
        ? (
            AppTheme.gradientSuccess,
            AppTheme.successColor,
            'PAID',
            Icons.check_circle_rounded,
          )
        : isCash
        ? (
            const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF22D3EE)],
            ),
            AppTheme.infoColor,
            'CASH · PENDING',
            Icons.payments_rounded,
          )
        : (
            AppTheme.gradientWarning,
            AppTheme.warningColor,
            'CREDIT · PENDING',
            Icons.credit_card_rounded,
          );

    final orderNumber = sale['orderNumber'] as String? ?? '';
    final totalAmount = (sale['totalAmount'] as num?) ?? 0;
    final dateStr = sale['orderDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat(
            'EEEE, MMM dd, yyyy · HH:mm',
          ).format(DateTime.parse(dateStr).toLocal())
        : '';
    final region = sale['region'] as String?;
    final city = sale['city'] as String?;
    final customerName = sale['customerName'] as String? ?? 'Unknown';
    final items = (sale['items'] as List?) ?? [];
    final notes = sale['notes'] as String?;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          backgroundColor: AppTheme.slate900,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (!isCancelled && !isPaid)
              IconButton(
                icon: const Icon(Icons.block_rounded),
                onPressed: _cancelOrder,
                tooltip: 'Cancel order',
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: HeroHeader(
              gradient: gradient,
              height: 240,
              glow: true,
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    orderNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
              // Total amount big card
              GlassCard(
                accentColor: accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w800,
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
                          NumberFormat.decimalPattern().format(totalAmount),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate900,
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
              // Customer card
              SectionHeaderPro(
                title: 'Customer',
                icon: Icons.person_rounded,
                accentColor: AppTheme.infoColor,
              ),
              GlassCard(
                accentColor: AppTheme.infoColor,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.infoColor.withValues(alpha: 0.18),
                            AppTheme.infoColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate900,
                            ),
                          ),
                          if (region != null && city != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$city, $region',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () =>
                          context.push('/customers/${sale['customerId']}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Items
              SectionHeaderPro(
                title: 'Items',
                subtitle:
                    '${items.length} product${items.length == 1 ? '' : 's'}',
                icon: Icons.inventory_2_rounded,
                accentColor: AppTheme.warningColor,
              ),
              GlassCard(
                accentColor: AppTheme.warningColor,
                padding: EdgeInsets.zero,
                child: Column(
                  children: List.generate(items.length, (i) {
                    final item = items[i] as Map<String, dynamic>;
                    final qty = (item['quantity'] as num?) ?? 0;
                    final price = (item['unitPrice'] as num?) ?? 0;
                    final lineTotal = (item['itemTotal'] as num?) ?? 0;
                    final productName = item['productName'] as String? ?? '';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i < items.length - 1
                              ? const BorderSide(color: AppTheme.slate100)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_drink_rounded,
                              color: AppTheme.warningColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName.isNotEmpty
                                      ? productName
                                      : 'Product',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.slate900,
                                  ),
                                ),
                                Text(
                                  '${qty.toStringAsFixed(0)} × ETB ${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'ETB ${NumberFormat.decimalPattern().format(lineTotal)}',
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
                  }),
                ),
              ),
              if (notes != null && notes.toString().isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Notes',
                  icon: Icons.note_rounded,
                  accentColor: AppTheme.accentColor,
                ),
                GlassCard(
                  accentColor: AppTheme.accentColor,
                  child: Text(
                    notes.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.slate700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (!isPaid && !isCancelled) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/payments/create');
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 20),
                    label: const Text(
                      'Record Payment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
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
