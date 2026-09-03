import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_tokens.dart';

class JoinQrImage extends StatelessWidget {
  const JoinQrImage({super.key, required this.code, required this.size});

  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: QrImageView(
          data: code,
          size: size,
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.white,
          semanticsLabel: code,
        ),
      ),
    );
  }
}
