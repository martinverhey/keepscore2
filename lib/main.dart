import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/dependency_injection/injector.dart';
import 'core/config/env.dart';
import 'features/match/presentation/cubit/game_type_filter_cubit.dart';
import 'features/settings/presentation/cubit/language_cubit.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Env.load();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  await configureDependencies();
  await getIt<ThemeCubit>().load();
  await getIt<LanguageCubit>().load();
  await getIt<GameTypeFilterCubit>().load();

  runApp(const KeepScoreApp());
}
