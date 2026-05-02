import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/trip_repository.dart';
import 'trip_create_screen.dart';
import 'trip_dashboard_screen.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(myTripsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('আমার ট্যুর')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TripCreateScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('নতুন ট্যুর'),
      ),
      body: trips.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('কোন ট্যুর নেই — নিচে থেকে নতুন বানাও'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final t = list[i];
              return Card(
                child: ListTile(
                  title: Text(t.name),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(t.startDate)} • ${t.memberIds.length} জন • ${t.status}',
                  ),
                  trailing: Text('৳${t.totalCash.toStringAsFixed(0)}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TripDashboardScreen(tripId: t.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
