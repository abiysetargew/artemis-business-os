import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePaymentScreen extends StatelessWidget {
  const CreatePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 80, color: Colors.green[300]),
              const SizedBox(height: 24),
              Text(
                'Payment Collection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'This screen will allow you to:\n• Select customer\n• Enter payment amount\n• Choose payment method\n• Upload receipt photos\n• Link to specific invoices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const Text(
                'Features: Camera/Gallery integration, Auto-balance update',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
