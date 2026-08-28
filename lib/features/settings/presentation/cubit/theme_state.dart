import 'package:equatable/equatable.dart';

import '../../domain/theme_preference.enum.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.preference});

  final ThemePreference preference;

  @override
  List<Object?> get props => [preference];
}
