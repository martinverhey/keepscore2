import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/copyable.dart';
import '../../../../core/widgets/tag.dart';

class JoinCodeTag extends StatelessWidget {
  const JoinCodeTag({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Copyable(
      text: code,
      builder: (context, copied, copy) => AdaptiveTappable(
        onTap: copy,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Tag(
          copied ? context.l10n.competitionCodeCopied : code,
          color: AdaptiveColors.accent(context),
          style: TagStyle.code,
        ),
      ),
    );
  }
}
