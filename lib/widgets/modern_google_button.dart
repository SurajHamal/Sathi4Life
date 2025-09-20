// modern_google_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModernGoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const ModernGoogleButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: SvgPicture.asset(
        'assets/google_signIn_logo.svg', // Ensure this is a vector or modern PNG
        height: 24,
        width: 24,
      ),
      label: Text(
        'Continue with Google',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.deepOrange, width: 1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
