import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../activity/ui/activity_feed_screen.dart';
import '../../deposit/ui/deposit_screen.dart';
import '../../expense/ui/add_expense_screen.dart';
import '../../expense/ui/peer_loan_screen.dart';
import '../../expense/ui/personal_expense_screen.dart';
import '../../reports/ui/reports_screen.dart';
import '../../settle/ui/settle_screen.dart';
import '../data/trip_repository.dart';

class TripDashboardScreen extends ConsumerWidget {
  const TripDashboardScreen({super.key, required this.tripId});
  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    final me = FirebaseAuth.instance.currentUser?.uid;
    return tripAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (trip) {
        final isAdmin = me != null && trip.isAdmin(me);
        return Scaffold(
          appBar: AppBar(title: Text(trip.name)),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('পুল', style: TextStyle(fontSize: 12)),
                      Text('৳${trip.totalCash.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('খরচ: ৳${trip.totalSpent.toStringAsFixed(0)}'),
                      Text('বাকি: ৳${(trip.totalCash - trip.totalSpent).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DashAction(
                    icon: Icons.savings,
                    label: 'জমা',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DepositScreen(tripId: tripId))),
                  ),
                  if (isAdmin)
                    _DashAction(
                      icon: Icons.shopping_cart,
                      label: 'গ্রুপ খরচ',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddExpenseScreen(tripId: tripId))),
                    ),
                  _DashAction(
                    icon: Icons.person,
                    label: 'নিজের খরচ',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PersonalExpenseScreen(tripId: tripId))),
                  ),
                  _DashAction(
                    icon: Icons.handshake,
                    label: 'ধার দিলাম',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PeerLoanScreen(tripId: tripId))),
                  ),
                  _DashAction(
                    icon: Icons.feed,
                    label: 'অ্যাক্টিভিটি',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ActivityFeedScreen(tripId: tripId))),
                  ),
                  _DashAction(
                    icon: Icons.balance,
                    label: 'সেটেল',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SettleScreen(tripId: tripId))),
                  ),
                  _DashAction(
                    icon: Icons.summarize,
                    label: 'রিপোর্ট',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ReportsScreen(tripId: tripId))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashAction extends StatelessWidget {
  const _DashAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 32), const SizedBox(height: 6), Text(label)],
          ),
        ),
      ),
    );
  }
}
