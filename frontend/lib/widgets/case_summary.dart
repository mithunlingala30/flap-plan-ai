import 'package:flutter/material.dart';

import '../models/patient_case.dart';
import '../theme/app_theme.dart';

class CaseSummary extends StatelessWidget {
  final PatientCase c;

  const CaseSummary({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 480;

      // Split into two groups for two-column layout
      final leftItems = [
        _DataItem(icon: Icons.person_outline_rounded, label: 'Age', value: '${c.age} yrs'),
        _DataItem(icon: Icons.wc_rounded, label: 'Sex', value: c.sex.label),
        _DataItem(icon: Icons.monitor_heart_outlined, label: 'Diabetes', value: c.diabetes.label),
        _DataItem(
          icon: Icons.bloodtype_outlined,
          label: 'Bleeding on Probing',
          value: c.bleedingOnProbing.label,
        ),
        _DataItem(
          icon: Icons.medical_services_outlined,
          label: 'Procedure',
          value: c.procedure.label,
          isHighlighted: true,
        ),
      ];

      final rightItems = [
        _DataItem(
          icon: Icons.straighten_rounded,
          label: 'Probing Depth',
          value: '${c.probingDepth.toStringAsFixed(1)} mm',
        ),
        _DataItem(
          icon: Icons.show_chart_rounded,
          label: 'Clinical Attachment Loss',
          value: '${c.clinicalAttachmentLoss.toStringAsFixed(1)} mm',
        ),
        _DataItem(
          icon: Icons.thermostat_rounded,
          label: 'Gingival Index',
          value: c.gingivalIndex.toStringAsFixed(2),
        ),
        _DataItem(
          icon: Icons.lens_blur_rounded,
          label: 'Plaque Index',
          value: c.plaqueIndex.toStringAsFixed(2),
        ),
      ];

      if (!wide) {
        return Column(
          children: [
            ...leftItems.map((e) => e.build()),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(thickness: 0.5, color: AppColors.gray200),
            ),
            ...rightItems.map((e) => e.build()),
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: leftItems.map((e) => e.build()).toList())),
          const SizedBox(width: 20),
          Container(width: 1, color: AppColors.gray100),
          const SizedBox(width: 20),
          Expanded(child: Column(children: rightItems.map((e) => e.build()).toList())),
        ],
      );
    });
  }
}

class _DataItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const _DataItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  Widget build() => _DataItemWidget(
        icon: icon,
        label: label,
        value: value,
        isHighlighted: isHighlighted,
      );
}

class _DataItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isHighlighted;

  const _DataItemWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray100.withValues(alpha: 0.8), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isHighlighted ? AppColors.brand50 : AppColors.gray50,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isHighlighted ? AppColors.brand600 : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.gray500,
                fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.brand700 : AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}
