import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../competition/presentation/widgets/home_sidebar_competition.dart';
import '../../../competition/presentation/widgets/sidebar.dart';
import '../../../competition/presentation/widgets/sidebar_section.enum.dart';
import '../../domain/language_preference.enum.dart';
import '../cubit/language_cubit.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key, this.sidebarCompetition});

  final HomeSidebarCompetition? sidebarCompetition;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LanguageCubit>();

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        setPageTitle(context, context.l10n.settingsLanguageTitle);

        return Sidebar(
          competition: sidebarCompetition,
          current: SidebarSection.language,
          child: AdaptiveScaffold(
            title: context.l10n.settingsLanguageTitle,
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AdaptiveSegmented<LanguagePreference>(
                value: state.preference,
                onChanged: cubit.select,
                segments: {
                  LanguagePreference.system: context.l10n.languageOptionSystem,
                  LanguagePreference.english:
                      context.l10n.languageOptionEnglish,
                  LanguagePreference.dutch: context.l10n.languageOptionDutch,
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
