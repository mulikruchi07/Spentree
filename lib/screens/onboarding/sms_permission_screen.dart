import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_style.dart';
import 'loading_screen.dart';
import 'dart:ui';

class SmsPermissionScreen extends StatefulWidget {
  /// true = shown right after signup/signin, proceeds to LoadingScreen once
  /// a decision is made. false = opened from Data & Privacy settings, just
  /// lets the user view/change their existing decision, no forced navigation.
  final bool isOnboarding;

  const SmsPermissionScreen({super.key, this.isOnboarding = false});

  @override
  State<SmsPermissionScreen> createState() => _SmsPermissionScreenState();
}

Future<String> _decisionKey() async {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
  return 'sms_permission_decision_$userId';
}

Future<String> _seenKey() async {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
  return 'has_seen_sms_permission_screen_$userId';
}

class _SmsPermissionScreenState extends State<SmsPermissionScreen>
    with WidgetsBindingObserver {
  bool _isChecked = false;
  bool _isProcessing = false;
  bool _revokedExternally = false;
  final GlobalKey _checkboxKey = GlobalKey();
  OverlayEntry? _tooltipEntry;

  final ScrollController _scrollController = ScrollController();
  bool _showBottomFade = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_updateFadeVisibility);
    _refreshPermissionState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_updateFadeVisibility);
    _scrollController.dispose();
    _removeTooltip();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissionState();
  }

  void _updateFadeVisibility() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 8;
    if (atBottom == _showBottomFade) {
      setState(() => _showBottomFade = !atBottom);
    }
  }

  Future<void> _refreshPermissionState() async {
    final prefs = await SharedPreferences.getInstance();
    final decision = prefs.getString(
      await _decisionKey(),
    ); // 'granted' | 'manual' | null
    final actualStatus = await Permission.sms.status;

    if (!mounted) return;
    setState(() {
      if (widget.isOnboarding) {
        // Fresh consent flow — checkbox always starts unticked until tapped.
        _isChecked = decision == 'granted';
        _revokedExternally = false;
      } else {
        // Settings mode — checkbox reflects the user's saved decision.
        _isChecked = decision == 'granted';
        _revokedExternally = decision == 'granted' && !actualStatus.isGranted;
      }
    });
  }

  Future<void> _persistDecision(bool granted) async {
    final key = await _decisionKey();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, granted ? 'granted' : 'manual');
    await prefs.setBool(await _seenKey(), true);
  }

  void _proceedIfOnboarding() {
    if (!widget.isOnboarding || !mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(isAuthFlow: true),
      ),
    );
  }

  // ── Tooltip (checkbox not checked) ──────────────────────────────────────

  void _showCheckboxTooltip() {
    _removeTooltip();
    final box = _checkboxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);

    _tooltipEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 5,
        top: position.dy + 32,
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: CustomPaint(
                  size: const Size(12, 8),
                  painter: _ArrowPainter(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.colwhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFAB40).withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.colblack.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Please check this box to proceed.",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.colblack,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_tooltipEntry!);
    Future.delayed(const Duration(seconds: 3), _removeTooltip);
  }

  void _removeTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
  }

  // ── Allow flow ───────────────────────────────────────────────────────────

  Future<void> _handleAllowTap() async {
    if (!_isChecked) {
      _showCheckboxTooltip();
      return;
    }
    await _requestPermissionFlow();
  }

  Future<void> _requestPermissionFlow() async {
    setState(() => _isProcessing = true);
    final result = await Permission.sms.request();
    setState(() => _isProcessing = false);

    if (result.isGranted) {
      await _persistDecision(true);
      if (mounted) setState(() => _revokedExternally = false);
      if (!widget.isOnboarding) {
        // Granted from Settings, not onboarding — kick off SMS import right now,
        // no app restart needed.
        unawaited(TransactionService().resetForNewUser());
      }
      _proceedIfOnboarding();
    } else if (result.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermanentlyDeniedDialog();
    } else {
      if (!mounted) return;
      _showPermissionDeniedDialog(); // regular first-time denial — Try Again is meaningful here
    }
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
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
                    child: Icon(
                      PhosphorIconsRegular.warning,
                      color: AppColors.colwhite,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Permission Blocked",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SMS permission has been permanently denied for Spentree. To enable automatic expense tracking, please allow SMS access from your device settings.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.desctext,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructiveRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Open Settings",
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _persistDecision(false);
                        _proceedIfOnboarding();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputFill,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Continue with Manual Entry",
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
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
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
                    child: Icon(
                      PhosphorIconsRegular.warning,
                      color: AppColors.colwhite,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Permission Denied",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Automatic expense detection requires SMS access",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.desctext,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _requestPermissionFlow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructiveRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Try Again",
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
                      onPressed: () async {
                        Navigator.pop(context);
                        await _persistDecision(false);
                        _proceedIfOnboarding();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.inputFill,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Continue with Manual Entry",
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
  }

  Future<void> _handleManualEntryTap() async {
    await _persistDecision(false);
    if (widget.isOnboarding) {
      _proceedIfOnboarding();
    } else if (mounted) {
      setState(() {
        _isChecked = false;
        _revokedExternally = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return PopScope(
          canPop: !_isProcessing,
          child: Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isOnboarding) const SizedBox(height: 24),
                        Center(
                          child: Text(
                            "SMS Permission",
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            "Understand why we need SMS access\nbefore you decide.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.grey700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- SCROLLABLE CONTENT BOX (only this part scrolls) ---
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildScrollableContent(),
                                ),
                              ),
                              if (_showBottomFade)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    child: Container(
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            AppColors.bgWhite,
                                            AppColors.bgWhite.withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // --- FIXED: consent checkbox / permission status ---
                        _buildCheckboxRow(),

                        const SizedBox(height: 16),

                        // --- FIXED: buttons ---
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _handleAllowTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.colwhite,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "Allow SMS access",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.colwhite,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : _handleManualEntryTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inputFill,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Continue with Manual Entry",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom > 0
                              ? 8
                              : 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckboxRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isChecked = !_isChecked),
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                key: _checkboxKey,
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: _isChecked
                      ? AppColors.primaryGreen
                      : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _isChecked
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "I understand why Spentree requests SMS access and I "
                  "voluntarily consent to the processing of eligible "
                  "transaction SMS for automatic expense tracking.",
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.grey700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_revokedExternally)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Permission Required",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "SMS permission is disabled in Android Settings until access is given again.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.errorRed,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScrollableContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading("1. Track Expenses Automatically"),
        const SizedBox(height: 8),
        _bodyText(
          "Spentree can automatically detect eligible bank and UPI "
          "transaction SMS messages to help record your expenses and income "
          "without requiring manual entry.\nThis feature is completely "
          "optional and is designed to make expense tracking faster and "
          "more accurate.",
        ),
        const SizedBox(height: 22),

        _sectionHeading("2. What We Access"),
        const SizedBox(height: 8),
        _bodyText(
          "If you choose to allow SMS access, Spentree will scan only SMS "
          "messages that appear to contain financial transaction "
          "information, such as:",
        ),
        const SizedBox(height: 8),
        _bulletList(const [
          "Bank transaction alerts",
          "UPI payment confirmations",
          "Card payment notifications",
          "Wallet transaction messages",
        ]),
        const SizedBox(height: 8),
        _bodyText(
          "Spentree is not designed to read your personal conversations, "
          "OTPs, promotional messages, or other unrelated SMS content for "
          "this feature.",
        ),
        const SizedBox(height: 22),

        _sectionHeading("3. Why We Need This Permission"),
        const SizedBox(height: 8),
        _bodyText("We use transaction messages to:"),
        const SizedBox(height: 8),
        _bulletList(const [
          "Automatically detect expenses and income",
          "Extract transaction details such as merchant, amount, date, and payment method",
          "Reduce manual data entry",
          "Generate spending insights and reports",
        ]),
        const SizedBox(height: 22),

        _sectionHeading("4. Your Privacy Matters"),
        const SizedBox(height: 8),
        _bodyText(
          "Your SMS data is processed solely for providing automatic "
          "expense tracking.\nWe do not sell your SMS data.\nWe do not use "
          "your SMS content for advertising or profiling unrelated to the "
          "service.\nOnly information required for the functioning of this "
          "feature is processed.",
        ),
        const SizedBox(height: 22),

        _sectionHeading("5. Your Choice"),
        const SizedBox(height: 8),
        _bodyText(
          "Granting SMS permission is entirely optional.\nYou can continue "
          "using Spentree without this permission by entering transactions "
          "manually.\nYou may withdraw permission at any time through your "
          "device's Settings.",
        ),
        const SizedBox(height: 22),

        _sectionHeading("6. Consent"),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.colblack,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "By tapping "),
              const TextSpan(
                text: '"Allow SMS Access"',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                text:
                    ", you acknowledge that you have read and understood why "
                    "Spentree requests access to your SMS messages and "
                    "voluntarily consent to the processing of relevant "
                    "transaction messages for automatic expense tracking in "
                    "accordance with our Privacy Policy.",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.colblack,
    ),
  );

  Widget _bodyText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 13.5,
      color: AppColors.colblack,
      height: 1.5,
    ),
  );

  Widget _bulletList(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: AppColors.colblack,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.colwhite
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFFAB40).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width / 2, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
