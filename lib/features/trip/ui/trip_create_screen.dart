import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/trip_repository.dart';

class TripCreateScreen extends ConsumerStatefulWidget {
  const TripCreateScreen({super.key});
  @override
  ConsumerState<TripCreateScreen> createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends ConsumerState<TripCreateScreen> {
  final _name = TextEditingController();
  final _budget = TextEditingController(text: '5000');
  final _memberPhones = TextEditingController(); // comma-separated
  DateTime _start = DateTime.now();
  bool _busy = false;

  Future<void> _create() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      final memberIds = <String>[me.uid];
      // Production: resolve phone → userId via /users index. MVP stores phones for invite.
      final tripId = await ref.read(tripRepositoryProvider).createTrip(
            name: _name.text.trim(),
            adminId: me.uid,
            memberIds: memberIds,
            startDate: _start,
          );
      await ref.read(tripRepositoryProvider).setBudget(
            tripId,
            me.uid,
            double.tryParse(_budget.text) ?? 0,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন ট্যুর')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'ট্যুরের নাম',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memberPhones,
              decoration: const InputDecoration(
                labelText: 'মেম্বার ফোন (কমা দিয়ে আলাদা)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'প্রতি জনের প্রাথমিক বাজেট (৳)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('শুরুর তারিখ'),
              subtitle: Text('${_start.year}-${_start.month}-${_start.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _start = picked);
              },
            ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _create,
              child: const Text('ট্যুর তৈরি করো'),
            ),
          ],
        ),
      ),
    );
  }
}
