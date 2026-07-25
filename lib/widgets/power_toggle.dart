import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class PowerToggle extends StatelessWidget {
  final bool power;
  final ValueChanged<bool> onChanged;

  const PowerToggle({super.key, required this.power, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            color: power ? AppColors.primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Power',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _Segment(
            label: 'OFF',
            selected: !power,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 6),
          _Segment(
            label: 'ON',
            selected: power,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
