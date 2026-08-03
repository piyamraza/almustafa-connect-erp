import 'package:equatable/equatable.dart';

import '../../domain/entities/user_preferences_entity.dart';

sealed class UserPreferencesState extends Equatable {
  const UserPreferencesState();

  @override
  List<Object?> get props => const [];
}

class UserPreferencesInitial extends UserPreferencesState {
  const UserPreferencesInitial();
}

class UserPreferencesLoading extends UserPreferencesState {
  const UserPreferencesLoading();
}

class UserPreferencesLoaded extends UserPreferencesState {
  const UserPreferencesLoaded({
    required this.preferences,
    this.isSaving = false,
    this.message,
  });

  final UserPreferencesEntity preferences;
  final bool isSaving;
  final String? message;

  @override
  List<Object?> get props => [preferences, isSaving, message];
}

class UserPreferencesFailure extends UserPreferencesState {
  const UserPreferencesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
