import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sorts early years before numeric classes', () {
    final values = ['8', 'Nursery', '2', 'Prep', 'Play Group', '1'];

    values.sort(compareAcademicClassNames);

    expect(values, ['Play Group', 'Nursery', 'Prep', '1', '2', '8']);
  });

  test('supports alternate spellings and class prefixes', () {
    final values = ['Class 10', 'Grade 2', 'Nersery', 'PG', 'Preparatory'];

    values.sort(compareAcademicClassNames);

    expect(values, ['PG', 'Nersery', 'Preparatory', 'Grade 2', 'Class 10']);
  });

  test('puts unknown class names last in alphabetical order', () {
    final values = ['Senior', '1', 'Junior'];

    values.sort(compareAcademicClassNames);

    expect(values, ['1', 'Junior', 'Senior']);
  });
}
