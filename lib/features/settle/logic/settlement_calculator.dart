import '../../deposit/data/deposit_repository.dart';
import '../../expense/domain/expense.dart';

/// Net amount user owes (positive) or is owed (negative).
class Balance {
  Balance(this.userId, this.amount);
  final String userId;
  final double amount; // > 0 means user owes the pool/network; < 0 means owed
  @override
  String toString() => '$userId: ${amount.toStringAsFixed(2)}';
}

class Transfer {
  Transfer({required this.from, required this.to, required this.amount});
  final String from;
  final String to;
  final double amount;
  @override
  String toString() => '$from → $to : ${amount.toStringAsFixed(2)}';
}

class SettlementResult {
  SettlementResult({required this.balances, required this.transfers});
  final List<Balance> balances;
  final List<Transfer> transfers;
}

/// Computes per-user net balance considering:
///   - deposits to admin pool (confirmed only)
///   - shared/partial pool expenses (each participant owes perHead share)
///   - peer_loan expenses still in 'pending' status
/// Then runs a min-transactions greedy solver.
class SettlementCalculator {
  static const double _eps = 0.01;

  SettlementResult compute({
    required List<String> memberIds,
    required String adminId,
    required List<Deposit> deposits,
    required List<Expense> expenses,
  }) {
    final net = <String, double>{for (final m in memberIds) m: 0.0};

    // Deposits: member gave money to admin pool. Lowers what they owe.
    for (final d in deposits) {
      if (!d.confirmedByAdmin) continue;
      net[d.userId] = (net[d.userId] ?? 0) - d.amount;
    }

    for (final e in expenses) {
      if (e.type == ExpenseType.individual) continue;

      if (e.fromPool) {
        // Pool spent on behalf of participants. Each owes their per-head share.
        // Admin is bookkeeper, not a counter-party — deposits already capture
        // every member's contribution including admin's.
        for (final p in e.participants) {
          net[p] = (net[p] ?? 0) + e.perHeadAmount;
        }
      } else if (e.type == ExpenseType.peerLoan) {
        if (e.loanStatus == 'repaid') continue;
        for (final p in e.participants) {
          if (p == e.paidBy) continue; // lender's own share isn't a debt
          net[p] = (net[p] ?? 0) + e.perHeadAmount;
        }
        // Lender is owed the total minus their own share if they were a participant.
        final lenderShare = e.participants.contains(e.paidBy) ? e.perHeadAmount : 0;
        net[e.paidBy] = (net[e.paidBy] ?? 0) - (e.amount - lenderShare);
      }
    }

    final balances = net.entries
        .map((e) => Balance(e.key, _round(e.value)))
        .toList(growable: false);

    final transfers = _minimizeTransfers(balances);
    return SettlementResult(balances: balances, transfers: transfers);
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  List<Transfer> _minimizeTransfers(List<Balance> balances) {
    final creditors = <_Holder>[]; // negative => owed money
    final debtors = <_Holder>[]; // positive => owes money
    for (final b in balances) {
      if (b.amount > _eps) {
        debtors.add(_Holder(b.userId, b.amount));
      } else if (b.amount < -_eps) {
        creditors.add(_Holder(b.userId, -b.amount));
      }
    }
    // Greedy: largest debtor pays largest creditor each step.
    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final out = <Transfer>[];
    var i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];
      final pay = d.amount < c.amount ? d.amount : c.amount;
      if (pay > _eps) {
        out.add(Transfer(from: d.userId, to: c.userId, amount: _round(pay)));
        d.amount -= pay;
        c.amount -= pay;
      }
      if (d.amount <= _eps) i++;
      if (c.amount <= _eps) j++;
    }
    return out;
  }
}

class _Holder {
  _Holder(this.userId, this.amount);
  final String userId;
  double amount;
}
