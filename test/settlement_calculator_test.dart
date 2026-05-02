import 'package:flutter_test/flutter_test.dart';
import 'package:tour_app/features/deposit/data/deposit_repository.dart';
import 'package:tour_app/features/expense/domain/expense.dart';
import 'package:tour_app/features/settle/logic/settlement_calculator.dart';

Deposit dep(String uid, double amt, {bool confirmed = true}) => Deposit(
      id: '$uid-$amt',
      userId: uid,
      amount: amt,
      date: DateTime(2026, 1, 1),
      confirmedByAdmin: confirmed,
    );

Expense ex({
  required ExpenseType type,
  required String paidBy,
  required double amount,
  required List<String> participants,
  bool fromPool = true,
  String? loanStatus,
}) {
  return Expense(
    id: 'ex-${DateTime.now().microsecondsSinceEpoch}',
    tripId: 't',
    type: type,
    paidBy: paidBy,
    fromPool: fromPool,
    participants: participants,
    witnesses: const [],
    amount: amount,
    perHeadAmount: participants.isEmpty ? 0 : amount / participants.length,
    loanStatus: loanStatus,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final calc = SettlementCalculator();
  const admin = 'admin';
  const a = 'A';
  const b = 'B';
  const c = 'C';
  final members = [admin, a, b, c];

  Balance pick(SettlementResult r, String uid) =>
      r.balances.firstWhere((e) => e.userId == uid);

  test('সমান ভাগ — সবাই সমান জমা ও সমান ভাগে শেয়ার', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: [
        dep(admin, 1000), dep(a, 1000), dep(b, 1000), dep(c, 1000),
      ],
      expenses: [
        ex(type: ExpenseType.shared, paidBy: admin, amount: 4000, participants: members),
      ],
    );
    for (final m in members) {
      expect(pick(r, m).amount, closeTo(0, 0.01));
    }
    expect(r.transfers, isEmpty);
  });

  test('অসম জমা — admin বেশি দিল, settle-up এ বাকিরা পরিশোধ করবে', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: [dep(admin, 4000)],
      expenses: [
        ex(type: ExpenseType.shared, paidBy: admin, amount: 4000, participants: members),
      ],
    );
    expect(pick(r, admin).amount, closeTo(-3000, 0.01));
    expect(pick(r, a).amount, closeTo(1000, 0.01));
    expect(r.transfers.length, 3);
  });

  test('পার্শিয়াল-ওনলি — শুধু A আর B একটা partial খরচে শেয়ার করেছে', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: [dep(admin, 2000)],
      expenses: [
        ex(type: ExpenseType.partial, paidBy: admin, amount: 1000, participants: [a, b]),
      ],
    );
    expect(pick(r, a).amount, closeTo(500, 0.01));
    expect(pick(r, b).amount, closeTo(500, 0.01));
    expect(pick(r, c).amount, closeTo(0, 0.01));
    // Admin deposited 2000, consumed 0 of partial → owed 2000.
    // (Leftover pool cash stays with admin physically; calculator only shows raw debts.)
    expect(pick(r, admin).amount, closeTo(-2000, 0.01));
  });

  test('একজন বেশি দিল — A বেশি জমা দিয়েছে, কম খরচ', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: [dep(a, 3000), dep(admin, 1000)],
      expenses: [
        ex(type: ExpenseType.shared, paidBy: admin, amount: 2000, participants: members),
      ],
    );
    expect(pick(r, a).amount, closeTo(-2500, 0.01));
    expect(pick(r, admin).amount, closeTo(-500, 0.01));
    expect(pick(r, b).amount, closeTo(500, 0.01));
    expect(pick(r, c).amount, closeTo(500, 0.01));
  });

  test('একজন কিছুই দেয়নি — C জমা দেয়নি কিন্তু খরচ ভাগ পেয়েছে', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: [dep(a, 1000), dep(b, 1000), dep(admin, 1000)],
      expenses: [
        ex(type: ExpenseType.shared, paidBy: admin, amount: 2000, participants: members),
      ],
    );
    expect(pick(r, c).amount, closeTo(500, 0.01));
    final cTransfers = r.transfers.where((t) => t.from == c);
    expect(cTransfers.fold<double>(0, (a, t) => a + t.amount), closeTo(500, 0.01));
  });

  test('peer_loan pending — A B-এর জন্য পুরো বিল দিয়েছে', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: const [],
      expenses: [
        ex(type: ExpenseType.peerLoan, paidBy: a, amount: 300, participants: [b],
            fromPool: false, loanStatus: 'pending'),
      ],
    );
    expect(pick(r, a).amount, closeTo(-300, 0.01));
    expect(pick(r, b).amount, closeTo(300, 0.01));
    final t = r.transfers.firstWhere((tr) => tr.from == b && tr.to == a);
    expect(t.amount, closeTo(300, 0.01));
  });

  test('peer_loan dual-share — দুজনে খেল, A বিল দিল (participants=[A,B])', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: const [],
      expenses: [
        ex(type: ExpenseType.peerLoan, paidBy: a, amount: 400, participants: [a, b],
            fromPool: false, loanStatus: 'pending'),
      ],
    );
    // A's own share = 200; A is owed 200. B owes 200.
    expect(pick(r, a).amount, closeTo(-200, 0.01));
    expect(pick(r, b).amount, closeTo(200, 0.01));
  });

  test('peer_loan repaid — repaid status থাকলে settle-up এ ignore', () {
    final r = calc.compute(
      memberIds: members,
      adminId: admin,
      deposits: const [],
      expenses: [
        ex(type: ExpenseType.peerLoan, paidBy: a, amount: 500, participants: [b],
            fromPool: false, loanStatus: 'repaid'),
      ],
    );
    for (final m in members) {
      expect(pick(r, m).amount, closeTo(0, 0.01));
    }
  });
}
