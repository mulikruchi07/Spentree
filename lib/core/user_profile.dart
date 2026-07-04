import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for user profile state.
/// All screens observe this; AccountScreen writes to it.
class UserProfile {
  final String name;
  final Uint8List? imageBytes;

  const UserProfile({required this.name, this.imageBytes});
  String get firstName => name.split(' ').first;

  UserProfile copyWith({
    String? name,
    Uint8List? imageBytes,
    bool clearImage = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
    );
  }
}

class UserProfileNotifier extends ValueNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile(name: 'User'));

  static const _keyName = 'user_name';
  static const _keyImage = 'profile_image';
  static const _keyPendingSync = 'name_pending_sync';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName) ?? 'User';
    final b64 = prefs.getString(_keyImage);
    value = UserProfile(
      name: name,
      imageBytes: b64 != null ? base64Decode(b64) : null,
    );
    await _refreshFromDatabase(); // ← ADD THIS
  }

  Future<void> _refreshFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && row['name'] != null) {
        final dbName = row['name'] as String;
        if (dbName != value.name) await updateName(dbName);
      }
    } catch (e) {
      debugPrint("Couldn't refresh profile from DB: $e");
    }
  }

Future<void> updateName(String name) async {
  value = value.copyWith(name: name);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyName, name);
  await prefs.setBool(_keyPendingSync, true);
  _trySyncName(name);
}

Future<void> _trySyncName(String name) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  try {
    await Supabase.instance.client.from('users').update({'name': name}).eq('id', user.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPendingSync, false);
  } catch (e) {
    debugPrint("Name sync deferred (likely offline): $e");
  }
}

Future<void> retryPendingSync() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_keyPendingSync) ?? false) {
    await _trySyncName(value.name);
  }
}

  Future<void> updateImage(Uint8List bytes) async {
    value = value.copyWith(imageBytes: bytes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyImage, base64Encode(bytes));
  }

  Future<void> removeImage() async {
    value = value.copyWith(clearImage: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyImage);
  }
}

/// Global singleton — import this everywhere.
final userProfileNotifier = UserProfileNotifier();
