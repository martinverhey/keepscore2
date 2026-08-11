import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/theme_preference.dart';
import '../cubit/theme_cubit.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ThemeCubit>();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return AdaptiveScaffold(
          title: l10n.settingsThemeTitle,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AdaptiveSegmented<ThemePreference>(
              value: state.preference,
              onChanged: cubit.select,
              segments: {
                ThemePreference.system: l10n.themeOptionSystem,
                ThemePreference.light: l10n.themeOptionLight,
                ThemePreference.dark: l10n.themeOptionDark,
              },
            ),
          ),
        );
      },
    );
  }
}
