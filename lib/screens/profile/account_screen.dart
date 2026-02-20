import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/user_data.dart';
import '../../core/biometric_service.dart';
import '../auth/change_password_screen.dart';
import '../../core/app_style.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Toggle States - All initially OFF
  bool _isFaceIdEnabled = false;
  bool _spendingAlerts = false;
  bool _notifications = false;
  bool _spendingTips = false;
  bool _soundEffects = false;

  // Inline Editing States
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserData.userName);
    _phoneController = TextEditingController(text: "+91 00000 00000");
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFaceIdEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  // --- SECURITY LOGIC: Face ID Toggle ---
  void _handleFaceIdToggle(bool val) async {
    if (val) {
      if (await BiometricService.authenticateUser()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isFaceIdEnabled', true);
        setState(() => _isFaceIdEnabled = true);
      }
    } else {
      // Floating destructive dialog for removal
      _showConfirmationDialog(
        title: "Remove App Lock",
        message: "Are you sure you want to remove app-lock?",
        confirmText: "Remove",
        icon: Icons.fingerprint,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isFaceIdEnabled', false);
          setState(() => _isFaceIdEnabled = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              _buildInlineEditableField(
                "Name",
                _nameController,
                _isEditingName,
                (v) => setState(() => _isEditingName = v),
              ),
              const SizedBox(height: 16),
              _buildInlineEditableField(
                "Phone Number",
                _phoneController,
                _isEditingPhone,
                (v) => setState(() => _isEditingPhone = v),
                isPhone: true,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Login & Security"),
              _buildActionTile(
                Icons.password,
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
                Icons.fingerprint,
                "Face ID / Touch ID",
                "Manage your device security",
                _isFaceIdEnabled,
                _handleFaceIdToggle,
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Communication Preferences"),
              _buildToggleTile(
                Icons.warning_amber_rounded,
                "Spending Alerts",
                "Get alerts when you overspend",
                _spendingAlerts,
                (v) => setState(() => _spendingAlerts = v),
              ),
              _buildToggleTile(
                Icons.lightbulb_outline_rounded,
                "Spending Tips",
                "Get tips for daily expenses",
                _spendingTips,
                (v) => setState(() => _spendingTips = v),
              ),
              _buildToggleTile(
                Icons.notifications_none_rounded,
                "Notifications",
                "Streak & Milestone Notifications",
                _notifications,
                (v) => setState(() => _notifications = v),
              ),
              _buildToggleTile(
                Icons.volume_up,
                "Sound Effects",
                "Control Sound effects & Music",
                _soundEffects,
                (v) => setState(() => _soundEffects = v),
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Account Preferences"),
              _buildStaticField("Language", "English"),
              const SizedBox(height: 16),
              _buildStaticField("Currency", "INR"),

              const SizedBox(height: 32),
              _buildSectionHeader("Account Control"),
              _buildActionTile(
                Icons.lock_outline_rounded,
                "Deactivate Account",
                "Temporarily disable account",
                onPop: () => _showConfirmationDialog(
                  title: "Deactivate Account",
                  message: "You can come back anytime by logging in again.",
                  confirmText: "Yes, Deactivate",
                  icon: Icons.lock_outline,
                  onConfirm: () {},
                ),
              ),
              _buildActionTile(
                Icons.delete_outline_rounded,
                "Delete My Account",
                "Delete your account permanently",
                onPop: () => _showConfirmationDialog(
                  title: "Delete Account",
                  message: "All your data will be removed permanently.",
                  confirmText: "Yes, Delete",
                  icon: Icons.delete_outline,
                  onConfirm: () {},
                ),
              ),

              const SizedBox(height: 48),
              _buildFooter(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Reusable Components ---

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.inputFill,
            child: ClipOval(
              child: Image.asset(
                'assets/images/user_avaar.png',
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: 60, color: AppColors.colblack),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.colblack,
            ),
          ),
          Text(
            "Planting since January 2025",
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditableField(
    String label,
    TextEditingController controller,
    bool isEditing,
    Function(bool) setEditing, {
    bool isPhone = false,
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
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: isPhone
                            ? TextInputType.phone
                            : TextInputType.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.colblack,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
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
                onPressed: () => setEditing(!isEditing),
                child: Text(
                  isEditing ? "Save" : (isPhone ? "Change" : "Edit"),
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
      ],
    );
  }

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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ),
              Text(
                "Change",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
            ],
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
          color: value ? AppColors.primaryGreen : const Color(0xFFE8E8E8),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : const Color(0xFFABABAB),
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
          onTap: () => _launchURL("https://linkedin.com/in/designer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                const TextSpan(
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
          onTap: () => _launchURL("https://linkedin.com/in/developer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.white500,
              ),
              children: [
                const TextSpan(
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

  Future<void> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    required VoidCallback onConfirm,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Background Blur
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(
                  28,
                ), // Floating rounded look
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red Circular Icon at Top
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.destructiveRed, // Design Red
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.colwhite, size: 32),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.desctext,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Confirm Button (Red)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructiveRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
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

                  // Cancel Button (Grey)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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
                          color:
                              AppColors.destructiveRed, // Red text for cancel
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
