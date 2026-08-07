enum DocumentTemplateCategory {
  official,
  modern,
  kids,
  minimal,
  islamic,
  custom,
}

extension DocumentTemplateCategoryX
    on DocumentTemplateCategory {
  String get label {
    return switch (this) {
      DocumentTemplateCategory.official => 'Official',
      DocumentTemplateCategory.modern => 'Modern',
      DocumentTemplateCategory.kids => 'Kids',
      DocumentTemplateCategory.minimal => 'Minimal',
      DocumentTemplateCategory.islamic => 'Islamic',
      DocumentTemplateCategory.custom => 'Custom',
    };
  }
}
