import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StatTone { brand, green, red, gray }

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final StatTone tone;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.sub,
    this.tone = StatTone.brand,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      StatTone.brand => (AppColors.brand50, AppColors.brand600),
      StatTone.green => (AppColors.greenBg, AppColors.green),
      StatTone.red => (AppColors.redBg, AppColors.red),
      StatTone.gray => (AppColors.gray100, AppColors.gray600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: fg),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: AppColors.gray400),
            ),
          ],
        ],
      ),
    );
  }
}
