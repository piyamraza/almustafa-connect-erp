import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../widgets/attendance_academic_structure.dart';
import 'attendance_calendar_page.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  final _academicStructureRepository = sl<AcademicStructureRepository>();
  final _searchController = TextEditingController();

  late Future<AttendanceAcademicStructure> _academicStructureFuture;
  String? _selectedClass;
  String? _selectedSection;

  bool get _isChoosingClass => _selectedClass == null;

  @override
  void initState() {
    super.initState();
    _reloadAcademicStructure();
  }

  void _reloadAcademicStructure() {
    _academicStructureFuture = AttendanceAcademicStructure.load(
      _academicStructureRepository,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectClass(String className, List<String> sections) async {
    String? section;
    if (sections.length == 1) {
      section = sections.single;
    } else if (sections.length > 1) {
      section = await _showSectionPicker(className, sections);
      if (section == null || !mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _selectedClass = className;
      _selectedSection = section;
    });
  }

  Future<String?> _showSectionPicker(String className, List<String> sections) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select $className section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sections
              .map(
                (section) => ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: Text('Section $section'),
                  onTap: () => Navigator.pop(dialogContext, section),
                ),
              )
              .toList(growable: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AttendanceBloc>()..add(const LoadAttendanceEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isChoosingClass ? 'Attendance History' : _selectedClass!,
          ),
          leading: _isChoosingClass
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'All classes',
                  onPressed: () => setState(() {
                    _selectedClass = null;
                    _selectedSection = null;
                  }),
                ),
          actions: [
            IconButton(
              tooltip: 'Refresh classes',
              onPressed: () => setState(_reloadAcademicStructure),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<AttendanceAcademicStructure>(
          future: _academicStructureFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _HistoryLoadError(
                onRetry: () => setState(_reloadAcademicStructure),
              );
            }
            final structure = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: _isChoosingClass
                  ? _HistoryClassGrid(
                      classes: structure.classNames,
                      onSelected: (className) => _selectClass(
                        className,
                        structure.sectionNamesForClass(className),
                      ),
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText:
                                'Search by student name or admission number',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${_selectedClass!}${_selectedSection == null ? '' : ' • Section $_selectedSection'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: AttendanceCalendarPage(
                            classId: _selectedClass!,
                            sectionId: _selectedSection,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryClassGrid extends StatelessWidget {
  const _HistoryClassGrid({required this.classes, required this.onSelected});

  final List<String> classes;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return const Center(
        child: Text('No active classes are available in the Classes module.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 1.8 : 3.2,
          ),
          itemCount: classes.length,
          itemBuilder: (context, index) => Card(
            child: InkWell(
              onTap: () => onSelected(classes[index]),
              child: Center(
                child: Text(
                  classes[index],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryLoadError extends StatelessWidget {
  const _HistoryLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Retry loading classes'),
    ),
  );
}
