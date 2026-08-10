class AuthProviders {
  const AuthProviders({required this.apple, required this.google});
  final bool apple;
  final bool google;

  bool get any => apple || google;
}
