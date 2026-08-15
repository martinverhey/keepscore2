import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context_l10n.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../domain/theme_preference.enum.dart';
import '../cubit/theme_cubit.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit>();

    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return AdaptiveScaffold(
          title: context.l10n.settingsThemeTitle,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AdaptiveSegmented<ThemePreference>(
              value: state.preference,
              onChanged: cubit.select,
              segments: {
                ThemePreference.system: context.l10n.themeOptionSystem,
                ThemePreference.light: context.l10n.themeOptionLight,
                ThemePreference.dark: context.l10n.themeOptionDark,
              },
            ),
          ),
        );
      },
    );
  }
}
