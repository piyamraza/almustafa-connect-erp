import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/academic_class_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import '../../domain/services/academic_reference_resolver.dart';

class AcademicReferenceLabel extends StatefulWidget {
  const AcademicReferenceLabel({
    required this.classReference,
    required this.sectionReference,
    this.separator = ' / ',
    this.style,
    super.key,
  });

  final String classReference;
  final String sectionReference;
  final String separator;
  final TextStyle? style;

  @override
  State<AcademicReferenceLabel> createState() =>
      _AcademicReferenceLabelState();
}

class _AcademicReferenceLabelState extends State<AcademicReferenceLabel> {
  late Future<AcademicReferenceResolver> _resolver;

  @override
  void initState() {
    super.initState();
    _resolver = _load();
  }

  Future<AcademicReferenceResolver> _load() async {
    final repository = sl<AcademicStructureRepository>();
    final values = await Future.wait<Object>([
      repository.getClasses(),
      repository.getSections(),
    ]);
    return AcademicReferenceResolver(
      classes: values[0] as List<AcademicClassEntity>,
      sections: values[1] as List<SectionEntity>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AcademicReferenceResolver>(
      future: _resolver,
      builder: (context, snapshot) {
        final resolver = snapshot.data;
        final className = resolver?.className(widget.classReference) ??
            widget.classReference;
        final sectionName = resolver?.sectionName(widget.sectionReference) ??
            widget.sectionReference;
        return Text(
          '$className${widget.separator}$sectionName',
          style: widget.style,
        );
      },
    );
  }
}
