import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../../core/widgets/app_page_layout.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../school_engagement/presentation/pages/school_engagement_page.dart';
import '../../domain/entities/student_entity.dart';
import '../bloc/student_bloc.dart';
import '../bloc/student_event.dart';
import '../bloc/student_state.dart';
import 'add_student_page.dart';
import 'student_details_page.dart';

const _pageBackground = Color(0xFFF5F7FA);
const _brandBlue = Color(0xFF0B63CE);
const _borderColor = Color(0xFFE1E6ED);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

enum _SearchField {
  all('All student details', Icons.manage_search),
  fatherName('Father name', Icons.person_outline),
  motherName('Mother name', Icons.person_outline),
  guardianName('Guardian name', Icons.supervisor_account_outlined),
  mobileNumber('Mobile number', Icons.phone_outlined),
  cnic('CNIC', Icons.credit_card_outlined),
  dateOfBirth('Date of birth', Icons.calendar_today_outlined),
  bloodGroup('Blood group', Icons.bloodtype_outlined);

  const _SearchField(this.label, this.icon);
  final String label;
  final IconData icon;
}

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentBloc>(
      create: (_) => sl<StudentBloc>()..add(const LoadStudentsEvent()),
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatefulWidget {
  const _StudentsView();

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  static const _rowsPerPage = 10;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SearchField _searchField = _SearchField.all;
  String? _selectedClassId;
  String? _selectedSectionId;
  bool? _selectedActiveStatus;
  int _currentPage = 0;
  late final Future<List<Object>> _structureFuture;

  @override
  void initState() {
    super.initState();
    final repository = sl<AcademicStructureRepository>();
    _structureFuture = Future.wait<Object>([
      repository.getClasses(),
      repository.getSections(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshStudents() async {
    final bloc = context.read<StudentBloc>();
    bloc.add(const RefreshStudentsEvent());
    await bloc.stream.firstWhere(
      (state) => state is StudentLoaded || state is StudentError,
    );
  }

  void _resetPage() => _currentPage = 0;

  List<StudentEntity> _filterStudents(
    List<StudentEntity> students,
    List<AcademicClassEntity> classes,
    List<SectionEntity> sections,
  ) {
    AcademicClassEntity? selectedClass;
    SectionEntity? selectedSection;
    for (final academicClass in classes) {
      if (academicClass.id == _selectedClassId) selectedClass = academicClass;
    }
    for (final section in sections) {
      if (section.id == _selectedSectionId) selectedSection = section;
    }
    return students.where((student) {
      final searchText = _searchTextFor(student);
      final studentClass = student.classId.trim().toLowerCase();
      final studentSection = student.sectionId.trim().toLowerCase();
      final classMatches =
          _selectedClassId == null ||
          studentClass == _selectedClassId!.trim().toLowerCase() ||
          (selectedClass != null &&
              studentClass == selectedClass.name.trim().toLowerCase());
      final sectionMatches =
          _selectedSectionId == null ||
          studentSection == _selectedSectionId!.trim().toLowerCase() ||
          (selectedSection != null &&
              studentSection == selectedSection.name.trim().toLowerCase());
      return (_searchQuery.isEmpty || searchText.contains(_searchQuery)) &&
          classMatches &&
          sectionMatches &&
          (_selectedActiveStatus == null ||
              student.isActive == _selectedActiveStatus);
    }).toList()..sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
  }

  String _searchTextFor(StudentEntity student) {
    final dob = student.dateOfBirth;
    final formattedDob = '${dob.day}/${dob.month}/${dob.year}';
    final values = switch (_searchField) {
      _SearchField.fatherName => [student.fatherName],
      _SearchField.motherName => [student.motherName],
      _SearchField.guardianName => [student.guardianName],
      _SearchField.mobileNumber => [
        student.fatherPhone,
        student.motherPhone,
        student.guardianPhone,
      ],
      _SearchField.cnic => [
        student.fatherCnic,
        student.motherCnic,
        student.guardianCnic,
      ],
      _SearchField.dateOfBirth => [formattedDob, dob.toIso8601String()],
      _SearchField.bloodGroup => [student.bloodGroup],
      _SearchField.all => [
        student.fullName,
        student.admissionNo,
        student.rollNumber,
        student.fatherName,
        student.fatherCnic,
        student.fatherPhone,
        student.motherName,
        student.motherCnic,
        student.motherPhone,
        student.guardianName,
        student.guardianCnic,
        student.guardianPhone,
        student.guardianEmail,
        formattedDob,
        dob.toIso8601String(),
        student.bloodGroup,
        student.medicalAllergies,
      ],
    };
    return values.join(' ').toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: BlocBuilder<StudentBloc, StudentState>(
          builder: (context, state) {
            if (state is StudentLoading || state is StudentInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StudentError) {
              return _ErrorState(
                message: state.message,
                onRetry: _refreshStudents,
              );
            }
            final students = state is StudentLoaded
                ? state.students
                : const <StudentEntity>[];
            return FutureBuilder<List<Object>>(
              future: _structureFuture,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final classes = data == null
                    ? const <AcademicClassEntity>[]
                    : data[0] as List<AcademicClassEntity>;
                final sections = data == null
                    ? const <SectionEntity>[]
                    : data[1] as List<SectionEntity>;
                return _buildDirectory(students, classes, sections);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDirectory(
    List<StudentEntity> students,
    List<AcademicClassEntity> classes,
    List<SectionEntity> sections,
  ) {
    final filtered = _filterStudents(students, classes, sections);
    final totalPages = math.max(1, (filtered.length / _rowsPerPage).ceil());
    final safePage = math.min(_currentPage, totalPages - 1);
    final start = safePage * _rowsPerPage;
    final visible = filtered.skip(start).take(_rowsPerPage).toList();
    final classNames = {for (final item in classes) item.id: item.name};
    final sectionNames = {for (final item in sections) item.id: item.name};

    return RefreshIndicator(
      onRefresh: _refreshStudents,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            sliver: SliverToBoxAdapter(child: _buildHeader()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            sliver: SliverToBoxAdapter(
              child: _SummaryCards(students: students),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverToBoxAdapter(
              child: _DirectoryCard(
                students: visible,
                filteredCount: filtered.length,
                startIndex: filtered.isEmpty ? 0 : start + 1,
                endIndex: math.min(start + visible.length, filtered.length),
                currentPage: safePage,
                totalPages: totalPages,
                searchController: _searchController,
                searchField: _searchField,
                classes: classes,
                sections: sections,
                selectedClassId: _selectedClassId,
                selectedSectionId: _selectedSectionId,
                selectedActiveStatus: _selectedActiveStatus,
                classNames: classNames,
                sectionNames: sectionNames,
                onSearch: (value) => setState(() {
                  _searchQuery = value.trim().toLowerCase();
                  _resetPage();
                }),
                onClearSearch: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _resetPage();
                }),
                onSearchFieldChanged: (value) => setState(() {
                  _searchField = value;
                  _resetPage();
                }),
                onClassChanged: (value) => setState(() {
                  _selectedClassId = value;
                  _selectedSectionId = null;
                  _resetPage();
                }),
                onSectionChanged: (value) => setState(() {
                  _selectedSectionId = value;
                  _resetPage();
                }),
                onStatusChanged: (value) => setState(() {
                  _selectedActiveStatus = value;
                  _resetPage();
                }),
                onResetFilters: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchField = _SearchField.all;
                  _selectedClassId = null;
                  _selectedSectionId = null;
                  _selectedActiveStatus = null;
                  _resetPage();
                }),
                onPageChanged: (page) => setState(() => _currentPage = page),
                onOpen: _openDetails,
                onEdit: _openEditor,
                onToggleStatus: _toggleStudentStatus,
                onDelete: _deleteStudent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return AppPageHeader(
      title: 'Students',
      description: 'Manage admissions, profiles and student records',
      icon: Icons.school_rounded,
      actions: compact
          ? [
              const DashboardNavigationButton(),
              IconButton.filledTonal(
                tooltip: 'Import Students',
                onPressed: () => _showComingSoon('Student import'),
                icon: const Icon(Icons.upload_file_outlined),
              ),
              IconButton.filled(
                tooltip: 'Birthdays',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SchoolEngagementPage(),
                  ),
                ),
                icon: const Icon(Icons.cake_outlined),
              ),
              IconButton.filledTonal(
                tooltip: 'Export',
                onPressed: () => _showComingSoon('Student export'),
                icon: const Icon(Icons.download_outlined),
              ),
              IconButton.filled(
                tooltip: 'Add Student',
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
              ),
            ]
          : [
              const DashboardNavigationButton(),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon('Student import'),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import Students'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE94883),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SchoolEngagementPage(),
                  ),
                ),
                icon: const Icon(Icons.cake_outlined),
                label: const Text('Birthdays'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon('Student export'),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export'),
              ),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
              ),
            ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be available soon.')));
  }

  Future<void> _openEditor([StudentEntity? student]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StudentBloc>(),
          child: AddStudentPage(student: student),
        ),
      ),
    );
    if (result == true && mounted) await _refreshStudents();
  }

  Future<void> _openDetails(StudentEntity student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StudentBloc>(),
          child: StudentDetailsPage(student: student),
        ),
      ),
    );
    if (result == true && mounted) await _refreshStudents();
  }

  Future<void> _deleteStudent(StudentEntity student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text(
          'This will permanently delete ${student.fullName}\'s record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<StudentBloc>().add(DeleteStudentEvent(student.id));
    }
  }

  void _toggleStudentStatus(StudentEntity student) {
    context.read<StudentBloc>().add(
      UpdateStudentEvent(student.copyWith(isActive: !student.isActive)),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.students});
  final List<StudentEntity> students;

  @override
  Widget build(BuildContext context) {
    final active = students.where((student) => student.isActive).length;
    final boys = students
        .where((student) => student.gender.toLowerCase() == 'male')
        .length;
    final girls = students
        .where((student) => student.gender.toLowerCase() == 'female')
        .length;
    final cards = [
      _MetricData(
        'Total Students',
        students.length,
        'All enrolled students',
        Icons.groups_outlined,
        const Color(0xFF246BFD),
      ),
      _MetricData(
        'Active Students',
        active,
        'Currently active students',
        Icons.how_to_reg_outlined,
        const Color(0xFF17A66B),
      ),
      _MetricData(
        'Boys',
        boys,
        '${_percentage(boys, students.length)}% of total students',
        Icons.face_6_outlined,
        const Color(0xFF3578F6),
        _MetricIllustration.boy,
      ),
      _MetricData(
        'Girls',
        girls,
        '${_percentage(girls, students.length)}% of total students',
        Icons.face_3_outlined,
        const Color(0xFFE54868),
        _MetricIllustration.girl,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 560
            ? 2
            : 2;
        final itemWidth = (width - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _MetricCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static String _percentage(int value, int total) =>
      total == 0 ? '0' : (value * 100 / total).toStringAsFixed(1);
}

enum _MetricIllustration { boy, girl }

class _MetricData {
  const _MetricData(
    this.label,
    this.value,
    this.caption,
    this.icon,
    this.color, [
    this.illustration,
  ]);
  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final Color color;
  final _MetricIllustration? illustration;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, data.color.withValues(alpha: .045)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: .20)),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 21),
                ),
                const SizedBox(height: 6),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.color.withValues(alpha: .18),
                      width: 1.5,
                    ),
                  ),
                  child: data.illustration == null
                      ? Icon(data.icon, color: data.color, size: 36)
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: CustomPaint(
                            painter: _StudentAvatarPainter(
                              color: data.color,
                              girl:
                                  data.illustration == _MetricIllustration.girl,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${data.value}',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data.caption,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StudentAvatarPainter extends CustomPainter {
  const _StudentAvatarPainter({required this.color, required this.girl});

  final Color color;
  final bool girl;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;

    if (girl) {
      final hair = Path()
        ..moveTo(24, 5)
        ..cubicTo(12, 5, 8, 13, 9, 28)
        ..cubicTo(10, 35, 7, 39, 5, 40)
        ..cubicTo(10, 42, 14, 40, 15, 36)
        ..moveTo(24, 5)
        ..cubicTo(36, 5, 40, 13, 39, 28)
        ..cubicTo(38, 35, 41, 39, 43, 40)
        ..cubicTo(38, 42, 34, 40, 33, 36);
      canvas.drawPath(hair, stroke);
      final fringe = Path()
        ..moveTo(24, 6)
        ..cubicTo(22, 12, 17, 14, 14, 17)
        ..moveTo(24, 6)
        ..cubicTo(26, 12, 31, 14, 34, 17);
      canvas.drawPath(fringe, stroke);
      canvas.drawOval(const Rect.fromLTWH(12, 13, 24, 25), stroke);
      final shoulders = Path()
        ..moveTo(9, 47)
        ..cubicTo(11, 41, 16, 39, 19, 38)
        ..cubicTo(20, 42, 28, 42, 29, 38)
        ..cubicTo(32, 39, 37, 41, 39, 47);
      canvas.drawPath(shoulders, stroke);
    } else {
      canvas.drawOval(const Rect.fromLTWH(11, 11, 26, 27), stroke);
      final hair = Path()
        ..moveTo(12, 20)
        ..cubicTo(12, 9, 19, 5, 28, 7)
        ..cubicTo(34, 8, 37, 12, 36, 18)
        ..cubicTo(30, 14, 21, 14, 13, 18);
      canvas.drawPath(hair, stroke);
      final shoulders = Path()
        ..moveTo(6, 47)
        ..cubicTo(7, 41, 13, 38, 18, 37)
        ..lineTo(24, 43)
        ..lineTo(30, 37)
        ..cubicTo(35, 38, 41, 41, 42, 47);
      canvas.drawPath(shoulders, stroke);
      canvas.drawLine(const Offset(18, 37), const Offset(18, 41), stroke);
      canvas.drawLine(const Offset(30, 37), const Offset(30, 41), stroke);
    }

    canvas.drawCircle(const Offset(19, 25), 1.15, dot);
    canvas.drawCircle(const Offset(29, 25), 1.15, dot);
    final smile = Path()
      ..moveTo(20, 30)
      ..quadraticBezierTo(24, 34, 28, 30);
    canvas.drawPath(smile, stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StudentAvatarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.girl != girl;
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({
    required this.students,
    required this.filteredCount,
    required this.startIndex,
    required this.endIndex,
    required this.currentPage,
    required this.totalPages,
    required this.searchController,
    required this.searchField,
    required this.classes,
    required this.sections,
    required this.selectedClassId,
    required this.selectedSectionId,
    required this.selectedActiveStatus,
    required this.classNames,
    required this.sectionNames,
    required this.onSearch,
    required this.onClearSearch,
    required this.onSearchFieldChanged,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onStatusChanged,
    required this.onResetFilters,
    required this.onPageChanged,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final List<StudentEntity> students;
  final int filteredCount, startIndex, endIndex, currentPage, totalPages;
  final TextEditingController searchController;
  final _SearchField searchField;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final String? selectedClassId, selectedSectionId;
  final bool? selectedActiveStatus;
  final Map<String, String> classNames, sectionNames;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch, onResetFilters;
  final ValueChanged<_SearchField> onSearchFieldChanged;
  final ValueChanged<String?> onClassChanged, onSectionChanged;
  final ValueChanged<bool?> onStatusChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<StudentEntity> onOpen, onEdit, onToggleStatus, onDelete;

  @override
  Widget build(BuildContext context) {
    final availableSections = sections
        .where(
          (item) =>
              item.isActive &&
              (selectedClassId == null || item.classId == selectedClassId),
        )
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Text(
              'Student Directory',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final searchWidth = constraints.maxWidth >= 850
                    ? math.min(380.0, constraints.maxWidth * .34)
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: searchWidth,
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearch,
                        decoration: InputDecoration(
                          hintText: searchField == _SearchField.all
                              ? 'Search student records...'
                              : 'Search by ${searchField.label.toLowerCase()}...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 40,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (searchController.text.isNotEmpty)
                                IconButton(
                                  onPressed: onClearSearch,
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                              Container(
                                height: 28,
                                width: 1,
                                color: _borderColor,
                              ),
                              PopupMenuButton<_SearchField>(
                                tooltip: 'Choose search option',
                                icon: Icon(
                                  Icons.tune,
                                  color: searchField == _SearchField.all
                                      ? _textSecondary
                                      : _brandBlue,
                                ),
                                onSelected: onSearchFieldChanged,
                                itemBuilder: (context) => _SearchField.values
                                    .map(
                                      (field) => PopupMenuItem<_SearchField>(
                                        value: field,
                                        child: Row(
                                          children: [
                                            Icon(
                                              field.icon,
                                              size: 20,
                                              color: field == searchField
                                                  ? _brandBlue
                                                  : _textSecondary,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(child: Text(field.label)),
                                            if (field == searchField)
                                              const Icon(
                                                Icons.check,
                                                size: 18,
                                                color: _brandBlue,
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    _StringDropdown(
                      label: 'All Classes',
                      value: selectedClassId,
                      items: classes
                          .where((item) => item.isActive)
                          .map((item) => MapEntry(item.id, item.name))
                          .toList(),
                      onChanged: onClassChanged,
                    ),
                    _StringDropdown(
                      label: 'All Sections',
                      value: selectedSectionId,
                      items: availableSections
                          .map((item) => MapEntry(item.id, item.name))
                          .toList(),
                      onChanged: onSectionChanged,
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<bool>(
                        initialValue: selectedActiveStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('All Status'),
                          ),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: onStatusChanged,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onResetFilters,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset'),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          if (students.isEmpty)
            const SizedBox(
              height: 280,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 48,
                      color: _textSecondary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No students match these filters.',
                      style: TextStyle(color: _textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            _StudentTable(
              students: students,
              classNames: classNames,
              sectionNames: sectionNames,
              onOpen: onOpen,
              onEdit: onEdit,
              onToggleStatus: onToggleStatus,
              onDelete: onDelete,
            ),
          const Divider(height: 1),
          _PaginationFooter(
            startIndex: startIndex,
            endIndex: endIndex,
            total: filteredCount,
            currentPage: currentPage,
            totalPages: totalPages,
            onChanged: onPageChanged,
          ),
        ],
      ),
    );
  }
}

class _StringDropdown extends StatelessWidget {
  const _StringDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: items.any((item) => item.key == value) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(label)),
          ...items.map(
            (item) => DropdownMenuItem(
              value: item.key,
              child: Text(item.value, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StudentTable extends StatelessWidget {
  const _StudentTable({
    required this.students,
    required this.classNames,
    required this.sectionNames,
    required this.onOpen,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });
  final List<StudentEntity> students;
  final Map<String, String> classNames, sectionNames;
  final ValueChanged<StudentEntity> onOpen, onEdit, onToggleStatus, onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: math.max(constraints.maxWidth, 1120),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              headingTextStyle: const TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              dataRowMinHeight: 66,
              dataRowMaxHeight: 66,
              horizontalMargin: 20,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('STUDENT')),
                DataColumn(label: Text('FATHER NAME')),
                DataColumn(label: Text('ADMISSION NO.')),
                DataColumn(label: Text('ROLL NO.')),
                DataColumn(label: Text('CLASS / SECTION')),
                DataColumn(label: Text('CONTACT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: students
                  .map(
                    (student) => DataRow(
                      onSelectChanged: (_) => onOpen(student),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Row(
                              children: [
                                _Avatar(student: student),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.fullName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: Text(
                              student.fatherName.isEmpty
                                  ? '—'
                                  : student.fatherName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            student.admissionNo.isEmpty
                                ? '—'
                                : student.admissionNo,
                          ),
                        ),
                        DataCell(
                          Text(
                            student.rollNumber.isEmpty
                                ? '—'
                                : student.rollNumber,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${classNames[student.classId] ?? student.classId} — ${sectionNames[student.sectionId] ?? student.sectionId}',
                          ),
                        ),
                        DataCell(
                          Text(
                            student.guardianPhone.isEmpty
                                ? '—'
                                : student.guardianPhone,
                          ),
                        ),
                        DataCell(_StatusChip(active: student.isActive)),
                        DataCell(
                          PopupMenuButton<_StudentAction>(
                            tooltip: 'Student actions',
                            onSelected: (action) {
                              if (action == _StudentAction.view) {
                                onOpen(student);
                              }
                              if (action == _StudentAction.edit) {
                                onEdit(student);
                              }
                              if (action == _StudentAction.toggleStatus) {
                                onToggleStatus(student);
                              }
                              if (action == _StudentAction.delete) {
                                onDelete(student);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: _StudentAction.view,
                                child: _MenuItem(
                                  icon: Icons.visibility_outlined,
                                  label: 'View profile',
                                ),
                              ),
                              const PopupMenuItem(
                                value: _StudentAction.edit,
                                child: _MenuItem(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                ),
                              ),
                              PopupMenuItem(
                                value: _StudentAction.toggleStatus,
                                child: _MenuItem(
                                  icon: student.isActive
                                      ? Icons.person_off_outlined
                                      : Icons.person_add_alt_outlined,
                                  label: student.isActive
                                      ? 'Deactivate'
                                      : 'Activate',
                                  color: student.isActive
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: _StudentAction.delete,
                                child: _MenuItem(
                                  icon: Icons.delete_outline,
                                  label: 'Delete',
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

enum _StudentAction { view, edit, toggleStatus, delete }

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: color),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.student});
  final StudentEntity student;
  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      backgroundColor: const Color(0xFFE8F0FE),
      child: Text(
        student.firstName.isEmpty ? '?' : student.firstName[0].toUpperCase(),
        style: const TextStyle(color: _brandBlue, fontWeight: FontWeight.w700),
      ),
    );
    if (student.profileImageUrl.trim().isEmpty) return fallback;
    return CircleAvatar(
      backgroundColor: const Color(0xFFE8F0FE),
      foregroundImage: NetworkImage(student.profileImageUrl),
      onForegroundImageError: (_, _) {},
      child: fallback.child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE8F8EF) : const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: active ? const Color(0xFFA6E4C0) : const Color(0xFFD0D5DD),
      ),
    ),
    child: Text(
      active ? 'Active' : 'Inactive',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: active ? const Color(0xFF137A45) : _textSecondary,
      ),
    ),
  );
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.startIndex,
    required this.endIndex,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.onChanged,
  });
  final int startIndex, endIndex, total, currentPage, totalPages;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            total == 0
                ? 'No students to show'
                : 'Showing $startIndex-$endIndex of $total students',
            style: const TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ),
        IconButton(
          onPressed: currentPage > 0 ? () => onChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous page',
        ),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _brandBlue,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '${currentPage + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'of $totalPages',
            style: const TextStyle(color: _textSecondary),
          ),
        ),
        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => onChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next page',
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
