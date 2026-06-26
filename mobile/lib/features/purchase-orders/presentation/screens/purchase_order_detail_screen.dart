import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/confirm_dialog.dart';
import 'package:artemis_business_os/core/widgets/ui_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String poId;
  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  bool _isReceiving = false;

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
      final res = await api.get('/purchase-orders/${widget.poId}');
      if (!mounted) return;
      setState(() {
        _order = res.data as Map<String, dynamic>;
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

  Future<void> _cancel() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel PO?',
      message: 'Cancel ${_order!['poNumber']}? Cannot be undone.',
      confirmLabel: 'Cancel PO',
      type: ConfirmDialogType.destructive,
    );
    if (!confirmed) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/purchase-orders/${widget.poId}');
      if (mounted) {
        showAppSnackBar(context, message: 'PO cancelled', isSuccess: true);
        _load();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, message: parseApiError(e), isError: true);
      }
    }
  }

  Future<void> _showReceiveDialog() async {
    final items = (_order!['items'] as List)
        .cast<Map<String, dynamic>>()
        .where((i) => (i['quantity'] as num) - (i['receivedQty'] as num) > 0)
        .toList();

    if (items.isEmpty) {
      showAppSnackBar(
        context,
        message: 'All items already received',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReceiveSheet(
        poId: widget.poId,
        poNumber: _order!['poNumber'] as String,
        items: items
            .map(
              (i) => {
                'productId': i['productId'],
                'productName': i['productName'],
                'unit': i['unitOfMeasure'],
                'ordered': (i['quantity'] as num).toDouble(),
                'alreadyReceived': (i['receivedQty'] as num).toDouble(),
                'remaining':
                    (i['quantity'] as num).toDouble() -
                    (i['receivedQty'] as num).toDouble(),
                'unitCost': (i['unitCost'] as num).toDouble(),
              },
            )
            .toList(),
      ),
    );

    if (result == true) _load();
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
      floatingActionButton:
          _order != null &&
              _order!['status'] != 'RECEIVED' &&
              _order!['status'] != 'CANCELLED'
          ? FloatingActionButton.extended(
              onPressed: _isReceiving ? null : _showReceiveDialog,
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              icon: _isReceiving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.inventory_rounded),
              label: const Text('Receive'),
            )
          : null,
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
    final o = _order!;
    final status = o['status'] as String? ?? 'DRAFT';
    final (gradient, accent, label, icon) = switch (status) {
      'RECEIVED' => (
        const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
        AppTheme.successColor,
        'RECEIVED',
        Icons.check_circle_rounded,
      ),
      'PARTIALLY_RECEIVED' => (
        const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFFBBF24)]),
        AppTheme.warningColor,
        'PARTIALLY RECEIVED',
        Icons.hourglass_top_rounded,
      ),
      'CANCELLED' => (
        const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFFB7185)]),
        AppTheme.dangerColor,
        'CANCELLED',
        Icons.block_rounded,
      ),
      _ => (
        const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
        const Color(0xFF0F766E),
        'SENT',
        Icons.send_rounded,
      ),
    };

    final poNumber = o['poNumber'] as String? ?? '';
    final supplierName = o['supplierName'] as String? ?? '';
    final items = (o['items'] as List? ?? []).cast<Map<String, dynamic>>();
    final total = (o['total'] as num? ?? 0).toDouble();
    final dateStr = o['orderDate'] as String?;
    final dateLabel = dateStr != null
        ? DateFormat(
            'EEEE, MMM dd, yyyy',
          ).format(DateTime.parse(dateStr).toLocal())
        : '';
    final expectedDate = o['expectedDate'] as String?;
    final notes = o['notes'] as String?;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 220,
          backgroundColor: AppTheme.slate900,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (status != 'RECEIVED' && status != 'CANCELLED')
              IconButton(
                icon: const Icon(Icons.block_rounded),
                onPressed: _cancel,
                tooltip: 'Cancel PO',
              ),
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
                  StatusPill(
                    label: label,
                    color: Colors.white,
                    icon: icon,
                    small: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    poNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplierName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
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
              // Total
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
                          NumberFormat.decimalPattern().format(total),
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
              const SizedBox(height: 20),
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
                    final item = items[i];
                    final qty = (item['quantity'] as num? ?? 0).toDouble();
                    final received = (item['receivedQty'] as num? ?? 0)
                        .toDouble();
                    final unitCost = (item['unitCost'] as num? ?? 0).toDouble();
                    final itemTotal = (item['itemTotal'] as num? ?? 0)
                        .toDouble();
                    final progress = qty > 0 ? received / qty : 0.0;
                    final unit = item['unitOfMeasure'] as String? ?? '';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i < items.length - 1
                              ? const BorderSide(color: AppTheme.slate100)
                              : BorderSide.none,
                        ),
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
                                  color: AppTheme.warningLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.science_rounded,
                                  color: AppTheme.warningColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['productName'] as String? ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.slate900,
                                      ),
                                    ),
                                    Text(
                                      'SKU ${item['productSku']}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'ETB ${itemTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.slate100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress >= 1.0
                                          ? AppTheme.successColor
                                          : accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${received.toStringAsFixed(0)} / ${qty.toStringAsFixed(0)} $unit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: progress >= 1.0
                                      ? AppTheme.successColor
                                      : AppTheme.slate700,
                                ),
                              ),
                            ],
                          ),
                          if (unitCost > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '@ ETB ${unitCost.toStringAsFixed(2)} / $unit',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.slate500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              if (expectedDate != null) ...[
                const SizedBox(height: 20),
                SectionHeaderPro(
                  title: 'Schedule',
                  icon: Icons.event_rounded,
                  accentColor: AppTheme.infoColor,
                ),
                GlassCard(
                  accentColor: AppTheme.infoColor,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        color: AppTheme.infoColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Expected: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(expectedDate).toLocal())}',
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
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReceiveSheet extends ConsumerStatefulWidget {
  final String poId;
  final String poNumber;
  final List<Map<String, dynamic>> items;

  const _ReceiveSheet({
    required this.poId,
    required this.poNumber,
    required this.items,
  });

  @override
  ConsumerState<_ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends ConsumerState<_ReceiveSheet> {
  late List<TextEditingController> _qtyControllers;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qtyControllers = widget.items
        .map((i) => TextEditingController(text: i['remaining'].toString()))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final qty = double.tryParse(_qtyControllers[i].text) ?? 0;
      if (qty > 0) {
        items.add({
          'productId': item['productId'],
          'receivedQty': qty,
          'unitCost': item['unitCost'],
        });
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter quantities to receive')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/purchase-orders/${widget.poId}/receive',
        data: {'items': items},
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(parseApiError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.inventory_rounded,
                    color: Color(0xFF0F766E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receive Goods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                      Text(
                        widget.poNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = widget.items[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.slate50,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
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
                        ),
                        Text(
                          '${item['remaining'].toStringAsFixed(0)} ${item['unit']} remaining (already received: ${item['alreadyReceived'].toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _qtyControllers[i],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Receive qty',
                            suffixText: item['unit'] as String,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                icon: _saving
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
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  _saving ? 'Receiving...' : 'Confirm Receipt',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
