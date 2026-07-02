import 'package:shared_preferences/shared_preferences.dart';

import 'user_profile.dart';

class UserData {
  static String dailyLimit = "5000";
  static String spendingCategory = "";
  static String spendingGoal = "";

  // Pass-through to the notifier — keeps legacy references compiling
  // while screens are migrated one by one.
  static String get userName => userProfileNotifier.value.name;
  static set userName(String name) => userProfileNotifier.updateName(name);
  static Future<void> saveQuestionnaireData({
    required String dailyLimitValue,
    required String category,
    required String goal,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    dailyLimit = dailyLimitValue;
    spendingCategory = category;
    spendingGoal = goal;

    await prefs.setString('daily_limit_raw', dailyLimitValue);
    await prefs.setInt(
      'daily_expense_limit',
      int.tryParse(dailyLimitValue) ?? 5000,
    ); // FIX 4: same key Dashboard already reads
    await prefs.setString('spending_category', category);
    await prefs.setString('spending_goal', goal);
    await prefs.setBool('questionnaire_sync_pending', true); 
  }

  // ── FIX 3: Load questionnaire answers on app start ──
  static Future<void> loadQuestionnaireData() async {
    final prefs = await SharedPreferences.getInstance();
    dailyLimit = prefs.getString('daily_limit_raw') ?? dailyLimit;
    spendingCategory = prefs.getString('spending_category') ?? "";
    spendingGoal = prefs.getString('spending_goal') ?? "";
  }
}
