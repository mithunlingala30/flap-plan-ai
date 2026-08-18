import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../theme/app_theme.dart';

class DriversPanel extends StatelessWidget {
  final List<FeatureDriver> drivers;

  const DriversPanel({super.key, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < drivers.length; i++) ...[
          _DriverCard(driver: drivers[i], index: i),
          if (i != drivers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DriverCard extends StatefulWidget {
  final FeatureDriver driver;
  final int index;

  const _DriverCard({required this.driver, required this.index});

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isNeg = widget.driver.worse;
    final barColor = isNeg ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final bgColor = isNeg ? const Color(0xFFFFF1F1) : const Color(0xFFEEFDF5);
    final borderColor = isNeg ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0);
    final labelColor = isNeg ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    final gradColors = isNeg
        ? [const Color(0xFFFCA5A5), const Color(0xFFEF4444)]
        : [const Color(0xFF6EE7B7), const Color(0xFF10B981)];

    final rankColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFF78716C),
    ];
    final rankBg = [
      const Color(0xFFFFFBEB),
      const Color(0xFFF1F5F9),
      const Color(0xFFFAF8F5),
    ];

    final rankIdx = widget.index.clamp(0, 2);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? borderColor : AppColors.gray100,
            width: 1.2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: barColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank badge
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankBg[rankIdx],
                shape: BoxShape.circle,
                border: Border.all(color: rankColors[rankIdx].withValues(alpha: 0.4)),
              ),
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  color: rankColors[rankIdx],
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature name + direction badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.driver.feature,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNeg
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 11,
                              color: labelColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isNeg ? 'Lowers' : 'Raises',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Importance bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 5,
                      color: AppColors.gray100,
                      child: LayoutBuilder(builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth *
                              widget.driver.importance.clamp(0, 1),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradColors),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Detail text
                  Text(
                    widget.driver.detail,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.gray500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
