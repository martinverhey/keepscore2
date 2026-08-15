import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/extensions/build_context_l10n.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/adaptive/app_platform.dart';
import '../features/auth/presentation/cubit/auth_bloc.dart';
import '../features/match/presentation/cubit/game_type_filter_cubit.dart';
import '../features/settings/domain/theme_preference.enum.dart';
import '../features/settings/presentation/cubit/theme_cubit.dart';
import '../l10n/app_localizations.dart';
import 'dependency_injection/injector.dart';
import 'router/app_router.dart';

extension on ThemePreference {
  ThemeMode get mode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  Brightness? get brightnessOverride => switch (this) {
    ThemePreference.system => null,
    ThemePreference.light => Brightness.light,
    ThemePreference.dark => Brightness.dark,
  };
}

class KeepScoreApp extends StatefulWidget {
  const KeepScoreApp({super.key});

  @override
  State<KeepScoreApp> createState() => _KeepScoreAppState();
}

class _KeepScoreAppState extends State<KeepScoreApp> {
  late final AuthBloc _authBloc = getIt<AuthBloc>();
  late final ThemeCubit _themeCubit = getIt<ThemeCubit>();
  late final GameTypeFilterCubit _gameTypeFilterCubit =
      getIt<GameTypeFilterCubit>();
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
        BlocProvider<GameTypeFilterCubit>.value(value: _gameTypeFilterCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) =>
            _buildApp(context, themeState.preference),
      ),
    );
  }

  Widget _buildApp(BuildContext context, ThemePreference preference) {
    if (AppPlatform.useCupertino) {
      final brightness =
          preference.brightnessOverride ??
          MediaQuery.platformBrightnessOf(context);
      return CupertinoApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: AppTheme.cupertino(brightness),
        routerConfig: _router,
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
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
