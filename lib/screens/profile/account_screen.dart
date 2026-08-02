import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/app_lock.dart';
import 'package:spentree/core/auth_helper.dart';
import 'package:spentree/core/auth_landing_screen.dart';
import 'package:spentree/core/error_helper.dart';
import 'package:spentree/screens/account/post_delete_feedback_screens.dart';
import 'package:spentree/screens/auth/sign_in_screen.dart';
import 'package:spentree/screens/auth/verify_number_screen.dart';
import 'package:spentree/screens/onboarding/splash_onboarding_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/user_profile.dart';
import '../../core/biometric_service.dart';
import '../auth/change_password_screen.dart';
import '../../core/app_style.dart';
import '../forest/forest_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with WidgetsBindingObserver {
  // Loading state to prevent toggle switch flickering on load
  bool _isLoading = true;

  // Toggle States
  bool _isFaceIdEnabled = false;
  bool _spendingAlerts = false;
  bool _spendingTips = false;
  String _selectedTheme = "System";

  // Inline Editing States & Validation
  bool _isEditingName = false;
  bool _isSavingEmail = false;
  late TextEditingController _nameController;

  late String _originalName;
  //email editing states
  String _accountEmail = "";
  bool _isEditingEmail = false;
  late TextEditingController _emailController;
  late String _originalEmail;
  String? _emailError;
  String? _emailInfo;

  String? _nameError;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _editSectionKey = GlobalKey();

  // Local crop path only — image bytes live in userProfileNotifier
  String? _originalImagePath;
  final ImagePicker _picker = ImagePicker();

  bool _isCheckingEmail = false;

  String _plantingSince = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Name sourced from the global notifier
    _originalName = userProfileNotifier.value.name;

    _nameController = TextEditingController(text: _originalName);
    _originalEmail = Supabase.instance.client.auth.currentUser?.email ?? "";
    _emailController = TextEditingController(text: _originalEmail);
    _accountEmail = Supabase.instance.client.auth.currentUser?.email ?? "";
    _loadSettings();
    _refreshNotificationToggleState();
    _loadNameFromDatabase();
    _loadPlantingSince();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationToggleState();
    }
  }

  void _loadPlantingSince() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final created = DateTime.parse(user.createdAt).toLocal();

    setState(() {
      _plantingSince =
          "Planting since ${_monthName(created.month)} ${created.year}";
    });
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  Future<void> _loadNameFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null && row['name'] != null && mounted) {
        final dbName = row['name'] as String;
        userProfileNotifier.updateName(dbName);
        setState(() {
          _originalName = dbName;
          _nameController.text = dbName;
        });
      }
    } catch (e) {
      debugPrint("Couldn't load name from DB: $e");
    }
  }

  Future<void> _syncNameToDatabase(String name) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client
          .from('users')
          .update({'name': name})
          .eq('id', user.id);
    } catch (e) {
      debugPrint("Name sync failed: $e");
    }
  }

  void _toggleEmailEdit() async {
    if (_isEditingEmail) {
      setState(() => _emailError = null);
      final newEmail = _emailController.text.trim();
      final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
      if (!emailRegex.hasMatch(newEmail)) {
        setState(() => _emailError = "Please enter a valid email address");
        return;
      }
      if (newEmail == _originalEmail) {
        setState(() => _isEditingEmail = false);
        return;
      }
      final hasInternet = await checkInternetConnection();
      if (!hasInternet) {
        setState(
          () => _emailError =
              "No internet connection. Please check your network and try again.",
        );
        return;
      }

      setState(() => _isCheckingEmail = true);
      try {
        await Supabase.instance.client.auth
            .updateUser(UserAttributes(email: newEmail))
            .timeout(const Duration(seconds: 10));
        setState(() => _isCheckingEmail = false);

        if (!mounted) return;
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyEmailScreen(email: newEmail, isEmailChange: true),
          ),
        );
        if (verified == true) {
          setState(() {
            _originalEmail = newEmail;
            _isEditingEmail = false;
          });
          await _unlinkStaleGoogleIdentity();
        } else {
          setState(() {
            _emailController.text = _originalEmail;
            _isEditingEmail = false;
          });
        }
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        setState(() {
          _isCheckingEmail = false;
          if (msg.contains('already') ||
              msg.contains('registered') ||
              msg.contains('exists')) {
            _emailError = "This email already exists.";
          } else if (msg.contains('invalid') ||
              msg.contains('unable to validate')) {
            _emailError = "This email address is invalid.";
          } else {
            _emailError = mapAuthError(e);
          }
        });
      } on TimeoutException {
        setState(() {
          _isCheckingEmail = false;
          _emailError =
              "No internet connection. Please check your network and try again.";
        });
      } catch (e) {
        setState(() {
          _isCheckingEmail = false;
          _emailError = "Something went wrong. Please try again.";
        });
      }
    } else {
      setState(() {
        _isEditingEmail = true;
        _emailError = null;
      });
    }
  }

  Future<void> _unlinkStaleGoogleIdentity() async {
    try {
      final identities = await Supabase.instance.client.auth
          .getUserIdentities();
      UserIdentity? googleIdentity;
      for (final identity in identities) {
        if (identity.provider == 'google') {
          googleIdentity = identity;
          break;
        }
      }
      if (googleIdentity != null) {
        await Supabase.instance.client.auth.unlinkIdentity(googleIdentity);
      }
    } catch (e) {
      debugPrint("Couldn't unlink stale Google identity: $e");
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFaceIdEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
      _selectedTheme = prefs.getString('app_theme') ?? "System";
      _spendingAlerts = prefs.getBool('spending_alerts_user_enabled') ?? true;

      // Profile image is loaded from userProfileNotifier — no local loading needed
      _isLoading = false;
    });
  }

  void _handleBackNavigation() {
    bool nameChanged = _nameController.text != _originalName;
    if (_isEditingName && nameChanged) {
      setState(() => _nameError = "Please save your name before leaving.");
      Scrollable.ensureVisible(
        _editSectionKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _isEditingName = false;
        _nameController.text = _originalName;
      });
      Navigator.of(context).pop();
    }
  }

  void _toggleNameEdit() {
    if (_isEditingName) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = "Name cannot be empty");
        return;
      }
      final newName = _nameController.text.trim();
      userProfileNotifier.updateName(newName);
      setState(() {
        _originalName = newName;
        _nameError = null;
        _isEditingName = false;
      });
      _syncNameToDatabase(newName);
    } else {
      setState(() {
        _isEditingName = true;
        _nameError = null;
      });
    }
  }

  Future<void> _handleEditIconTap() async {
    if (userProfileNotifier.value.imageBytes != null) {
      _showImageActionSheet();
    } else {
      _showImageSourceSelector(false);
    }
  }

  Future<void> _removeImageFromDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await AuthHelper.syncEncryptedUserFields({
        'profile_image_url': null,
      }).timeout(const Duration(seconds: 8));
      await Supabase.instance.client.storage.from('avatar').remove([
        '${user.id}/profile.jpg',
      ]);
    } catch (e) {
      debugPrint("Image removal sync deferred (offline): $e");
    }
  }

  void _showImageActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.image,
                color: AppColors.colblack,
              ),
              title: Text(
                "Change Profile Picture",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceSelector(true);
              },
            ),
            if (_originalImagePath != null)
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsRegular.crop,
                  color: AppColors.colblack,
                ),
                title: Text(
                  "Adjust Profile Picture",
                  style: GoogleFonts.poppins(color: AppColors.colblack),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cropImage(_originalImagePath!);
                },
              ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: AppColors.destructiveRed,
              ),
              title: Text(
                "Remove Profile Picture",
                style: GoogleFonts.poppins(color: AppColors.destructiveRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                await userProfileNotifier.removeImage();
                await _removeImageFromDatabase();
                setState(() => _originalImagePath = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSelector(bool isChanging) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.camera,
                color: AppColors.colblack,
              ),
              title: Text(
                "Take Photo",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.image,
                color: AppColors.colblack,
              ),
              title: Text(
                "Choose from Gallery",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final int fileBytesLength = await pickedFile.length();
        if (fileBytesLength > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Image size must be less than 5MB",
                  style: GoogleFonts.poppins(color: AppColors.colwhite),
                ),
                backgroundColor: AppColors.destructiveRed,
              ),
            );
          }
          return;
        }
        _originalImagePath = pickedFile.path;
        _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _cropImage(String path) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Profile Picture',
            toolbarColor: AppColors.bgWhite,
            toolbarWidgetColor: AppColors.colblack,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Adjust Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        // Persists bytes to SharedPrefs + broadcasts to all listeners
        await userProfileNotifier.updateImage(bytes);
        await _uploadImageToStorage(bytes);
        // Sync the home widget
        await HomeWidget.saveWidgetData<String>(
          'widget_user_name',
          userProfileNotifier.value.name,
        );
        await HomeWidget.updateWidget(
          name: 'GreetingWidgetProvider',
          iOSName: 'GreetingWidgetProvider',
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
  }

  Future<void> _uploadImageToStorage(Uint8List bytes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final path = '${user.id}/profile.jpg';
      await Supabase.instance.client.storage
          .from('avatar')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final url = Supabase.instance.client.storage
          .from('avatar')
          .getPublicUrl(path);
      await AuthHelper.syncEncryptedUserFields({
        'profile_image_url': url,
      }).timeout(const Duration(seconds: 8));
    } catch (e, stack) {
      debugPrint("UPLOAD ERROR:");
      debugPrint(e.toString());
      debugPrint(stack.toString());

      rethrow;
    }
  }

  void _viewProfileImage() {
    final bytes = userProfileNotifier.value.imageBytes;
    if (bytes == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.8),
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: 'profile_image_hero',
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleFaceIdToggle(bool val) async {
    if (val) {
      final result = await BiometricService.authenticate();
      if (result == AuthResult.success) {
        await AppLockController.setLockEnabled(true);
        setState(() => _isFaceIdEnabled = true);
      }
    } else {
      _showConfirmationDialog(
        title: 'Remove App Lock',
        message: 'Are you sure you want to remove app-lock?',
        confirmText: 'Remove',
        icon: Icons.fingerprint,
        onConfirm: () async {
          await AppLockController.setLockEnabled(false);
          setState(() => _isFaceIdEnabled = false);
        },
      );
    }
  }

  void _handleThemeChange(String theme) async {
    setState(() => _selectedTheme = theme);

    if (theme == "System") {
      themeNotifier.value = ThemeMode.system;
    } else if (theme == "Light mode") {
      themeNotifier.value = ThemeMode.light;
    } else if (theme == "Dark mode") {
      themeNotifier.value = ThemeMode.dark;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme);
  }

  Future<void> _refreshNotificationToggleState() async {
    final status = await Permission.notification.status;
    final prefs = await SharedPreferences.getInstance();
    final userEnabled = prefs.getBool('spending_alerts_user_enabled') ?? true;

    if (mounted) {
      setState(() {
        _spendingAlerts = status.isGranted && userEnabled;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.bgWhite);
    }
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackNavigation();
          },
          child: Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 70),
                    Text(
                      "My",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      "Account",
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildProfileHeader(),

                    const SizedBox(height: 32),

                    Container(
                      key: _editSectionKey,
                      child: Column(
                        children: [
                          _buildInlineEditableField(
                            label: "Name",
                            controller: _nameController,
                            isEditing: _isEditingName,
                            onToggle: _toggleNameEdit,
                            errorMsg: null,
                          ),
                          const SizedBox(height: 16),
                          _buildInlineEditableField(
                            label: "Email",
                            controller: _emailController,
                            isEditing: _isEditingEmail,
                            onToggle: _toggleEmailEdit,
                            errorMsg: _emailError,
                          ),
                          if (_isCheckingEmail)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 12,
                                    width: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Checking if the email is valid...",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                              ),
                              child: Text(
                                _emailError!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.destructiveRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Login & Security"),
                    _buildActionTile(
                      PhosphorIconsRegular.password,
                      "Change Password",
                      "Change your current password",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _buildToggleTile(
                      PhosphorIconsRegular.fingerprintSimple,
                      "Face ID / Touch ID",
                      "Manage your device security",
                      _isFaceIdEnabled,
                      _handleFaceIdToggle,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Appearance"),
                    _buildAppearanceSection(),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Communication Preferences"),
                    _buildToggleTile(
                      PhosphorIconsRegular.warning,
                      "Spending Alerts",
                      "Get alerts when you overspend",
                      _spendingAlerts,
                      (v) async {
                        final prefs = await SharedPreferences.getInstance();

                        if (v) {
                          var status = await Permission.notification.status;

                          if (!status.isGranted) {
                            status = await Permission.notification.request();
                          }

                          if (status.isGranted) {
                            await prefs.setBool(
                              'spending_alerts_user_enabled',
                              true,
                            );
                            setState(() => _spendingAlerts = true);
                          } else {
                            setState(() => _spendingAlerts = false);
                          }
                        } else {
                          await prefs.setBool(
                            'spending_alerts_user_enabled',
                            false,
                          );
                          setState(() => _spendingAlerts = false);
                        }
                      },
                    ),
                    _buildToggleTile(
                      PhosphorIconsRegular.lightbulb,
                      "Spending Tips",
                      "Get tips for daily expenses",
                      _spendingTips,
                      (v) => setState(() => _spendingTips = v),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Account Control"),
                    _buildActionTile(
                      PhosphorIconsRegular.lockKey,
                      "Deactivate Account",
                      "Temporarily disable account",
                      onTap: () async {
                        final confirmed = await _showConfirmationDialog(
                          title: "Deactivate Account",
                          message:
                              "You can come back anytime by logging in again.",
                          confirmText: "Yes, Deactivate",
                          icon: PhosphorIconsRegular.lockKey,
                          onConfirm: () async {
                            final user =
                                Supabase.instance.client.auth.currentUser;
                            if (user == null) throw Exception("Not signed in");
                            await Supabase.instance.client
                                .from('users')
                                .update({
                                  'is_active': false,
                                  'deactivated_at': DateTime.now()
                                      .toUtc()
                                      .toIso8601String(),
                                })
                                .eq('id', user.id)
                                .timeout(const Duration(seconds: 10));
                            await AuthHelper.signOutEverywhere();
                          },
                        );
                        if (confirmed == true && mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthLandingScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),
                    _buildActionTile(
                      PhosphorIconsRegular.trash,
                      "Delete My Account",
                      "Delete your account permanently",
                      onTap: () async {
                        final confirmed = await _showConfirmationDialog(
                          title: "Delete Account",
                          message: "All your data will be removed permanently.",
                          confirmText: "Yes, Delete",
                          icon: PhosphorIconsRegular.trash,
                          onConfirm: () async {
                            final response = await Supabase
                                .instance
                                .client
                                .functions
                                .invoke('delete-account')
                                .timeout(const Duration(seconds: 15));

                            if (response.status != 200) {
                              final err = (response.data is Map)
                                  ? response.data['error']
                                  : null;
                              throw Exception(
                                err ??
                                    "Account deletion failed. Please try again.",
                              );
                            }

                            await AuthHelper.signOutEverywhere();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                          },
                        );
                        if (confirmed == true && mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PostDeleteNoteScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 48),
                    _buildFooter(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    // Wraps in ValueListenableBuilder so name + image update instantly
    // across the whole app without requiring any manual refresh
    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileNotifier,
      builder: (context, profile, _) {
        return Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: profile.imageBytes != null
                        ? _viewProfileImage
                        : null,
                    child: Hero(
                      tag: 'profile_image_hero',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.inputFill,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profile.imageBytes != null
                            ? Image.memory(
                                profile.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  PhosphorIconsRegular
                                      .user, // Icon as requested
                                  size: 60,
                                  color: AppColors.grey600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _handleEditIconTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderGrey.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsRegular.pencilSimple,
                          size: 20,
                          color: AppColors.colblack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                profile.firstName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _plantingSince,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildThemeOption("System"),
          _buildThemeOption("Light mode"),
          _buildThemeOption("Dark mode"),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title) {
    bool isSelected = _selectedTheme == title;
    Color activeColor = const Color(0xFF6B6B6B);
    Color inactiveColor = const Color(0xFFC4C4C4);

    return GestureDetector(
      onTap: () => _handleThemeChange(title),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.colblack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onToggle,
    String? errorMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: errorMsg != null
                ? Border.all(color: AppColors.destructiveRed)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: label == "Email"
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        inputFormatters: label == "Name"
                            ? [
                                FilteringTextInputFormatter.allow(
                                  RegExp(
                                    r'[a-zA-Z\s\u00C0-\u017F\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
                                    unicode: true,
                                  ),
                                ),
                              ]
                            : null,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.colblack,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) {
                          if (errorMsg != null) {
                            setState(() {
                              if (label == "Email") {
                                _emailError = null;
                                _emailInfo = null;
                              } else {
                                _nameError = null;
                              }
                            });
                          }
                        },
                      )
                    : Text(
                        controller.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
              ),
              TextButton(
                onPressed: onToggle,
                child: Text(
                  isEditing ? "Save" : "Edit",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              errorMsg,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.destructiveRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // Widget _buildStaticField(String label, String value) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: GoogleFonts.poppins(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //           color: AppColors.colblack,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //         decoration: BoxDecoration(
  //           color: AppColors.inputFill,
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 value,
  //                 style: GoogleFonts.poppins(
  //                   fontSize: 14,
  //                   color: AppColors.grey600,
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               "Change",
  //               style: GoogleFonts.poppins(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w500,
  //                 color: AppColors.white500,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildStaticField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey600),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool val,
    Function(bool) changed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.colIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: AppColors.colblack),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.desctext,
                  ),
                ),
              ],
            ),
          ),
          _buildCustomToggle(val, changed),
        ],
      ),
    );
  }

  Widget _buildCustomToggle(bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? AppColors.primaryGreen : AppColors.toggle,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : AppColors.toggledot,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    VoidCallback? onPop,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap ?? onPop,
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.colIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: AppColors.colblack),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.desctext,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.desctext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planted with love in Mumbai, India",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.white500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/pranav-phanse-8b4bbb318"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(
                  text: "Designed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ),
                ),
                TextSpan(
                  text: "Designer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () =>
              _launchURL("https://in.linkedin.com/in/ruchi-mulik-816a2b295"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                TextSpan(
                  text: "Developed by ",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.white500,
                  ),
                ),
                TextSpan(
                  text: "Developer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    required Future<void> Function() onConfirm,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        String? dialogError;
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.destructiveRed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppColors.colwhite, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.desctext,
                        ),
                      ),
                      if (dialogError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            dialogError!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final hasInternet =
                                      await checkInternetConnection();
                                  if (!hasInternet) {
                                    setDialogState(
                                      () => dialogError =
                                          "No internet connection. Please check your network and try again.",
                                    );
                                    return;
                                  }
                                  setDialogState(() {
                                    isProcessing = true;
                                    dialogError = null;
                                  });
                                  try {
                                    await onConfirm();
                                    if (context.mounted)
                                      Navigator.pop(context, true);
                                  } catch (e) {
                                    setDialogState(() {
                                      isProcessing = false;
                                      dialogError =
                                          "Something went wrong. Please try again.";
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.destructiveRed,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isProcessing
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.colwhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  confirmText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colwhite,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.inputFill,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.destructiveRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      t,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.colblack,
      ),
    ),
  );
}
