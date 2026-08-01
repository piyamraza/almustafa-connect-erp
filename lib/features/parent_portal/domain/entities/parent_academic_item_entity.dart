import 'package:equatable/equatable.dart';

enum ParentAcademicModule {
  attendance,
  timetable,
  homework,
  dateSheet,
  results,
}

class ParentAcademicItemEntity extends Equatable {
  const ParentAcademicItemEntity({
    required this.id,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.details,
  });

  final String id;
  final ParentAcademicModule module;
  final String title;
  final String subtitle;
  final DateTime? date;
  final String status;
  final Map<String, String> details;

  @override
  List<Object?> get props => [
    id,
    module,
    title,
    subtitle,
    date,
    status,
    details,
  ];
}
