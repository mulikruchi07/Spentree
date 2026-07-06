import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
  static const _keyPendingAction = 'profile_image_pending_action';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName) ?? 'User';
    final b64 = prefs.getString(_keyImage);
    value = UserProfile(
      name: name,
      imageBytes: b64 != null ? base64Decode(b64) : null,
    );

    // Never block app startup on network — refresh happens in background.
    _refreshFromDatabase()
        .timeout(const Duration(seconds: 5))
        .catchError((e) => debugPrint("Profile refresh skipped (offline): $e"));
  }

  Future<void> _refreshFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('name, profile_image_url')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (row == null) return;
      if (row['name'] != null && row['name'] != value.name) {
        await updateName(row['name'] as String);
      }
      final hasPendingImageAction =
          (await SharedPreferences.getInstance()).getString(
            _keyPendingAction,
          ) !=
          null;
      if (!hasPendingImageAction) {
        final imageUrl = row['profile_image_url'] as String?;
        if (imageUrl != null) {
          final response = await http
              .get(Uri.parse(imageUrl))
              .timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            value = value.copyWith(imageBytes: response.bodyBytes);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyImage, base64Encode(response.bodyBytes));
          }
        } else {
          value = value.copyWith(clearImage: true);
          await (await SharedPreferences.getInstance()).remove(_keyImage);
        }
      } else {
        await _trySyncPendingImage();
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
      await Supabase.instance.client
          .from('users')
          .update({'name': name})
          .eq('id', user.id);
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
    await prefs.setString(_keyPendingAction, 'upload'); // last action wins
    await _trySyncPendingImage();
  }

  Future<void> removeImage() async {
    value = value.copyWith(clearImage: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyImage);
    await prefs.setString(_keyPendingAction, 'delete');
    await _trySyncPendingImage();
  }

  Future<void> _trySyncPendingImage() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_keyPendingAction);
    if (pending == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final path = '${user.id}/profile.jpg';
      if (pending == 'upload') {
        final b64 = prefs.getString(_keyImage);
        if (b64 == null) {
          await prefs.remove(_keyPendingAction);
          return;
        }
        final bytes = base64Decode(b64);
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            )
            .timeout(const Duration(seconds: 15));
        final url = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(path);
        final bustedUrl =
            '$url?v=${DateTime.now().millisecondsSinceEpoch}'; // avoids stale CDN cache on other devices
        await Supabase.instance.client
            .from('users')
            .update({'profile_image_url': bustedUrl})
            .eq('id', user.id)
            .timeout(const Duration(seconds: 10));
      } else if (pending == 'delete') {
        try {
          await Supabase.instance.client.storage
              .from('avatars')
              .remove([path])
              .timeout(const Duration(seconds: 10));
        } catch (_) {} // fine if it's already gone
        await Supabase.instance.client
            .from('users')
            .update({'profile_image_url': null})
            .eq('id', user.id)
            .timeout(const Duration(seconds: 10));
      }
      await prefs.remove(_keyPendingAction);
    } catch (e) {
      debugPrint("Profile image sync deferred: $e");
      // flag stays set, retried automatically next call below
    }
  }

  Future<void> retryPendingImageSync() => _trySyncPendingImage();
}

/// Global singleton — import this everywhere.
final userProfileNotifier = UserProfileNotifier();
