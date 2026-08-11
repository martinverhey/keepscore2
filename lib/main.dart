import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/dependency_injection/injector.dart';
import 'core/config/env.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
  await configureDependencies();
  await getIt<ThemeCubit>().load();

  runApp(const KeepScoreApp());
}
