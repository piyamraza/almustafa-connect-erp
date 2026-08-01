$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$target = 'lib/features/fees/presentation/pages/fee_collection_page.dart'
$targetPath = Join-Path $root $target

if (-not (Test-Path $targetPath)) {
    throw "Required file not found: $target"
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path `
    (Split-Path $root -Parent) `
    "almustafa-connect-erp_backups/fee_collection_class_section_filter_$stamp"

$backupFile = Join-Path $backupRoot $target
New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
Copy-Item $targetPath $backupFile -Force

$content = [IO.File]::ReadAllText($targetPath).Replace("`r`n", "`n")

function Add-Import {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ImportLine
    )

    if ($Content.Contains($ImportLine)) {
        return $Content
    }

    $matches = [regex]::Matches(
        $Content,
        "(?m)^import\s+['""].+?['""];\s*$"
    )

    if ($matches.Count -eq 0) {
        throw "Import block not found: $ImportLine"
    }

    $last = $matches[$matches.Count - 1]
    return $Content.Insert(
        $last.Index + $last.Length,
        "`n$ImportLine"
    )
}

foreach ($importLine in @(
    "import '../../../academic_structure/domain/entities/academic_class_entity.dart';",
    "import '../../../academic_structure/domain/entities/section_entity.dart';",
    "import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';"
)) {
    $content = Add-Import -Content $content -ImportLine $importLine
}

# Add class / section state.
if (-not $content.Contains('List<AcademicClassEntity> _classes')) {
    $content = $content.Replace(
        "  List<StudentEntity> _students = const [];`n" +
        "  StudentEntity? _selectedStudent;",
        "  List<StudentEntity> _students = const [];`n" +
        "  List<AcademicClassEntity> _classes = const [];`n" +
        "  List<SectionEntity> _sections = const [];`n" +
        "  String? _selectedClassId;`n" +
        "  String? _selectedSectionId;`n" +
        "  StudentEntity? _selectedStudent;"
    )
}

# Replace student loading with students + academic structure loading.
$loadPattern = '(?ms)  Future<void> _loadStudents\(\) async \{.*?^  \}\n\n  void _selectStudent'

$newLoad = @'
  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);

    try {
      final repository = sl<AcademicStructureRepository>();
      final values = await Future.wait<Object>([
        sl<StudentRepository>().getStudents(),
        repository.getClasses(),
        repository.getSections(),
      ]);

      if (!mounted) return;

      final students = (values[0] as List<StudentEntity>)
          .where((item) => item.isActive)
          .toList()
        ..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(
                b.fullName.toLowerCase(),
              ),
        );

      final classes = (values[1] as List<AcademicClassEntity>)
          .where((item) => item.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final sections = (values[2] as List<SectionEntity>)
          .where((item) => item.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _students = students;
        _classes = classes;
        _sections = sections;
        _loadingStudents = false;

        if (_selectedClassId != null &&
            !classes.any((item) => item.id == _selectedClassId)) {
          _selectedClassId = null;
          _selectedSectionId = null;
          _selectedStudent = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
      _show(error.toString());
    }
  }

  void _selectStudent
'@

if ([regex]::IsMatch($content, $loadPattern)) {
    $content = [regex]::Replace($content, $loadPattern, $newLoad, 1)
} else {
    throw 'Student loading method anchor not found.'
}

# Add class / section matching helpers and replace visible students.
$visiblePattern = '(?ms)  List<StudentEntity> get _visibleStudents \{.*?^  \}\n\n  double _selectedOutstanding'

$newVisible = @'
  String _normal(String value) => value.trim().toLowerCase();

  AcademicClassEntity? get _selectedClass {
    final id = _selectedClassId;
    if (id == null) return null;

    for (final item in _classes) {
      if (item.id == id) return item;
    }

    return null;
  }

  SectionEntity? get _selectedSection {
    final id = _selectedSectionId;
    if (id == null) return null;

    for (final item in _sections) {
      if (item.id == id) return item;
    }

    return null;
  }

  List<SectionEntity> get _availableSections {
    final classId = _selectedClassId;
    if (classId == null) return const [];

    return _sections
        .where((section) => section.classId == classId)
        .toList(growable: false);
  }

  bool _matchesClass(StudentEntity student) {
    final selected = _selectedClass;
    if (selected == null) return false;

    final value = _normal(student.classId);
    return value == _normal(selected.id) ||
        value == _normal(selected.name);
  }

  bool _matchesSection(StudentEntity student) {
    final selected = _selectedSection;
    if (selected == null) return false;

    final value = _normal(student.sectionId);
    return value == _normal(selected.id) ||
        value == _normal(selected.name);
  }

  List<StudentEntity> get _visibleStudents {
    if (_selectedClassId == null || _selectedSectionId == null) {
      return const [];
    }

    final query = _query.trim().toLowerCase();

    return _students.where((student) {
      if (!_matchesClass(student) || !_matchesSection(student)) {
        return false;
      }

      if (query.isEmpty) return true;

      return student.fullName.toLowerCase().contains(query) ||
          student.admissionNo.toLowerCase().contains(query) ||
          student.rollNumber.toLowerCase().contains(query) ||
          student.guardianPhone.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  double _selectedOutstanding
'@

if ([regex]::IsMatch($content, $visiblePattern)) {
    $content = [regex]::Replace($content, $visiblePattern, $newVisible, 1)
} else {
    throw 'Visible student filter anchor not found.'
}

# Replace the left selection panel with class -> section -> search workflow.
$panelPattern = '(?ms)                            Padding\(\n                              padding: const EdgeInsets\.all\(14\),\n                              child: TextFormField\(.*?                            Expanded\(\n                              child: ListView\.builder\(.*?                            \),\n                          \],'

$newPanel = @'
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedClassId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: '1. Select Class',
                                      prefixIcon:
                                          Icon(Icons.school_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _classes
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: busy
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedClassId = value;
                                              _selectedSectionId = null;
                                              _selectedStudent = null;
                                              _selectedDueIds.clear();
                                              _searchController.clear();
                                              _query = '';
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _availableSections.any(
                                      (item) =>
                                          item.id == _selectedSectionId,
                                    )
                                        ? _selectedSectionId
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: '2. Select Section',
                                      prefixIcon:
                                          Icon(Icons.view_list_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _availableSections
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged:
                                        busy || _selectedClassId == null
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _selectedSectionId =
                                                      value;
                                                  _selectedStudent = null;
                                                  _selectedDueIds.clear();
                                                  _searchController.clear();
                                                  _query = '';
                                                });
                                              },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _searchController,
                                    enabled:
                                        _selectedSectionId != null,
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    decoration: const InputDecoration(
                                      labelText:
                                          '3. Search selected section',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _selectedClassId == null
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text(
                                          'Select a class first.',
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : _selectedSectionId == null
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Text(
                                              'Now select a section.',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : _visibleStudents.isEmpty
                                          ? const Center(
                                              child: Padding(
                                                padding:
                                                    EdgeInsets.all(20),
                                                child: Text(
                                                  'No active students found in this section.',
                                                  textAlign:
                                                      TextAlign.center,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount:
                                                  _visibleStudents.length,
                                              itemBuilder:
                                                  (context, index) {
                                                final student =
                                                    _visibleStudents[index];
                                                final name =
                                                    student.fullName.trim();
                                                return ListTile(
                                                  selected:
                                                      _selectedStudent?.id ==
                                                          student.id,
                                                  selectedTileColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withValues(
                                                            alpha: .35,
                                                          ),
                                                  leading: CircleAvatar(
                                                    child: Text(
                                                      name.isEmpty
                                                          ? '?'
                                                          : name[0]
                                                              .toUpperCase(),
                                                    ),
                                                  ),
                                                  title:
                                                      Text(student.fullName),
                                                  subtitle: Text(
                                                    '${student.admissionNo}\n'
                                                    'Roll: '
                                                    '${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                                                  ),
                                                  isThreeLine: true,
                                                  trailing: _selectedStudent
                                                              ?.id ==
                                                          student.id
                                                      ? const Icon(
                                                          Icons
                                                              .check_circle,
                                                        )
                                                      : null,
                                                  onTap: busy
                                                      ? null
                                                      : () =>
                                                          _selectStudent(
                                                            student,
                                                          ),
                                                );
                                              },
                                            ),
                            ),
                          ],
'@

if ([regex]::IsMatch($content, $panelPattern)) {
    $content = [regex]::Replace($content, $panelPattern, $newPanel, 1)
} else {
    throw 'Fee Collection left panel anchor not found.'
}

[IO.File]::WriteAllText($targetPath, $content, $utf8)
Write-Host "Updated: $target" -ForegroundColor Green

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format $target

if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan

& flutter analyze

if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Copy the complete output into ChatGPT.'
}

Write-Host ''
Write-Host 'Fee Collection class and section selection added successfully.' -ForegroundColor Green
Write-Host 'Students are now shown only after selecting both class and section.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
