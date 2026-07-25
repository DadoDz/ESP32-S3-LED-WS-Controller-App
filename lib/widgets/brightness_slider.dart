import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrightnessSlider extends StatelessWidget {
  final int value; // 0-100
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  const BrightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brightnessAccent.withOpacity(0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.light_mode_rounded, color: AppColors.brightnessAccent, size: 15),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: AppColors.brightnessAccent,
              inactiveTrackColor: AppColors.brightnessAccent.withOpacity(0.15),
              thumbColor: AppColors.brightnessAccent,
              overlayColor: AppColors.brightnessAccent.withOpacity(0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 100,
              onChanged: (v) => onChanged(v.round()),
              onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
