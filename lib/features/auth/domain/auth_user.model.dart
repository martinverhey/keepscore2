import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.isGuest,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final bool isGuest;
  final String? email;
  final String? avatarUrl;

  bool get isRegistered => !isGuest;

  AuthUser copyWith({String? displayName, String? avatarUrl}) => AuthUser(
    id: id,
    displayName: displayName ?? this.displayName,
    isGuest: isGuest,
    email: email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );

  @override
  List<Object?> get props => [id, displayName, isGuest, email, avatarUrl];
}
