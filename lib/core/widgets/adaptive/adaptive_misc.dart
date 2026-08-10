import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_platform.dart';

class AdaptiveLoader extends StatelessWidget {
  const AdaptiveLoader({super.key, this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    final child = AppPlatform.useCupertino
        ? const CupertinoActivityIndicator()
        : const CircularProgressIndicator();
    return Center(
      child: size == null
          ? child
          : SizedBox(width: size, height: size, child: child),
    );
  }
}

class AdaptiveRefresh extends StatelessWidget {
  const AdaptiveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.useCupertino) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(child: child),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: child,
      ),
    );
  }
}

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppPlatform.useCupertino
        ? CupertinoSwitch(value: value, onChanged: onChanged)
        : Switch(value: value, onChanged: onChanged);
  }
}

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
