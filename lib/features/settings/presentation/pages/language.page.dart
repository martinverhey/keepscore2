import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/build_context.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/nav_row.dart';
import '../../../../core/widgets/page_title.dart';
import '../../domain/language_preference.enum.dart';
import '../cubit/language_cubit.dart';

const double _markSize = 24;

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        setPageTitle(context, context.l10n.settingsLanguageTitle);

        return AdaptiveScaffold(
          title: context.l10n.settingsLanguageTitle,
          body: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _options(context, state.preference),
            ),
          ),
        );
      },
    );
  }

  Widget _options(BuildContext context, LanguagePreference selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final preference in LanguagePreference.values)
          NavRow(
            label: _label(context, preference),
            onTap: () => context.read<LanguageCubit>().select(preference),
            trailing: _mark(context, preference == selected),
          ),
      ],
    );
  }

  Widget _mark(BuildContext context, bool selected) {
    return SizedBox(
      width: _markSize,
      height: _markSize,
      child: selected
          ? AdaptiveIcon(
              AdaptiveGlyph.check,
              color: AdaptiveColors.accent(context),
              size: _markSize,
            )
          : null,
    );
  }

  String _label(BuildContext context, LanguagePreference preference) =>
      switch (preference) {
        LanguagePreference.system => context.l10n.languageOptionSystem,
        LanguagePreference.english => context.l10n.languageOptionEnglish,
        LanguagePreference.dutch => context.l10n.languageOptionDutch,
      };
}
