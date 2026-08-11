import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveSegmented<T extends Object> extends StatelessWidget {
  const AdaptiveSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.useCupertino) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          onValueChanged: (v) {
            if (v != null) onChanged(v);
          },
          children: {
            for (final entry in segments.entries)
              entry.key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(entry.value),
              ),
          },
        ),
      );
    }
    return SegmentedButton<T>(
      segments: [
        for (final entry in segments.entries)
          ButtonSegment(value: entry.key, label: Text(entry.value)),
      ],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
