import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_tokens.dart';

const double _reticleFactor = 0.6;
const double _reticleStroke = 2;

class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onCode,
    required this.unavailableMessage,
  });

  final ValueChanged<String> onCode;
  final String unavailableMessage;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: ColoredBox(
          color: AppColors.neutralSurface,
          child: _unavailable ? _unavailableMessage() : _preview(),
        ),
      ),
    );
  }

  Widget _preview() {
    return MobileScanner(
      controller: _controller,
      onDetect: _detected,
      overlayBuilder: (_, _) => _reticle(),
      errorBuilder: (_, _) => _unavailableMessage(),
      placeholderBuilder: (_) => const SizedBox.shrink(),
    );
  }

  Widget _reticle() {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: _reticleFactor,
          heightFactor: _reticleFactor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white, width: _reticleStroke),
              borderRadius: AppRadius.card,
            ),
          ),
        ),
      ),
    );
  }

  Widget _unavailableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          widget.unavailableMessage,
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _start() async {
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) setState(() => _unavailable = true);
    }
  }

  void _detected(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue case final value?) widget.onCode(value);
    }
  }
}
