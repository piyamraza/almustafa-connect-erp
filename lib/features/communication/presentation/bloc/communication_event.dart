import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_message_entity.dart';

sealed class CommunicationEvent extends Equatable {
  const CommunicationEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCommunicationDashboard extends CommunicationEvent {
  const LoadCommunicationDashboard();
}

class SaveCommunicationMessageRequested extends CommunicationEvent {
  const SaveCommunicationMessageRequested(this.message);

  final CommunicationMessageEntity message;

  @override
  List<Object?> get props => [message];
}

class DeleteCommunicationMessageRequested extends CommunicationEvent {
  const DeleteCommunicationMessageRequested(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}
