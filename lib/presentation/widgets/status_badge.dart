import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isOutline;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.isOutline = false,
  });

  factory StatusBadge.confidence(String level) {
    Color badgeColor;
    switch (level.toUpperCase()) {
      case 'HIGH':
      case 'HIGH CONFIDENCE':
        badgeColor = AppColors.confidenceHigh;
        break;
      case 'MEDIUM':
      case 'MEDIUM CONFIDENCE':
        badgeColor = AppColors.confidenceMedium;
        break;
      default:
        badgeColor = AppColors.confidenceLow;
    }
    return StatusBadge(label: level.toUpperCase(), color: badgeColor);
  }

  factory StatusBadge.risk(String risk) {
    Color badgeColor;
    switch (risk.toUpperCase()) {
      case 'LOW':
        badgeColor = AppColors.success;
        break;
      case 'MEDIUM':
        badgeColor = AppColors.warning;
        break;
      default:
        badgeColor = AppColors.danger;
    }
    return StatusBadge(label: '$risk RISK', color: badgeColor);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : effectiveColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
