import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/transaction_service.dart';
import 'package:spentree/core/entitlement_service.dart';
import 'package:spentree/core/pro_upgrade_sheet.dart';
import 'package:spentree/screens/buckets/slide_route.dart';
import '../../core/app_style.dart';
import '../../core/transaction_service.dart'; // Make sure this path points to your new service
import 'package:spentree/core/database/local_transaction.dart';
import '../buckets/buckets_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  static final ValueNotifier<bool> triggerOpenForm = ValueNotifier(false);
  final bool startWithAddExpense;
  const AnalyticsScreen({super.key, this.startWithAddExpense = false});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedDate;
  late DateTime _today;
  late AnimationController _chartAnimController;
  late Animation<double> _chartFillAnim;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _addFormKey = GlobalKey();
  final Map<String, GlobalKey> _itemKeys = {};

  bool _isPickerOpen = false;
  bool _isEditMode = false;
  bool _isAddingExpense = false;
  String? _editingTransactionId;
  bool _hasAutoOpenedForm = false;

  final double cardRadius = 15.0;
  final double boxHeight = 76.0;

  final List<Color> _greenPalette = [
    const Color(0xFF005A32),
    const Color(0xFF238B45),
    const Color(0xFF41AB5D),
    const Color(0xFF74C476),
    const Color(0xFFA1D99B),
    const Color(0xFFC7E9C0),
  ];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _focusedDate = _today;

    _chartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartFillAnim = CurvedAnimation(
      parent: _chartAnimController,
      curve: Curves.easeOutCubic,
    );
    AnalyticsScreen.triggerOpenForm.addListener(_onGlobalTrigger);

    if (AnalyticsScreen.triggerOpenForm.value) {
      _onGlobalTrigger();
    }
    TransactionService().addListener(_onDataChanged);
    _chartAnimController.forward();
  }

  void _onGlobalTrigger() async {
    if (AnalyticsScreen.triggerOpenForm.value) {
      while (TransactionService().isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      if (mounted && !_isAddingExpense) {
        _toggleAddExpense();
        AnalyticsScreen.triggerOpenForm.value = false; // Reset the trigger
      }
    }
  }

  @override
  void dispose() {
    AnalyticsScreen.triggerOpenForm.removeListener(_onGlobalTrigger);
    TransactionService().removeListener(_onDataChanged);
    _chartAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
      _chartAnimController.reset();
      _chartAnimController.forward();
    }
  }

  void _moveWeek(int days) {
    setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
    _chartAnimController.reset();
    _chartAnimController.forward();
  }

  void _scrollToAddForm() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_addFormKey.currentContext != null) {
        Scrollable.ensureVisible(
          _addFormKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.25,
        );
      }
    });
  }

  void _scrollToItem(String id) {
    Future.delayed(const Duration(milliseconds: 350), () {
      final key = _itemKeys[id];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.25,
        );
      }
    });
  }

  void _toggleAddExpense() {
    setState(() {
      _isAddingExpense = !_isAddingExpense;
      _editingTransactionId = null;
      _isEditMode = false;
    });
    if (_isAddingExpense) _scrollToAddForm();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _isAddingExpense = false;
      _editingTransactionId = null;
    });
  }

  void _saveNewExpense(
    String title,
    String amountStr,
    String category,
    TimeOfDay time,
  ) {
    if (title.isEmpty || amountStr.isEmpty) return;
    double amount = double.tryParse(amountStr) ?? 0.0;

    // Safety check: block saving zero amounts
    if (amount <= 0) return;

    TransactionService().addExpense(
      title,
      amount,
      category,
      _focusedDate,
      time,
    );

    setState(() {
      _isAddingExpense = false;
    });
  }

  void _updateExpense(
    LocalTransaction tx,
    String title,
    String amountStr,
    String category,
    TimeOfDay time,
  ) {
    double amount = double.tryParse(amountStr) ?? tx.amount;

    TransactionService().updateExpense(tx.id, title, amount, category, time);

    setState(() {
      // FIXED: Nullifies the active edit box, but KEEPS the user in Edit Mode!
      _editingTransactionId = null;
    });
  }

  List<Map<String, dynamic>> _calculateChartData(
    List<LocalTransaction> dailyTx,
  ) {
    Map<String, double> totals = {};
    for (var tx in dailyTx) {
      totals[tx.category] = (totals[tx.category] ?? 0.0) + tx.amount;
    }
    var entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < entries.length; i++) {
      result.add({
        "name": entries[i].key,
        "val": entries[i].value,
        "color": _greenPalette[i % _greenPalette.length],
      });
    }
    return result;
  }

  List<DateTime> _getWeekDays() {
    int currentWeekday = _focusedDate.weekday;
    DateTime startOfWeek = _focusedDate.subtract(
      Duration(days: currentWeekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final dailyTx = TransactionService().getTransactionsForDay(_focusedDate);
    double totalCalc = dailyTx.fold(0, (sum, item) => sum + item.amount);
    bool isEmpty = dailyTx.isEmpty;
    var chartData = _calculateChartData(dailyTx);

    if (widget.startWithAddExpense &&
        !_hasAutoOpenedForm &&
        !TransactionService().isLoading) {
      // We wrap this in a post-frame callback so it doesn't interrupt the current drawing phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isAddingExpense) {
          setState(() {
            _hasAutoOpenedForm = true; // Lock it so it only happens once
          });
          _toggleAddExpense();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      resizeToAvoidBottomInset: false,
      body: TransactionService().isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: bottomPadding + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCalendarBox(),
                  const SizedBox(height: 24),

                  // --- ANALYSIS SECTION ---
                  AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isEditMode
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Analysis",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.colblack,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _chartFillAnim,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            size: const Size(210, 210),
                                            painter: RingChartPainter(
                                              data: isEmpty ? [] : chartData,
                                              total: isEmpty
                                                  ? 1
                                                  : totalCalc.toInt(),
                                              animationValue:
                                                  _chartFillAnim.value,
                                              isEmptyState: isEmpty,
                                            ),
                                          );
                                        },
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Total Expense",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.colblack,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            "Rs. ${NumberFormat('#,##0').format(totalCalc)}",
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.colblack,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                              if (!isEmpty) ...[
                                _buildCategoryList(chartData),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                  ),

                  // --- SECTION HEADER ---
                  if (_isEditMode)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select Expense to Edit",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.colblack,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleEditMode,
                              child: Text(
                                "Close",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Tap on the expense you want to edit",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.white500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _toggleAddExpense,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, color: AppColors.colwhite),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Add Expense",
                                    style: GoogleFonts.poppins(
                                      color: AppColors.colwhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Expenses",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.colblack,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isEmpty) {
                              _toggleAddExpense();
                            } else {
                              _toggleEditMode();
                            }
                          },
                          child: Text(
                            isEmpty ? "Add expense" : "Edit expense",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // --- ADD EXPENSE FORM ---
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: _isAddingExpense
                        ? Padding(
                            key: _addFormKey,
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ExpenseForm(
                              isEditing: false,
                              isManual: true, // It's a new manual expense
                              initialDate: _focusedDate,
                              onCancel: _toggleAddExpense,
                              onSave: _saveNewExpense,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // --- LIST ---
                  if (isEmpty && !_isAddingExpense)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 20),
                      child: Text(
                        "Nothing spent here so far.\nLet’s keep growing smart habits",
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                          color: AppColors.colblack,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dailyTx.length,
                      itemBuilder: (context, index) {
                        final tx = dailyTx[index];
                        final String txIdStr = tx.id
                            .toString(); // Safely convert ID to String

                        // FIX: Properly add to the existing map without redefining it
                        if (!_itemKeys.containsKey(txIdStr)) {
                          _itemKeys[txIdStr] = GlobalKey();
                        }

                        if (_isEditMode && _editingTransactionId == txIdStr) {
                          return Padding(
                            key: _itemKeys[txIdStr],
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExpenseForm(
                              isEditing: true,
                              isManual: (tx.type == 'Cash'),
                              initialTitle: tx.receiverName,
                              initialAmount: tx.amount.toString().replaceAll(
                                '.0',
                                '',
                              ),
                              initialCategory: tx.category,
                              initialDate: tx.dateTime,
                              initialTime: TimeOfDay.fromDateTime(tx.dateTime),
                              onCancel: () =>
                                  setState(() => _editingTransactionId = null),
                              onSave: (t, a, c, time) =>
                                  _updateExpense(tx, t, a, c, time),
                            ),
                          );
                        }

                        return KeyedSubtree(
                          key: _itemKeys[txIdStr],
                          child: _buildTransactionCard(tx),
                        );
                      },
                    ),

                  if (!isEmpty || (_isEditMode && !isEmpty)) ...[
                    const SizedBox(height: 12),
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
                  ],

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
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // --- SUB WIDGETS ---
  // --- HEADER ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.colblack,
              ),
            ),
            Text(
              "Analytics",
              style: GoogleFonts.montserrat(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: AppColors.colblack,
              ),
            ),
          ],
        ),
        // Wrap the trophy icon with GestureDetector to open BucketsScreen
        // GestureDetector(
        //   onTap: () {
        //     if (EntitlementService().isProForCurrentUser) {
        //       Navigator.push(context, slideRoute(const BucketsScreen()));
        //     } else {
        //       showProUpgradeSheet(context);
        //     }
        //   },
        //   child: Stack(
        //     clipBehavior: Clip.none,
        //     children: [
        //       Icon(
        //         PhosphorIconsRegular.archive,
        //         size: 32,
        //         color: AppColors.colblack,
        //       ),
        //       Positioned(
        //         top: 0,
        //         right: 0,
        //         child: Container(
        //           width: 10,
        //           height: 10,
        //           decoration: BoxDecoration(
        //             color: Colors.red,
        //             shape: BoxShape.circle,
        //             border: Border.all(color: AppColors.bgWhite, width: 1.5),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildCalendarBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(cardRadius),
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
        bool isToday = DateUtils.isSameDay(date, _today);
        return GestureDetector(
          onTap: () {
            setState(() => _focusedDate = date);
            _chartAnimController.reset();
            _chartAnimController.forward();
          },
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
                  color: DateUtils.isSameDay(date, _focusedDate)
                      ? AppColors.datebox
                      : Colors.transparent,
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
              onSelectedItemChanged: (i) {
                setState(() {
                  _focusedDate = DateTime(
                    _focusedDate.year,
                    i + 1,
                    _focusedDate.day,
                  );
                });
                _chartAnimController.reset();
                _chartAnimController.forward();
              },
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
              onSelectedItemChanged: (index) {
                setState(() {
                  _focusedDate = DateTime(
                    2025 + index,
                    _focusedDate.month,
                    _focusedDate.day,
                  );
                });
                _chartAnimController.reset();
                _chartAnimController.forward();
              },
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

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.colblack,
          ),
        ),
        Text(
          action,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> data) {
    return Column(
      children: data
          .map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cat['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.colblack,
                      ),
                    ),
                  ),
                  Text(
                    "- Rs. ${NumberFormat('#,##0').format(cat['val'])}",
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
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

  Widget _buildTransactionCard(LocalTransaction tx) {
    final String txIdStr = tx.id.toString(); // Safely convert ID to String
    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          setState(() => _editingTransactionId = txIdStr);
          _scrollToItem(txIdStr);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 15),
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(cardRadius),
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
              child: Icon(
                TransactionService().getIconForCategory(tx.category),
                color: AppColors.colblack,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tx.receiverName,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (tx.type == 'Cash') ? "Cash" : "Bank account",
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
                  "- Rs. ${NumberFormat('#,##0').format(tx.amount)}",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.colblack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TimeOfDay.fromDateTime(tx.dateTime).format(context),
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
}

// --- FORM WIDGET ---
class ExpenseForm extends StatefulWidget {
  final bool isEditing;
  final bool isManual; // Dictates if user can edit amount/category/time
  final String? initialTitle;
  final String? initialAmount;
  final String? initialCategory;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final VoidCallback onCancel;
  final Function(String title, String amount, String category, TimeOfDay time)
  onSave;

  const ExpenseForm({
    super.key,
    required this.isEditing,
    this.isManual = true,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialDate,
    this.initialTime,
    required this.onCancel,
    required this.onSave,
  });
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  late String _selectedCategory;
  late TimeOfDay _selectedTime;
  String _liveAmount = "000";
  bool _titleError = false;
  bool _amountError = false;
  bool _isTimePickerVisible = false;
  bool _isCategoryListVisible = false;
  final List<String> _categories = [
    "Food & Beverages",
    "Shopping",
    "To People",
    "Fuel",
    "Bills & Subscriptions",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? "");
    _amountCtrl = TextEditingController(text: widget.initialAmount ?? "");
    _selectedCategory = widget.initialCategory ?? "Food & Beverages";
    _selectedTime = widget.initialTime ?? TimeOfDay.now();
    if (widget.initialAmount != null) _liveAmount = widget.initialAmount!;
    _amountCtrl.addListener(() {
      String text = _amountCtrl.text;
      if (text.startsWith('0')) {
        String cleaned = text.replaceAll(RegExp(r'^0+'), '');
        _amountCtrl.value = TextEditingValue(
          text: cleaned,
          selection: TextSelection.collapsed(offset: cleaned.length),
        );
      }
      setState(() {
        _liveAmount = _amountCtrl.text.isEmpty ? "000" : _amountCtrl.text;
        _amountError = false;
      });
    });
    _titleCtrl.addListener(() {
      setState(() {
        _titleError = false;
      });
    });
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) _closePickers();
    });
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) _closePickers();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _titleFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _closePickers() {
    setState(() {
      _isTimePickerVisible = false;
      _isCategoryListVisible = false;
    });
  }

  IconData _getIcon(String cat) {
    if (!widget.isEditing &&
        _titleCtrl.text.isEmpty &&
        _amountCtrl.text.isEmpty) {
      if (_titleCtrl.text.isEmpty) return PhosphorIconsRegular.question;
    }
    if (cat == "Food & Beverages") return PhosphorIconsRegular.bowlSteam;
    if (cat == "Shopping") return PhosphorIconsRegular.tShirt;
    if (cat == "Fuel") return PhosphorIconsRegular.gasCan;
    if (cat == "Bills & Subscriptions") return PhosphorIconsRegular.simCard;
    if (cat == "To People") return PhosphorIconsRegular.user;
    return PhosphorIconsRegular.currencyInr;
  }

  void _trySave() {
    double parsedVal = double.tryParse(_amountCtrl.text) ?? 0.0;

    setState(() {
      _titleError = _titleCtrl.text.trim().isEmpty;
      // Amount is invalid if the text is empty OR if the parsed value is <= 0
      _amountError = _amountCtrl.text.trim().isEmpty || parsedVal <= 0;
    });

    if (_titleError || _amountError) return;

    widget.onSave(
      _titleCtrl.text.trim(),
      _amountCtrl.text.trim(),
      _selectedCategory,
      _selectedTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = widget.isEditing
        ? (_titleCtrl.text.isEmpty ? "Expense" : _titleCtrl.text)
        : (_titleCtrl.text.isEmpty ? "New Expense" : _titleCtrl.text);

    // If Editing and NOT Manual (i.e. Auto-fetched Bank SMS), lock inputs
    bool canEditTitle =
        true; // Always editable (Add, Manual Edit, Auto-Fetched Edit)
    bool canEditCategory = true; // Always editable
    bool canEditAmount =
        !widget.isEditing || widget.isManual; // Locked for auto-fetched edits
    bool canEditTime =
        !widget.isEditing || widget.isManual; // Locked for auto-fetched edits
    Color disabledColor = AppColors.grey600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(9.63),
        border: Border.all(color: AppColors.primaryGreen, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.iconbox,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.colblack.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(_selectedCategory),
                  size: 28,
                  color: AppColors.colblack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      widget.isManual ? "Cash" : "Bank account",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.white500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "- Rs. $_liveAmount",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'E, d MMM yyyy',
                    ).format(widget.initialDate ?? DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.white500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputBlock(
            child: TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              onTap: _closePickers,
              style: GoogleFonts.poppins(
                color: AppColors.colblack,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Enter receiver name",
                hintStyle: GoogleFonts.poppins(
                  color: disabledColor,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            hasError: _titleError,
            errorText: "Name required",
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: canEditCategory
                ? () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _isCategoryListVisible = !_isCategoryListVisible;
                      _isTimePickerVisible = false;
                    });
                  }
                : null,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: canEditCategory
                          ? AppColors.colblack
                          : disabledColor,
                    ),
                  ),
                  Icon(
                    _isCategoryListVisible
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: disabledColor,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isCategoryListVisible
                ? Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.colblack.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _categories
                          .map(
                            (cat) => InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                  _isCategoryListVisible = false;
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: cat != _categories.last
                                      ? Border(
                                          bottom: BorderSide(
                                            color: AppColors.inputFill,
                                          ),
                                        )
                                      : null,
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.colblack,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: canEditTime
                      ? () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isTimePickerVisible = !_isTimePickerVisible;
                            _isCategoryListVisible = false;
                          });
                        }
                      : null,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isTimePickerVisible ||
                                  _selectedTime != widget.initialTime
                              ? _selectedTime.format(context)
                              : "Time",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color:
                                (canEditTime &&
                                    (_isTimePickerVisible ||
                                        _selectedTime != widget.initialTime))
                                ? AppColors.colblack
                                : disabledColor,
                          ),
                        ),
                        Icon(Icons.access_time, size: 18, color: disabledColor),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _buildInputBlock(
                  child: TextField(
                    controller: _amountCtrl,
                    readOnly: !canEditAmount,
                    focusNode: _amountFocus,
                    onTap: _closePickers,
                    style: GoogleFonts.poppins(
                      color: canEditAmount ? AppColors.colblack : disabledColor,
                      fontSize: 14,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      hintStyle: GoogleFonts.poppins(
                        color: disabledColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  hasError: _amountError,
                  errorText: "Amount required",
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isTimePickerVisible
                ? Container(
                    height: 150,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: AppColors.colblack,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        backgroundColor: AppColors.bgWhite,
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: DateTime(
                          2023,
                          1,
                          1,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        ),
                        onDateTimeChanged: (val) {
                          setState(
                            () => _selectedTime = TimeOfDay.fromDateTime(val),
                          );
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: widget.onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7D8D6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(
                        color: AppColors.destructiveRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _trySave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.isEditing ? "Save" : "Add",
                      style: GoogleFonts.poppins(
                        color: AppColors.colwhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBlock({
    required Widget child,
    required bool hasError,
    required String errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? AppColors.errorRed : Colors.transparent,
            ),
          ),
          child: child,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.errorRed,
              ),
            ),
          ),
      ],
    );
  }
}

class RingChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int total;
  final double animationValue;
  final bool isEmptyState;
  RingChartPainter({
    required this.data,
    required this.total,
    required this.animationValue,
    required this.isEmptyState,
  });
  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 22.0;
    Rect rect =
        Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    Paint bgPaint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      size.center(Offset.zero),
      (size.width - strokeWidth) / 2,
      bgPaint,
    );
    if (isEmptyState) return;
    double startAngle = -1.5708;
    double totalSweepAvailable = 2 * 3.14159 * animationValue;
    for (var item in data) {
      double segmentSweep = (item['val'] / total) * totalSweepAvailable;
      Paint segmentPaint = Paint()
        ..color = item['color'] as Color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, segmentSweep, false, segmentPaint);
      startAngle += segmentSweep;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
