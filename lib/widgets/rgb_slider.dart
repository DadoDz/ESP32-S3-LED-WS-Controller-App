import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RgbSlider extends StatelessWidget {
  final String channel; // 'R', 'G', or 'B'
  final int value;
  final Color trackColor;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  const RgbSlider({
    super.key,
    required this.channel,
    required this.value,
    required this.trackColor,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: trackColor.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              channel,
              style: TextStyle(color: trackColor, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                activeTrackColor: trackColor,
                inactiveTrackColor: trackColor.withOpacity(0.15),
                thumbColor: trackColor,
                overlayColor: trackColor.withOpacity(0.18),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 255,
                onChanged: (v) => onChanged(v.round()),
                onChangeEnd: onChangeEnd == null ? null : (v) => onChangeEnd!(v.round()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
