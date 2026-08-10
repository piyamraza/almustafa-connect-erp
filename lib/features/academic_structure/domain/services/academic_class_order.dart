import '../entities/academic_class_entity.dart';

int compareAcademicClasses(
  AcademicClassEntity first,
  AcademicClassEntity second,
) => compareAcademicClassNames(first.name, second.name);

int compareAcademicClassNames(String first, String second) {
  final firstKey = _classSortKey(first);
  final secondKey = _classSortKey(second);
  final rankComparison = firstKey.rank.compareTo(secondKey.rank);
  if (rankComparison != 0) {
    return rankComparison;
  }
  return firstKey.normalized.compareTo(secondKey.normalized);
}

_AcademicClassSortKey _classSortKey(String value) {
  final normalized = value.trim().toLowerCase();
  final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

  if (compact == 'playgroup' || compact == 'pg') {
    return _AcademicClassSortKey(0, normalized);
  }
  if (compact == 'nursery' || compact == 'nersery') {
    return _AcademicClassSortKey(1, normalized);
  }
  if (compact == 'prep' || compact == 'preparatory') {
    return _AcademicClassSortKey(2, normalized);
  }

  final numericMatch = RegExp(r'^(?:class|grade)?0*(\d+)$').firstMatch(compact);
  final numericClass = int.tryParse(numericMatch?.group(1) ?? '');
  if (numericClass != null) {
    return _AcademicClassSortKey(100 + numericClass, normalized);
  }

  return _AcademicClassSortKey(10000, normalized);
}

class _AcademicClassSortKey {
  const _AcademicClassSortKey(this.rank, this.normalized);

  final int rank;
  final String normalized;
}
