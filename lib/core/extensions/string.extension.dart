extension StringJoinCode on String {
  String get normalizedJoinCode =>
      replaceAll(RegExp(r'[\s-]'), '').toUpperCase();

  bool get isJoinCode => normalizedJoinCode.length == 6;
}

extension StringNumberInput on String {
  int? get wholeNumberValue => int.tryParse(trim());

  double? get decimalValue => double.tryParse(trim().replaceAll(',', '.'));
}
