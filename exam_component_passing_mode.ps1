[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\exam_component_passing_mode_$stamp"

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

$entity='lib/features/exams/domain/entities/exam_subject_setup_entity.dart'
$model='lib/features/exams/data/models/exam_subject_setup_model.dart'
$service='lib/features/academic_structure/domain/services/subject_component_exam_service.dart'
$form='lib/features/exams/presentation/pages/exam_form_page.dart'
$results='lib/features/exams/domain/usecases/generate_exam_results.dart'

foreach($f in @($entity,$model,$service,$form,$results)){BackupFile $f}

# ---------- ENTITY ----------
$text=[IO.File]::ReadAllText((Full $entity)).Replace("`r`n","`n")

$text=$text.Replace(
"    this.componentPassingMarks = const {},`n  });",
"    this.componentPassingMarks = const {},`n    this.enforceComponentPassingMarks = false,`n    this.aggregatePassingMarks = 0,`n  });"
)

$text=$text.Replace(
"  final Map<String, double> componentPassingMarks;",
"  final Map<String, double> componentPassingMarks;`n`n  /// True when every component has its own compulsory passing marks.`n  final bool enforceComponentPassingMarks;`n`n  /// Parent-subject passing marks retained on expanded component setups.`n  final double aggregatePassingMarks;"
)

$oldValid=@'
  bool get isComponentDistributionValid {
    if (!hasComponentDistribution) return true;
    return _same(configuredComponentTotal, totalMarks) &&
        componentTotalMarks.keys.every(
          (id) {
            final total = componentTotalMarks[id] ?? 0;
            final passing = componentPassingMarks[id] ?? 0;
            return total > 0 && passing >= 0 && passing <= total;
          },
        );
  }
'@
$newValid=@'
  bool get isComponentDistributionValid {
    if (!hasComponentDistribution) return true;
    if (!_same(configuredComponentTotal, totalMarks)) return false;

    final passingKeys = componentPassingMarks.keys.toSet();
    final totalKeys = componentTotalMarks.keys.toSet();
    final hasNoComponentPassing = passingKeys.isEmpty;
    final hasCompleteComponentPassing =
        passingKeys.length == totalKeys.length &&
        passingKeys.containsAll(totalKeys);

    if (!hasNoComponentPassing && !hasCompleteComponentPassing) {
      return false;
    }

    return componentTotalMarks.keys.every((id) {
      final total = componentTotalMarks[id] ?? 0;
      if (total <= 0) return false;
      if (hasNoComponentPassing) return true;
      final passing = componentPassingMarks[id];
      return passing != null && passing >= 0 && passing <= total;
    });
  }
'@
if(-not $text.Contains($oldValid)){throw 'Entity validation block not found.'}
$text=$text.Replace($oldValid,$newValid)

$text=$text.Replace(
"    Map<String, double>? componentPassingMarks,`n  }) {",
"    Map<String, double>? componentPassingMarks,`n    bool? enforceComponentPassingMarks,`n    double? aggregatePassingMarks,`n  }) {"
)

$text=$text.Replace(
"      componentPassingMarks:`n          componentPassingMarks ?? this.componentPassingMarks,`n    );",
"      componentPassingMarks:`n          componentPassingMarks ?? this.componentPassingMarks,`n      enforceComponentPassingMarks:`n          enforceComponentPassingMarks ?? this.enforceComponentPassingMarks,`n      aggregatePassingMarks:`n          aggregatePassingMarks ?? this.aggregatePassingMarks,`n    );"
)

$text=$text.Replace(
"        componentPassingMarks,`n      ];",
"        componentPassingMarks,`n        enforceComponentPassingMarks,`n        aggregatePassingMarks,`n      ];"
)
WriteText $entity $text

# ---------- MODEL ----------
$text=[IO.File]::ReadAllText((Full $model)).Replace("`r`n","`n")
$text=$text.Replace(
"    super.componentPassingMarks,`n  });",
"    super.componentPassingMarks,`n    super.enforceComponentPassingMarks,`n    super.aggregatePassingMarks,`n  });"
)
$text=$text.Replace(
"      componentPassingMarks: entity.componentPassingMarks,`n    );",
"      componentPassingMarks: entity.componentPassingMarks,`n      enforceComponentPassingMarks: entity.enforceComponentPassingMarks,`n      aggregatePassingMarks: entity.aggregatePassingMarks,`n    );"
)
$text=$text.Replace(
"      componentPassingMarks:`n          _numberMap(map['componentPassingMarks']),`n    );",
"      componentPassingMarks:`n          _numberMap(map['componentPassingMarks']),`n      enforceComponentPassingMarks:`n          map['enforceComponentPassingMarks'] as bool? ?? false,`n      aggregatePassingMarks: _number(map['aggregatePassingMarks']),`n    );"
)
$text=$text.Replace(
"      'componentPassingMarks': componentPassingMarks,`n      'displayOrder': displayOrder,",
"      'componentPassingMarks': componentPassingMarks,`n      'enforceComponentPassingMarks': enforceComponentPassingMarks,`n      'aggregatePassingMarks': aggregatePassingMarks,`n      'displayOrder': displayOrder,"
)
WriteText $model $text

# ---------- EXPANSION SERVICE ----------
$text=[IO.File]::ReadAllText((Full $service)).Replace("`r`n","`n")

$oldService=@'
      final useManual = setup.componentTotalMarks.isNotEmpty;

      for (final component in active) {
        final total = useManual
            ? setup.componentTotalMarks[component.id]
            : setup.totalMarks / active.length;
        final passing = useManual
            ? setup.componentPassingMarks[component.id]
            : setup.passingMarks / active.length;

        if (total == null || total <= 0 || passing == null) {
'@
$newService=@'
      final useManualTotals = setup.componentTotalMarks.isNotEmpty;
      final useComponentPassing = setup.componentPassingMarks.isNotEmpty;

      for (final component in active) {
        final total = useManualTotals
            ? setup.componentTotalMarks[component.id]
            : setup.totalMarks / active.length;
        final passing = useComponentPassing
            ? setup.componentPassingMarks[component.id]
            : 0.0;

        if (total == null || total <= 0 || passing == null) {
'@
if(-not $text.Contains($oldService)){throw 'Service calculation block not found.'}
$text=$text.Replace($oldService,$newService)

$text=$text.Replace(
"            componentPassingMarks: const {},`n          ),",
"            componentPassingMarks: const {},`n            enforceComponentPassingMarks: useComponentPassing,`n            aggregatePassingMarks: setup.passingMarks,`n          ),"
)
WriteText $service $text

# ---------- EXAM FORM ----------
$text=[IO.File]::ReadAllText((Full $form)).Replace("`r`n","`n")

# Equal split must no longer fill component passing fields.
$oldSplit=@'
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
'@
$newSplit=@'
    final totalEach = total / draft.components.length;

    for (final component in draft.components) {
      draft.componentTotalControllers[component.id]!.text =
          _marksText(totalEach);
    }
'@
if(-not $text.Contains($oldSplit)){throw 'Equal split block not found.'}
$text=$text.Replace($oldSplit,$newSplit)

# Validation: passing fields all blank OR all filled; do not require sum equals parent.
$oldValidation=@'
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
'@
$newValidation=@'
        var componentTotal = 0.0;
        var filledPassingCount = 0;

        for (final component in draft.components) {
          final componentMaximum = double.tryParse(
            draft.componentTotalControllers[component.id]!.text.trim(),
          );
          final passingText =
              draft.componentPassingControllers[component.id]!.text.trim();
          final componentPass =
              passingText.isEmpty ? null : double.tryParse(passingText);

          if (componentMaximum == null || componentMaximum <= 0) {
            _showMessage(
              'Check total marks for ${draft.subject.name} '
              '${component.componentName}.',
            );
            return;
          }

          if (passingText.isNotEmpty) {
            filledPassingCount++;
            if (componentPass == null ||
                componentPass < 0 ||
                componentPass > componentMaximum) {
              _showMessage(
                'Check passing marks for ${draft.subject.name} '
                '${component.componentName}.',
              );
              return;
            }
          }

          componentTotal += componentMaximum;
        }

        if ((componentTotal - total).abs() > 0.001) {
          _showMessage(
            '${draft.subject.name} component totals must equal '
            '${_marksText(total)}. Current total: '
            '${_marksText(componentTotal)}.',
          );
          return;
        }

        if (filledPassingCount != 0 &&
            filledPassingCount != draft.components.length) {
          _showMessage(
            'Enter passing marks for every ${draft.subject.name} '
            'component, or leave all component passing fields blank.',
          );
          return;
        }
'@
if(-not $text.Contains($oldValidation)){throw 'Form validation block not found.'}
$text=$text.Replace($oldValidation,$newValidation)

# Save only non-empty passing values.
$oldSave=@'
          componentPassingMarks: {
            for (final component in draft.components)
              component.id: double.parse(
                draft.componentPassingControllers[component.id]!.text.trim(),
              ),
          },
'@
$newSave=@'
          componentPassingMarks: {
            for (final component in draft.components)
              if (draft.componentPassingControllers[component.id]!
                  .text
                  .trim()
                  .isNotEmpty)
                component.id: double.parse(
                  draft.componentPassingControllers[component.id]!
                      .text
                      .trim(),
                ),
          },
'@
if(-not $text.Contains($oldSave)){throw 'Form save passing map not found.'}
$text=$text.Replace($oldSave,$newSave)

# New/legacy drafts should show component passing blank unless saved.
$oldInit=@'
        componentPassingControllers = {
          for (final component in components)
            component.id: TextEditingController(
              text: _marksText(
                componentPassingMarks[component.id] ??
                    passingMarks / components.length,
              ),
            ),
        };
'@
$newInit=@'
        componentPassingControllers = {
          for (final component in components)
            component.id: TextEditingController(
              text: componentPassingMarks.containsKey(component.id)
                  ? _marksText(componentPassingMarks[component.id]!)
                  : '',
            ),
        };
'@
if(-not $text.Contains($oldInit)){throw 'Draft passing initialization not found.'}
$text=$text.Replace($oldInit,$newInit)

# Add UI guidance beneath component rows.
$uiAnchor=@'
                  for (final component in components)
                    Padding(
'@
# We'll insert note before loop
$uiReplacement=@'
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Passing rule: leave every component Passing field blank '
                      'to use the parent subject passing marks. Fill all fields '
                      'to make every component compulsory.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final component in components)
                    Padding(
'@
if(-not $text.Contains($uiAnchor)){throw 'Component UI loop anchor not found.'}
$text=$text.Replace($uiAnchor,$uiReplacement)

WriteText $form $text

# ---------- RESULT CALCULATION ----------
$text=[IO.File]::ReadAllText((Full $results)).Replace("`r`n","`n")

# Rename initial list so we can normalize pass status after building rows.
$text=$text.Replace(
"    final subjectResults = <SubjectResultEntity>[];",
"    final rawSubjectResults = <SubjectResultEntity>[];"
)
$text=$text.Replace(
"      subjectResults.add(",
"      rawSubjectResults.add("
)

$afterLoop=@'
    }

    final grandTotal = subjectResults.fold<double>(
'@
$normalizeBlock=@'
    }

    final subjectResults = _applyComponentPassingRules(
      setups: setups,
      results: rawSubjectResults,
    );

    final grandTotal = subjectResults.fold<double>(
'@
if(-not $text.Contains($afterLoop)){throw 'Result normalization insertion anchor not found.'}
$text=$text.Replace($afterLoop,$normalizeBlock)

# Insert helper before _applyRanks or end of class. Find known method after _buildResult.
$helperAnchor="  List<ExamResultEntity> _applyRanks("
if(-not $text.Contains($helperAnchor)){throw 'Result helper anchor not found.'}

$helper=@'
  List<SubjectResultEntity> _applyComponentPassingRules({
    required List<ExamSubjectSetupEntity> setups,
    required List<SubjectResultEntity> results,
  }) {
    final setupBySubjectId = {
      for (final setup in setups) setup.subjectId: setup,
    };

    final groupedIds = <String, List<String>>{};
    for (final setup in setups) {
      final parentId = SubjectComponentExamService.parentId(setup.subjectId);
      if (parentId == null) continue;
      (groupedIds[parentId] ??= []).add(setup.subjectId);
    }

    if (groupedIds.isEmpty) return results;

    final passBySubjectId = <String, bool>{};

    for (final entry in groupedIds.entries) {
      final componentIds = entry.value;
      final componentSetups = componentIds
          .map((id) => setupBySubjectId[id])
          .whereType<ExamSubjectSetupEntity>()
          .toList(growable: false);
      final componentResults = results
          .where((result) => componentIds.contains(result.subjectId))
          .toList(growable: false);

      if (componentSetups.isEmpty ||
          componentResults.length != componentSetups.length) {
        continue;
      }

      final enforceEach =
          componentSetups.any((setup) => setup.enforceComponentPassingMarks);

      if (enforceEach) {
        for (final result in componentResults) {
          passBySubjectId[result.subjectId] = result.isPassed;
        }
        continue;
      }

      final parentPassing = componentSetups.first.aggregatePassingMarks;
      final obtained = componentResults.fold<double>(
        0,
        (sum, result) => sum + result.obtainedMarks,
      );
      final combinedPass = obtained >= parentPassing;

      for (final result in componentResults) {
        passBySubjectId[result.subjectId] = combinedPass;
      }
    }

    return results
        .map(
          (result) => passBySubjectId.containsKey(result.subjectId)
              ? SubjectResultEntity(
                  subjectId: result.subjectId,
                  subjectName: result.subjectName,
                  totalMarks: result.totalMarks,
                  obtainedMarks: result.obtainedMarks,
                  isAbsent: result.isAbsent,
                  isPassed: passBySubjectId[result.subjectId]!,
                  remarks: result.remarks,
                )
              : result,
        )
        .toList(growable: false);
  }

'@

$text=$text.Replace($helperAnchor,$helper+$helperAnchor)
WriteText $results $text

dart format $entity $model $service $form $results
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/exams lib/features/academic_structure lib/features/results --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Component passing mode completed successfully.' -ForegroundColor Green
Write-Host 'Blank component passing fields: combined parent-subject passing rule.' -ForegroundColor Green
Write-Host 'All component passing fields filled: every component must pass.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
