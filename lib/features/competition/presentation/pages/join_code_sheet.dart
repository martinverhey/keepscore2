import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/sheet.dart';
import '../cubit/join_competition_cubit.dart';

class JoinCodeSheet extends StatefulWidget {
  const JoinCodeSheet({super.key, required this.state});

  final JoinCode state;

  @override
  State<JoinCodeSheet> createState() => _JoinCodeSheetState();
}

class _JoinCodeSheetState extends State<JoinCodeSheet> {
  late final _code = TextEditingController(text: widget.state.code);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<JoinCompetitionCubit>();

    return Sheet(
      title: context.l10n.joinTitle,
      subtitle: context.l10n.joinSubtitle,
      content: _content(context, cubit),
      primaryButton: AdaptiveButton(
        label: context.l10n.joinLookUp,
        busy: widget.state.busy,
        onPressed: widget.state.canLookUp ? cubit.lookUp : null,
      ),
      secondaryButton: AdaptiveButton(
        label: context.l10n.commonCancel,
        kind: AdaptiveButtonKind.plain,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _content(BuildContext context, JoinCompetitionCubit cubit) {
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AdaptiveTextField(
          label: context.l10n.competitionJoinCodeLabel,
          controller: _code,
          autofocus: true,
          enabled: !state.busy,
          maxLength: 8,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\s-]')),
            TextInputFormatter.withFunction(
              (_, next) => next.copyWith(text: next.text.toUpperCase()),
            ),
          ],
          errorText: state.code.isEmpty || state.codeIsValid
              ? null
              : context.l10n.joinCodeInvalid,
          onChanged: cubit.codeChanged,
          onSubmitted: (_) => cubit.lookUp(),
        ),
        if (state.failure case final failure?) FailureText(failure),
      ],
    );
  }
}
