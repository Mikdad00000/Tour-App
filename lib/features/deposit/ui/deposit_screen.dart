import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../trip/data/trip_repository.dart';
import '../data/deposit_repository.dart';

class DepositScreen extends ConsumerWidget {
  const DepositScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final tripAsync = ref.watch(tripProvider(tripId));
    final depositsAsync = ref.watch(depositsProvider(tripId));
    return Scaffold(
      appBar: AppBar(title: const Text('জমা')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: depositsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final isAdmin = tripAsync.maybeWhen(
            data: (t) => me != null && t.isAdmin(me),
            orElse: () => false,
          );
          if (list.isEmpty) return const Center(child: Text('কোন জমা নেই'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = list[i];
              return ListTile(
                leading: Icon(d.confirmedByAdmin ? Icons.check_circle : Icons.schedule,
                    color: d.confirmedByAdmin ? Colors.green : Colors.orange),
                title: Text('৳${d.amount.toStringAsFixed(0)} — ${d.userId.substring(0, 6)}'),
                subtitle: Text(DateFormat.yMd().add_Hm().format(d.date)),
                trailing: isAdmin && !d.confirmedByAdmin
                    ? TextButton(
                        onPressed: () => ref
                            .read(depositRepositoryProvider)
                            .confirm(tripId, d.id, d.amount),
                        child: const Text('Confirm'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final amount = TextEditingController();
    final note = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'কত টাকা?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'নোট (ঐচ্ছিক)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final me = FirebaseAuth.instance.currentUser?.uid;
                if (me == null) return;
                final v = double.tryParse(amount.text);
                if (v == null || v <= 0) return;
                await ref.read(depositRepositoryProvider).add(
                      tripId: tripId,
                      userId: me,
                      amount: v,
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('জমা যোগ করো'),
            ),
          ],
        ),
      ),
    );
  }
}
