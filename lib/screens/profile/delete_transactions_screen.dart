import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/user_data.dart';
import 'package:url_launcher/url_launcher.dart';

class DeleteTransactionsScreen extends StatefulWidget {
  const DeleteTransactionsScreen({super.key});

  @override
  State<DeleteTransactionsScreen> createState() =>
      _DeleteTransactionsScreenState();
}

class _DeleteTransactionsScreenState extends State<DeleteTransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _dockKey = GlobalKey();
  bool _isPinned = false;
  bool _isPickerOpen = false;
  DateTime _focusedDate = DateTime.now();
  final DateTime _today = DateTime.now();

  // Selected transaction IDs (not indices — IDs are stable)
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateButtonPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateButtonPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _moveWeek(int days) {
    setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
  }

  List<DateTime> _getWeekDays() {
    int currentWeekday = _focusedDate.weekday;
    DateTime startOfWeek = _focusedDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  void _onMonthChanged(int newMonthIndex) {
    setState(() {
      int year = _focusedDate.year;
      int day = _focusedDate.day;
      int maxDays = DateTime(year, newMonthIndex + 2, 0).day;
      if (day > maxDays) day = maxDays;
      _focusedDate = DateTime(year, newMonthIndex + 1, day);
    });
  }

  void _onYearChanged(int newYear) {
    setState(() {
      _focusedDate = DateTime(newYear, _focusedDate.month, _focusedDate.day);
    });
  }

  void _updateButtonPosition() {
    if (_selectedIds.isEmpty) return;
    final RenderBox? renderBox =
        _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero).dy;
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() {
        _isPinned = position < (screenHeight - 80);
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateButtonPosition(),
    );
  }

  Future<void> _deleteSelected() async {
    final service = TransactionService();
    final ids = Set<String>.from(_selectedIds); // snapshot before clear
    setState(() {
      _selectedIds.clear();
      _isPinned = false;
    });
    for (final id in ids) {
      await service.deleteTransaction(id);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  /// All transactions for the focused date — includes hidden ones so they can
  /// be permanently deleted from this screen too.
  List<Transaction> _txForFocusedDate(TransactionService service) {
    return service.getAllTransactionsForDay(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        final service = TransactionService();
        return ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final dayTx = _txForFocusedDate(service);

            return Scaffold(
              backgroundColor: AppColors.bgWhite,
              body: Stack(
                children: [
                  const SizedBox(height: 70),
                  SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            "Delete",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: AppColors.colblack,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Transactions",
                            style: GoogleFonts.montserrat(
                              fontSize: 36,
                              color: AppColors.colblack,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 20),
                          _buildCalendarBox(),

                          const SizedBox(height: 28),
                          Text(
                            "Select Expense to Delete",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.colblack,
                            ),
                          ),
                          Text(
                            "Tap on the expense you want to permanently delete",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white500,
                            ),
                          ),

                          const SizedBox(height: 14),

                          if (service.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (dayTx.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  "No transactions for this day.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.white500,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayTx.length,
                              itemBuilder: (context, index) =>
                                  _buildTransactionCard(dayTx[index]),
                            ),

                          SizedBox(key: _dockKey, height: 10),

                          if (_isPinned && _selectedIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 8,
                                bottom: 12,
                              ),
                              child: _buildDeleteButton(),
                            ),

                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "That's it for today.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          _buildTipSection(),
                          const SizedBox(height: 20),
                          Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              "Planted with love in Mumbai, India",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),

                  if (!_isPinned && _selectedIds.isNotEmpty)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      bottom: 30 + MediaQuery.of(context).padding.bottom,
                      left: 24,
                      right: 24,
                      child: _buildDeleteButton(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _deleteSelected,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.destructiveRed,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructiveRed.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "Delete ${_selectedIds.length} Transaction${_selectedIds.length > 1 ? 's' : ''}",
            style: GoogleFonts.poppins(
              color: AppColors.colwhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Transaction tx) {
    final bool isSelected = _selectedIds.contains(tx.id);
    final hour = tx.time.hourOfPeriod == 0 ? 12 : tx.time.hourOfPeriod;
    final minute = tx.time.minute.toString().padLeft(2, '0');
    final period = tx.time.period == DayPeriod.am ? "AM" : "PM";
    final timeStr = "$hour:$minute $period";

    return GestureDetector(
      onTap: () => _toggleSelection(tx.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 15),
        width: double.infinity,
        height: 76.0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.destructiveRed : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: AppColors.iconbox,
                borderRadius: BorderRadius.circular(9.63),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.colblack.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(tx.icon, color: AppColors.colblack, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    tx.isManual ? "Manual entry" : "Bank account",
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "- Rs. ${tx.amount.toStringAsFixed(0)}",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _moveWeek(-7),
                  child: Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy').format(_focusedDate),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _moveWeek(7),
                  child: Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppColors.colblack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPickerOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildWeekStrip(),
            secondChild: _buildScrollPickers(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    final weekDays = _getWeekDays();
    final dayNames = ["M", "T", "W", "T", "F", "S", "S"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        DateTime date = weekDays[index];
        bool isFocused =
            date.day == _focusedDate.day &&
            date.month == _focusedDate.month &&
            date.year == _focusedDate.year;
        bool isToday =
            date.day == _today.day &&
            date.month == _today.month &&
            date.year == _today.year;

        return GestureDetector(
          onTap: () => setState(() => _focusedDate = date),
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 48,
                decoration: BoxDecoration(
                  color: isFocused ? AppColors.datebox : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.colblack,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 9),
                    Text(
                      "${date.day}",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildScrollPickers() {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _focusedDate.month - 1,
              ),
              itemExtent: 32,
              onSelectedItemChanged: _onMonthChanged,
              children: List.generate(
                12,
                (index) => Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, index + 1)),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(
                initialItem: _focusedDate.year - 2025,
              ),
              itemExtent: 32,
              onSelectedItemChanged: (index) => _onYearChanged(2025 + index),
              children: List.generate(
                11,
                (index) => Center(
                  child: Text(
                    "${2025 + index}",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: AppColors.colblack,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tip of the day",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Cooking one meal at home can save enough to grow 3 new leaves.",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: AppColors.white500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}