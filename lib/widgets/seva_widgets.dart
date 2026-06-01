import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class SevaAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bgColor;

  const SevaAvatar({super.key, required this.initials, this.size = 48, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bgColor ?? SevaColors.primaryLight,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(initials,
          style: GoogleFonts.inter(
            fontSize: size * 0.36, fontWeight: FontWeight.w700,
            color: bgColor != null ? Colors.white : SevaColors.primary,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'stable': return SevaColors.green;
      case 'attention': return SevaColors.amber;
      case 'critical': return SevaColors.red;
      case 'completed': return SevaColors.green;
      case 'active': return SevaColors.primary;
      case 'pending': return SevaColors.textTertiary;
      default: return SevaColors.textTertiary;
    }
  }

  Color get _bg {
    switch (status.toLowerCase()) {
      case 'stable': return SevaColors.greenLight;
      case 'attention': return SevaColors.amberLight;
      case 'critical': return SevaColors.redLight;
      case 'completed': return SevaColors.greenLight;
      case 'active': return SevaColors.primaryLight;
      case 'pending': return SevaColors.divider;
      default: return SevaColors.divider;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(status[0].toUpperCase() + status.substring(1),
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
      ]),
    );
  }
}

class VitalCard extends StatelessWidget {
  final String label, value, subtitle;
  final IconData icon;
  final Color color, bgColor;

  const VitalCard({super.key, required this.label, required this.value,
    required this.subtitle, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.9))),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}

class SevaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const SevaCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SevaColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      ),
    );
  }
}

class GradientHeader extends StatelessWidget {
  final Widget child;

  const GradientHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: SevaColors.sevaGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final IconData? icon;

  const SectionTitle({super.key, required this.title, this.trailing, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: SevaColors.primary),
        const SizedBox(width: 8),
      ],
      Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: SevaColors.textPrimary)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]);
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final VoidCallback? onTap;

  const QuickActionButton({super.key, required this.icon, required this.label,
    required this.color, required this.bgColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: SevaColors.textSecondary),
          textAlign: TextAlign.center),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: SevaColors.textTertiary),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: SevaColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
