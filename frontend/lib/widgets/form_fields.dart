import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SliderField extends StatelessWidget {
  final String label;
  final String? unit;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? hint;

  const SliderField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unit,
    this.hint,
  });

  int get _decimals => step < 1 ? (step < 0.1 ? 2 : 1) : 0;

  String _fmt(double v) => v.toStringAsFixed(_decimals);

  @override
  Widget build(BuildContext context) {
    final divisions = ((max - min) / step).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.gray700)),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 32,
                  child: TextFormField(
                    key: ValueKey('$label-${_fmt(value)}'),
                    initialValue: _fmt(value),
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray900),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onFieldSubmitted: (text) {
                      final parsed = double.tryParse(text);
                      if (parsed != null) {
                        onChanged(parsed.clamp(min, max));
                      }
                    },
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 6),
                  Text(unit!, style: const TextStyle(fontSize: 11.5, color: AppColors.gray400)),
                ],
              ],
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.brand600,
            inactiveTrackColor: AppColors.gray200,
            thumbColor: AppColors.brand600,
            overlayColor: AppColors.brand100,
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions == 0 ? null : divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_fmt(min)}${unit != null ? ' $unit' : ''}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.gray400)),
              if (hint != null)
                Text(hint!, style: const TextStyle(fontSize: 10.5, color: AppColors.gray400)),
              Text('${_fmt(max)}${unit != null ? ' $unit' : ''}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.gray400)),
            ],
          ),
        ),
      ],
    );
  }
}

class SegmentedField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const SegmentedField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: options.map((opt) {
              final active = opt == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: active ? Border.all(color: AppColors.brand200) : null,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1)),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labelOf(opt),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.brand700 : AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
