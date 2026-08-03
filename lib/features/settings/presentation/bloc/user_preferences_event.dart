import 'package:equatable/equatable.dart';

import '../../domain/entities/user_preferences_entity.dart';

sealed class UserPreferencesEvent extends Equatable {
  const UserPreferencesEvent();

  @override
  List<Object?> get props => const [];
}

class LoadUserPreferences extends UserPreferencesEvent {
  const LoadUserPreferences(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class SaveUserPreferencesRequested extends UserPreferencesEvent {
  const SaveUserPreferencesRequested(this.preferences);

  final UserPreferencesEntity preferences;

  @override
  List<Object?> get props => [preferences];
}
