import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dependency_injection/injector.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/profile_cubit.dart';
import 'initials_circle.dart';
import 'profile_sheet.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.competitionId,
    required this.playerId,
    required this.displayName,
  });

  final String competitionId;
  final String playerId;
  final String displayName;

  static const double _avatarSize = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => showAdaptiveSheet<void>(
        context,
        builder: (_) => BlocProvider(
          create: (_) => getIt<ProfileCubit>(
            param1: competitionId,
            param2: playerId,
          )..load(),
          child: ProfileSheet(displayName: displayName),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InitialsCircle(displayName: displayName, size: _avatarSize),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              l10n.profileGreeting(displayName),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
