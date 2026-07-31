import 'package:equatable/equatable.dart';

enum TimetablePeriodType { teaching, assembly, breakTime }

class TimetablePeriodEntity extends Equatable {
  const TimetablePeriodEntity({
    required this.id,
    required this.label,
    required this.order,
    required this.startMinutes,
    required this.endMinutes,
    required this.type,
  });

  final String id;
  final String label;
  final int order;

  /// Minutes elapsed since midnight.
  final int startMinutes;

  /// Minutes elapsed since midnight.
  final int endMinutes;
  final TimetablePeriodType type;

  int get durationMinutes => endMinutes - startMinutes;

  bool get isTeaching => type == TimetablePeriodType.teaching;

  List<String> get validationErrors {
    final errors = <String>[];

    if (id.trim().isEmpty) {
      errors.add('Period ID is required.');
    }
    if (label.trim().isEmpty) {
      errors.add('Period label is required.');
    }
    if (order < 1) {
      errors.add('Period order must be greater than zero.');
    }
    if (startMinutes < 0 || startMinutes >= 1440) {
      errors.add('Period start time is invalid.');
    }
    if (endMinutes <= 0 || endMinutes > 1440) {
      errors.add('Period end time is invalid.');
    }
    if (endMinutes <= startMinutes) {
      errors.add('Period end time must be after its start time.');
    }

    return errors;
  }

  TimetablePeriodEntity copyWith({
    String? id,
    String? label,
    int? order,
    int? startMinutes,
    int? endMinutes,
    TimetablePeriodType? type,
  }) {
    return TimetablePeriodEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      order: order ?? this.order,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      type: type ?? this.type,
    );
  }

  @override
  List<Object> get props => [id, label, order, startMinutes, endMinutes, type];
}
