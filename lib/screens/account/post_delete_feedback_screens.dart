import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/app_style.dart';
import '../onboarding/splash_onboarding_screen.dart';

// Your existing Google Apps Script Web App URL
const String kGoogleSheetWebhookUrl = "https://script.google.com/macros/s/AKfycby9P4NM5NAqKYPGqScf_fUU_pe-AnjHhJRiHdRxttvvOltkK6BJYgjXFjKFsOE20paw/exec";

/// Data model representing the Founder/Co-Founder message configurations
class PersonMessage {
  final String titleRole;
  final String btnText;
  final String bodyText;
  final String signOffName;
  final String signOffRole;

  const PersonMessage({
    required this.titleRole,
    required this.btnText,
    required this.bodyText,
    required this.signOffName,
    required this.signOffRole,
  });
}

// 50/50 Message Pool
final List<PersonMessage> _kPersonMessages = [
  const PersonMessage(
    titleRole: "Founder",
    btnText: "Write to the Founder",
    bodyText:
        "Hello!\nFirst of all, thank you for giving Spentree a chance.\n\n"
        "When we started building Spentree, our goal was simple, to help people better understand where their money goes and make managing expenses a little easier.\n\n"
        "If you're leaving today, we're genuinely grateful that you were part of our journey, even if it was only for a short while.\n\n"
        "If there's something we could have done better, I'd truly appreciate hearing your thoughts. Every piece of feedback helps us build a better Spentree for everyone.\n\n"
        "Thank you for being a part of our story.\n",
    signOffName: "Ruchi Mulik",
    signOffRole: "Founder, Spentree",
  ),
  const PersonMessage(
    titleRole: "Co-Founder",
    btnText: "Write to the Co-Founder",
    bodyText:
        "Hey!\nIf you're reading this, you're probably about to say goodbye to Spentree and that's okay.\n\n"
        "I just wanted to say thank you for giving something we built a chance. Every download, every bug report, every bit of feedback has helped us improve along the way.\n\n"
        "If something didn't work the way you expected, or you have an idea that could make Spentree better, I'd genuinely love to hear it.\n\n"
        "Take care, and maybe we'll see you again someday.\n",
    signOffName: "Pranav Phanse",
    signOffRole: "Co-Founder, Spentree",
  ),
];

class PostDeleteNoteScreen extends StatefulWidget {
  const PostDeleteNoteScreen({super.key});

  @override
  State<PostDeleteNoteScreen> createState() => _PostDeleteNoteScreenState();
}

class _PostDeleteNoteScreenState extends State<PostDeleteNoteScreen> {
  late final PersonMessage _selectedPerson;

  @override
  void initState() {
    super.initState();
    // Equal 50/50 Random Selection
    _selectedPerson =
        _kPersonMessages[Random().nextInt(_kPersonMessages.length)];
  }

  void _navigateToSplash(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashOnboardingScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopScope(
      canPop: false, // Prevents navigating back into the app session
      child: Scaffold(
        backgroundColor: AppColors.bgWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Top Close Key (X) - "Not Now" action
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, right: 2.0),
                    child: IconButton(
                      onPressed: () => _navigateToSplash(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.closecircle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.cross,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 44),
                        Text(
                          "We're sorry to see you go,",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Dynamic Subtext
                        Text(
                          "Here’s a small message from\nour ${_selectedPerson.titleRole}",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF979797),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Message Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: AppColors.closecircle,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPerson.bodyText,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.goodbyetext,
                                ),
                              ),
                              Text(
                                "${_selectedPerson.signOffName}\n${_selectedPerson.signOffRole}",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.goodbyetext,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Dynamic CTA Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WriteFounderScreen(
                              role: _selectedPerson.titleRole,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedPerson.btnText,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colwhite,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SCREEN 2: Write Letter Screen
/// ---------------------------------------------------------------------------
class WriteFounderScreen extends StatefulWidget {
  final String role; // "Founder" or "Co-Founder"

  const WriteFounderScreen({super.key, this.role = "Founder"});

  @override
  State<WriteFounderScreen> createState() => _WriteFounderScreenState();
}

class _WriteFounderScreenState extends State<WriteFounderScreen> {
  final TextEditingController _msgController = TextEditingController();
  bool _isSending = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _navigateToSplash() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashOnboardingScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your message before sending.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSending = true;
    });

    try {
      final uri = Uri.parse(kGoogleSheetWebhookUrl);

      // Handles CORS and Google Redirects (302) seamlessly
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"email": "Anonymous", "message": text, "role": widget.role},
      );

      debugPrint("Response status: ${response.statusCode}");
    } catch (e) {
      debugPrint("Error sending feedback: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isSent = true;
        });

        // Wait for 1.5 seconds so the user sees the confirmation before navigating
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          _navigateToSplash();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bgWhite,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Top Close Key (X)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, right: 2.0),
                    child: IconButton(
                      onPressed: _navigateToSplash,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.closecircle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.cross,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Center(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: Image.asset(
                              'assets/images/mailbox.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),


                        Text(
                          "Write a letter to our ${widget.role}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Every message is personally read\nby our ${widget.role.toLowerCase()}, and we care",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF979797),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 38),

                        // Input Card Container
                        Container(
                          width: double.infinity,
                          height: 290,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.closecircle,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgController,
                                  maxLength: 1000,
                                  maxLines: null,
                                  expands: true,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.colblack,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Share your thoughts...",
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.goodbyetext,
                                    ),
                                    border: InputBorder.none,
                                    counterText: "",
                                  ),
                                  onChanged: (text) {
                                    // Clears the error immediately when the user enters characters
                                    if (text.trim().isNotEmpty &&
                                        _errorMessage != null) {
                                      setState(() => _errorMessage = null);
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "${_msgController.text.length}/1000",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Inline Error Display
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Share Message Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isSending || _isSent) ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        // Dynamic background color once sent
                        backgroundColor
                            : AppColors.primaryGreen,
                        disabledBackgroundColor
                            : AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSending
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.closecircle,
                              ),
                            )
                          : _isSent
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  "Message sent",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.colwhite,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              "Share message",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.colwhite,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
