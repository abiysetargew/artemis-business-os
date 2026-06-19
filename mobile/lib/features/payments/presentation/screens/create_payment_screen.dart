import 'package:artemis_business_os/core/network/api_errors.dart';
import 'package:artemis_business_os/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String _paymentMethod = 'CASH';
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final customersRes = await api.get('/customers');
      setState(() {
        _customers = customersRes.data as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customers: ${parseApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/payments',
        data: {
          'customerId': _selectedCustomer!['id'],
          'amount': double.parse(_amountController.text),
          'paymentMethod': _paymentMethod,
          'paymentDate': _paymentDate.toIso8601String(),
          'referenceNumber': _referenceController.text,
          'notes': _notesController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ETB ${_amountController.text} recorded!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parseApiError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Selection
            Text('Customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              initialValue: _selectedCustomer,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select Customer',
                prefixIcon: Icon(Icons.person),
              ),
              items: _customers.map<DropdownMenuItem<Map<String, dynamic>>>((
                c,
              ) {
                return DropdownMenuItem(
                  value: c as Map<String, dynamic>,
                  child: Text(
                    '${c['name']} • Owes: ETB ${(c['outstandingBalance'] as num).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: (c['outstandingBalance'] as num) > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (c) {
                setState(() {
                  _selectedCustomer = c;
                  // Pre-fill amount with outstanding balance
                  if (c != null &&
                      (c['outstandingBalance'] as num) > 0 &&
                      _amountController.text.isEmpty) {
                    _amountController.text = (c['outstandingBalance'] as num)
                        .toStringAsFixed(2);
                  }
                });
              },
              validator: (v) => v == null ? 'Please select a customer' : null,
            ),
            const SizedBox(height: 16),

            // Amount
            Text('Amount', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (ETB)',
                prefixIcon: Icon(Icons.payments),
                prefixText: 'ETB ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter amount';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return 'Enter valid amount';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Payment Method
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Method',
                prefixIcon: Icon(Icons.account_balance),
              ),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                DropdownMenuItem(
                  value: 'BANK_TRANSFER',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(
                  value: 'MOBILE_MONEY',
                  child: Text('Mobile Money'),
                ),
                DropdownMenuItem(value: 'CHECK', child: Text('Check')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
            ),
            const SizedBox(height: 16),

            // Payment Date
            Text(
              'Payment Date',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('${_paymentDate.toLocal()}'.split('.')[0]),
                trailing: const Icon(Icons.edit),
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
              ),
            ),
            const SizedBox(height: 16),

            // Reference Number
            Text(
              'Reference (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Transaction Reference',
                prefixIcon: Icon(Icons.tag),
                hintText: 'e.g., TRX123456',
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Summary Card
            if (_selectedCustomer != null && _amountController.text.isNotEmpty)
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer:'),
                          Text(
                            _selectedCustomer!['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount:'),
                          Text(
                            'ETB ${_amountController.text}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Method:'), Text(_paymentMethod)],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePayment,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('RECORD PAYMENT'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
