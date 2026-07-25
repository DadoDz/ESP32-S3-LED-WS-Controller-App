import 'package:flutter/material.dart';
import '../models/led_state.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ColorPreview extends StatelessWidget {
  final LedState state;
  final VoidCallback? onRandomize;

  const ColorPreview({super.key, required this.state, this.onRandomize});

  String get _hex =>
      '#${state.red.toRadixString(16).padLeft(2, '0')}'
      '${state.green.toRadixString(16).padLeft(2, '0')}'
      '${state.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  @override
  Widget build(BuildContext context) {
    final color = state.power ? state.displayColor : AppColors.surfaceHighlight;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
              boxShadow: state.power
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 28, spreadRadius: 4)]
                  : [],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _hex,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (onRandomize != null)
                      _RandomizeButton(onPressed: onRandomize!),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'RGB ${state.red} · ${state.green} · ${state.blue}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.brightness}% brightness',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RandomizeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RandomizeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shuffle_rounded, color: AppColors.primary, size: 18),
        ),
      ),
    );
  }
}
