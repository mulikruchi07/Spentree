import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'local_transaction.dart';

class LocalDatabaseService {
  static late Isar isar;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Finds a safe folder on the Android/iOS device to store the database
    final dir = await getApplicationDocumentsDirectory();
    
    // Opens the database
    isar = await Isar.open(
      [LocalTransactionSchema],
      directory: dir.path,
    );
    
    _isInitialized = true;
  }
}