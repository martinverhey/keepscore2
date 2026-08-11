import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_messages.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/competition.dart';
import '../cubit/create_competition_cubit.dart';

class CreateCompetitionPage extends StatefulWidget {
  const CreateCompetitionPage({super.key});

  @override
  State<CreateCompetitionPage> createState() => _CreateCompetitionPageState();
}

class _CreateCompetitionPageState extends State<CreateCompetitionPage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CreateCompetitionCubit, CreateCompetitionState>(
      listenWhen: (previous, current) => current.created != null,
      listener: (context, state) {
        context.pop();
        context.push('/competition/${state.created!.id}');
      },
      builder: (context, state) {
        final cubit = context.read<CreateCompetitionCubit>();

        return AdaptiveScaffold(
          title: l10n.competitionsCreate,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdaptiveTextField(
                  label: l10n.competitionNameLabel,
                  controller: _nameController,
                  autofocus: true,
                  enabled: !state.busy,
                  maxLength: 60,
                  textInputAction: TextInputAction.done,
                  errorText: state.name.isEmpty || state.nameIsValid
                      ? null
                      : l10n.competitionNameTooShort,
                  onChanged: cubit.nameChanged,
                  onSubmitted: (_) => cubit.submit(),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  l10n.competitionSeasonLengthLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                AdaptiveSegmented<SeasonLength>(
                  value: state.seasonLength,
                  onChanged: cubit.seasonLengthChanged,
                  segments: {
                    SeasonLength.monthly: l10n.seasonMonthly,
                    SeasonLength.quarterly: l10n.seasonQuarterly,
                    SeasonLength.yearly: l10n.seasonYearly,
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.competitionSeasonExplainer(1000),
                  style: const TextStyle(
                    color: AppColors.neutral,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                AdaptiveButton(
                  label: l10n.competitionCreateSubmit,
                  busy: state.busy,
                  onPressed: state.canSubmit ? cubit.submit : null,
                ),

                if (state.failure != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      state.failure!.localized(l10n),
                      style: const TextStyle(color: AppColors.negative),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
