import 'package:flutter/material.dart';

import '../models/patient_case.dart';

class OutcomeStyle {
  final Color bar;
  final List<Color> gradient;
  final Color text;
  final Color bg;
  final Color border;
  final IconData icon;

  const OutcomeStyle({
    required this.bar,
    required this.gradient,
    required this.text,
    required this.bg,
    required this.border,
    required this.icon,
  });
}

const Map<HealingOutcome, OutcomeStyle> kOutcomeStyles = {
  HealingOutcome.poor: OutcomeStyle(
    bar: Color(0xFFEF4444),
    gradient: [Color(0xFFF87171), Color(0xFFEF4444)],
    text: Color(0xFFB91C1C),
    bg: Color(0xFFFEF2F2),
    border: Color(0xFFFECACA),
    icon: Icons.error_outline_rounded,
  ),
  HealingOutcome.fair: OutcomeStyle(
    bar: Color(0xFFF59E0B),
    gradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    text: Color(0xFFB45309),
    bg: Color(0xFFFFFBEB),
    border: Color(0xFFFDE68A),
    icon: Icons.info_outline_rounded,
  ),
  HealingOutcome.good: OutcomeStyle(
    bar: Color(0xFF10B981),
    gradient: [Color(0xFF34D399), Color(0xFF10B981)],
    text: Color(0xFF047857),
    bg: Color(0xFFECFDF5),
    border: Color(0xFFA7F3D0),
    icon: Icons.check_circle_outline_rounded,
  ),
  HealingOutcome.excellent: OutcomeStyle(
    bar: Color(0xFF059669),
    gradient: [Color(0xFF10B981), Color(0xFF047857)],
    text: Color(0xFF065F46),
    bg: Color(0xFFD1FAE5),
    border: Color(0xFF6EE7B7),
    icon: Icons.verified_outlined,
  ),
};

String pctText(double n) => '${(n * 100).toStringAsFixed(1)}%';

