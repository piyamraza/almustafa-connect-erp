[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_component_distribution_part2_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $s=Full $p
  if(-not(Test-Path $s)){throw "Required file not found: $p"}
  $d=Join-Path $backup $p
  New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
  Copy-Item $s $d -Force
}
function WriteText([string]$p,[string]$t){
  [IO.File]::WriteAllText((Full $p),$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$page='lib/features/exams/presentation/pages/exam_form_page.dart'
BackupFile $page

$text=[IO.File]::ReadAllText((Full $page)).Replace("`r`n","`n")

# Imports
$importAnchor="import '../../../academic_structure/domain/entities/section_entity.dart';"
$imports=@"
$importAnchor
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';
"@
if(-not $text.Contains("subject_component_entity.dart")){
  if(-not $text.Contains($importAnchor)){throw 'Import anchor not found.'}
  $text=$text.Replace($importAnchor,$imports.TrimEnd())
}

# State fields
$fieldAnchor="  final Set<String> _selectedSectionIds = {};"
$fieldReplacement=@'
  final Set<String> _selectedSectionIds = {};
  List<SubjectComponentEntity> _components = const [];
  bool _componentsLoading = true;
'@
if(-not $text.Contains('List<SubjectComponentEntity> _components')){
  if(-not $text.Contains($fieldAnchor)){throw 'State field anchor not found.'}
  $text=$text.Replace($fieldAnchor,$fieldReplacement)
}

# init load
$initAnchor="    _resultDate = exam?.resultDate;`n  }"
$initReplacement=@'
    _resultDate = exam?.resultDate;
    _loadComponents();
  }

  Future<void> _loadComponents() async {
    try {
      final values = await sl<SubjectComponentRepository>().getComponents();
      if (!mounted) return;
      setState(() {
        _components = values.where((item) => item.isActive).toList()
          ..sort(
            (first, second) =>
                first.displayOrder.compareTo(second.displayOrder),
          );
        _componentsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _componentsLoading = false);
      _showMessage('Subject components could not be loaded: $error');
    }
  }
'@
if(-not $text.Contains('Future<void> _loadComponents()')){
  if(-not $text.Contains($initAnchor)){throw 'initState anchor not found.'}
  $text=$text.Replace($initAnchor,$initReplacement)
}

# Draft constructors existing setup
$text=$text.Replace(
"        existing: setup,`n      );",
"        existing: setup,`n        components: _componentsFor(subject),`n        componentTotalMarks: setup.componentTotalMarks,`n        componentPassingMarks: setup.componentPassingMarks,`n      );"
)

$text=$text.Replace(
"            existing: existing,`n          ),",
"            existing: existing,`n            components: _componentsFor(subject),`n            componentTotalMarks: existing?.componentTotalMarks ?? const {},`n            componentPassingMarks:`n                existing?.componentPassingMarks ?? const {},`n          ),"
)

$text=$text.Replace(
"        existing: old,`n      );",
"        existing: old,`n        components: _componentsFor(subject),`n        componentTotalMarks: old?.componentTotalMarks ?? const {},`n        componentPassingMarks: old?.componentPassingMarks ?? const {},`n      );"
)

# Helper methods before _key
$keyAnchor="  String _key("
$helpers=@'
  List<SubjectComponentEntity> _componentsFor(
    AcademicSubjectEntity subject,
  ) {
    if (!subject.useComponentsInExamination) return const [];
    return _components
        .where((item) => item.parentSubjectId == subject.id && item.isActive)
        .toList(growable: false);
  }

  void _distributeDraftEqually(_SubjectDraft draft) {
    if (draft.components.isEmpty) return;

    final total =
        double.tryParse(draft.totalController.text.trim()) ?? 0;
    final passing =
        double.tryParse(draft.passingController.text.trim()) ?? 0;

    final totalEach = total / draft.components.length;
    final passingEach = passing / draft.components.length;

    for (final component in draft.components) {
      draft.componentTotalControllers[component.id]!.text =
          _marksText(totalEach);
      draft.componentPassingControllers[component.id]!.text =
          _marksText(passingEach);
    }
  }

'@
if(-not $text.Contains('List<SubjectComponentEntity> _componentsFor')){
  if(-not $text.Contains($keyAnchor)){throw 'Helper anchor not found.'}
  $text=$text.Replace($keyAnchor,$helpers+$keyAnchor)
}

# Apply common marks also components
$oldApply=@'
        draft.totalController.text = _marksText(total);
        draft.passingController.text = _marksText(passing);
'@
$newApply=@'
        draft.totalController.text = _marksText(total);
        draft.passingController.text = _marksText(passing);
        _distributeDraftEqually(draft);
'@
if(-not $text.Contains($oldApply)){throw 'Apply marks anchor not found.'}
$text=$text.Replace($oldApply,$newApply)

# Validation loop
$validationAnchor=@'
      if (total == null ||
          total <= 0 ||
          passing == null ||
          passing < 0 ||
          passing > total) {
        _showMessage(
          'Check total and passing marks for ${draft.subject.name}.',
        );
        return;
      }
'@
$validationReplacement=@'
      if (total == null ||
          total <= 0 ||
          passing == null ||
          passing < 0 ||
          passing > total) {
        _showMessage(
          'Check total and passing marks for ${draft.subject.name}.',
        );
        return;
      }

      if (draft.components.isNotEmpty) {
        var componentTotal = 0.0;
        var componentPassing = 0.0;

        for (final component in draft.components) {
          final componentMaximum = double.tryParse(
            draft.componentTotalControllers[component.id]!.text.trim(),
          );
          final componentPass = double.tryParse(
            draft.componentPassingControllers[component.id]!.text.trim(),
          );

          if (componentMaximum == null ||
              componentMaximum <= 0 ||
              componentPass == null ||
              componentPass < 0 ||
              componentPass > componentMaximum) {
            _showMessage(
              'Check marks for ${draft.subject.name} '
              '${component.componentName}.',
            );
            return;
          }

          componentTotal += componentMaximum;
          componentPassing += componentPass;
        }

        if ((componentTotal - total).abs() > 0.001) {
          _showMessage(
            '${draft.subject.name} component totals must equal '
            '${_marksText(total)}. Current total: '
            '${_marksText(componentTotal)}.',
          );
          return;
        }

        if ((componentPassing - passing).abs() > 0.001) {
          _showMessage(
            '${draft.subject.name} component passing marks must equal '
            '${_marksText(passing)}. Current total: '
            '${_marksText(componentPassing)}.',
          );
          return;
        }
      }
'@
if(-not $text.Contains($validationAnchor)){throw 'Validation anchor not found.'}
$text=$text.Replace($validationAnchor,$validationReplacement)

# Entity save maps
$saveAnchor="          passingMarks: double.parse(draft.passingController.text.trim()),`n          isActive: true,"
$saveReplacement=@'
          passingMarks: double.parse(draft.passingController.text.trim()),
          componentTotalMarks: {
            for (final component in draft.components)
              component.id: double.parse(
                draft.componentTotalControllers[component.id]!.text.trim(),
              ),
          },
          componentPassingMarks: {
            for (final component in draft.components)
              component.id: double.parse(
                draft.componentPassingControllers[component.id]!.text.trim(),
              ),
          },
          isActive: true,
'@
if(-not $text.Contains($saveAnchor)){throw 'Save setup anchor not found.'}
$text=$text.Replace($saveAnchor,$saveReplacement)

# Loading components guard
$formAnchor="          final data = state as ExamConfigurationLoaded;`n          _initializeConfiguration(data);"
$formReplacement=@'
          final data = state as ExamConfigurationLoaded;
          if (_componentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          _initializeConfiguration(data);
'@
if(-not $text.Contains($formAnchor)){throw 'Form loading anchor not found.'}
$text=$text.Replace($formAnchor,$formReplacement)

# Replace subject row return block
$start=$text.IndexOf("    return Padding(`n      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 10),")
$endMarker="  Widget _field(Widget child)"
$end=$text.IndexOf($endMarker,$start)
if($start -lt 0 -or $end -lt 0){throw 'Subject row block boundaries not found.'}

$newSubjectBlock=@'
    final components = draft.components;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: draft.selected,
                onChanged: (value) =>
                    setState(() => draft!.selected = value ?? false),
              ),
              Expanded(child: Text(subject.name)),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: draft.totalController,
                  enabled: draft.selected,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (components.isNotEmpty) setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: draft.passingController,
                  enabled: draft.selected,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (components.isNotEmpty) setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Passing',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              if (components.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: OutlinedButton.icon(
                    onPressed: draft.selected
                        ? () => setState(
                              () => _distributeDraftEqually(draft!),
                            )
                        : null,
                    icon: const Icon(Icons.balance_outlined),
                    label: const Text('Equal Split'),
                  ),
                ),
              if (isProtected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message:
                        'Marks already exist; this subject cannot be deselected.',
                    child: Icon(Icons.lock_outline),
                  ),
                ),
            ],
          ),
          if (draft.selected && components.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 48, top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (final component in components)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${subject.name} ${component.componentName}',
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: draft
                                  .componentTotalControllers[component.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Total',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              controller: draft
                                  .componentPassingControllers[component.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Passing',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

'@

$text=$text.Substring(0,$start)+$newSubjectBlock+$text.Substring($end)

# Replace _SubjectDraft class
$classStart=$text.IndexOf("class _SubjectDraft {")
$classEnd=$text.IndexOf("class _DateSelector", $classStart)
if($classStart -lt 0 -or $classEnd -lt 0){throw '_SubjectDraft boundaries not found.'}

$newDraft=@'
class _SubjectDraft {
  _SubjectDraft({
    required this.academicClass,
    required this.section,
    required this.subject,
    required this.selected,
    required double totalMarks,
    required double passingMarks,
    required this.components,
    required Map<String, double> componentTotalMarks,
    required Map<String, double> componentPassingMarks,
    this.existing,
  })  : totalController =
            TextEditingController(text: _marksText(totalMarks)),
        passingController =
            TextEditingController(text: _marksText(passingMarks)),
        componentTotalControllers = {
          for (final component in components)
            component.id: TextEditingController(
              text: _marksText(
                componentTotalMarks[component.id] ??
                    totalMarks / components.length,
              ),
            ),
        },
        componentPassingControllers = {
          for (final component in components)
            component.id: TextEditingController(
              text: _marksText(
                componentPassingMarks[component.id] ??
                    passingMarks / components.length,
              ),
            ),
        };

  final AcademicClassEntity academicClass;
  final SectionEntity section;
  final AcademicSubjectEntity subject;
  final ExamSubjectSetupEntity? existing;
  final List<SubjectComponentEntity> components;
  final TextEditingController totalController;
  final TextEditingController passingController;
  final Map<String, TextEditingController> componentTotalControllers;
  final Map<String, TextEditingController> componentPassingControllers;
  bool selected;

  void dispose() {
    totalController.dispose();
    passingController.dispose();
    for (final controller in componentTotalControllers.values) {
      controller.dispose();
    }
    for (final controller in componentPassingControllers.values) {
      controller.dispose();
    }
  }
}

'@

$text=$text.Substring(0,$classStart)+$newDraft+$text.Substring($classEnd)

WriteText $page $text

dart format $page
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/exams lib/features/academic_structure --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Exam Component Distribution Part 2 completed successfully.' -ForegroundColor Green
Write-Host 'Create/Edit Exam now asks component-wise total and passing marks.' -ForegroundColor Green
Write-Host 'Parent and component totals are validated before save.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
