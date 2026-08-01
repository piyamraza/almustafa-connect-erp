import 'package:equatable/equatable.dart';

class ParentTimelineItemEntity extends Equatable {
  const ParentTimelineItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime eventDate;
  final String status;

  @override
  List<Object> get props => [
    id,
    title,
    description,
    category,
    eventDate,
    status,
  ];
}
