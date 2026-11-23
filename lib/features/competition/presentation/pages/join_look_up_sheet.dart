import 'package:flutter/widgets.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../cubit/join_competition_cubit.dart';

class JoinLookUpSheet extends StatelessWidget {
  const JoinLookUpSheet({super.key, required this.state});

  final JoinCode state;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      title: context.l10n.joinTitle,
      subtitle: state.code,
      content: _content(),
    );
  }

  Widget _content() {
    if (state.failure case final failure?) return FailureText(failure);
    return const AdaptiveLoader();
  }
}
