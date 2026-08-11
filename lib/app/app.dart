import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/adaptive/app_platform.dart';
import '../features/auth/presentation/cubit/auth_bloc.dart';
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
  late final GoRouter _router = createRouter(_authBloc);

  static const _localizationsDelegates = <LocalizationsDelegate<Object?>>[
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: _buildApp(brightness),
    );
  }

  Widget _buildApp(Brightness brightness) {
    if (AppPlatform.useCupertino) {
      return CupertinoApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.cupertino(brightness),
        routerConfig: _router,
        localizationsDelegates: _localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Material(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
      );
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.material(Brightness.light),
      darkTheme: AppTheme.material(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
