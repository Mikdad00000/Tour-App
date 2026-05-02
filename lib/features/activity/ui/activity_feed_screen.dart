import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/activity_repository.dart';

class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final activity = ref.watch(activityProvider(tripId));
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাক্টিভিটি')),
      body: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('কোন অ্যাক্টিভিটি নেই'));
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final a = list[i];
              final read = me != null && a.readBy.contains(me);
              return ListTile(
                leading: Icon(_iconFor(a.type),
                    color: read ? Colors.grey : Theme.of(context).colorScheme.primary),
                title: Text(_titleFor(a)),
                subtitle: Text(DateFormat.yMd().add_Hm().format(a.createdAt)),
                trailing: read ? null : const Icon(Icons.fiber_manual_record, size: 10),
                onTap: () {
                  if (me != null && !read) {
                    ref.read(activityRepositoryProvider).markRead(tripId, a.id, me);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'shared': return Icons.group;
      case 'partial': return Icons.group_work;
      case 'peer_loan': return Icons.handshake;
      case 'repayment': return Icons.check_circle;
      case 'deposit': return Icons.savings;
      default: return Icons.info;
    }
  }

  String _titleFor(ActivityItem a) {
    final amt = (a.payload['amount'] as num?)?.toStringAsFixed(0) ?? '';
    final note = a.payload['note'] as String? ?? a.payload['category'] as String? ?? '';
    switch (a.type) {
      case 'shared': return 'গ্রুপ খরচ ৳$amt — $note';
      case 'partial': return 'পার্শিয়াল খরচ ৳$amt — $note';
      case 'peer_loan': return 'ধার ৳$amt — $note';
      case 'repayment': return 'ধার শোধ ৳$amt';
      case 'deposit': return 'জমা ৳$amt';
      default: return a.type;
    }
  }
}
