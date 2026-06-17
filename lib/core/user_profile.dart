import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

/// Single source of truth for user profile state.
/// All screens observe this; AccountScreen writes to it.
class UserProfile {
  final String name;
  final Uint8List? imageBytes;

  const UserProfile({required this.name, this.imageBytes});

  UserProfile copyWith({String? name, Uint8List? imageBytes, bool clearImage = false}) {
    return UserProfile(
      name: name ?? this.name,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
    );
  }
}

class UserProfileNotifier extends ValueNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile(name: 'Pranav'));

  static const _keyName  = 'user_name';
  static const _keyImage = 'profile_image';

  /// Call once at app startup (before runApp).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString(_keyName) ?? 'Pranav';
    final b64   = prefs.getString(_keyImage);
    value = UserProfile(
      name:       name,
      imageBytes: b64 != null ? base64Decode(b64) : null,
    );
  }

  Future<void> updateName(String name) async {
    value = value.copyWith(name: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
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