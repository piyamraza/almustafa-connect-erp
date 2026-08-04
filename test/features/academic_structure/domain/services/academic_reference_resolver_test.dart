import 'package:flutter_test/flutter_test.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/entities/academic_class_entity.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/entities/section_entity.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_reference_resolver.dart';
import 'package:almustafa_connect_erp/features/academic_structure/data/models/academic_class_model.dart';
import 'package:almustafa_connect_erp/features/academic_structure/data/models/section_model.dart';

void main() {
  final now = DateTime(2026);
  final resolver = AcademicReferenceResolver(
    classes: [
      AcademicClassEntity(
        id: 'class_doc_3',
        name: '3',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      AcademicClassEntity(
        id: 'class_doc_2',
        name: '2',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    sections: [
      SectionEntity(
        id: 'section_doc_3_a',
        classId: 'class_doc_3',
        name: 'A',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      SectionEntity(
        id: 'section_doc_2_a',
        classId: 'class_doc_2',
        name: 'A',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );

  test('resolves legacy display names to canonical document IDs', () {
    final scope = resolver.resolve(classReference: '3', sectionReference: 'A');

    expect(scope.classId, 'class_doc_3');
    expect(scope.sectionId, 'section_doc_3_a');
    expect(scope.matches(classId: '3', sectionId: 'A'), isTrue);
    expect(
      scope.matches(classId: 'class_doc_3', sectionId: 'section_doc_3_a'),
      isTrue,
    );
  });

  test('selected Class 3 scope never matches Class 2 students', () {
    final scope = resolver.resolve(
      classReference: 'class_doc_3',
      sectionReference: 'section_doc_3_a',
    );

    expect(
      scope.matches(classId: 'class_doc_2', sectionId: 'section_doc_2_a'),
      isFalse,
    );
    expect(scope.matches(classId: '2', sectionId: 'A'), isFalse);
  });

  test('normalizes hidden and repeated whitespace in display references', () {
    final scope = resolver.resolve(
      classReference: ' 3\u200B ',
      sectionReference: ' A ',
    );

    expect(scope.classId, 'class_doc_3');
    expect(scope.sectionId, 'section_doc_3_a');
  });

  test('accepts model-typed lists returned by Firestore repositories', () {
    final modelResolver = AcademicReferenceResolver(
      classes: [
        AcademicClassModel(
          id: 'class_doc_3',
          name: '3',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sections: [
        SectionModel(
          id: 'section_doc_3_a',
          classId: 'class_doc_3',
          name: 'A',
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final scope = modelResolver.resolve(
      classReference: 'class_doc_3',
      sectionReference: 'section_doc_3_a',
    );

    expect(scope.className, '3');
    expect(scope.sectionName, 'A');
  });
}
