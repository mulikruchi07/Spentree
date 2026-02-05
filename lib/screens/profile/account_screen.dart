import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/user_data.dart';
import '../../core/biometric_service.dart';
import '../auth/change_password_screen.dart';

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

  // Inline Editing States
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // UI Constants
  final Color colBlack = const Color(0xFF000000);
  final Color colGreyText = const Color(0xFF808080);
  final Color colBoxBg = const Color(0xFFF1F1F1);
  final Color colIconBg = const Color(0xFFB8F0C9);
  final Color colPrimaryGreen = const Color(0xFF34C759);
  final Color colDestructiveRed = const Color(0xFFFF4141);

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
      _showDestructiveDialog(
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
      backgroundColor: Colors.white,
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
                ),
              ),
              Text(
                "Account",
                style: GoogleFonts.montserrat(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
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
                Icons.notifications_none_rounded,
                "Notifications",
                "Streak & Milestone Notifications",
                _notifications,
                (v) => setState(() => _notifications = v),
              ),
              _buildToggleTile(
                Icons.lightbulb_outline_rounded,
                "Spending Tips",
                "Get tips for daily expenses",
                _spendingTips,
                (v) => setState(() => _spendingTips = v),
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
                onPop: () => _showDestructiveDialog(
                  title: "Deactivate Account",
                  message: "You can come back anytime by logging in again.",
                  confirmText: "Yes, Deactivate",
                  icon: Icons.lock_outline,
                ),
              ),
              _buildActionTile(
                Icons.delete_outline_rounded,
                "Delete My Account",
                "Delete your account permanently",
                onPop: () => _showDestructiveDialog(
                  title: "Delete Account",
                  message: "All your data will be removed permanently.",
                  confirmText: "Yes, Delete",
                  icon: Icons.delete_outline,
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
            backgroundColor: colBoxBg,
            child: ClipOval(
              child: Image.asset(
                'assets/images/user_avatar.png',
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: 60, color: colGreyText),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "Planting since January 2025",
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colGreyText,
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
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colBoxBg,
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
                          color: Colors.black,
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
                          color: const Color(0xFF9EA3AE),
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
                    color: colGreyText,
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
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colBoxBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9EA3AE),
                  ),
                ),
              ),
              Text(
                "Change",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colGreyText.withValues(alpha: 0.3),
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
        color: colBoxBg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colIconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: colBlack),
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
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 10, color: colGreyText),
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
          color: value ? colPrimaryGreen : const Color(0xFFE0E0E0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : const Color(0xFFAAAAAA),
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
        color: colBoxBg,
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
                    color: colIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: colBlack),
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
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: colGreyText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFABABAB)),
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
            color: colGreyText,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _launchURL("https://linkedin.com/in/designer"),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 14, color: colGreyText),
              children: [
                const TextSpan(
                  text: "Designed by ",
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: "Designer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
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
              style: GoogleFonts.poppins(fontSize: 14, color: colGreyText),
              children: [
                const TextSpan(
                  text: "Developed by ",
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: "Developer",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w200,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDestructiveDialog({
    required String title,
    required String message,
    required String confirmText,
    required IconData icon,
    VoidCallback? onConfirm,
  }) async {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colDestructiveRed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: colGreyText),
                ),
                const SizedBox(height: 32),
                _buildPopupButton(
                  confirmText,
                  colDestructiveRed,
                  Colors.white,
                  () {
                    if (onConfirm != null) onConfirm();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildPopupButton(
                  "Cancel",
                  colBoxBg,
                  colDestructiveRed,
                  () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupButton(
    String text,
    Color bg,
    Color textCol,
    VoidCallback tap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: tap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textCol,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      t,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
}
