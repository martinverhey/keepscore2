import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/build_context.extension.dart';
import '../core/extensions/language_preference.extension.dart';
import '../core/extensions/theme_preference.extension.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/adaptive/app_platform.dart';
import '../features/auth/presentation/cubit/auth_bloc.dart';
import '../features/competition/presentation/cubit/competition_cubit.dart';
import '../features/competition/presentation/cubit/competition_list_cubit.dart';
import '../features/match/presentation/cubit/game_type_filter_cubit.dart';
import '../features/settings/domain/theme_preference.enum.dart';
import '../features/settings/presentation/cubit/language_cubit.dart';
import '../features/settings/presentation/cubit/theme_cubit.dart';
import '../l10n/app_localizations.dart';
import 'dependency_injection/injector.dart';
import 'router/app_router.dart';

class KeepScoreApp extends StatefulWidget {
  const KeepScoreApp({super.key});

  @override
  State<KeepScoreApp> createState() => _KeepScoreAppState();
}

class _KeepScoreAppState extends State<KeepScoreApp> {
  late final AuthBloc _authBloc = getIt<AuthBloc>();
  late final ThemeCubit _themeCubit = getIt<ThemeCubit>();
  late final LanguageCubit _languageCubit = getIt<LanguageCubit>();
  late final GameTypeFilterCubit _gameTypeFilterCubit =
      getIt<GameTypeFilterCubit>();
  late final CompetitionCubit _competitionCubit = getIt<CompetitionCubit>();
  late final CompetitionListCubit _competitionListCubit =
      getIt<CompetitionListCubit>();
  late final GoRouter _router = createRouter(_authBloc);

  static const _localizationsDelegates = <LocalizationsDelegate<Object?>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<LanguageCubit>.value(value: _languageCubit),
        BlocProvider<GameTypeFilterCubit>.value(value: _gameTypeFilterCubit),
        BlocProvider<CompetitionCubit>.value(value: _competitionCubit),
        BlocProvider<CompetitionListCubit>.value(
          value: _competitionListCubit,
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) =>
            BlocBuilder<LanguageCubit, LanguageState>(
              builder: (context, languageState) => _buildApp(
                context,
                themeState.preference,
                languageState.preference.locale,
              ),
            ),
      ),
    );
  }

  Widget _buildApp(
    BuildContext context,
    ThemePreference preference,
    Locale? locale,
  ) {
    if (AppPlatform.useCupertino) {
      return CupertinoApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.cupertino(preference.brightness),
        routerConfig: _router,
        locale: locale,
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Material(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
      );
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.material(Brightness.light),
      darkTheme: AppTheme.material(Brightness.dark),
      themeMode: preference.mode,
      routerConfig: _router,
      locale: locale,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
