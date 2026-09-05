import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef CopyableBuilder =
    Widget Function(BuildContext context, bool copied, VoidCallback copy);

class Copyable extends StatefulWidget {
  const Copyable({super.key, required this.text, required this.builder});

  final String text;
  final CopyableBuilder builder;

  @override
  State<Copyable> createState() => _CopyableState();
}

class _CopyableState extends State<Copyable> {
  static const Duration _confirmation = Duration(seconds: 2);

  Timer? _resetCopied;
  bool _copied = false;

  @override
  void dispose() {
    _resetCopied?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _copied, _copy);

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetCopied?.cancel();
    _resetCopied = Timer(_confirmation, () {
      if (mounted) setState(() => _copied = false);
    });
  }
}
