import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/data_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum PaymentIntent { settleInvoice, advancePayment, onAccount }

class CreatePaymentScreen extends ConsumerStatefulWidget {
  const CreatePaymentScreen({super.key});

  @override
  ConsumerState<CreatePaymentScreen> createState() =>
      _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends ConsumerState<CreatePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  List<dynamic> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  List<dynamic> _pendingOrders = [];
  Map<String, dynamic>? _selectedOrder;
  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();
  PaymentIntent _intent = PaymentIntent.settleInvoice;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/customers');
      setState(() {
        _customers = res.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showError('Error loading customers: ${parseApiError(e)}');
    }
  }

  Future<void> _onCustomerChanged(Map<String, dynamic>? customer) async {
    setState(() {
      _selectedCustomer = customer;
      _selectedOrder = null;
      _pendingOrders = [];
      _amountController.clear();
    });
    if (customer == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(
        '/sales',
        queryParameters: {
          'customerId': customer['id'],
          'paymentStatus': 'PENDING',
        },
      );
      final orders = (res.data as List<dynamic>)
          .where((o) => (o as Map<String, dynamic>)['isCancelled'] != true)
          .toList();
      if (!mounted) return;
      setState(() => _pendingOrders = orders);

      // Auto-pick first order if intent is settle
      if (_intent == PaymentIntent.settleInvoice && orders.isNotEmpty) {
        final first = orders.first as Map<String, dynamic>;
        _selectedOrder = first;
        _amountController.text = ((first['totalAmount'] as num?) ?? 0)
            .toStringAsFixed(2);
      }
    } catch (_) {
      // ignore — orders are optional
    }
  }

  double get _outstandingBalance =>
      (_selectedCustomer?['outstandingBalance'] as num?)?.toDouble() ?? 0.0;

  double get _currentAmount => double.tryParse(_amountController.text) ?? 0.0;

  double get _balanceAfterPayment {
    if (_selectedCustomer == null) return 0;
    final outstanding = _outstandingBalance;
    return (outstanding - _currentAmount)
        .clamp(double.negativeInfinity, double.infinity)
        .toDouble();
  }

  void _onIntentChanged(PaymentIntent intent) {
    setState(() {
      _intent = intent;
      if (intent != PaymentIntent.settleInvoice) {
        _selectedOrder = null;
      }
      // Pre-fill amount based on intent
      if (intent == PaymentIntent.settleInvoice && _selectedOrder != null) {
        _amountController.text = ((_selectedOrder!['totalAmount'] as num?) ?? 0)
            .toStringAsFixed(2);
      }
    });
  }

  void _onOrderChanged(Map<String, dynamic>? order) {
    setState(() => _selectedOrder = order);
    if (order != null) {
      _amountController.text = ((order['totalAmount'] as num?) ?? 0)
          .toStringAsFixed(2);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      _showError('Please select a customer');
      return;
    }
    if (_intent == PaymentIntent.settleInvoice && _selectedOrder == null) {
      _showError('Please select an invoice to settle');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final payload = <String, dynamic>{
        'customerId': _selectedCustomer!['id'],
        'amount': double.parse(_amountController.text),
        'paymentMethod': _paymentMethod,
        'paymentDate': _paymentDate.toIso8601String(),
        'referenceNumber': _referenceController.text,
        'notes': _notesController.text,
      };
      if (_intent == PaymentIntent.settleInvoice && _selectedOrder != null) {
        payload['salesOrderId'] = _selectedOrder!['id'];
      }
      await api.post('/payments', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment of ETB ${NumberFormat.decimalPattern().format(_currentAmount)} recorded!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError(parseApiError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildIntentCard(),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 16),
                    _buildBalanceSummary(),
                  ],
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 16),
                    _buildInvoiceSection(),
                  ],
                  const SizedBox(height: 16),
                  _buildAmountSection(),
                  const SizedBox(height: 16),
                  _buildMethodAndDateSection(),
                  const SizedBox(height: 16),
                  _buildReferenceAndNotes(),
                  if (_selectedCustomer != null && _currentAmount > 0) ...[
                    const SizedBox(height: 16),
                    _buildPaymentSummary(),
                  ],
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentCard() {
    final intentInfo = _getIntentInfo();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intentInfo.bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: intentInfo.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: intentInfo.color,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(intentInfo.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Intent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intentInfo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: intentInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            intentInfo.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _IntentOption(
                  selected: _intent == PaymentIntent.settleInvoice,
                  icon: Icons.receipt_long,
                  label: 'Settle',
                  description: 'Invoice',
                  color: AppTheme.primaryColor,
                  onTap: () => _onIntentChanged(PaymentIntent.settleInvoice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IntentOption(
                  selected: _intent == PaymentIntent.advancePayment,
                  icon: Icons.forward_to_inbox,
                  label: 'Advance',
                  description: 'Pre-pay',
                  color: AppTheme.infoColor,
                  onTap: () => _onIntentChanged(PaymentIntent.advancePayment),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IntentOption(
                  selected: _intent == PaymentIntent.onAccount,
                  icon: Icons.account_balance_wallet,
                  label: 'On Account',
                  description: 'Generic',
                  color: AppTheme.successColor,
                  onTap: () => _onIntentChanged(PaymentIntent.onAccount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Customer',
          subtitle: 'Who is making the payment?',
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: _selectedCustomer,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Customer *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: _customers.map<DropdownMenuItem<Map<String, dynamic>>>((c) {
            final m = c as Map<String, dynamic>;
            final balance = (m['outstandingBalance'] as num?) ?? 0;
            final name = m['name'] as String? ?? 'Unknown';
            return DropdownMenuItem(
              value: m,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: balance > 0
                        ? AppTheme.warningLight
                        : AppTheme.successLight,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: balance > 0
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          balance > 0
                              ? 'Owes: ETB ${NumberFormat.decimalPattern().format(balance)}'
                              : balance < 0
                              ? 'Credit: ETB ${NumberFormat.decimalPattern().format(balance.abs())}'
                              : 'No outstanding balance',
                          style: TextStyle(
                            fontSize: 11,
                            color: balance > 0
                                ? AppTheme.warningColor
                                : balance < 0
                                ? AppTheme.successColor
                                : AppTheme.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (c) => _onCustomerChanged(c),
          validator: (v) => v == null ? 'Customer is required' : null,
        ),
      ],
    );
  }

  Widget _buildBalanceSummary() {
    final balance = _outstandingBalance;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              label: 'Current Balance',
              value: balance.abs(),
              color: balance > 0
                  ? AppTheme.warningColor
                  : balance < 0
                  ? AppTheme.successColor
                  : AppTheme.slate500,
              suffix: balance > 0
                  ? 'Owed'
                  : balance < 0
                  ? 'Credit'
                  : 'Clear',
              prefix: balance > 0
                  ? '+'
                  : balance < 0
                  ? '-'
                  : '',
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: AppTheme.slate200,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _MiniMetric(
              label: 'After This Payment',
              value: _balanceAfterPayment.abs(),
              color: _balanceAfterPayment > 0
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
              suffix: _balanceAfterPayment > 0 ? 'Owed' : 'Settled',
              prefix: _balanceAfterPayment > 0 ? '+' : '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    if (_intent != PaymentIntent.settleInvoice) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Row(
          children: [
            Icon(
              _intent == PaymentIntent.advancePayment
                  ? Icons.forward_to_inbox
                  : Icons.account_balance_wallet,
              color: AppTheme.slate500,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _intent == PaymentIntent.advancePayment
                        ? 'No invoice link'
                        : 'On-account payment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _intent == PaymentIntent.advancePayment
                        ? 'This amount will be held as customer credit toward future orders.'
                        : 'Payment reduces the customer\'s overall balance without tying to a specific invoice.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_pendingOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: AppTheme.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This customer has no unpaid invoices. Use "Advance" or "On Account" instead.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.slate800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Invoice',
          subtitle: 'Which invoice is this settling?',
        ),
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: _selectedOrder,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Unpaid Invoice *',
            prefixIcon: Icon(Icons.receipt_long_outlined),
          ),
          items: _pendingOrders.map<DropdownMenuItem<Map<String, dynamic>>>((
            o,
          ) {
            final m = o as Map<String, dynamic>;
            final amount = (m['totalAmount'] as num?) ?? 0;
            final orderNum = m['orderNumber'] as String? ?? '?';
            final dateStr = m['orderDate'] as String?;
            final dateLabel = dateStr != null
                ? DateFormat('MMM dd').format(DateTime.parse(dateStr))
                : '';
            return DropdownMenuItem(
              value: m,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          orderNum,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ETB ${NumberFormat.decimalPattern().format(amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (o) => _onOrderChanged(o),
          validator: (v) => v == null ? 'Select an invoice' : null,
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Amount',
          subtitle: 'How much is being paid?',
        ),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.slate900,
          ),
          decoration: InputDecoration(
            labelText: 'Amount (ETB)',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text(
                'ETB',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            hintText: '0.00',
            suffixIcon: _amountController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _amountController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter amount';
            final amount = double.tryParse(v);
            if (amount == null || amount <= 0) return 'Enter valid amount';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        if (_selectedOrder != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 14,
                color: AppTheme.slate500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Partial payment allowed. Invoice will be marked PARTIALLY_PAID.',
                  style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMethodAndDateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Method & Date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'CASH',
                child: Row(
                  children: [
                    Icon(
                      Icons.payments,
                      size: 18,
                      color: AppTheme.successColor,
                    ),
                    SizedBox(width: 8),
                    Text('Cash'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'BANK_TRANSFER',
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 18,
                      color: AppTheme.infoColor,
                    ),
                    SizedBox(width: 8),
                    Text('Bank Transfer'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'MOBILE_MONEY',
                child: Row(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 18,
                      color: AppTheme.warningColor,
                    ),
                    SizedBox(width: 8),
                    Text('Mobile Money'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'CHECK',
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 18,
                      color: AppTheme.slate600,
                    ),
                    SizedBox(width: 8),
                    Text('Check'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'OTHER',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, size: 18, color: AppTheme.slate600),
                    SizedBox(width: 8),
                    Text('Other'),
                  ],
                ),
              ),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _paymentDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.slate200),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: AppTheme.slate600,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Payment Date',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_paymentDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceAndNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _referenceController,
          decoration: const InputDecoration(
            labelText: 'Reference (Optional)',
            hintText: 'e.g. TRX123456, Cheque #...',
            prefixIcon: Icon(Icons.tag),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Any additional context...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Icon(Icons.note_outlined),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    final intentInfo = _getIntentInfo();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intentInfo.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: intentInfo.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_rounded, size: 18, color: intentInfo.color),
              const SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: intentInfo.color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Customer', value: _selectedCustomer!['name']),
          const SizedBox(height: 6),
          _SummaryRow(label: 'Intent', value: intentInfo.title),
          if (_selectedOrder != null) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              label: 'For Invoice',
              value: _selectedOrder!['orderNumber'] as String,
            ),
          ],
          const SizedBox(height: 6),
          _SummaryRow(label: 'Method', value: _formatMethod(_paymentMethod)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              Text(
                'ETB ${NumberFormat.decimalPattern().format(_currentAmount)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: intentInfo.color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance After',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _balanceAfterPayment >= 0
                    ? 'ETB ${NumberFormat.decimalPattern().format(_balanceAfterPayment)} owed'
                    : 'ETB ${NumberFormat.decimalPattern().format(_balanceAfterPayment.abs())} credit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _balanceAfterPayment > 0
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canSave =
        !_isSaving &&
        _selectedCustomer != null &&
        _currentAmount > 0 &&
        (_intent != PaymentIntent.settleInvoice || _selectedOrder != null);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: canSave ? _savePayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getIntentInfo().color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 22),
            label: const Text(
              'Record Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  _IntentInfo _getIntentInfo() {
    switch (_intent) {
      case PaymentIntent.settleInvoice:
        return const _IntentInfo(
          title: 'Settle Invoice',
          description:
              'Pay against a specific credit sales order. The invoice will be marked PAID (full) or PARTIALLY_PAID (partial).',
          icon: Icons.receipt_long,
          color: AppTheme.primaryColor,
          bgColor: AppTheme.primaryLight,
        );
      case PaymentIntent.advancePayment:
        return const _IntentInfo(
          title: 'Advance Payment',
          description:
              'Customer pre-pays for future deliveries. Funds are held as customer credit and applied to invoices when they are created.',
          icon: Icons.forward_to_inbox,
          color: AppTheme.infoColor,
          bgColor: AppTheme.infoLight,
        );
      case PaymentIntent.onAccount:
        return const _IntentInfo(
          title: 'On-Account Payment',
          description:
              'Generic payment that reduces the customer\'s overall balance without tying to a specific invoice. Use for ad-hoc collections.',
          icon: Icons.account_balance_wallet,
          color: AppTheme.successColor,
          bgColor: AppTheme.successLight,
        );
    }
  }

  String _formatMethod(String m) {
    switch (m) {
      case 'CASH':
        return 'Cash';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'MOBILE_MONEY':
        return 'Mobile Money';
      case 'CHECK':
        return 'Check';
      default:
        return 'Other';
    }
  }
}

class _IntentInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _IntentInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

class _IntentOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _IntentOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? color : AppTheme.slate300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : color,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppTheme.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String suffix;
  final String prefix;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.suffix,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.slate500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix ETB ${NumberFormat.decimalPattern().format(value)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          suffix,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.slate600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
