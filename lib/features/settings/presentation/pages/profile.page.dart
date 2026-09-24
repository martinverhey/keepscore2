import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/config/app_version.dart';
import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/extensions/player_list.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/nav_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../auth/presentation/cubit/auth_bloc.dart';
import '../../../competition/presentation/cubit/competition_cubit.dart';
import '../../../player/presentation/cubit/players_cubit.dart';
import '../../../player/presentation/pages/player_name_sheet.dart';
import '../../../profile/presentation/widgets/initials_circle.dart';
import '../../domain/theme_preference.enum.dart';
import '../cubit/theme_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const double _avatarSize = 112;

  @override
  Widget build(BuildContext context) {
    setPageTitle(context, context.l10n.profilePageTitle);
    return AdaptiveScaffold(title: context.l10n.profilePageTitle, body: _profile(context));
  }

  Widget _profile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _identity(context),
          const SizedBox(height: AppSpacing.xxl),
          SectionLabel(context.l10n.competitionSettingsSectionSystem),
          _themeRow(context),
          NavRow(
            label: context.l10n.settingsLanguageTitle,
            onTap: () => context.push(Routes.language),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _version(context),
          const SizedBox(height: AppSpacing.sm),
          AdaptiveButton(
            label: context.l10n.authSignOut,
            kind: AdaptiveButtonKind.plain,
            onPressed: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context) {
    final myPlayerId = context.select<CompetitionCubit, String?>((cubit) => cubit.state.myPlayerId);

    return BlocBuilder<PlayersCubit, PlayersState>(
      builder: (context, state) => switch (state) {
        PlayersLoading() => const AdaptiveLoader(),
        PlayersFailed() => const SizedBox.shrink(),
        PlayersReady() => switch (state.players.displayNameFor(myPlayerId)) {
          final name? => _nameBlock(context, state, myPlayerId!, name),
          null => const SizedBox.shrink(),
        },
      },
    );
  }

  Widget _nameBlock(BuildContext context, PlayersReady state, String playerId, String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InitialsCircle(displayName: name, size: _avatarSize),
        const SizedBox(height: AppSpacing.md),
        Text(name, textAlign: TextAlign.center, style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        AdaptiveButton(
          label: context.l10n.profileChangeName,
          kind: AdaptiveButtonKind.tinted,
          expand: false,
          busy: state.busy,
          onPressed: () => _changeName(context, playerId, name),
        ),
        if (state.actionFailure case final failure?)
          FailureText(failure, textAlign: TextAlign.center),
      ],
    );
  }

  Future<void> _changeName(BuildContext context, String playerId, String currentName) async {
    final cubit = context.read<PlayersCubit>();

    final name = await showPlayerNameSheet(
      context,
      title: context.l10n.joinNewPlayerNameTitle,
      submitLabel: context.l10n.commonSave,
      initialValue: currentName,
    );
    if (name == null || name == currentName) return;

    await cubit.rename(playerId, name);
  }

  Widget _themeRow(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) => NavRow(
        label: context.l10n.settingsDarkModeTitle,
        onTap: context.read<ThemeCubit>().toggle,
        trailing: AdaptiveSwitch(
          value: state.preference == ThemePreference.dark,
          onChanged: (_) => context.read<ThemeCubit>().toggle(),
        ),
      ),
    );
  }

  Widget _version(BuildContext context) {
    final label = AppVersion.label;
    if (label == null) return const SizedBox.shrink();

    return Text(
      context.l10n.settingsVersionLabel(label),
      textAlign: TextAlign.center,
      style: AppTypography.captionSmall,
    );
  }
}
