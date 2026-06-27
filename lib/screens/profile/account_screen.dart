// import 'dart:ui';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Needed for input formatters
// import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import '../../core/user_data.dart';
// import '../../core/biometric_service.dart';
// import '../auth/change_password_screen.dart';
// import '../../core/app_style.dart';

// class AccountScreen extends StatefulWidget {
//   const AccountScreen({super.key});

//   @override
//   State<AccountScreen> createState() => _AccountScreenState();
// }

// class _AccountScreenState extends State<AccountScreen> {
//   // Toggle States
//   bool _isFaceIdEnabled = false;
//   bool _spendingAlerts = false;
//   bool _notifications = false;
//   bool _spendingTips = false;
//   bool _soundEffects = false;
//   String _selectedTheme = "System";

//   // --- Inline Editing States & Validation ---
//   bool _isEditingName = false;
//   bool _isEditingPhone = false;

//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;

//   // Track original values to know if user actually made changes
//   late String _originalName;
//   late String _originalPhone;

//   String? _nameError;
//   String? _phoneError;

//   // Auto-scroll controller & key
//   final ScrollController _scrollController = ScrollController();
//   final GlobalKey _editSectionKey = GlobalKey();

//   // Image Handling
//   Uint8List? _profileBytes;
//   String? _originalImagePath;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _originalName = UserData.userName;
//     _originalPhone = "0000000000"; // Removed +91

//     _nameController = TextEditingController(text: _originalName);
//     _phoneController = TextEditingController(text: _originalPhone);
//     _loadSettings();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isFaceIdEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
//       _selectedTheme = prefs.getString('app_theme') ?? "System";

//       final String? savedImageBase64 = prefs.getString('profile_image');
//       if (savedImageBase64 != null) {
//         _profileBytes = base64Decode(savedImageBase64);
//       }
//     });
//   }

//   // --- BACK NAVIGATION LOGIC ---
//   void _handleBackNavigation() {
//     bool nameChanged = _nameController.text != _originalName;
//     bool phoneChanged = _phoneController.text != _originalPhone;

//     if ((_isEditingName && nameChanged) || (_isEditingPhone && phoneChanged)) {
//       // User has unsaved changes: Block back, show error, scroll to fields
//       setState(() {
//         if (_isEditingName && nameChanged)
//           _nameError = "Please save your name before leaving.";
//         if (_isEditingPhone && phoneChanged)
//           _phoneError = "Please save your phone number before leaving.";
//       });

//       Scrollable.ensureVisible(
//         _editSectionKey.currentContext!,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     } else {
//       // Revert any empty edit states and pop
//       setState(() {
//         _isEditingName = false;
//         _isEditingPhone = false;
//         _nameController.text = _originalName;
//         _phoneController.text = _originalPhone;
//       });
//       Navigator.of(context).pop();
//     }
//   }

//   // --- EDIT FIELD SAVE LOGIC ---
//   void _toggleNameEdit() {
//     if (_isEditingName) {
//       // Trying to save
//       if (_nameController.text.trim().isEmpty) {
//         setState(() => _nameError = "Name cannot be empty");
//         return;
//       }
//       // Save successful
//       setState(() {
//         _originalName = _nameController.text.trim();
//         _nameError = null;
//         _isEditingName = false;
//       });
//     } else {
//       // Trying to edit
//       setState(() {
//         _isEditingName = true;
//         _nameError = null;
//       });
//     }
//   }

//   void _togglePhoneEdit() {
//     if (_isEditingPhone) {
//       // Trying to save
//       if (_phoneController.text.length < 10) {
//         setState(() => _phoneError = "Phone number must be exactly 10 digits");
//         return;
//       }
//       // Save successful
//       setState(() {
//         _originalPhone = _phoneController.text;
//         _phoneError = null;
//         _isEditingPhone = false;
//       });
//     } else {
//       // Trying to edit
//       setState(() {
//         _isEditingPhone = true;
//         _phoneError = null;
//       });
//     }
//   }

//   // --- IMAGE LOGIC ---
//   Future<void> _handleEditIconTap() async {
//     if (_profileBytes != null) {
//       _showImageActionSheet();
//     } else {
//       _showImageSourceSelector(false);
//     }
//   }

//   void _showImageActionSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.bgWhite,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: PhosphorIcon(
//                 PhosphorIconsRegular.image(),
//                 color: AppColors.colblack,
//               ),
//               title: Text(
//                 "Change Profile Picture",
//                 style: GoogleFonts.poppins(color: AppColors.colblack),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showImageSourceSelector(true);
//               },
//             ),
//             if (_originalImagePath != null)
//               ListTile(
//                 leading: PhosphorIcon(
//                   PhosphorIconsRegular.crop(),
//                   color: AppColors.colblack,
//                 ),
//                 title: Text(
//                   "Adjust Profile Picture",
//                   style: GoogleFonts.poppins(color: AppColors.colblack),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _cropImage(_originalImagePath!);
//                 },
//               ),
//             ListTile(
//               leading: PhosphorIcon(
//                 PhosphorIconsRegular.trash(),
//                 color: AppColors.destructiveRed,
//               ),
//               title: Text(
//                 "Remove Profile Picture",
//                 style: GoogleFonts.poppins(color: AppColors.destructiveRed),
//               ),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final prefs = await SharedPreferences.getInstance();
//                 await prefs.remove('profile_image');
//                 setState(() {
//                   _profileBytes = null;
//                   _originalImagePath = null;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showImageSourceSelector(bool isChanging) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.bgWhite,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: PhosphorIcon(
//                 PhosphorIconsRegular.camera(),
//                 color: AppColors.colblack,
//               ),
//               title: Text(
//                 "Take Photo",
//                 style: GoogleFonts.poppins(color: AppColors.colblack),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.camera);
//               },
//             ),
//             ListTile(
//               leading: PhosphorIcon(
//                 PhosphorIconsRegular.image(),
//                 color: AppColors.colblack,
//               ),
//               title: Text(
//                 "Choose from Gallery",
//                 style: GoogleFonts.poppins(color: AppColors.colblack),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage(ImageSource.gallery);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: source,
//         imageQuality: 80,
//       );

//       if (pickedFile != null) {
//         final int fileBytesLength = await pickedFile.length();
//         if (fileBytesLength > 5 * 1024 * 1024) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                   "Image size must be less than 5MB",
//                   style: GoogleFonts.poppins(color: Colors.white),
//                 ),
//                 backgroundColor: AppColors.destructiveRed,
//               ),
//             );
//           }
//           return;
//         }

//         _originalImagePath = pickedFile.path;
//         _cropImage(pickedFile.path);
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     }
//   }

//   Future<void> _cropImage(String path) async {
//     try {
//       final croppedFile = await ImageCropper().cropImage(
//         sourcePath: path,
//         aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Adjust Profile Picture',
//             toolbarColor: AppColors.bgWhite,
//             toolbarWidgetColor: AppColors.colblack,
//             initAspectRatio: CropAspectRatioPreset.square,
//             lockAspectRatio: true,
//             hideBottomControls: false,
//           ),
//           IOSUiSettings(
//             title: 'Adjust Profile Picture',
//             aspectRatioLockEnabled: true,
//             resetAspectRatioEnabled: false,
//           ),
//         ],
//       );

//       if (croppedFile != null) {
//         final bytes = await croppedFile.readAsBytes();
//         final String base64Image = base64Encode(bytes);
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('profile_image', base64Image);

//         setState(() {
//           _profileBytes = bytes;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error cropping image: $e");
//     }
//   }

//   void _viewProfileImage() {
//     if (_profileBytes == null) return;
//     Navigator.of(context).push(
//       PageRouteBuilder(
//         opaque: false,
//         barrierColor: Colors.black.withOpacity(0.8),
//         barrierDismissible: true,
//         pageBuilder: (BuildContext context, _, __) {
//           return Center(
//             child: GestureDetector(
//               onTap: () => Navigator.pop(context),
//               child: Hero(
//                 tag: 'profile_image_hero',
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.85,
//                   height: MediaQuery.of(context).size.width * 0.85,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: DecorationImage(
//                       image: MemoryImage(_profileBytes!),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(
//             opacity: animation,
//             child: ScaleTransition(
//               scale: Tween<double>(begin: 0.8, end: 1.0).animate(
//                 CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
//               ),
//               child: child,
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _handleFaceIdToggle(bool val) async {
//     if (val) {
//       if (await BiometricService.authenticateUser()) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setBool('isFaceIdEnabled', true);
//         setState(() => _isFaceIdEnabled = true);
//       }
//     } else {
//       _showConfirmationDialog(
//         title: "Remove App Lock",
//         message: "Are you sure you want to remove app-lock?",
//         confirmText: "Remove",
//         icon: Icons.fingerprint,
//         onConfirm: () async {
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setBool('isFaceIdEnabled', false);
//           setState(() => _isFaceIdEnabled = false);
//         },
//       );
//     }
//   }

//   void _handleThemeChange(String theme) async {
//     setState(() => _selectedTheme = theme);

//     if (theme == "System") {
//       themeNotifier.value = ThemeMode.system;
//     } else if (theme == "Light mode") {
//       themeNotifier.value = ThemeMode.light;
//     } else if (theme == "Dark mode") {
//       themeNotifier.value = ThemeMode.dark;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('app_theme', theme);
//   }

//   Future<void> _launchURL(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (!await launchUrl(uri)) throw 'Could not launch $url';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false, // Prevent default pop
//       onPopInvoked: (didPop) {
//         if (didPop) return;
//         _handleBackNavigation(); // Route through our custom logic
//       },
//       child: Scaffold(
//         backgroundColor: AppColors.bgWhite,
//         body: SafeArea(
//           top: false,
//           child: SingleChildScrollView(
//             controller: _scrollController,
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 70),
//                 Text(
//                   "My",
//                   style: GoogleFonts.montserrat(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.colblack,
//                   ),
//                 ),
//                 Text(
//                   "Account",
//                   style: GoogleFonts.montserrat(
//                     fontSize: 36,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.colblack,
//                     height: 1.1,
//                   ),
//                 ),

//                 const SizedBox(height: 32),
//                 _buildProfileHeader(),

//                 const SizedBox(height: 32),

//                 // Wrap fields in a Key for Auto-Scrolling
//                 Container(
//                   key: _editSectionKey,
//                   child: Column(
//                     children: [
//                       _buildInlineEditableField(
//                         label: "Name",
//                         controller: _nameController,
//                         isEditing: _isEditingName,
//                         onToggle: _toggleNameEdit,
//                         errorMsg: _nameError,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildInlineEditableField(
//                         label: "Phone Number",
//                         controller: _phoneController,
//                         isEditing: _isEditingPhone,
//                         onToggle: _togglePhoneEdit,
//                         isPhone: true,
//                         errorMsg: _phoneError,
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 32),
//                 _buildSectionHeader("Login & Security"),
//                 _buildActionTile(
//                   PhosphorIconsRegular.password(),
//                   "Change Password",
//                   "Change your current password",
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ChangePasswordScreen(),
//                       ),
//                     );
//                   },
//                 ),
//                 _buildToggleTile(
//                   PhosphorIconsRegular.fingerprintSimple(),
//                   "Face ID / Touch ID",
//                   "Manage your device security",
//                   _isFaceIdEnabled,
//                   _handleFaceIdToggle,
//                 ),

//                 const SizedBox(height: 32),
//                 _buildSectionHeader("Appearance"),
//                 _buildAppearanceSection(),

//                 const SizedBox(height: 32),
//                 _buildSectionHeader("Communication Preferences"),
//                 _buildToggleTile(
//                   PhosphorIconsRegular.warning(),
//                   "Spending Alerts",
//                   "Get alerts when you overspend",
//                   _spendingAlerts,
//                   (v) => setState(() => _spendingAlerts = v),
//                 ),
//                 _buildToggleTile(
//                   PhosphorIconsRegular.lightbulb(),
//                   "Spending Tips",
//                   "Get tips for daily expenses",
//                   _spendingTips,
//                   (v) => setState(() => _spendingTips = v),
//                 ),
//                 _buildToggleTile(
//                   PhosphorIconsRegular.bellSimpleRinging(),
//                   "Notifications",
//                   "Streak & Milestone Notifications",
//                   _notifications,
//                   (v) => setState(() => _notifications = v),
//                 ),
//                 _buildToggleTile(
//                   PhosphorIconsRegular.speakerHigh(),
//                   "Sound Effects",
//                   "Control Sound effects & Music",
//                   _soundEffects,
//                   (v) => setState(() => _soundEffects = v),
//                 ),

//                 const SizedBox(height: 32),
//                 _buildSectionHeader("Account Preferences"),
//                 _buildStaticField("Language", "English"),
//                 const SizedBox(height: 16),
//                 _buildStaticField("Currency", "INR"),

//                 const SizedBox(height: 32),
//                 _buildSectionHeader("Account Control"),
//                 _buildActionTile(
//                   PhosphorIconsRegular.lockKey(),
//                   "Deactivate Account",
//                   "Temporarily disable account",
//                   onPop: () => _showConfirmationDialog(
//                     title: "Deactivate Account",
//                     message: "You can come back anytime by logging in again.",
//                     confirmText: "Yes, Deactivate",
//                     icon: PhosphorIconsRegular.lockKey(),
//                     onConfirm: () {},
//                   ),
//                 ),
//                 _buildActionTile(
//                   PhosphorIconsRegular.trash(),
//                   "Delete My Account",
//                   "Delete your account permanently",
//                   onPop: () => _showConfirmationDialog(
//                     title: "Delete Account",
//                     message: "All your data will be removed permanently.",
//                     confirmText: "Yes, Delete",
//                     icon: PhosphorIconsRegular.trash(),
//                     onConfirm: () {},
//                   ),
//                 ),

//                 const SizedBox(height: 48),
//                 _buildFooter(context),
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // --- UI Reusable Components ---

//   Widget _buildAppearanceSection() {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _buildThemeOption("System"),
//           _buildThemeOption("Light mode"),
//           _buildThemeOption("Dark mode"),
//         ],
//       ),
//     );
//   }

//   Widget _buildThemeOption(String title) {
//     bool isSelected = _selectedTheme == title;
//     Color activeColor = const Color(0xFF6B6B6B);
//     Color inactiveColor = const Color(0xFFC4C4C4);

//     return GestureDetector(
//       onTap: () => _handleThemeChange(title),
//       behavior: HitTestBehavior.opaque,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: isSelected ? activeColor : inactiveColor,
//                 width: 2,
//               ),
//             ),
//             child: isSelected
//                 ? Center(
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: activeColor,
//                       ),
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             title,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: AppColors.colblack,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileHeader() {
//     return Center(
//       child: Column(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               GestureDetector(
//                 onTap: _viewProfileImage,
//                 child: Hero(
//                   tag: 'profile_image_hero',
//                   child: Container(
//                     width: 120,
//                     height: 120,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppColors.inputFill,
//                     ),
//                     clipBehavior: Clip.antiAlias,
//                     child: _profileBytes != null
//                         ? Image.memory(_profileBytes!, fit: BoxFit.cover)
//                         : Image.asset(
//                             'assets/images/user_avaar.png',
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) => Icon(
//                               Icons.person,
//                               size: 60,
//                               color: AppColors.colblack,
//                             ),
//                           ),
//                   ),
//                 ),
//               ),

//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: GestureDetector(
//                   onTap: _handleEditIconTap,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: AppColors.bgWhite,
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: AppColors.borderGrey.withOpacity(0.5),
//                         width: 1,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.15),
//                           blurRadius: 8,
//                           spreadRadius: 0,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: PhosphorIcon(
//                       PhosphorIconsRegular.pencilSimple(),
//                       size: 20,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _originalName, // Display validated saved name
//             style: GoogleFonts.poppins(
//               fontSize: 22,
//               fontWeight: FontWeight.w600,
//               color: AppColors.colblack,
//             ),
//           ),
//           Text(
//             "Planting since January 2025",
//             style: GoogleFonts.montserrat(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: AppColors.white500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInlineEditableField({
//     required String label,
//     required TextEditingController controller,
//     required bool isEditing,
//     required VoidCallback onToggle,
//     bool isPhone = false,
//     String? errorMsg,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.colblack,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           decoration: BoxDecoration(
//             color: AppColors.inputFill,
//             borderRadius: BorderRadius.circular(12),
//             border: errorMsg != null
//                 ? Border.all(color: AppColors.destructiveRed)
//                 : null,
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: isEditing
//                     ? TextField(
//                         controller: controller,
//                         autofocus: true,
//                         keyboardType: isPhone
//                             ? TextInputType.number
//                             : TextInputType.text,
//                         inputFormatters: isPhone
//                             ? [
//                                 FilteringTextInputFormatter.digitsOnly,
//                                 LengthLimitingTextInputFormatter(10),
//                               ]
//                             : [],
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           color: AppColors.colblack,
//                         ),
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           isDense: true,
//                         ),
//                         onChanged: (_) {
//                           if (errorMsg != null)
//                             setState(() {
//                               if (isPhone)
//                                 _phoneError = null;
//                               else
//                                 _nameError = null;
//                             });
//                         },
//                       )
//                     : Text(
//                         controller.text,
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           color: AppColors.grey600,
//                         ),
//                       ),
//               ),
//               TextButton(
//                 onPressed: onToggle,
//                 child: Text(
//                   isEditing ? "Save" : (isPhone ? "Change" : "Edit"),
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.white500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         if (errorMsg != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 6.0, left: 4.0),
//             child: Text(
//               errorMsg,
//               style: GoogleFonts.poppins(
//                 fontSize: 12,
//                 color: AppColors.destructiveRed,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildStaticField(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.colblack,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             color: AppColors.inputFill,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   value,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     color: AppColors.grey600,
//                   ),
//                 ),
//               ),
//               Text(
//                 "Change",
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   color: AppColors.white500,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildToggleTile(
//     IconData icon,
//     String title,
//     String subtitle,
//     bool val,
//     Function(bool) changed,
//   ) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.inputFill,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: AppColors.colIconBg,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, size: 24, color: AppColors.colblack),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: GoogleFonts.poppins(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: AppColors.colblack,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: GoogleFonts.poppins(
//                     fontSize: 10,
//                     color: AppColors.desctext,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildCustomToggle(val, changed),
//         ],
//       ),
//     );
//   }

//   Widget _buildCustomToggle(bool value, Function(bool) onChanged) {
//     return GestureDetector(
//       onTap: () => onChanged(!value),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 50,
//         height: 28,
//         padding: const EdgeInsets.symmetric(horizontal: 4),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: value ? AppColors.primaryGreen : const Color(0xFFE8E8E8),
//         ),
//         child: AnimatedAlign(
//           duration: const Duration(milliseconds: 200),
//           alignment: value ? Alignment.centerRight : Alignment.centerLeft,
//           child: Container(
//             width: 20,
//             height: 20,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: value ? Colors.white : const Color(0xFFABABAB),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionTile(
//     IconData icon,
//     String title,
//     String subtitle, {
//     VoidCallback? onTap,
//     VoidCallback? onPop,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Material(
//         color: AppColors.inputFill,
//         borderRadius: BorderRadius.circular(15),
//         child: InkWell(
//           onTap: onTap ?? onPop,
//           borderRadius: BorderRadius.circular(15),
//           splashColor: Colors.transparent,
//           highlightColor: Colors.transparent,
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: AppColors.colIconBg,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(icon, size: 24, color: AppColors.colblack),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: AppColors.colblack,
//                         ),
//                       ),
//                       Text(
//                         subtitle,
//                         style: GoogleFonts.poppins(
//                           fontSize: 10,
//                           color: AppColors.desctext,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.chevron_right, color: AppColors.desctext),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFooter(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Planted with love in Mumbai, India",
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w400,
//             color: AppColors.white500,
//           ),
//         ),
//         const SizedBox(height: 4),
//         GestureDetector(
//           onTap: () => _launchURL("https://in.linkedin.com/in/pranav-phanse-8b4bbb318"),
//           child: RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppColors.white500,
//               ),
//               children: [
//                 TextSpan(
//                   text: "Designed by ",
//                   style: TextStyle(
//                     fontWeight: FontWeight.w400,
//                     color: AppColors.white500,
//                   ),
//                 ),
//                 TextSpan(
//                   text: "Designer",
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w200,
//                     fontStyle: FontStyle.italic,
//                     color: AppColors.white500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         GestureDetector(
//           onTap: () => _launchURL("www.linkedin.com/in/ruchi-mulik-816a2b295"),
//           child: RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 color: AppColors.white500,
//               ),
//               children: [
//                 TextSpan(
//                   text: "Developed by ",
//                   style: TextStyle(
//                     fontWeight: FontWeight.w400,
//                     color: AppColors.white500,
//                   ),
//                 ),
//                 TextSpan(
//                   text: "Developer",
//                   style: GoogleFonts.poppins(
//                     fontWeight: FontWeight.w200,
//                     fontStyle: FontStyle.italic,
//                     color: AppColors.white500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _showConfirmationDialog({
//     required String title,
//     required String message,
//     required String confirmText,
//     required IconData icon,
//     required VoidCallback onConfirm,
//   }) async {
//     return showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) {
//         return BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Dialog(
//             backgroundColor: Colors.transparent,
//             insetPadding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: AppColors.bgWhite,
//                 borderRadius: BorderRadius.circular(28),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: const BoxDecoration(
//                       color: AppColors.destructiveRed,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(icon, color: AppColors.colwhite, size: 32),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     title,
//                     style: GoogleFonts.poppins(
//                       fontSize: 22,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.colblack,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     message,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w400,
//                       color: AppColors.desctext,
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 54,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         onConfirm();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.destructiveRed,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: Text(
//                         confirmText,
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.colwhite,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 54,
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.inputFill,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: Text(
//                         "Cancel",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.destructiveRed,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSectionHeader(String t) => Padding(
//     padding: const EdgeInsets.only(bottom: 16),
//     child: Text(
//       t,
//       style: GoogleFonts.poppins(
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: AppColors.colblack,
//       ),
//     ),
//   );
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spentree/app_lock.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/user_profile.dart';
import '../../core/biometric_service.dart';
import '../auth/change_password_screen.dart';
import '../../core/app_style.dart';
import '../forest/forest_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Loading state to prevent toggle switch flickering on load
  bool _isLoading = true;

  // Toggle States
  bool _isFaceIdEnabled = false;
  bool _spendingAlerts = false;
  bool _spendingTips = false;
  String _selectedTheme = "System";

  // Inline Editing States & Validation
  bool _isEditingName = false;
  bool _isEditingPhone = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  late String _originalName;
  late String _originalPhone;

  String? _nameError;
  String? _phoneError;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _editSectionKey = GlobalKey();

  // Local crop path only — image bytes live in userProfileNotifier
  String? _originalImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Name sourced from the global notifier
    _originalName = userProfileNotifier.value.name;
    _originalPhone = "0000000000";

    _nameController = TextEditingController(text: _originalName);
    _phoneController = TextEditingController(text: _originalPhone);
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFaceIdEnabled = prefs.getBool('isFaceIdEnabled') ?? false;
      _selectedTheme = prefs.getString('app_theme') ?? "System";
      // Profile image is loaded from userProfileNotifier — no local loading needed
      _isLoading = false;
    });
  }

  void _handleBackNavigation() {
    bool nameChanged = _nameController.text != _originalName;
    bool phoneChanged = _phoneController.text != _originalPhone;

    if ((_isEditingName && nameChanged) || (_isEditingPhone && phoneChanged)) {
      setState(() {
        if (_isEditingName && nameChanged)
          _nameError = "Please save your name before leaving.";
        if (_isEditingPhone && phoneChanged)
          _phoneError = "Please save your phone number before leaving.";
      });

      Scrollable.ensureVisible(
        _editSectionKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() {
        _isEditingName = false;
        _isEditingPhone = false;
        _nameController.text = _originalName;
        _phoneController.text = _originalPhone;
      });
      Navigator.of(context).pop();
    }
  }

  void _toggleNameEdit() {
    if (_isEditingName) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _nameError = "Name cannot be empty");
        return;
      }
      final newName = _nameController.text.trim();
      // Write through the notifier — broadcasts instantly to every screen
      userProfileNotifier.updateName(newName);
      setState(() {
        _originalName = newName;
        _nameError = null;
        _isEditingName = false;
      });
    } else {
      setState(() {
        _isEditingName = true;
        _nameError = null;
      });
    }
  }

  void _togglePhoneEdit() {
    if (_isEditingPhone) {
      if (_phoneController.text.length < 10) {
        setState(() => _phoneError = "Phone number must be exactly 10 digits");
        return;
      }
      setState(() {
        _originalPhone = _phoneController.text;
        _phoneError = null;
        _isEditingPhone = false;
      });
    } else {
      setState(() {
        _isEditingPhone = true;
        _phoneError = null;
      });
    }
  }

  Future<void> _handleEditIconTap() async {
    if (userProfileNotifier.value.imageBytes != null) {
      _showImageActionSheet();
    } else {
      _showImageSourceSelector(false);
    }
  }

  void _showImageActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.image,
                color: AppColors.colblack,
              ),
              title: Text(
                "Change Profile Picture",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceSelector(true);
              },
            ),
            if (_originalImagePath != null)
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsRegular.crop,
                  color: AppColors.colblack,
                ),
                title: Text(
                  "Adjust Profile Picture",
                  style: GoogleFonts.poppins(color: AppColors.colblack),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cropImage(_originalImagePath!);
                },
              ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.trash,
                color: AppColors.destructiveRed,
              ),
              title: Text(
                "Remove Profile Picture",
                style: GoogleFonts.poppins(color: AppColors.destructiveRed),
              ),
              onTap: () async {
                Navigator.pop(context);
                // Clears from notifier + SharedPreferences in one call
                await userProfileNotifier.removeImage();
                setState(() => _originalImagePath = null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSelector(bool isChanging) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.camera,
                color: AppColors.colblack,
              ),
              title: Text(
                "Take Photo",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: PhosphorIcon(
                PhosphorIconsRegular.image,
                color: AppColors.colblack,
              ),
              title: Text(
                "Choose from Gallery",
                style: GoogleFonts.poppins(color: AppColors.colblack),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final int fileBytesLength = await pickedFile.length();
        if (fileBytesLength > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Image size must be less than 5MB",
                  style: GoogleFonts.poppins(color: AppColors.colwhite),
                ),
                backgroundColor: AppColors.destructiveRed,
              ),
            );
          }
          return;
        }
        _originalImagePath = pickedFile.path;
        _cropImage(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _cropImage(String path) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Profile Picture',
            toolbarColor: AppColors.bgWhite,
            toolbarWidgetColor: AppColors.colblack,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Adjust Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final bytes = await croppedFile.readAsBytes();
        // Persists bytes to SharedPrefs + broadcasts to all listeners
        await userProfileNotifier.updateImage(bytes);
        // Sync the home widget
        await HomeWidget.saveWidgetData<String>(
          'widget_user_name',
          userProfileNotifier.value.name,
        );
        await HomeWidget.updateWidget(
          name: 'GreetingWidgetProvider',
          iOSName: 'GreetingWidgetProvider',
        );
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
  }

  void _viewProfileImage() {
    final bytes = userProfileNotifier.value.imageBytes;
    if (bytes == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.8),
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: 'profile_image_hero',
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleFaceIdToggle(bool val) async {
    if (val) {
      final result = await BiometricService.authenticate();
      if (result == AuthResult.success) {
        await AppLockController.setLockEnabled(true);
        setState(() => _isFaceIdEnabled = true);
      }
    } else {
      _showConfirmationDialog(
        title: 'Remove App Lock',
        message: 'Are you sure you want to remove app-lock?',
        confirmText: 'Remove',
        icon: Icons.fingerprint,
        onConfirm: () async {
          await AppLockController.setLockEnabled(false);
          setState(() => _isFaceIdEnabled = false);
        },
      );
    }
  }

  void _handleThemeChange(String theme) async {
    setState(() => _selectedTheme = theme);

    if (theme == "System") {
      themeNotifier.value = ThemeMode.system;
    } else if (theme == "Light mode") {
      themeNotifier.value = ThemeMode.light;
    } else if (theme == "Dark mode") {
      themeNotifier.value = ThemeMode.dark;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppColors.bgWhite);
    }
    MediaQuery.platformBrightnessOf(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackNavigation();
          },
          child: Scaffold(
            backgroundColor: AppColors.bgWhite,
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: _scrollController,
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
                        color: AppColors.colblack,
                      ),
                    ),
                    Text(
                      "Account",
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.colblack,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildProfileHeader(),

                    const SizedBox(height: 32),

                    Container(
                      key: _editSectionKey,
                      child: Column(
                        children: [
                          _buildInlineEditableField(
                            label: "Name",
                            controller: _nameController,
                            isEditing: _isEditingName,
                            onToggle: _toggleNameEdit,
                            errorMsg: _nameError,
                          ),
                          const SizedBox(height: 16),
                          _buildInlineEditableField(
                            label: "Phone Number",
                            controller: _phoneController,
                            isEditing: _isEditingPhone,
                            onToggle: _togglePhoneEdit,
                            isPhone: true,
                            errorMsg: _phoneError,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Login & Security"),
                    _buildActionTile(
                      PhosphorIconsRegular.password,
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
                      PhosphorIconsRegular.fingerprintSimple,
                      "Face ID / Touch ID",
                      "Manage your device security",
                      _isFaceIdEnabled,
                      _handleFaceIdToggle,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Appearance"),
                    _buildAppearanceSection(),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Communication Preferences"),
                    _buildToggleTile(
                      PhosphorIconsRegular.warning,
                      "Spending Alerts",
                      "Get alerts when you overspend",
                      _spendingAlerts,
                      (v) => setState(() => _spendingAlerts = v),
                    ),
                    _buildToggleTile(
                      PhosphorIconsRegular.lightbulb,
                      "Spending Tips",
                      "Get tips for daily expenses",
                      _spendingTips,
                      (v) => setState(() => _spendingTips = v),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Account Control"),
                    _buildActionTile(
                      PhosphorIconsRegular.lockKey,
                      "Deactivate Account",
                      "Temporarily disable account",
                      onPop: () => _showConfirmationDialog(
                        title: "Deactivate Account",
                        message:
                            "You can come back anytime by logging in again.",
                        confirmText: "Yes, Deactivate",
                        icon: PhosphorIconsRegular.lockKey,
                        onConfirm: () {},
                      ),
                    ),
                    _buildActionTile(
                      PhosphorIconsRegular.trash,
                      "Delete My Account",
                      "Delete your account permanently",
                      onPop: () => _showConfirmationDialog(
                        title: "Delete Account",
                        message: "All your data will be removed permanently.",
                        confirmText: "Yes, Delete",
                        icon: PhosphorIconsRegular.trash,
                        onConfirm: () {},
                      ),
                    ),

                    const SizedBox(height: 48),
                    _buildFooter(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── UI Components ────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    // Wraps in ValueListenableBuilder so name + image update instantly
    // across the whole app without requiring any manual refresh
    return ValueListenableBuilder<UserProfile>(
      valueListenable: userProfileNotifier,
      builder: (context, profile, _) {
        return Center(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: profile.imageBytes != null
                        ? _viewProfileImage
                        : null,
                    child: Hero(
                      tag: 'profile_image_hero',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.inputFill,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profile.imageBytes != null
                            ? Image.memory(
                                profile.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  PhosphorIconsRegular.user, // Icon as requested
                                  size: 60,
                                  color: AppColors.grey600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _handleEditIconTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderGrey.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsRegular.pencilSimple,
                          size: 20,
                          color: AppColors.colblack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                profile.firstName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.colblack,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Planting since January 2025",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildThemeOption("System"),
          _buildThemeOption("Light mode"),
          _buildThemeOption("Dark mode"),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title) {
    bool isSelected = _selectedTheme == title;
    Color activeColor = const Color(0xFF6B6B6B);
    Color inactiveColor = const Color(0xFFC4C4C4);

    return GestureDetector(
      onTap: () => _handleThemeChange(title),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.colblack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onToggle,
    bool isPhone = false,
    String? errorMsg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: errorMsg != null
                ? Border.all(color: AppColors.destructiveRed)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: isPhone
                            ? TextInputType.number
                            : TextInputType.text,
                        inputFormatters: isPhone
                            ? [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ]
                            : [],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.colblack,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) {
                          if (errorMsg != null) {
                            setState(() {
                              if (isPhone)
                                _phoneError = null;
                              else
                                _nameError = null;
                            });
                          }
                        },
                      )
                    : Text(
                        controller.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey600,
                        ),
                      ),
              ),
              TextButton(
                onPressed: onToggle,
                child: Text(
                  isEditing ? "Save" : (isPhone ? "Change" : "Edit"),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 4.0),
            child: Text(
              errorMsg,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.destructiveRed,
                fontWeight: FontWeight.w500,
              ),
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
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.colblack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ),
              Text(
                "Change",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white500,
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
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(15),
      ),
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
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.colblack,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.desctext,
                  ),
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
          color: value ? AppColors.primaryGreen : AppColors.toggle,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : AppColors.toggledot,
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
        color: AppColors.inputFill,
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
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colblack,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
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
                    child: Icon(icon, color: AppColors.colwhite, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.colblack,
                    ),
                  ),
                  const SizedBox(height: 8),
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

  Widget _buildSectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      t,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.colblack,
      ),
    ),
  );
}
