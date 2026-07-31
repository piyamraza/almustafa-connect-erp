import '../../domain/entities/timetable_period_entity.dart';

class TimetablePeriodModel extends TimetablePeriodEntity {
  const TimetablePeriodModel({
    required super.id,
    required super.label,
    required super.order,
    required super.startMinutes,
    required super.endMinutes,
    required super.type,
  });

  factory TimetablePeriodModel.fromMap(Map<String, dynamic> map) {
    return TimetablePeriodModel(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
      type: _periodType(map['type']),
    );
  }

  factory TimetablePeriodModel.fromEntity(TimetablePeriodEntity value) {
    return TimetablePeriodModel(
      id: value.id,
      label: value.label,
      order: value.order,
      startMinutes: value.startMinutes,
      endMinutes: value.endMinutes,
      type: value.type,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'order': order,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'type': type.name,
  };

  static TimetablePeriodType _periodType(Object? value) {
    final name = value?.toString();
    for (final type in TimetablePeriodType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return TimetablePeriodType.teaching;
  }
}
