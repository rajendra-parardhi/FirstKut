import 'package:firstkut/core/theme/app_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;

  const GradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textWhite),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}