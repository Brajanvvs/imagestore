import 'package:flutter/material.dart';

import '../core/theme.dart';

class FormBanner extends StatelessWidget {
  const FormBanner({super.key, required this.message, this.tone = FormBannerTone.error});

  final String message;
  final FormBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final danger = tone == FormBannerTone.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFDECEC) : const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger ? const Color(0xFFF3C4C4) : const Color(0xFFC9E4D4)),
      ),
      child: Text(
        message,
        style: TextStyle(color: danger ? AppColors.danger : AppColors.success, height: 1.35),
      ),
    );
  }
}

enum FormBannerTone { error, success }
