import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';

class PersonalExpenseScreen extends ConsumerStatefulWidget {
  const PersonalExpenseScreen({super.key, required this.tripId});
  final String tripId;
  @override
  ConsumerState<PersonalExpenseScreen> createState() => _PersonalExpenseScreenState();
}

class _PersonalExpenseScreenState extends ConsumerState<PersonalExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = 'অন্যান্য';
  bool _busy = false;

  Future<void> _save() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      final loc = await LocationService.instance.tryGetCurrent();
      await ref.read(expenseRepositoryProvider).add(
            tripId: widget.tripId,
            type: ExpenseType.individual,
            paidBy: me,
            fromPool: false,
            participants: [me],
            amount: amount,
            category: _category,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            location: loc,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নিজের খরচ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('এই খরচটা শুধু তোমার বাজেট থেকে কাটবে — গ্রুপ পুল-এ যাবে না।'),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'কত টাকা (৳)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'কী কিনলে?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('সেভ'),
          ),
        ],
      ),
    );
  }
}
