import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PaymentDetailScreen extends ConsumerStatefulWidget {
  final String paymentId;
  const PaymentDetailScreen({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailScreen> createState() =>
      _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends ConsumerState<PaymentDetailScreen> {
  Map<String, dynamic>? _payment;
  bool _isLoading = true;
  String? _error;
  bool _isVerifying = false;

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
      final res = await api.get('/payments/${widget.paymentId}');
      if (!mounted) return;
      setState(() {
        _payment = res.data as Map<String, dynamic>;
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

  Future<void> _verify(String status) async {
    setState(() => _isVerifying = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/payments/${widget.paymentId}',
        data: {'verificationStatus': status},
      );
      if (mounted) {
        showAppSnackBar(
          context,
          message: 'Payment ${status.toLowerCase()}',
          isSuccess: status == 'VERIFIED',
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
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
            decoration: const BoxDecoration(gradient: AppTheme.gradientSuccess),
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
    final p = _payment!;
    final status = p['verificationStatus'] as String? ?? 'PENDING';
    final (gradient, accent, statusLabel, statusIcon) = switch (status) {
      'VERIFIED' => (
        AppTheme.gradientSuccess,
        AppTheme.successColor,
        'VERIFIED',
        Icons.verified_rounded,
      ),
      'REJECTED' => (
        AppTheme.gradientDanger,
        AppTheme.dangerColor,
        'REJECTED',
        Icons.cancel_rounded,
      ),
      _ => (
        AppTheme.gradientWarning,
        AppTheme.warningColor,
        'PENDING',
        Icons.hourglass_top_rounded,
      ),
    };

    final amount = (p['amount'] as num? ?? 0).toDouble();
    final customerName = p['customerName'] as String? ?? 'Unknown';
    final method = p['paymentMethod'] as String? ?? 'CASH';
    final reference = p['referenceNumber'] as String?;
    final invoiceNum = p['salesOrderNumber'] as String?;
    final recordedBy = p['userName'] as String?;
    final notes = p['notes'] as String?;
    final verification = p['verification'] as Map<String, dynamic>?;
    final dateStr = p['paymentDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat(
            'EEEE, MMM dd, yyyy · HH:mm',
          ).format(DateTime.parse(dateStr).toLocal())
        : '';

    final (methodColor, methodIcon, methodLabel) = switch (method) {
      'CASH' => (AppTheme.successColor, Icons.payments_rounded, 'CASH'),
      'BANK_TRANSFER' => (
        AppTheme.infoColor,
        Icons.account_balance_rounded,
        'BANK TRANSFER',
      ),
      'MOBILE_MONEY' => (
        AppTheme.warningColor,
        Icons.phone_android_rounded,
        'MOBILE MONEY',
      ),
      'CHECK' => (AppTheme.slate600, Icons.note_alt_rounded, 'CHECK'),
      _ => (AppTheme.slate500, Icons.more_horiz_rounded, method),
    };

    final isAdmin = ref.read(authNotifierProvider).user?.isAdmin ?? false;
    final isPending = status == 'PENDING';

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
              onPressed: _load,
              tooltip: 'Refresh',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: HeroHeader(
              gradient: gradient,
              height: 220,
              glow: true,
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        label: statusLabel,
                        color: Colors.white,
                        icon: statusIcon,
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'ETB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        NumberFormat.decimalPattern().format(amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          height: 1,
                        ),
                      ),
                    ],
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
              // Customer
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.infoColor.withValues(alpha: 0.18),
                            AppTheme.infoColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () =>
                          context.push('/customers/${p['customerId']}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Payment info
              SectionHeaderPro(
                title: 'Payment Info',
                icon: Icons.receipt_long_rounded,
                accentColor: methodColor,
              ),
              GlassCard(
                accentColor: methodColor,
                child: Column(
                  children: [
                    _DetailRow(
                      icon: methodIcon,
                      label: 'Method',
                      value: methodLabel,
                      color: methodColor,
                    ),
                    if (reference != null && reference.isNotEmpty)
                      _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Reference',
                        value: reference,
                      ),
                    if (invoiceNum != null && invoiceNum.isNotEmpty)
                      _DetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'Invoice',
                        value: invoiceNum,
                      ),
                    if (recordedBy != null && recordedBy.isNotEmpty)
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Recorded by',
                        value: recordedBy,
                        last:
                            (reference == null || reference.isEmpty) &&
                            (invoiceNum == null || invoiceNum.isEmpty),
                      ),
                  ],
                ),
              ),
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
              if (verification != null) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Verification',
                  icon: Icons.verified_rounded,
                  accentColor: AppTheme.successColor,
                ),
                GlassCard(
                  accentColor: AppTheme.successColor,
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.check_circle_outline,
                        label: 'Status',
                        value: verification['status']?.toString() ?? '—',
                      ),
                      _DetailRow(
                        icon: Icons.person_outline,
                        label: 'Verified by',
                        value: verification['verifierName']?.toString() ?? '—',
                      ),
                      _DetailRow(
                        icon: Icons.event,
                        label: 'Verified at',
                        value: verification['verificationDate'] != null
                            ? DateFormat('MMM dd, yyyy · HH:mm').format(
                                DateTime.parse(
                                  verification['verificationDate'] as String,
                                ).toLocal(),
                              )
                            : '—',
                      ),
                      if (verification['notes'] != null &&
                          (verification['notes'] as String).isNotEmpty)
                        _DetailRow(
                          icon: Icons.note_outlined,
                          label: 'Notes',
                          value: verification['notes'] as String,
                          last: true,
                        ),
                    ],
                  ),
                ),
              ],
              if (isAdmin && isPending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isVerifying
                            ? null
                            : () => _verify('REJECTED'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: BorderSide(
                            color: AppTheme.dangerColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        label: const Text(
                          'Reject',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying
                            ? null
                            : () => _verify('VERIFIED'),
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
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          'Verify Payment',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
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
  final Color? color;
  final bool last;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.slate500;
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: c, size: 14),
          ),
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
