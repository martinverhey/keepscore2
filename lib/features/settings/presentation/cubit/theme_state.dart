import 'package:equatable/equatable.dart';

import '../../domain/theme_preference.dart';

class ThemeState extends Equatable {
  const ThemeState({this.preference = ThemePreference.system});

  final ThemePreference preference;

  @override
  List<Object?> get props => [preference];
}
