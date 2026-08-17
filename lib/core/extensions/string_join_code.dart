extension StringJoinCode on String {
  String get normalizedJoinCode => replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
}
