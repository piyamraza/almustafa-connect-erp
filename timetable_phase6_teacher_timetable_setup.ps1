$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Get-Location).Path
if (-not (Test-Path (Join-Path $projectRoot 'pubspec.yaml'))) {
    throw 'pubspec.yaml not found. Run this script from the almustafa-connect-erp project root.'
}

$repositoryRelative = 'lib/features/timetable/domain/repositories/timetable_repository.dart'
$dataSourceRelative = 'lib/features/timetable/data/datasources/timetable_remote_datasource.dart'
$repositoryImplRelative = 'lib/features/timetable/data/repositories/timetable_repository_impl.dart'
$serviceLocatorRelative = 'lib/core/di/service_locator.dart'
$dashboardRelative = 'lib/features/timetable/presentation/pages/timetable_dashboard_page.dart'

$requiredChecks = @(
    @{ Path = $repositoryRelative; Marker = 'generateClassTimetableEntryId' },
    @{ Path = $dataSourceRelative; Marker = '_getSessionEntries' },
    @{ Path = $repositoryImplRelative; Marker = 'getClassTimetable' },
    @{ Path = $serviceLocatorRelative; Marker = 'ClassTimetableBloc' },
    @{ Path = $dashboardRelative; Marker = 'ClassTimetablePage' }
)

foreach ($check in $requiredChecks) {
    $checkPath = Join-Path $projectRoot $check.Path
    if (-not (Test-Path $checkPath)) {
        throw "Required Phase 5 file is missing: $($check.Path)"
    }
    $checkContent = [System.IO.File]::ReadAllText($checkPath)
    if (-not $checkContent.Contains($check.Marker)) {
        throw "Phase 5 integration is incomplete in: $($check.Path)"
    }
}

$newFiles = @(
    'lib/features/timetable/domain/usecases/get_teacher_timetable.dart',
    'lib/features/timetable/presentation/bloc/teacher_timetable_event.dart',
    'lib/features/timetable/presentation/bloc/teacher_timetable_state.dart',
    'lib/features/timetable/presentation/bloc/teacher_timetable_bloc.dart',
    'lib/features/timetable/presentation/pages/teacher_timetable_page.dart'
)

$modifiedFiles = @(
    $repositoryRelative,
    $dataSourceRelative,
    $repositoryImplRelative,
    $serviceLocatorRelative,
    $dashboardRelative
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$projectParent = Split-Path $projectRoot -Parent
$backupRoot = Join-Path $projectParent "almustafa-connect-erp_backups/phase6_$timestamp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Backup-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $sourcePath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path $sourcePath)) {
        return
    }

    $destinationPath = Join-Path $backupRoot $RelativePath
    New-Item -ItemType Directory -Path (Split-Path $destinationPath -Parent) -Force | Out-Null
    Copy-Item -Path $sourcePath -Destination $destinationPath -Force
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $targetPath = Join-Path $projectRoot $RelativePath
    New-Item -ItemType Directory -Path (Split-Path $targetPath -Parent) -Force | Out-Null
    [System.IO.File]::WriteAllText($targetPath, $Content, $utf8NoBom)
    Write-Host "Created/updated: $RelativePath" -ForegroundColor Green
}

function Add-BlockBeforeAnchor {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$Anchor,
        [Parameter(Mandatory = $true)][string]$Block
    )

    if ($Content.Contains($Marker)) {
        return $Content
    }
    if (-not $Content.Contains($Anchor)) {
        throw "Required integration anchor was not found: $Anchor"
    }
    return $Content.Replace($Anchor, "$Block$Anchor")
}

function Add-BlockBeforePattern {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Block,
        [Parameter(Mandatory = $true)][string]$Description
    )

    if ($Content.Contains($Marker)) {
        return $Content
    }

    $match = [System.Text.RegularExpressions.Regex]::Match(
        $Content,
        $Pattern
    )
    if (-not $match.Success) {
        throw "Required integration point was not found: $Description"
    }

    $insertion = if ($Block.EndsWith("`n")) { $Block } else { "$Block`n" }
    return $Content.Insert($match.Index, $insertion)
}

foreach ($relativePath in ($modifiedFiles + $newFiles)) {
    Backup-ProjectFile -RelativePath $relativePath
}

$repositoryPath = Join-Path $projectRoot $repositoryRelative
$repositoryContent = [System.IO.File]::ReadAllText($repositoryPath)
$repositoryContent = $repositoryContent.Replace("`r`n", "`n")
$repositoryMethod = @'
  Future<List<ClassTimetableEntryEntity>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  });

'@
$repositoryContent = Add-BlockBeforePattern `
    -Content $repositoryContent `
    -Marker 'getTeacherTimetable({' `
    -Pattern '(?m)^  Future<void> saveClassTimetableEntry\([^;{]*\);' `
    -Block $repositoryMethod `
    -Description 'TimetableRepository.saveClassTimetableEntry declaration'
[System.IO.File]::WriteAllText($repositoryPath, $repositoryContent, $utf8NoBom)
Write-Host "Updated: $repositoryRelative" -ForegroundColor Green

$dataSourcePath = Join-Path $projectRoot $dataSourceRelative
$dataSourceContent = [System.IO.File]::ReadAllText($dataSourcePath)
$dataSourceContent = $dataSourceContent.Replace("`r`n", "`n")
$dataSourceAbstractMethod = @'
  Future<List<ClassTimetableEntryModel>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  });

'@
$dataSourceContent = Add-BlockBeforePattern `
    -Content $dataSourceContent `
    -Marker 'Future<List<ClassTimetableEntryModel>> getTeacherTimetable' `
    -Pattern '(?m)^  Future<void> saveClassTimetableEntry\([^;{]*\);' `
    -Block $dataSourceAbstractMethod `
    -Description 'TimetableRemoteDataSource.saveClassTimetableEntry declaration'

$dataSourceImplementation = @'
  @override
  Future<List<ClassTimetableEntryModel>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  }) async {
    final entries = await _getSessionEntries(
      branchId: branchId,
      academicSession: academicSession,
    );

    final filtered = entries
        .where((entry) => entry.teacherId == teacherId.trim())
        .toList()
      ..sort((first, second) {
        final dayComparison = first.weekday.compareTo(second.weekday);
        if (dayComparison != 0) {
          return dayComparison;
        }
        return first.periodOrder.compareTo(second.periodOrder);
      });

    return List<ClassTimetableEntryModel>.unmodifiable(filtered);
  }

'@
$dataSourceContent = Add-BlockBeforePattern `
    -Content $dataSourceContent `
    -Marker 'entry.teacherId == teacherId.trim()' `
    -Pattern '(?m)^  @override\n  Future<void> saveClassTimetableEntry\([^;{]*\)(?: async)? \{' `
    -Block $dataSourceImplementation `
    -Description 'TimetableRemoteDataSourceImpl.saveClassTimetableEntry method'
[System.IO.File]::WriteAllText($dataSourcePath, $dataSourceContent, $utf8NoBom)
Write-Host "Updated: $dataSourceRelative" -ForegroundColor Green

$repositoryImplPath = Join-Path $projectRoot $repositoryImplRelative
$repositoryImplContent = [System.IO.File]::ReadAllText($repositoryImplPath)
$repositoryImplContent = $repositoryImplContent.Replace("`r`n", "`n")
$repositoryImplementation = @'
  @override
  Future<List<ClassTimetableEntryEntity>> getTeacherTimetable({
    required String branchId,
    required String academicSession,
    required String teacherId,
  }) {
    return _remoteDataSource.getTeacherTimetable(
      branchId: branchId,
      academicSession: academicSession,
      teacherId: teacherId,
    );
  }

'@
$repositoryImplContent = Add-BlockBeforePattern `
    -Content $repositoryImplContent `
    -Marker '_remoteDataSource.getTeacherTimetable' `
    -Pattern '(?m)^  @override\n  Future<void> saveClassTimetableEntry\([^;{]*\) \{' `
    -Block $repositoryImplementation `
    -Description 'TimetableRepositoryImpl.saveClassTimetableEntry method'
[System.IO.File]::WriteAllText(
    $repositoryImplPath,
    $repositoryImplContent,
    $utf8NoBom
)
Write-Host "Updated: $repositoryImplRelative" -ForegroundColor Green

$useCaseContent = @'
import '../entities/class_timetable_entry_entity.dart';
import '../repositories/timetable_repository.dart';

class GetTeacherTimetable {
  const GetTeacherTimetable(this._repository);

  final TimetableRepository _repository;

  Future<List<ClassTimetableEntryEntity>> call({
    required String branchId,
    required String academicSession,
    required String teacherId,
  }) {
    if (branchId.trim().isEmpty) {
      throw ArgumentError.value(branchId, 'branchId', 'Branch is required.');
    }
    if (academicSession.trim().isEmpty) {
      throw ArgumentError.value(
        academicSession,
        'academicSession',
        'Academic session is required.',
      );
    }
    if (teacherId.trim().isEmpty) {
      throw ArgumentError.value(
        teacherId,
        'teacherId',
        'Teacher is required.',
      );
    }

    return _repository.getTeacherTimetable(
      branchId: branchId.trim(),
      academicSession: academicSession.trim(),
      teacherId: teacherId.trim(),
    );
  }
}
'@

$eventContent = @'
import 'package:equatable/equatable.dart';

sealed class TeacherTimetableEvent extends Equatable {
  const TeacherTimetableEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeacherTimetableEvent extends TeacherTimetableEvent {
  const LoadTeacherTimetableEvent({
    required this.branchId,
    required this.academicSession,
    required this.teacherId,
  });

  final String branchId;
  final String academicSession;
  final String teacherId;

  @override
  List<Object> get props => [branchId, academicSession, teacherId];
}
'@

$stateContent = @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';

sealed class TeacherTimetableState extends Equatable {
  const TeacherTimetableState();

  @override
  List<Object?> get props => [];
}

class TeacherTimetableInitial extends TeacherTimetableState {
  const TeacherTimetableInitial();
}

class TeacherTimetableLoading extends TeacherTimetableState {
  const TeacherTimetableLoading();
}

class TeacherTimetableLoaded extends TeacherTimetableState {
  TeacherTimetableLoaded(List<ClassTimetableEntryEntity> entries)
      : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final List<ClassTimetableEntryEntity> entries;

  @override
  List<Object> get props => [entries];
}

class TeacherTimetableError extends TeacherTimetableState {
  const TeacherTimetableError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
'@

$blocContent = @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_teacher_timetable.dart';
import 'teacher_timetable_event.dart';
import 'teacher_timetable_state.dart';

class TeacherTimetableBloc
    extends Bloc<TeacherTimetableEvent, TeacherTimetableState> {
  TeacherTimetableBloc(this._getTeacherTimetable)
      : super(const TeacherTimetableInitial()) {
    on<LoadTeacherTimetableEvent>(_onLoad);
  }

  final GetTeacherTimetable _getTeacherTimetable;

  Future<void> _onLoad(
    LoadTeacherTimetableEvent event,
    Emitter<TeacherTimetableState> emit,
  ) async {
    emit(const TeacherTimetableLoading());

    try {
      final entries = await _getTeacherTimetable(
        branchId: event.branchId,
        academicSession: event.academicSession,
        teacherId: event.teacherId,
      );
      emit(TeacherTimetableLoaded(entries));
    } catch (error) {
      emit(TeacherTimetableError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
'@

$pageContent = @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/teacher_timetable_bloc.dart';
import '../bloc/teacher_timetable_event.dart';
import '../bloc/teacher_timetable_state.dart';

class TeacherTimetablePage extends StatelessWidget {
  const TeacherTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherTimetableBloc>(
      create: (_) => sl<TeacherTimetableBloc>(),
      child: const _TeacherTimetableView(),
    );
  }
}

class _TeacherTimetableView extends StatefulWidget {
  const _TeacherTimetableView();

  @override
  State<_TeacherTimetableView> createState() =>
      _TeacherTimetableViewState();
}

class _TeacherTimetableViewState extends State<_TeacherTimetableView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  List<TeacherEntity> _teachers = const [];
  List<ClassTimetableEntryEntity> _cachedEntries = const [];
  TimetableConfigurationEntity? _configuration;
  String? _selectedTeacherId;
  String? _referenceError;
  bool _referenceLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReferenceData();
      }
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    final branchId = _branchController.text.trim();
    final academicSession = _sessionController.text.trim();
    if (branchId.isEmpty || academicSession.isEmpty) {
      setState(() {
        _referenceLoading = false;
        _referenceError = 'Branch and academic session are required.';
      });
      return;
    }

    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final values = await Future.wait<Object?>([
        sl<TeacherRepository>().getTeachers(),
        sl<TimetableRepository>().getConfiguration(
          branchId: branchId,
          academicSession: academicSession,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final teachers = (values[0] as List<TeacherEntity>)
          .where((teacher) => teacher.isActive)
          .toList()
        ..sort((first, second) =>
            first.fullName.compareTo(second.fullName));
      final configuration = values[1] as TimetableConfigurationEntity?;
      final teacherId = teachers.isEmpty ? null : teachers.first.id;

      setState(() {
        _teachers = teachers;
        _configuration = configuration;
        _selectedTeacherId = teacherId;
        _cachedEntries = const [];
        _referenceLoading = false;
      });

      if (configuration != null && teacherId != null) {
        _loadTimetable();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _referenceLoading = false;
        _referenceError = _message(error);
      });
    }
  }

  void _selectTeacher(String? teacherId) {
    if (teacherId == null) {
      return;
    }
    setState(() {
      _selectedTeacherId = teacherId;
      _cachedEntries = const [];
    });
    _loadTimetable();
  }

  void _loadTimetable() {
    final teacherId = _selectedTeacherId;
    if (_configuration == null || teacherId == null) {
      return;
    }
    context.read<TeacherTimetableBloc>().add(
          LoadTeacherTimetableEvent(
            branchId: _branchController.text.trim(),
            academicSession: _sessionController.text.trim(),
            teacherId: teacherId,
          ),
        );
  }

  TeacherEntity? get _selectedTeacher {
    for (final teacher in _teachers) {
      if (teacher.id == _selectedTeacherId) {
        return teacher;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Timetable')),
      body: SafeArea(
        child: BlocConsumer<TeacherTimetableBloc, TeacherTimetableState>(
          listener: (context, state) {
            if (state is TeacherTimetableLoaded) {
              _cachedEntries = state.entries;
            } else if (state is TeacherTimetableError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final entries = state is TeacherTimetableLoaded
                ? state.entries
                : _cachedEntries;
            final isBusy =
                _referenceLoading || state is TeacherTimetableLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Timetable',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Review weekly teaching assignments and free '
                            'periods for each teacher.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilters(isBusy),
                          const SizedBox(height: 20),
                          if (_referenceError != null)
                            _MessageCard(
                              icon: Icons.error_outline,
                              message: _referenceError!,
                              color: Theme.of(context).colorScheme.error,
                            )
                          else if (!_referenceLoading)
                            _buildContent(entries),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isBusy)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(bool isBusy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 290,
              child: DropdownButtonFormField<String>(
                key: ValueKey('teacher_$_selectedTeacherId'),
                initialValue: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Teacher',
                  border: OutlineInputBorder(),
                ),
                items: _teachers
                    .map(
                      (teacher) => DropdownMenuItem<String>(
                        value: teacher.id,
                        child: Text(teacher.fullName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : _selectTeacher,
              ),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : _loadReferenceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Timetable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ClassTimetableEntryEntity> entries) {
    final configuration = _configuration;
    if (configuration == null) {
      return const _MessageCard(
        icon: Icons.settings_outlined,
        message:
            'Timetable configuration was not found. Complete Timetable '
            'Configuration for this branch and session first.',
        color: Color(0xFFF57C00),
      );
    }
    if (_teachers.isEmpty) {
      return const _MessageCard(
        icon: Icons.person_off_outlined,
        message: 'No active teachers are available.',
        color: Color(0xFFF57C00),
      );
    }

    final periods = configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList(growable: false);
    final days = configuration.workingDays.toList()..sort();
    if (periods.isEmpty || days.isEmpty) {
      return const _MessageCard(
        icon: Icons.event_busy_outlined,
        message: 'No teaching periods or working days are configured.',
        color: Color(0xFFF57C00),
      );
    }

    final validDays = days.toSet();
    final validPeriodIds = periods.map((period) => period.id).toSet();
    final currentEntries = entries
        .where(
          (entry) =>
              validDays.contains(entry.weekday) &&
              validPeriodIds.contains(entry.periodId),
        )
        .toList(growable: false);
    final bySlot = <String, ClassTimetableEntryEntity>{
      for (final entry in currentEntries)
        '${entry.weekday}|${entry.periodId}': entry,
    };
    final totalSlots = periods.length * days.length;
    final assignedSlots = bySlot.length;
    final freeSlots = totalSlots - assignedSlots;

    return Column(
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _SummaryCard(
              label: 'Assigned Periods',
              value: assignedSlots.toString(),
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF7E57C2),
            ),
            _SummaryCard(
              label: 'Free Periods',
              value: freeSlots.toString(),
              icon: Icons.free_breakfast_outlined,
              color: const Color(0xFF00897B),
            ),
            _SummaryCard(
              label: 'Weekly Slots',
              value: totalSlots.toString(),
              icon: Icons.calendar_view_week_outlined,
              color: const Color(0xFF039BE5),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.co_present_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedTeacher?.fullName ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('$assignedSlots periods'),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 165 + (days.length * 190),
                  child: Table(
                    border: TableBorder.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    columnWidths: <int, TableColumnWidth>{
                      0: const FixedColumnWidth(165),
                      for (var index = 1; index <= days.length; index++)
                        index: const FixedColumnWidth(190),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        children: [
                          _headerCell('Period'),
                          for (final day in days)
                            _headerCell(_dayName(day)),
                        ],
                      ),
                      for (final period in periods)
                        TableRow(
                          children: [
                            _periodCell(period),
                            for (final day in days)
                              _scheduleCell(
                                bySlot['$day|${period.id}'],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _periodCell(TimetablePeriodEntity period) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '${_formatMinutes(period.startMinutes)} - '
            '${_formatMinutes(period.endMinutes)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _scheduleCell(ClassTimetableEntryEntity? entry) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(10),
      color: entry == null
          ? const Color(0xFF00897B).withAlpha(15)
          : null,
      child: entry == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF00897B),
                ),
                SizedBox(height: 5),
                Text(
                  'Free',
                  style: TextStyle(
                    color: Color(0xFF00897B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${entry.className} - ${entry.sectionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _dayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Day',
    };
  }

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
'@

Write-ProjectFile -RelativePath $newFiles[0] -Content $useCaseContent
Write-ProjectFile -RelativePath $newFiles[1] -Content $eventContent
Write-ProjectFile -RelativePath $newFiles[2] -Content $stateContent
Write-ProjectFile -RelativePath $newFiles[3] -Content $blocContent
Write-ProjectFile -RelativePath $newFiles[4] -Content $pageContent

$serviceLocatorPath = Join-Path $projectRoot $serviceLocatorRelative
$serviceLocatorContent = [System.IO.File]::ReadAllText($serviceLocatorPath)
$serviceLocatorContent = $serviceLocatorContent.Replace("`r`n", "`n")

$useCaseImport = "import '../../features/timetable/domain/usecases/get_teacher_timetable.dart';`n"
$serviceLocatorContent = Add-BlockBeforeAnchor `
    -Content $serviceLocatorContent `
    -Marker "features/timetable/domain/usecases/get_teacher_timetable.dart" `
    -Anchor "import '../../features/timetable/domain/usecases/get_timetable_configuration.dart';" `
    -Block $useCaseImport

$blocImport = "import '../../features/timetable/presentation/bloc/teacher_timetable_bloc.dart';`n"
$serviceLocatorContent = Add-BlockBeforeAnchor `
    -Content $serviceLocatorContent `
    -Marker "features/timetable/presentation/bloc/teacher_timetable_bloc.dart" `
    -Anchor "import '../../features/timetable/presentation/bloc/timetable_configuration_bloc.dart';" `
    -Block $blocImport

$useCaseRegistration = @'
  sl.registerLazySingleton<GetTeacherTimetable>(
    () => GetTeacherTimetable(
      sl<TimetableRepository>(),
    ),
  );

'@
$serviceLocatorContent = Add-BlockBeforeAnchor `
    -Content $serviceLocatorContent `
    -Marker 'registerLazySingleton<GetTeacherTimetable>' `
    -Anchor '  sl.registerLazySingleton<GetTimetableConfiguration>(' `
    -Block $useCaseRegistration

$blocRegistration = @'
  sl.registerFactory<TeacherTimetableBloc>(
    () => TeacherTimetableBloc(
      sl<GetTeacherTimetable>(),
    ),
  );

'@
$serviceLocatorContent = Add-BlockBeforeAnchor `
    -Content $serviceLocatorContent `
    -Marker 'registerFactory<TeacherTimetableBloc>' `
    -Anchor '  sl.registerFactory<TimetableConfigurationBloc>(' `
    -Block $blocRegistration

[System.IO.File]::WriteAllText($serviceLocatorPath, $serviceLocatorContent, $utf8NoBom)
Write-Host "Updated: $serviceLocatorRelative" -ForegroundColor Green

$dashboardPath = Join-Path $projectRoot $dashboardRelative
$dashboardContent = [System.IO.File]::ReadAllText($dashboardPath)
$dashboardContent = $dashboardContent.Replace("`r`n", "`n")

$teacherTimetableImport = "import 'teacher_timetable_page.dart';"
if (-not $dashboardContent.Contains($teacherTimetableImport)) {
    $configurationImport = "import 'timetable_configuration_page.dart';"
    if (-not $dashboardContent.Contains($configurationImport)) {
        throw 'Could not find the Timetable Configuration import in dashboard.'
    }
    $dashboardContent = $dashboardContent.Replace(
        $configurationImport,
        "$teacherTimetableImport`n$configurationImport"
    )
}

$oldTeacherCard = @'
      const _TimetableFeature(
        title: 'Teacher Timetable',
        description: 'View each teacher\'s weekly teaching schedule.',
        icon: Icons.co_present_outlined,
        color: Color(0xFF7E57C2),
      ),
'@

$newTeacherCard = @'
      _TimetableFeature(
        title: 'Teacher Timetable',
        description: 'View each teacher\'s weekly teaching schedule.',
        icon: Icons.co_present_outlined,
        color: const Color(0xFF7E57C2),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TeacherTimetablePage(),
            ),
          );
        },
      ),
'@

if ($dashboardContent.Contains($oldTeacherCard)) {
    $dashboardContent = $dashboardContent.Replace(
        $oldTeacherCard,
        $newTeacherCard
    )
} elseif (-not $dashboardContent.Contains(
    'builder: (_) => const TeacherTimetablePage()'
)) {
    throw 'Could not locate the Teacher Timetable card in dashboard.'
}

[System.IO.File]::WriteAllText($dashboardPath, $dashboardContent, $utf8NoBom)
Write-Host "Updated: $dashboardRelative" -ForegroundColor Green
Write-Host "Backup location: $backupRoot" -ForegroundColor DarkGray

$formatFiles = $modifiedFiles + $newFiles

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan
& dart format $formatFiles
if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan
& flutter analyze
if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Review the output above.'
}

Write-Host ''
Write-Host 'Timetable Phase 6 Teacher Timetable completed successfully.' -ForegroundColor Green
