import 'package:isar/isar.dart';

part 'local_bucket.g.dart';

@collection
class LocalBucket {
  Id id = Isar.autoIncrement;

  // Supabase buckets.id (uuid) once this bucket has synced at least once.
  @Index()
  String? cloudId;

  @Index()
  String? userId;

  late String name;

  // The set of expenses in this bucket, referenced by the LOCAL Isar id
  // of each LocalTransaction — this is what the app's UI reads/writes
  // day-to-day (bucket_models.dart, screens, etc.), since a freshly
  // added Cash expense may not have a cloudId yet.
  List<int> transactionLocalIds = [];

  bool isDeleted = false;
  bool isSynced = false;

  DateTime updatedAt = DateTime.now();
}
