import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/error_helper.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/screens/profile/hide_transactions_screen.dart';
import 'delete_transactions_screen.dart';
import 'privacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_style.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _ExportResult { success, empty, failed }

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  int? _currentLimit;

  @override
  void initState() {
    super.initState();
    _loadCurrentLimit();
  }

  Future<void> _loadCurrentLimit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('daily_limit')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && row != null)
        setState(() => _currentLimit = (row['daily_limit'] as num?)?.toInt());
    } catch (e) {
      debugPrint("Couldn't load current limit: $e");
    }
  }

  // --- UI Constants ---
  final Color colDisabled = const Color(0xFFBABABA);

  // --- Logic Helpers ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  // --- Popups ---
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
                    child: Icon(
                      icon,
                      color: isDarkMode
                          ? AppColors.colwhite
                          : AppColors.colwhite,
                      size: 32,
                    ),
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

  Future<void> _showSquarePopup({required Widget content}) async {
    return showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: content,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleChangeLimit() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _ChangeLimitPopup(),
    );
  }

  void _handleExportFlow() {
    _showSquarePopup(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconCircle(
            PhosphorIconsRegular.calendarBlank,
            AppColors.primaryGreen,
          ),
          const SizedBox(height: 20),
          Text(
            "Select Dates",
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Select the date range to export data",
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.desctext,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildActionBtn(
            "Select Dates",
            AppColors.primaryGreen,
            AppColors.colwhite,
            () {
              Navigator.pop(context);
              _showCalendarPopup();
            },
          ),
          const SizedBox(height: 12),
          _buildActionBtn(
            "Cancel",
            AppColors.inactiveGrey,
            AppColors.destructiveRed,
            () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showCalendarPopup() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: _CustomRangeCalendar(
            onConfirm: (start, end) {
              Navigator.pop(context);
              _showFinalExportPopup(start, end);
            },
          ),
        ),
      ),
    );
  }

  void _showFinalExportPopup(DateTime start, DateTime? end) {
    bool isSingle =
        end == null ||
        (start.year == end.year &&
            start.month == end.month &&
            start.day == end.day);
    String dateDisplay = isSingle
        ? DateFormat('d MMMM y').format(start)
        : "${DateFormat('d MMM y').format(start)}  →  ${DateFormat('d MMM y').format(end)}";

    showDialog(
      context: context,
      builder: (context) {
        bool isExporting = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconCircle(
                        PhosphorIconsRegular.export,
                        AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Export Data",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Only data from this period will be exported",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.desctext,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          dateDisplay,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      if (errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            errorMsg!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: AppColors.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isExporting
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isExporting = true;
                                    errorMsg = null;
                                  });
                                  final result = await _performExport(
                                    start,
                                    end,
                                  );
                                  if (result == _ExportResult.empty) {
                                    setDialogState(() {
                                      isExporting = false;
                                      errorMsg =
                                          "No data available within selected dates.";
                                    });
                                  } else if (result == _ExportResult.failed) {
                                    setDialogState(() {
                                      isExporting = false;
                                      errorMsg =
                                          "Couldn't export your data. Please try again.";
                                    });
                                  } else if (mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isExporting
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.colwhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Yes, Export",
                                  style: GoogleFonts.montserrat(
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
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.inputFill,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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

  Future<_ExportResult> _performExport(DateTime start, DateTime? endRaw) async {
  final end = endRaw ?? start;
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

  final rows = TransactionService().allTransactions.where((tx) =>
      !tx.isHidden &&
      !tx.isDeleted &&
      !tx.dateTime.isBefore(startDay) &&
      !tx.dateTime.isAfter(endDay)).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  if (rows.isEmpty) return _ExportResult.empty;

  final buffer = StringBuffer();
  buffer.writeln('Sr. No.,Receiver Name,Category,Amount,Date,Time');
  int i = 1;
  for (final tx in rows) {
    final date = DateFormat('dd-MM-yyyy').format(tx.dateTime);
    final time = DateFormat('hh:mm a').format(tx.dateTime);
    final name = tx.receiverName.replaceAll(',', ' ');
    buffer.writeln('$i,$name,${tx.category},${tx.amount},$date,$time');
    i++;
  }

  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spentree_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Your Spentree transaction export');
    return _ExportResult.success;
  } catch (e) {
    debugPrint("Export error: $e");
    return _ExportResult.failed;
  }
}

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
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
                    "Data &",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    "Privacy",
                    style: GoogleFonts.montserrat(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTile(
                    PhosphorIconsRegular.export,
                    "Export Data",
                    "Export your account data",
                    _handleExportFlow,
                  ),
                  _buildTile(
                    PhosphorIconsRegular.trash,
                    "Hide Transactions",
                    "Exclude from active transactions",
                    () {
                      // SHOW CUSTOM LOGOUT DIALOG
                      _showConfirmationDialog(
                        title: "Hide Transactions",
                        message:
                            "Are you sure you want to hide all transactions?",
                        confirmText: "Yes, Hide",
                        icon: PhosphorIconsRegular.trash,
                        onConfirm: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HideTransactionsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildTile(
                    PhosphorIconsRegular.trash,
                    "Delete Transactions",
                    "Remove your transactions",
                    () {
                      // SHOW CUSTOM LOGOUT DIALOG
                      _showConfirmationDialog(
                        title: "Delete Transactions",
                        message:
                            "Are you sure you want to delete all transactions?",
                        confirmText: "Yes, Delete",
                        icon: PhosphorIconsRegular.trash,
                        onConfirm: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeleteTransactionsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildTile(
                    PhosphorIconsRegular.speedometer,
                    "Change Limit",
                    "Manage your transactions",
                    _handleChangeLimit,
                  ),
                  _buildTile(
                    PhosphorIconsRegular.shieldCheck,
                    "Privacy Policy",
                    "Further secure your account for safety",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFooter(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
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
          onTap: () => _launchURL("www.linkedin.com/in/ruchi-mulik-816a2b295"),
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

  Widget _buildIconCircle(IconData icon, Color bg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Icon(
      icon,
      color: isDarkMode ? AppColors.colwhite : AppColors.colwhite,
      size: 32,
    ),
  );

  Widget _buildActionBtn(String text, Color bg, Color tx, VoidCallback? tap) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: tap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            elevation: 0,
            disabledBackgroundColor: colDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: tx,
            ),
          ),
        ),
      );

  Widget _buildTile(IconData icon, String t, String s, VoidCallback tap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        t,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
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
      );
}

class _CustomRangeCalendar extends StatefulWidget {
  final Function(DateTime, DateTime?) onConfirm;
  const _CustomRangeCalendar({required this.onConfirm});

  @override
  State<_CustomRangeCalendar> createState() => _CustomRangeCalendarState();
}

class _CustomRangeCalendarState extends State<_CustomRangeCalendar> {
  DateTime _viewDate = DateTime.now();
  DateTime? _start;
  DateTime? _end;
  bool _showPicker = false;

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final days = DateUtils.getDaysInMonth(_viewDate.year, _viewDate.month);
        final offset = DateTime(_viewDate.year, _viewDate.month, 1).weekday - 1;

        return Container(
          constraints: const BoxConstraints(maxHeight: 460),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.colwhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showPicker = !_showPicker),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_viewDate),
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.colblack,
                      ),
                    ),
                  ),
                  if (!_showPicker)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: AppColors.colblack,
                          ),
                          onPressed: () => setState(
                            () => _viewDate = DateTime(
                              _viewDate.year,
                              _viewDate.month - 1,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: AppColors.colblack,
                          ),
                          onPressed: () => setState(
                            () => _viewDate = DateTime(
                              _viewDate.year,
                              _viewDate.month + 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Flexible(
                child: _showPicker
                    ? _buildSeparatePickers()
                    : _buildCalendarGrid(days, offset),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _btn(
                      "Cancel",
                      AppColors.inputFill,
                      AppColors.destructiveRed,
                      () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _btn(
                      "Confirm",
                      _start == null
                          ? const Color(0xFFBABABA)
                          : AppColors.primaryGreen,
                      AppColors.colwhite,
                      _start == null
                          ? null
                          : () => widget.onConfirm(_start!, _end),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeparatePickers() {
    return Row(
      children: [
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            scrollController: FixedExtentScrollController(
              initialItem: _viewDate.month - 1,
            ),
            onSelectedItemChanged: (i) =>
                setState(() => _viewDate = DateTime(_viewDate.year, i + 1)),
            children: List.generate(
              12,
              (i) => Center(
                child: Text(
                  DateFormat('MMMM').format(DateTime(2026, i + 1)),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: CupertinoPicker(
            itemExtent: 40,
            scrollController: FixedExtentScrollController(
              initialItem: _viewDate.year - 2026,
            ),
            onSelectedItemChanged: (i) =>
                setState(() => _viewDate = DateTime(2026 + i, _viewDate.month)),
            children: List.generate(
              11,
              (i) => Center(
                child: Text(
                  "${2026 + i}",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(int days, int offset) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
              .map(
                (e) => Text(
                  e,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, i) {
            if (i < offset || i >= days + offset) return const SizedBox();
            final date = DateTime(
              _viewDate.year,
              _viewDate.month,
              i - offset + 1,
            );
            bool isSelected = (date == _start || date == _end);
            bool inRange =
                _start != null &&
                _end != null &&
                date.isAfter(_start!) &&
                date.isBefore(_end!);

            return GestureDetector(
              onTap: () => setState(() {
                if (_start == null || _end != null) {
                  _start = date;
                  _end = null;
                } else {
                  if (date.isBefore(_start!)) {
                    _end = _start;
                    _start = date;
                  } else {
                    _end = date;
                  }
                }
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: (isSelected || inRange)
                      ? const Color(0xFF34C759)
                      : Colors.transparent,
                  borderRadius: isSelected
                      ? (date == _start
                            ? BorderRadius.horizontal(left: Radius.circular(8))
                            : const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ))
                      : BorderRadius.zero,
                ),
                child: Center(
                  child: Text(
                    "${date.day}",
                    style: GoogleFonts.montserrat(
                      color: (isSelected || inRange)
                          ? AppColors.colblack
                          : const Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _btn(String t, Color bg, Color tx, VoidCallback? tap) => SizedBox(
    height: 50,
    child: ElevatedButton(
      onPressed: tap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        elevation: 0,
        disabledBackgroundColor: const Color(0xFFBABABA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        t,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: tx,
        ),
      ),
    ),
  );
}

// --- NEW CHANGE LIMIT POPUP COMPONENT ---
class _ChangeLimitPopup extends StatefulWidget {
  final int? currentLimit;
  const _ChangeLimitPopup({this.currentLimit});
  @override
  State<_ChangeLimitPopup> createState() => _ChangeLimitPopupState();
}

class _ChangeLimitPopupState extends State<_ChangeLimitPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _limitCtrl = TextEditingController();
  bool _isChecked = false;
  bool _isSubmitting = false;
  String? _errorMsg;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerError(String msg) {
    setState(() => _errorMsg = msg);
    _shakeController.forward(from: 0.0);
  }

  Future<void> _validateAndSubmit() async {
    setState(() => _errorMsg = null);
    final val = int.tryParse(_limitCtrl.text) ?? 0;

    if (val <= 0) {
      _triggerError("Please enter a valid amount");
      return;
    }
    if (val > 100000) {
      _triggerError("Limit cannot exceed Rs. 1,00,000");
      return;
    }
    if (!_isChecked) {
      _triggerError("Please agree to the condition");
      return;
    }

    final hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      _triggerError(
        "No internet connection. Please check your network and try again.",
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _triggerError("You're signed out. Please sign in again.");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('last_limit_change')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (row != null && row['last_limit_change'] != null) {
        final lastChange = DateTime.parse(row['last_limit_change']);
        final daysSince = DateTime.now().toUtc().difference(lastChange).inDays;
        if (daysSince < 7) {
          final remaining = 7 - daysSince;
          _triggerError(
            "You can only change your limit once a week. Try again in $remaining day${remaining == 1 ? '' : 's'}.",
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      await Supabase.instance.client
          .from('users')
          .update({'daily_limit': val, 'last_limit_change': nowIso})
          .eq('id', user.id)
          .timeout(const Duration(seconds: 8));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_expense_limit', val);
      await prefs.setString('last_limit_change', nowIso);

      if (mounted) Navigator.pop(context, val);
    } catch (e) {
      _triggerError(
        "Couldn't update your limit. Check your connection and try again.",
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        // Shake Animation Logic
        final Animation<double> offsetAnimation =
            TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
              TweenSequenceItem(
                tween: Tween(begin: 10.0, end: -10.0),
                weight: 2,
              ),
              TweenSequenceItem(
                tween: Tween(begin: -10.0, end: 10.0),
                weight: 2,
              ),
              TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
            ]).animate(
              CurvedAnimation(parent: _shakeController, curve: Curves.linear),
            );

        // Wrapped in AnimatedBuilder for shaking, and LayoutBuilder for responsiveness
        return AnimatedBuilder(
          animation: offsetAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(offsetAnimation.value, 0),
              child: child,
            );
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(28),
                ),
                // FIX: Using SingleChildScrollView inside constraints prevents pixel errors
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Change limit",
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colblack,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              size: 24,
                              color: AppColors.colblack,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Current Limit : Rs. ${widget.currentLimit != null ? NumberFormat('#,##0').format(widget.currentLimit) : '—'}",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white600,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              _errorMsg != null &&
                                      _errorMsg!.contains("valid") ||
                                  _errorMsg != null &&
                                      _errorMsg!.contains("exceed")
                              ? Border.all(
                                  color: AppColors.destructiveRed,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _limitCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: AppColors.colblack,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter new limit",
                                  hintStyle: GoogleFonts.montserrat(
                                    color: AppColors.grey600,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (v) {
                                  if (_errorMsg != null)
                                    setState(() => _errorMsg = null);
                                },
                              ),
                            ),
                            Text(
                              "INR",
                              style: GoogleFonts.montserrat(
                                color: AppColors.grey600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => setState(() {
                          _isChecked = !_isChecked;
                          if (_isChecked) _errorMsg = null;
                        }),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _isChecked
                                    ? AppColors.primaryGreen
                                    : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    (_errorMsg != null &&
                                        _errorMsg!.contains("agree") &&
                                        !_isChecked)
                                    ? Border.all(
                                        color: AppColors.destructiveRed,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: _isChecked
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Limit can be changed only once a week",
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: AppColors.white500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _errorMsg!,
                            style: GoogleFonts.poppins(
                              color: AppColors.destructiveRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _validateAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.colwhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Change",
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colwhite,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
