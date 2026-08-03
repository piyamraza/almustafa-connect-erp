import 'package:equatable/equatable.dart';

class CommunicationDeliverySummaryEntity extends Equatable {
  const CommunicationDeliverySummaryEntity({
    required this.total,
    required this.sent,
    required this.delivered,
    required this.read,
    required this.failed,
    required this.scheduled,
  });

  final int total;
  final int sent;
  final int delivered;
  final int read;
  final int failed;
  final int scheduled;

  double get deliveryRate => sent == 0 ? 0 : delivered / sent;

  double get readRate => delivered == 0 ? 0 : read / delivered;

  @override
  List<Object?> get props => [total, sent, delivered, read, failed, scheduled];
}
