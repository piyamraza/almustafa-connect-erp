import '../entities/document_element_entity.dart';
import '../entities/document_page_entity.dart';
import '../entities/document_template_entity.dart';

class DocumentTemplateValidationResult {
  const DocumentTemplateValidationResult({
    required this.errors,
    required this.warnings,
  });

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;

  bool get hasWarnings => warnings.isNotEmpty;
}

class DocumentTemplateValidator {
  const DocumentTemplateValidator();

  DocumentTemplateValidationResult validate(
    DocumentTemplateEntity template,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    if (template.id.trim().isEmpty) {
      errors.add(
        'Template id is required.',
      );
    }

    if (template.name.trim().isEmpty) {
      errors.add(
        'Template name is required.',
      );
    }

    if (template.layoutKey.trim().isEmpty) {
      errors.add(
        'Template layout key is required.',
      );
    }

    if (template.version <= 0) {
      errors.add(
        'Template version must be greater than zero.',
      );
    }

    if (template.pages.isEmpty) {
      errors.add(
        'Template must contain at least one page.',
      );
    }

    final pageIds = <String>{};
    final pageNumbers = <int>{};

    for (final page in template.pages) {
      _validatePage(
        page,
        errors,
        warnings,
      );

      if (!pageIds.add(page.id)) {
        errors.add(
          'Duplicate page id: ${page.id}.',
        );
      }

      if (!pageNumbers.add(page.pageNumber)) {
        errors.add(
          'Duplicate page number: ${page.pageNumber}.',
        );
      }
    }

    if (template.usePrincipalSignature &&
        !template.usePrincipalName) {
      warnings.add(
        'Principal signature is enabled while principal name is disabled.',
      );
    }

    if (template.useSchoolStamp &&
        !template.useSchoolName) {
      warnings.add(
        'School stamp is enabled while school name is disabled.',
      );
    }

    return DocumentTemplateValidationResult(
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  void _validatePage(
    DocumentPageEntity page,
    List<String> errors,
    List<String> warnings,
  ) {
    if (page.id.trim().isEmpty) {
      errors.add(
        'Page id is required.',
      );
    }

    if (page.pageNumber <= 0) {
      errors.add(
        'Page number must be greater than zero.',
      );
    }

    if (page.width <= 0) {
      errors.add(
        'Page ${page.pageNumber} width must be greater than zero.',
      );
    }

    if (page.height <= 0) {
      errors.add(
        'Page ${page.pageNumber} height must be greater than zero.',
      );
    }

    final elementIds = <String>{};

    for (final element in page.elements) {
      _validateElement(
        page,
        element,
        errors,
        warnings,
      );

      if (!elementIds.add(element.id)) {
        errors.add(
          'Duplicate element id "${element.id}" on page ${page.pageNumber}.',
        );
      }
    }

    if (page.elements.isEmpty) {
      warnings.add(
        'Page ${page.pageNumber} contains no elements.',
      );
    }
  }

  void _validateElement(
    DocumentPageEntity page,
    DocumentElementEntity element,
    List<String> errors,
    List<String> warnings,
  ) {
    final label =
        'Element "${element.id}" on page ${page.pageNumber}';

    if (element.id.trim().isEmpty) {
      errors.add(
        'Element id is required on page ${page.pageNumber}.',
      );
    }

    if (!_normalized(element.x)) {
      errors.add(
        '$label has invalid x coordinate.',
      );
    }

    if (!_normalized(element.y)) {
      errors.add(
        '$label has invalid y coordinate.',
      );
    }

    if (element.width <= 0 ||
        element.width > 1) {
      errors.add(
        '$label width must be greater than 0 and no more than 1.',
      );
    }

    if (element.height <= 0 ||
        element.height > 1) {
      errors.add(
        '$label height must be greater than 0 and no more than 1.',
      );
    }

    if (element.x + element.width > 1.000001) {
      warnings.add(
        '$label extends beyond the right page boundary.',
      );
    }

    if (element.y + element.height > 1.000001) {
      warnings.add(
        '$label extends beyond the bottom page boundary.',
      );
    }

    if (element.opacity < 0 ||
        element.opacity > 1) {
      errors.add(
        '$label opacity must be between 0 and 1.',
      );
    }

    if (element.hasDynamicData &&
        element.hasStaticValue) {
      warnings.add(
        '$label contains both dataKey and staticValue. Renderer precedence must be intentional.',
      );
    }

    if (element.visibleWhenKey != null &&
        element.visibleWhenKey!
            .trim()
            .isNotEmpty &&
        (element.visibleWhenValue == null ||
            element.visibleWhenValue!
                .trim()
                .isEmpty)) {
      warnings.add(
        '$label has a visibility key but no visibility value.',
      );
    }
  }

  bool _normalized(
    double value,
  ) {
    return value >= 0 && value <= 1;
  }
}
