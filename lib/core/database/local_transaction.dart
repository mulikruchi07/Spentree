import 'package:isar/isar.dart';

part 'local_transaction.g.dart';

@collection
class LocalTransaction {
  Id id = Isar.autoIncrement;

  // CHANGED: Removed unique: true so multiple local transactions can have a null cloudId
  @Index()
  String? cloudId;

  @Index(composite: [CompositeIndex('smsHash')])
  String? userId;

  late double amount;
  late String receiverName;
  late String category;
  late DateTime dateTime;
  late String type;

  bool isHidden = false;
  bool isDeleted = false;

  bool isSynced = false;

  // smsHash stays unique because every SMS truly has a different hash
  @Index()
  String? smsHash;
}
