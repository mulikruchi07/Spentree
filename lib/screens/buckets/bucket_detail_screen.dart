import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spentree/core/app_style.dart';
import 'package:spentree/core/database/local_transaction.dart';
import 'package:spentree/core/transaction_service.dart';
import 'bucket_models.dart';
import 'select_expense_screen.dart';
import 'slide_route.dart';

/// Handles BOTH "New Bucket" and "Edit Bucket". [existingBucket] == null
/// means New Bucket mode; passing a bucket means Edit mode. The two flows
/// share every bit of working logic — only the heading, the inline
/// name-save target, and how the final Save persists differ.
class BucketDetailScreen extends StatefulWidget {
  final Bucket? existingBucket;
  const BucketDetailScreen({super.key, required this.existingBucket});

  @override
  State<BucketDetailScreen> createState() => _BucketDetailScreenState();
}

class _BucketDetailScreenState extends State<BucketDetailScreen> {
  bool get isNew => widget.existingBucket == null;

  late String _bucketName;
  late List<LocalTransaction> _workingTransactions;

  bool _isEditingName = false;
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  // Only ever one error line below the expense list, and one below the
  // name field — both self-clear after a few seconds.
  String? _nameError;
  String? _listError;
  Timer? _nameErrorTimer;
  Timer? _listErrorTimer;

  // Live swipe progress per transaction id (0.0 → 1.0), used to fade the
  // row itself into red as it's dragged, independent of the reveal
  // background underneath.
  final Map<int, double> _dragProgress = {};

  @override
  void initState() {
    super.initState();
    _bucketName = widget.existingBucket?.name ?? "";
    _workingTransactions = List<LocalTransaction>.from(
      widget.existingBucket?.transactions ?? [],
    );
    _nameController = TextEditingController(text: _bucketName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _nameErrorTimer?.cancel();
    _listErrorTimer?.cancel();
    super.dispose();
  }

  void _showNameError(String message) {
    _nameErrorTimer?.cancel();
    setState(() => _nameError = message);
    _nameErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _nameError = null);
    });
  }

  void _showListError(String message) {
    _listErrorTimer?.cancel();
    setState(() => _listError = message);
    _listErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _listError = null);
    });
  }

  void _startEditingName() {
    setState(() {
      _isEditingName = true;
      _nameController.text = _bucketName;
      _nameError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nameFocusNode.requestFocus(),
    );
  }

  // isNew: no committed name yet → always show "Save", and tapping
  // anywhere in the field opens the keyboard directly. Once a name has
  // been committed once, the field behaves like Edit mode (Edit ↔ Save).
  bool get _nameActionIsSave =>
      _isEditingName || (isNew && _bucketName.isEmpty);

  void _saveNameInline() {
    final value = _nameController.text.trim();
    if (value.isEmpty) {
      _showNameError("Please enter the Bucket name");
      return;
    }
    setState(() {
      _bucketName = value;
      _isEditingName = false;
      _nameError = null;
    });
    _nameErrorTimer?.cancel();
    // Edit mode: the name commits to the bucket right away — independent
    // of whatever happens with the page-level Save/Cancel below, which
    // only governs the expense list.
    if (!isNew) {
      BucketService().renameBucket(widget.existingBucket!.id, value);
    }
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.push<List<LocalTransaction>>(
      context,
      slideRoute(
        SelectExpenseScreen(
          bucketTitle: _bucketName.isNotEmpty ? _bucketName : "New Bucket",
          alreadySelected: _workingTransactions,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      final existingIds = _workingTransactions.map((t) => t.id).toSet();
      for (final tx in result) {
        if (!existingIds.contains(tx.id)) {
          _workingTransactions.add(tx);
        }
      }
      _listError = null;
    });
    _listErrorTimer?.cancel();
  }

  Future<bool> _confirmRemove(LocalTransaction tx) async {
    if (_workingTransactions.length <= 2) {
      _showListError("Bucket must at least include 2 expenses");
      return false; // snaps back instead of completing the delete swipe
    }
    return true;
  }

  void _removeTransaction(LocalTransaction tx) {
    setState(() {
      _workingTransactions.removeWhere((t) => t.id == tx.id);
      _dragProgress.remove(tx.id);
    });
  }

  void _handleSave() {
    if (_workingTransactions.length < 2) {
      _showListError("Bucket must at least include 2 expenses");
      return;
    }
    if (isNew) {
      final nameToUse = _bucketName.trim().isNotEmpty
          ? _bucketName.trim()
          : _nameController.text.trim();
      if (nameToUse.isEmpty) {
        _showNameError("Please enter the Bucket name");
        return;
      }
      BucketService().addBucket(
        Bucket(
          id: BucketService().newId(),
          name: nameToUse,
          transactions: _workingTransactions,
        ),
      );
    } else {
      BucketService().updateTransactions(
        widget.existingBucket!.id,
        _workingTransactions,
      );
    }
    Navigator.pop(context);
  }

  void _handleCancel() {
    // Name changes (Edit mode) were already committed via the inline
    // Save — only the expense list changes made on this screen discard.
    Navigator.pop(context);
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  if (_workingTransactions.isEmpty)
                    _buildEmptyState()
                  else
                    _buildExpenseList(),
                  const SizedBox(height: 20),
                  _buildAddExpenseButton(),
                  const SizedBox(height: 14),
                  if (_workingTransactions.isNotEmpty)
                    _buildSaveCancelRow()
                  else
                    _buildCancelOnlyButton(),

                  const SizedBox(height: 32),
                  _buildTipSection(),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.divider, thickness: 0.5),
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
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            isNew ? "New Bucket" : "Edit Bucket",
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.colblack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(15),
            border: _nameError != null
                ? Border.all(color: AppColors.errorRed, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _isEditingName ? null : _startEditingName,
                  child: _isEditingName
                      ? TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.colblack,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: "Name of the Bucket",
                            hintStyle: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white500,
                            ),
                          ),
                          onChanged: (_) {
                            if (_nameError != null) {
                              _nameErrorTimer?.cancel();
                              setState(() => _nameError = null);
                            }
                          },
                          onSubmitted: (_) => _saveNameInline(),
                        )
                      : Text(
                          _bucketName.isNotEmpty
                              ? _bucketName
                              : "Name of the Bucket",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _bucketName.isNotEmpty
                                ? AppColors.colblack
                                : AppColors.white500,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _nameActionIsSave ? _saveNameInline : _startEditingName,
                child: Text(
                  _nameActionIsSave ? "Save" : "Edit",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _nameActionIsSave
                        ? AppColors.primaryGreen
                        : AppColors.white600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _nameError!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Transform.rotate(
              angle: -13.28 * math.pi / 180,
              child: Icon(
                PhosphorIconsRegular.bug,
                size: 90,
                color: AppColors.white500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This bucket is empty\nright now",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.white500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sized so ~3.5 rows are visible, the rest scrolls within the box.
  // ClipRRect keeps both the swipe reveal and the dragged row itself from
  // ever drawing outside the box's rounded corners. The divider now lives
  // in ListView.separated (a sibling, not a child of the swiped row) so it
  // never moves during a swipe, and it sits exactly centered between two
  // rows since both rows contribute an equal 12px of padding.
  Widget _buildExpenseList() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: _workingTransactions.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Divider(color: AppColors.divider, thickness: 0.5, height: 1),
        ),
        itemBuilder: (context, index) {
          final tx = _workingTransactions[index];
          return Dismissible(
            key: ValueKey(tx.id),
            direction: DismissDirection.horizontal,
            resizeDuration: const Duration(milliseconds: 350),
            movementDuration: const Duration(milliseconds: 220),
            confirmDismiss: (_) => _confirmRemove(tx),
            onDismissed: (_) => _removeTransaction(tx),
            onUpdate: (details) {
              setState(() => _dragProgress[tx.id] = details.progress);
            },
            background: _buildSwipeReveal(alignStart: true),
            secondaryBackground: _buildSwipeReveal(alignStart: false),
            child: _buildExpenseListRow(tx),
          );
        },
      ),
    );
  }

  // Only the trash icon is inset — the red itself spans the full row
  // width (no horizontal padding here, and none on the ListView above),
  // so it touches the grey box's clipped border exactly.
  Widget _buildSwipeReveal({required bool alignStart}) {
    return Container(
      color: AppColors.destructiveRed,
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(PhosphorIcons.trash, color: AppColors.colwhite, size: 26),
      ),
    );
  }

  // The whole row surface (background) turns red as it's dragged — full
  // The red is a genuine layer drawn OVER the entire row — icon box, icon,
  // and text all disappear underneath it together as it fades in, rather
  // than a background color changing behind still-visible content. Full
  // opacity is reached at 75% of the swipe, not 100%, so it visually
  // commits well before release.
  Widget _buildExpenseListRow(LocalTransaction tx) {
    final hour = TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod == 0
        ? 12
        : TimeOfDay.fromDateTime(tx.dateTime).hourOfPeriod;
    final minute = TimeOfDay.fromDateTime(
      tx.dateTime,
    ).minute.toString().padLeft(2, '0');
    final period = TimeOfDay.fromDateTime(tx.dateTime).period == DayPeriod.am
        ? "AM"
        : "PM";
    final timeStr = "$hour:$minute $period";

    final rawProgress = (_dragProgress[tx.id] ?? 0.0).clamp(0.0, 1.0);
    final overlayOpacity = (rawProgress / 0.75).clamp(0.0, 1.0);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      (tx.type == 'Cash') ? "Manual entry" : "Bank account",
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
        if (overlayOpacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: overlayOpacity,
                child: Container(color: AppColors.destructiveRed),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddExpenseButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openAddExpense,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.colwhite, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Add Expense",
                  style: GoogleFonts.poppins(
                    color: AppColors.colwhite,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_listError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              _listError!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveCancelRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inputFill,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _handleCancel,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.destructiveRed,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCancelOnlyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleCancel,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.destructiveRed,
          ),
        ),
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