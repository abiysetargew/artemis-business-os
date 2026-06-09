import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateSalesOrderScreen extends StatelessWidget {
  const CreateSalesOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
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
              Icon(Icons.construction, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 24),
              Text(
                'Sales Order Form',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'This screen will allow you to:\n• Select customer\n• Add products with quantities\n• Choose cash/credit sale\n• Calculate totals automatically',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const Text(
                'Architecture: Clean Architecture + Riverpod\nAPI: Fully integrated via Dio',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
