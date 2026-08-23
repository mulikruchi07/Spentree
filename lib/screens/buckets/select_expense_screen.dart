import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/transaction_service.dart';

/// Slides open from Edit/New Bucket. [alreadySelected] are expenses already
/// in the bucket (shown blurred + unclickable); newly selected expenses are
/// returned via Navigator.pop when the floating "Add N Expenses" button is
/// tapped. The plain back arrow pops with nothing — a pure cancel.
class SelectExpenseScreen extends StatefulWidget {
  final String bucketTitle;
  final List<LocalTransaction> alreadySelected;

  const SelectExpenseScreen({
    super.key,
    required this.bucketTitle,
    required this.alreadySelected,
  });

  @override
  State<SelectExpenseScreen> createState() => _SelectExpenseScreenState();
}

class _SelectExpenseScreenState extends State<SelectExpenseScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _dockKey = GlobalKey();
  bool _isPinned = false;
  bool _isPickerOpen = false;
  DateTime _focusedDate = DateTime.now();
  final DateTime _today = DateTime.now();

  // Newly selected this session, keyed by transaction id — persists across
  // day/week navigation so the button total reflects everything picked so
  // far, not just the currently-visible day.
  final Map<int, LocalTransaction> _newlySelected = {};
  late final Set<int> _alreadyInBucketIds;

  @override
  void initState() {
    super.initState();
    _alreadyInBucketIds = widget.alreadySelected.map((t) => t.id).toSet();
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
    DateTime startOfWeek = _focusedDate.subtract(Duration(days: currentWeekday - 1));
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
    setState(() => _focusedDate = DateTime(newYear, _focusedDate.month, _focusedDate.day));
  }

  void _updateButtonPosition() {
    if (_newlySelected.isEmpty) return;
    final RenderBox? renderBox = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero).dy;
      final screenHeight = MediaQuery.of(context).size.height;
      setState(() => _isPinned = position < (screenHeight - 80));
    }
  }

  void _toggleSelection(LocalTransaction tx) {
    if (_alreadyInBucketIds.contains(tx.id)) return; // already added — unclickable
    setState(() {
      if (_newlySelected.containsKey(tx.id)) {
        _newlySelected.remove(tx.id);
      } else {
        _newlySelected[tx.id] = tx;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateButtonPosition());
  }

  void _confirmAdd() {
    Navigator.pop(context, _newlySelected.values.toList());
  }

  List<LocalTransaction> _txForFocusedDate(TransactionService service) {
    return service.getAllTransactionsForDay(_focusedDate);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
                  SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  widget.bucketTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.colblack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildCalendarBox(),

                          const SizedBox(height: 24),
                          Text(
                            "Select 2 or more Expenses",
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.colblack),
                          ),
                          Text(
                            "Tap on the expenses to select them",
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.white500),
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
                                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.white500),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dayTx.length,
                              itemBuilder: (context, index) => _buildTransactionCard(dayTx[index]),
                            ),

                          SizedBox(key: _dockKey, height: 10),

                          if (_isPinned && _newlySelected.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 12),
                              child: _buildAddButton(),
                            ),

                          const SizedBox(height: 32),
                          _buildTipSection(),
                          const SizedBox(height: 20),
                          Divider(color: AppColors.divider, thickness: 1),
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              "Planted with love in Mumbai, India",
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white500),
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                  if (!_isPinned && _newlySelected.isNotEmpty)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      bottom: 30 + MediaQuery.of(context).padding.bottom,
                      left: 24,
                      right: 24,
                      child: _buildAddButton(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _confirmAdd,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: AppColors.primaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(
            "Add ${_newlySelected.length} Expense${_newlySelected.length > 1 ? 's' : ''}",
            style: GoogleFonts.poppins(color: AppColors.colwhite, fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(LocalTransaction tx) {
    final bool isAlreadyAdded = _alreadyInBucketIds.contains(tx.id);
    final bool isSelected = _newlySelected.containsKey(tx.id);

    final hour = TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod == 0
        ? 12
        : TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod;
    final minute = TimeOfDay.fromDateTime(tx.dateTime).minute.toString().padLeft(2, '0');
    final period = TimeOfDay.fromDateTime(tx.dateTime).period == DayPeriod.am ? "AM" : "PM";
    final timeStr = "$hour:$minute $period";

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity,
      height: 76.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
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
                BoxShadow(color: AppColors.colblack.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(TransactionService().getIconForCategory(tx.category), color: AppColors.colblack, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tx.receiverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.colblack),
                ),
                Text(
                  (tx.type == 'Cash') ? "Manual entry" : "Bank account",
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.white500),
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
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.colblack),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.white500),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isAlreadyAdded) {
      return GestureDetector(onTap: () => _toggleSelection(tx), child: card);
    }

    // Already in the bucket — blurred, labeled, and unclickable.
    return Stack(
      children: [
        Opacity(opacity: 0.2, child: IgnorePointer(child: card)),
        Positioned.fill(
          bottom: 15,
          child: Center(
            child: Text(
              "Already added",
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.colblack),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPickerOpen = !_isPickerOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _moveWeek(-7),
                  child: Icon(Icons.chevron_left, size: 24, color: AppColors.colblack),
                ),
                Row(
                  children: [
                    Text(
                      DateFormat('MMMM').format(_focusedDate),
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.colblack),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy').format(_focusedDate),
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.colblack),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _moveWeek(7),
                  child: Icon(Icons.chevron_right, size: 24, color: AppColors.colblack),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPickerOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
        bool isFocused = date.day == _focusedDate.day && date.month == _focusedDate.month && date.year == _focusedDate.year;
        bool isToday = date.day == _today.day && date.month == _today.month && date.year == _today.year;

        return GestureDetector(
          onTap: () => setState(() => _focusedDate = date),
          child: Column(
            children: [
              Text(
                dayNames[index],
                style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.white500),
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
                        decoration: BoxDecoration(color: AppColors.colblack, shape: BoxShape.circle),
                      )
                    else
                      const SizedBox(height: 9),
                    Text(
                      "${date.day}",
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.white500),
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
              scrollController: FixedExtentScrollController(initialItem: _focusedDate.month - 1),
              itemExtent: 32,
              onSelectedItemChanged: _onMonthChanged,
              children: List.generate(
                12,
                (index) => Center(
                  child: Text(
                    DateFormat('MMMM').format(DateTime(2025, index + 1)),
                    style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.colblack),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: FixedExtentScrollController(initialItem: _focusedDate.year - 2025),
              itemExtent: 32,
              onSelectedItemChanged: (index) => _onYearChanged(2025 + index),
              children: List.generate(
                11,
                (index) => Center(
                  child: Text(
                    "${2025 + index}",
                    style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.colblack),
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.colblack),
        ),
        const SizedBox(height: 8),
        Text(
          "Cooking one meal at home can save enough to grow 3 new leaves.",
          style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w500, color: AppColors.white500, height: 1.3),
        ),
      ],
    );
  }
}
