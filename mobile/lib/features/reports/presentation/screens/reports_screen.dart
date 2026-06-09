import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.green),
              title: const Text('Sales Reports'),
              subtitle: const Text('By product, customer, region, date'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory, color: Colors.blue),
              title: const Text('Inventory Reports'),
              subtitle: const Text('Valuation, movements, low stock'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.factory, color: Colors.orange),
              title: const Text('Production Reports'),
              subtitle: const Text('Batch history, consumption, yield'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.purple,
              ),
              title: const Text('Receivables Reports'),
              subtitle: const Text('Outstanding balances, aging analysis'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
