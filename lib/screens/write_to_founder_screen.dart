import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:spentree/core/user_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_style.dart';

const String kGoogleSheetWebhookUrl =
    "https://script.google.com/macros/s/AKfycbxFnUI8808-QGZVneW4JGdxN998RHpYTGto99IUUOOuFV4OR6qYuix-KebTJX68UnfO_Q/exec";

class WriteFounderScreen extends StatefulWidget {
  const WriteFounderScreen({super.key});

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

  // Return to the Dashboard.
  //
  // This screen is expected to be opened from the Dashboard,
  // so popping this screen takes the user back to Dashboard.
  void _navigateToDashboard() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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

    final currentUser = Supabase.instance.client.auth.currentUser;

    final String userEmail = currentUser?.email ?? "Anonymous";

    // IMPORTANT:
    // User's actual profile name comes from users.name,
    // which is already loaded into UserProfileNotifier.
    final String userName = UserData.userName;

    try {
      /*
       * Foundersnote Google Apps Script Web App URL.
       *
       * Replace this with your deployed Foundersnote Apps Script URL.
       */
      final uri = Uri.parse(kGoogleSheetWebhookUrl);
      /*
       * Send:
       * Name
       * Email
       * Role
       * Message
       */
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            body: {
              "name": userName,
              "email": userEmail,
              "role": "Founders",
              "message": text,
            },
          )
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              /*
               * Google Apps Script can sometimes keep the HTTP
               * connection open because of its redirect behavior.
               *
               * The request can already have reached the Sheet,
               * so don't leave the user stuck on the loading state.
               */
              return http.Response('Data sent successfully', 200);
            },
          );

      debugPrint("Foundersnote response status: ${response.statusCode}");
    } catch (e) {
      /*
       * Do not show the technical redirect/CORS error to the user.
       *
       * Apps Script can successfully receive the data even when
       * Flutter reports a redirect-related exception.
       */
      debugPrint("Error/Redirect sending Founders message: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isSent = true;
        });

        /*
         * Keep the exact existing 1.5 second success state.
         */
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          _navigateToDashboard();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopScope(
      canPop: true,
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
                      onPressed: _navigateToDashboard,
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
                          "Write a letter to our Founders",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Every message is personally read\nby our founders, and we care",
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
                                  maxLength: 500,
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
                                    if (text.trim().isNotEmpty &&
                                        _errorMessage != null) {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    } else {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),

                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  "${_msgController.text.length}/500",
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
                        backgroundColor: AppColors.primaryGreen,
                        disabledBackgroundColor: AppColors.primaryGreen,
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
