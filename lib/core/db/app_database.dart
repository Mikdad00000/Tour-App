import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// SyncStatus enum stored as int
class SyncStatusConst {
  static const int pending = 0;
  static const int synced = 1;
  static const int conflict = 2;
}

@DataClassName('UserRow')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get fcmToken => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get adminId => text()();
  TextColumn get memberIdsJson => text()(); // JSON list
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get currency => text().withDefault(const Constant('BDT'))();
  RealColumn get totalCash => real().withDefault(const Constant(0))();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DepositRow')
class Deposits extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get userId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get confirmedByAdmin => boolean().withDefault(const Constant(false))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  // 'shared' | 'partial' | 'individual' | 'peer_loan'
  TextColumn get type => text()();
  TextColumn get paidBy => text()();
  BoolColumn get fromPool => boolean().withDefault(const Constant(true))();
  TextColumn get participantsJson => text()();
  TextColumn get witnessesJson => text().withDefault(const Constant('[]'))();
  RealColumn get amount => real()();
  RealColumn get perHeadAmount => real()();
  TextColumn get category => text().nullable()();
  TextColumn get note => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get placeName => text().nullable()();
  TextColumn get receiptUrl => text().nullable()();
  // Loan-specific
  TextColumn get loanStatus => text().nullable()(); // 'pending' | 'repaid' | null
  DateTimeColumn get repaidAt => dateTime().nullable()();
  TextColumn get repaidByJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get tripId => text()();
  TextColumn get userId => text()();
  RealColumn get budgetAmount => real()();
  RealColumn get spent => real().withDefault(const Constant(0))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {tripId, userId};
}

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get type => text()(); // 'expense' | 'info' | 'loan' | 'repayment' | 'deposit'
  TextColumn get payloadJson => text()();
  TextColumn get recipientsJson => text()();
  TextColumn get readByJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Trips, Deposits, Expenses, Budgets, Activities])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 1;

  Future<List<TripRow>> watchTripsForUser(String userId) async {
    final all = await select(trips).get();
    return all
        .where((t) => t.adminId == userId || t.memberIdsJson.contains('"$userId"'))
        .toList();
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'tour_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
