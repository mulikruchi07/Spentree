import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:spentree/core/app_style.dart';

// --- DATA MODEL ---
class Transaction {
  String id;
  String title;
  String category;
  double amount;
  DateTime date;
  TimeOfDay time;
  IconData icon;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    required this.icon,
  });
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  // --- STATE ---
  late DateTime _focusedDate;
  late DateTime _today;
  late AnimationController _chartAnimController;
  late Animation<double> _chartFillAnim;

  final ScrollController _scrollController = ScrollController();

  // Keys for Auto-Scrolling
  final GlobalKey _addFormKey = GlobalKey();
  final Map<String, GlobalKey> _itemKeys = {};

  bool _isPickerOpen = false;

  // Mode State
  bool _isEditMode = false;
  bool _isAddingExpense = false;
  String? _editingTransactionId;

  // Data
  final List<Transaction> _transactions = [];

  // UI Constants
  final double cardRadius = 15.0;
  final double boxHeight = 76.0;

  // Dynamic Green Palette
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
    _chartAnimController.forward();
  }

  @override
  void dispose() {
    _chartAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveWeek(int days) {
    setState(() => _focusedDate = _focusedDate.add(Duration(days: days)));
  }

  // --- LOGIC ---

  void _scrollToAddForm() {
    // Wait for animation to start expanding the box
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
          // UPDATED: Changed from 0.1 to 0.25 for better centering
          alignment: 0.25,
        );
      }
    });
  }

  void _toggleAddExpense() {
    setState(() {
      _isAddingExpense = !_isAddingExpense;
      _editingTransactionId = null;
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

    final newId = DateTime.now().toString();
    setState(() {
      _transactions.insert(
        0,
        Transaction(
          id: newId,
          title: title,
          category: category,
          amount: amount,
          date: _focusedDate,
          time: time,
          icon: _getIconForCategory(category),
        ),
      );
      _isAddingExpense = false;
      _chartAnimController.reset();
      _chartAnimController.forward();
    });
  }

  void _updateExpense(
    Transaction tx,
    String title,
    String amountStr,
    String category,
    TimeOfDay time,
  ) {
    setState(() {
      tx.title = title;
      tx.amount = double.tryParse(amountStr) ?? tx.amount;
      tx.category = category;
      tx.time = time;
      tx.icon = _getIconForCategory(category);
      _editingTransactionId = null;
      _isEditMode = false;
    });
  }

  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case "Food & Beverages":
        return Icons.fastfood;
      case "Shopping":
        return Icons.checkroom;
      case "Fuel":
        return Icons.local_gas_station;
      case "Bills & Subscriptions":
        return Icons.smartphone;
      case "To People":
        return Icons.person;
      default:
        return Icons.receipt;
    }
  }

  List<Map<String, dynamic>> _calculateChartData() {
    Map<String, double> totals = {};
    for (var tx in _transactions) {
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

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    double totalCalc = _transactions.fold(0, (sum, item) => sum + item.amount);
    bool isEmpty = _transactions.isEmpty;
    var chartData = _calculateChartData();

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
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
                        _buildSectionHeader("Today's Analysis", "Filter"),
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
                                        total: isEmpty ? 1 : totalCalc.toInt(),
                                        animationValue: _chartFillAnim.value,
                                        isEmptyState: isEmpty,
                                      ),
                                    );
                                  },
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                            color: AppColors.white500,
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
                            const Icon(Icons.add, color: AppColors.colwhite),
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
                        color: AppColors.white500,
                      ),
                    ),
                  ),
                ],
              ),

            // UPDATED: Reduced gap distance above transaction cards
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
                        initialDate: _focusedDate,
                        onCancel: _toggleAddExpense,
                        onSave: (title, amount, cat, time) =>
                            _saveNewExpense(title, amount, cat, time),
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
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  if (!_itemKeys.containsKey(tx.id)) {
                    _itemKeys[tx.id] = GlobalKey();
                  }

                  if (_isEditMode && _editingTransactionId == tx.id) {
                    return Padding(
                      key: _itemKeys[tx.id],
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExpenseForm(
                        isEditing: true,
                        initialTitle: tx.title,
                        initialAmount: tx.amount.toString().replaceAll(
                          '.0',
                          '',
                        ),
                        initialCategory: tx.category,
                        initialDate: tx.date,
                        initialTime: tx.time,
                        onCancel: () =>
                            setState(() => _editingTransactionId = null),
                        onSave: (t, a, c, time) =>
                            _updateExpense(tx, t, a, c, time),
                      ),
                    );
                  }

                  return KeyedSubtree(
                    key: _itemKeys[tx.id],
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
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildTransactionCard(Transaction tx) {
    return GestureDetector(
      onTap: () {
        if (_isEditMode) {
          setState(() => _editingTransactionId = tx.id);
          _scrollToItem(tx.id);
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
                    "Bank account",
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
                  tx.time.format(context),
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
                fontSize: 18,
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
        const Icon(
          Icons.emoji_events_outlined,
          size: 32,
          color: AppColors.colblack,
        ),
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
            color: AppColors.white500,
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
}

// --- COMPLEX FORM WIDGET ---
class ExpenseForm extends StatefulWidget {
  final bool isEditing;
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

    // Auto-focus the Name field with delay to allow animation
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
      if (_titleCtrl.text.isEmpty) return Icons.question_mark;
    }

    if (cat == "Food & Beverages") return Icons.fastfood;
    if (cat == "Shopping") return Icons.checkroom;
    if (cat == "Fuel") return Icons.local_gas_station;
    if (cat == "Bills & Subscriptions") return Icons.smartphone;
    if (cat == "To People") return Icons.person;
    return Icons.receipt;
  }

  void _trySave() {
    setState(() {
      _titleError = _titleCtrl.text.isEmpty;
      _amountError = _amountCtrl.text.isEmpty;
    });
    if (_titleError || _amountError) return;
    widget.onSave(
      _titleCtrl.text,
      _amountCtrl.text,
      _selectedCategory,
      _selectedTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    String headerTitle = widget.isEditing
        ? (_titleCtrl.text.isEmpty ? "Expense" : _titleCtrl.text)
        : (_titleCtrl.text.isEmpty ? "New Expense" : _titleCtrl.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill, // Form background
        borderRadius: BorderRadius.circular(9.63),
        border: Border.all(color: AppColors.primaryGreen, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FORM HEADER ---
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  Text(
                    widget.isEditing ? "Bank account" : "Cash",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.white500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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

          // --- NAME INPUT ---
          _buildInputBlock(
            child: TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              onTap: _closePickers,
              style: GoogleFonts.poppins(
                color: AppColors.colblack, // Text color
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: "Enter receiver name",
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.grey600,
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

          // --- CUSTOM CATEGORY DROPDOWN ---
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _isCategoryListVisible = !_isCategoryListVisible;
                _isTimePickerVisible = false;
              });
            },
            child: Container(
              height: 44, // Reduced Height
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
                      color: AppColors.colblack,
                    ),
                  ),
                  Icon(
                    _isCategoryListVisible
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.grey600,
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
                                      ? const Border(
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

          // --- TIME & AMOUNT ROW ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Trigger
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _isTimePickerVisible = !_isTimePickerVisible;
                      _isCategoryListVisible = false;
                    });
                  },
                  child: Container(
                    height: 44, // Reduced Height
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
                                _isTimePickerVisible ||
                                    _selectedTime != widget.initialTime
                                ? AppColors.colblack
                                : AppColors.grey600,
                          ),
                        ),
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: AppColors.grey600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Amount Input
              Expanded(
                flex: 3,
                child: _buildInputBlock(
                  child: TextField(
                    controller: _amountCtrl,
                    focusNode: _amountFocus,
                    onTap: _closePickers,
                    style: GoogleFonts.poppins(
                      color: AppColors.colblack, // Text color
                      fontSize: 14,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.grey600,
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

          // --- EMBEDDED TIME PICKER ---
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isTimePickerVisible
                ? Container(
                    height: 150,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWhite, // Black background
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark, // Makes text white
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

          // --- BUTTONS ---
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: widget.onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0E0E0),
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
                      widget.isEditing ? "Save Expense" : "Add Expense",
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
          height: 44, // Reduced Height
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

// --- CHART PAINTER ---
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
