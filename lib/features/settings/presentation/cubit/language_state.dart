import 'package:equatable/equatable.dart';

import '../../domain/language_preference.enum.dart';

class LanguageState extends Equatable {
  const LanguageState({this.preference = LanguagePreference.system});

  final LanguagePreference preference;

  @override
  List<Object?> get props => [preference];
}
