import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductionBatchesScreen extends StatelessWidget {
  const ProductionBatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production'),
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
              Icon(Icons.factory, size: 80, color: Colors.orange[300]),
              const SizedBox(height: 24),
              Text(
                'Production Batches',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'This screen will allow you to:\n• View all production batches\n• Create new batches\n• Track material consumption\n• Monitor yield & waste',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const Text(
                'Auto: Material consumption + Finished goods production',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
