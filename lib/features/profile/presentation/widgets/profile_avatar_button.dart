import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
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

  @override
  Widget build(BuildContext context) {
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
      child: InitialsCircle(displayName: displayName),
    );
  }
}
