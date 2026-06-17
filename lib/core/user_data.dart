import 'user_profile.dart';

class UserData {
  static String dailyLimit = "5000";

  // Pass-through to the notifier — keeps legacy references compiling
  // while screens are migrated one by one.
  static String get userName => userProfileNotifier.value.name;
  static set userName(String name) => userProfileNotifier.updateName(name);
}