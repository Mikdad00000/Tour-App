import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../trip/data/trip_repository.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';

class PeerLoanScreen extends ConsumerStatefulWidget {
  const PeerLoanScreen({super.key, required this.tripId});
  final String tripId;
  @override
  ConsumerState<PeerLoanScreen> createState() => _PeerLoanScreenState();
}

class _PeerLoanScreenState extends ConsumerState<PeerLoanScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  Set<String> _borrowers = {};
  bool _includeMeInSplit = false; // dual-meal scenario
  bool _busy = false;

  Future<void> _save(String me) async {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0 || _borrowers.isEmpty) return;

    final participants = <String>{
      ..._borrowers,
      if (_includeMeInSplit) me,
    }.toList();

    setState(() => _busy = true);
    try {
      await ref.read(expenseRepositoryProvider).add(
            tripId: widget.tripId,
            type: ExpenseType.peerLoan,
            paidBy: me,
            fromPool: false,
            participants: participants,
            amount: amount,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final expenses = ref.watch(expensesProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('ধার দিলাম / ধার নিলাম')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trip) {
          final others = trip.memberIds.where((m) => m != me).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('"তুমি দাও, আমি পরে দিব" — এমন লেনদেন এখানে যোগ করো',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'মোট কত দিয়েছি (৳)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'কীসের জন্য?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('কার হয়ে দিয়েছি?'),
              ...others.map((m) => CheckboxListTile(
                    title: Text(m.substring(0, 6)),
                    value: _borrowers.contains(m),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _borrowers.add(m);
                      } else {
                        _borrowers.remove(m);
                      }
                    }),
                  )),
              SwitchListTile(
                title: const Text('আমিও একসাথে শেয়ার করেছি (e.g. দুজনে খেলাম)'),
                value: _includeMeInSplit,
                onChanged: (v) => setState(() => _includeMeInSplit = v),
              ),
              FilledButton(
                onPressed: _busy ? null : () => _save(me),
                child: const Text('লোন রেকর্ড করো'),
              ),
              const Divider(height: 32),
              const Text('আমার Pending লোন', style: TextStyle(fontWeight: FontWeight.bold)),
              expenses.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (list) {
                  final mine = list.where((e) =>
                      e.isPeerLoan && e.paidBy == me && e.loanStatus == 'pending').toList();
                  if (mine.isEmpty) return const Text('কিছু নেই।');
                  return Column(
                    children: mine.map((e) {
                      final perHead = e.perHeadAmount;
                      final borrowers =
                          e.participants.where((p) => p != me).toList();
                      return Card(
                        child: ListTile(
                          title: Text('৳${e.amount.toStringAsFixed(0)} — ${e.note ?? ""}'),
                          subtitle: Text(
                              '${borrowers.length} জন × ৳${perHead.toStringAsFixed(0)} • ${DateFormat.yMd().format(e.createdAt)}'),
                          trailing: TextButton(
                            onPressed: () => ref
                                .read(expenseRepositoryProvider)
                                .markLoanRepaid(widget.tripId, e.id),
                            child: const Text('Repaid'),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
