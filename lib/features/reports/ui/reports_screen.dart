import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../expense/data/expense_repository.dart';
import '../../expense/domain/expense.dart';
import '../../trip/data/trip_repository.dart';
import '../logic/pdf_exporter.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    final expensesAsync = ref.watch(expensesProvider(tripId));
    return Scaffold(
      appBar: AppBar(title: const Text('রিপোর্ট')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trip) => expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (exps) {
            final byCat = <String, double>{};
            for (final e in exps.where((e) => e.fromPool)) {
              byCat[e.category ?? 'অন্যান্য'] =
                  (byCat[e.category ?? 'অন্যান্য'] ?? 0) + e.amount;
            }
            final byDay = <String, double>{};
            for (final e in exps) {
              final day = DateFormat.yMMMd().format(e.createdAt);
              byDay[day] = (byDay[day] ?? 0) + e.amount;
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                FilledButton.icon(
                  onPressed: () => PdfExporter().exportTrip(
                    tripName: trip.name,
                    expenses: exps,
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF এক্সপোর্ট'),
                ),
                const SizedBox(height: 16),
                const Text('ক্যাটাগরি অনুযায়ী', style: TextStyle(fontWeight: FontWeight.bold)),
                ...byCat.entries.map((e) => ListTile(
                      title: Text(e.key),
                      trailing: Text('৳${e.value.toStringAsFixed(0)}'),
                    )),
                const Divider(),
                const Text('দিন অনুযায়ী', style: TextStyle(fontWeight: FontWeight.bold)),
                ...byDay.entries.map((e) => ListTile(
                      title: Text(e.key),
                      trailing: Text('৳${e.value.toStringAsFixed(0)}'),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
