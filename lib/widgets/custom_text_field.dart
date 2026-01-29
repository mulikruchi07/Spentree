import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_style.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final double height;
  final double cornerRadius;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.height = 64.0,
    this.cornerRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    // Using FormField to handle validation state and error messages
    return FormField<String>(
      validator: validator,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(cornerRadius),
                // Apply red border only when there's an error
                border: state.hasError
                    ? Border.all(color: AppColors.errorRed, width: 1.0)
                    : null,
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: (value) {
                  // Notify the form field state of changes
                  state.didChange(value);
                },
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: hintText,
                  hintStyle: GoogleFonts.montserrat(color: AppColors.textGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  suffixIcon: suffixIcon,
                ),
              ),
            ),
            // Display error message below the field if any
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 20.0),
                child: Text(state.errorText!, style: AppTextStyles.error),
              ),
          ],
        );
      },
    );
  }
}
