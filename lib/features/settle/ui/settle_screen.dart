import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../deposit/data/deposit_repository.dart';
import '../../expense/data/expense_repository.dart';
import '../../trip/data/trip_repository.dart';
import '../logic/settlement_calculator.dart';

class SettleScreen extends ConsumerWidget {
  const SettleScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    final depositsAsync = ref.watch(depositsProvider(tripId));
    final expensesAsync = ref.watch(expensesProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('সেটেল-আপ')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trip) {
          return depositsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (deps) {
              return expensesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (exps) {
                  final result = SettlementCalculator().compute(
                    memberIds: trip.memberIds,
                    adminId: trip.adminId,
                    deposits: deps,
                    expenses: exps,
                  );
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      const Text('Net Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...result.balances.map((b) => ListTile(
                            title: Text(b.userId.substring(0, 6)),
                            trailing: Text(
                              '৳${b.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: b.amount > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                      const Divider(),
                      const Text('Transfers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (result.transfers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('সবাই settled — কোন বকেয়া নাই।'),
                        )
                      else
                        ...result.transfers.map((t) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.arrow_forward),
                                title: Text('${t.from.substring(0, 6)} → ${t.to.substring(0, 6)}'),
                                trailing: Text('৳${t.amount.toStringAsFixed(2)}'),
                              ),
                            )),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
