import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../cubit/join_competition_cubit.dart';
import 'join_code_sheet.dart';
import 'join_confirm_sheet.dart';
import 'join_look_up_sheet.dart';
import 'join_result.dart';

Future<JoinResult?> showJoinCompetitionSheet(
  BuildContext context, {
  String? code,
}) {
  return showAdaptiveSheet<JoinResult>(
    context,
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = getIt<JoinCompetitionCubit>();
        if (code != null) cubit.lookUpCode(code);
        return cubit;
      },
      child: JoinCompetitionSheet(isScanned: code != null),
    ),
  );
}

class JoinCompetitionSheet extends StatelessWidget {
  const JoinCompetitionSheet({super.key, required this.isScanned});

  final bool isScanned;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JoinCompetitionCubit, JoinCompetitionState>(
      listenWhen: (previous, current) =>
          current is JoinConfirm && current.joined != null,
      listener: (context, state) => Navigator.of(
        context,
      ).pop(JoinResult.joined((state as JoinConfirm).preview.competitionId)),
      builder: (context, state) => switch (state) {
        JoinCode code when isScanned => JoinLookUpSheet(state: code),
        JoinCode code => JoinCodeSheet(state: code),
        JoinConfirm confirm => JoinConfirmSheet(
          state: confirm,
          isScanned: isScanned,
        ),
      },
    );
  }
}
