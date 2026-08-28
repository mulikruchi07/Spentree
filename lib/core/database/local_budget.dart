import 'package:isar/isar.dart';

part 'local_budget.g.dart';

@collection
class LocalBudget {
  Id id = Isar.autoIncrement;

  // Supabase budgets.id (uuid) once this budget has synced at least once.
  @Index()
  String? cloudId;

  @Index()
  String? userId;

  late String category;
  late double limit;

  // Normalized to the 1st of the month, stored as an actual DateTime
  // locally for easy range queries; synced to the server as a
  // 'year-month' string (see BudgetService._monthKey).
  late DateTime month;

  bool isDeleted = false;
  bool isSynced = false;

  DateTime updatedAt = DateTime.now();
}
