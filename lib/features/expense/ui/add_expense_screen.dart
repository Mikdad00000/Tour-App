import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../trip/data/trip_repository.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.tripId});
  final String tripId;
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _category = 'খাবার';
  ExpenseType _type = ExpenseType.shared;
  Set<String> _participants = {};
  Set<String> _witnesses = {};
  bool _busy = false;

  static const _categories = ['খাবার', 'ট্রান্সপোর্ট', 'হোটেল', 'টিকিট', 'অন্যান্য'];

  Future<void> _save(List<String> allMembers) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) return;

    final participants = _type == ExpenseType.shared
        ? allMembers
        : _participants.toList();
    final witnesses = _type == ExpenseType.partial
        ? allMembers.where((m) => !_participants.contains(m)).toList()
        : <String>[];

    setState(() => _busy = true);
    try {
      final loc = await LocationService.instance.tryGetCurrent();
      await ref.read(expenseRepositoryProvider).add(
            tripId: widget.tripId,
            type: _type,
            paidBy: me,
            fromPool: true,
            participants: participants,
            witnesses: witnesses,
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
    final trip = ref.watch(tripProvider(widget.tripId));
    return Scaffold(
      appBar: AppBar(title: const Text('গ্রুপ খরচ')),
      body: trip.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (t) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<ExpenseType>(
                segments: const [
                  ButtonSegment(value: ExpenseType.shared, label: Text('সবার')),
                  ButtonSegment(value: ExpenseType.partial, label: Text('কয়েকজনের')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  if (_type == ExpenseType.shared) _participants = t.memberIds.toSet();
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'কত টাকা (৳)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: const InputDecoration(
                  labelText: 'ক্যাটাগরি',
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
              if (_type == ExpenseType.partial) ...[
                const SizedBox(height: 16),
                const Text('কে কে শেয়ার করবে?', style: TextStyle(fontWeight: FontWeight.bold)),
                ...t.memberIds.map((m) => CheckboxListTile(
                      title: Text(m.substring(0, 6)),
                      value: _participants.contains(m),
                      onChanged: (v) => setState(() {
                        if (v ?? false) {
                          _participants.add(m);
                        } else {
                          _participants.remove(m);
                        }
                      }),
                    )),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _save(t.memberIds),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('সেভ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
