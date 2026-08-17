import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/appreciation_certificate_entity.dart';
import '../../domain/repositories/appreciation_certificate_repository.dart';
import '../bloc/appreciation_certificate_bloc.dart';
import '../services/appreciation_certificate_pdf_service.dart';
import '../widgets/student_document_selector_dialog.dart';

class AppreciationCertificatePage extends StatelessWidget {
  const AppreciationCertificatePage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        sl<AppreciationCertificateBloc>()
          ..add(const LoadAppreciationCertificates()),
    child: const _AppreciationView(),
  );
}

class _AppreciationView extends StatefulWidget {
  const _AppreciationView();
  @override
  State<_AppreciationView> createState() => _AppreciationViewState();
}

class _AppreciationViewState extends State<_AppreciationView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _title = TextEditingController(text: 'Certificate of Appreciation'),
      _description = TextEditingController(),
      _teacher = TextEditingController(),
      _customCategory = TextEditingController();
  StudentEntity? _student;
  AppreciationCategory _category = AppreciationCategory.excellentProject;
  AppreciationTheme _theme = AppreciationTheme.blueGold;
  DateTime _achievementDate = DateTime.now(), _issueDate = DateTime.now();
  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_title, _description, _teacher, _customCategory])
      c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Appreciation Certificates'),
      actions: const [DashboardNavigationButton()],
    ),
    body:
        BlocConsumer<AppreciationCertificateBloc, AppreciationCertificateState>(
          listener: (context, state) {
            if (state is AppreciationCertificateLoaded && state.message != null)
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
          },
          builder: (context, state) {
            if (state is AppreciationCertificateInitial ||
                state is AppreciationCertificateLoading)
              return const Center(child: CircularProgressIndicator());
            if (state is AppreciationCertificateError)
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    FilledButton(
                      onPressed: () => context
                          .read<AppreciationCertificateBloc>()
                          .add(const LoadAppreciationCertificates()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            final data = state as AppreciationCertificateLoaded;
            if (_description.text.isEmpty && _student != null)
              _description.text = _suggestion(_category, _student!.fullName);
            return Column(
              children: [
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.workspace_premium_outlined),
                      text: 'Create Certificate',
                    ),
                    Tab(icon: Icon(Icons.history), text: 'Issued History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_create(data), _history(data)],
                  ),
                ),
              ],
            );
          },
        ),
  );

  Widget _create(AppreciationCertificateLoaded data) => LayoutBuilder(
    builder: (context, constraints) {
      final form = _form(data);
      final preview = _preview(data);
      return constraints.maxWidth >= 1050
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 390,
                    child: SingleChildScrollView(child: form),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: preview),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                form,
                const SizedBox(height: 12),
                SizedBox(height: 650, child: preview),
              ],
            );
    },
  );
  Widget _form(AppreciationCertificateLoaded data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Certificate Details',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => StudentDocumentSelectorDialog(
                students: data.students,
                title: 'Select Student',
                onSelected: (value) => setState(() {
                  _student = value;
                  _description.text = _suggestion(_category, value.fullName);
                }),
              ),
            ),
            icon: const Icon(Icons.person_search),
            label: Text(_student?.fullName ?? 'Select Student'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppreciationCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Achievement category',
              border: OutlineInputBorder(),
            ),
            items: AppreciationCategory.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value!;
              if (_student != null)
                _description.text = _suggestion(_category, _student!.fullName);
            }),
          ),
          if (_category == AppreciationCategory.custom)
            TextField(
              controller: _customCategory,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Custom category'),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Certificate title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            onChanged: (_) => setState(() {}),
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Achievement wording',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _teacher,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Teacher name (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppreciationTheme>(
            initialValue: _theme,
            decoration: const InputDecoration(
              labelText: 'Certificate theme',
              border: OutlineInputBorder(),
            ),
            items: AppreciationTheme.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                .toList(),
            onChanged: (value) => setState(() => _theme = value!),
          ),
          _dateTile(
            'Achievement date',
            _achievementDate,
            (date) => setState(() => _achievementDate = date),
          ),
          _dateTile(
            'Issue date',
            _issueDate,
            (date) => setState(() => _issueDate = date),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _student == null || _description.text.trim().isEmpty
                ? null
                : () => _issue(data),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Issue & Save Certificate'),
          ),
        ],
      ),
    ),
  );
  Widget _preview(AppreciationCertificateLoaded data) {
    final colors = _themeColors(_theme);
    final student = _student;
    final className = student == null
        ? 'Class / Section'
        : _classSection(data, student);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Live Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: student == null
                      ? null
                      : () => _print(_draft(data)),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Preview'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1120,
                  height: 792,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: colors.$2, width: 8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.$1, width: 2),
                      ),
                      padding: const EdgeInsets.fromLTRB(42, 28, 42, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: _schoolLogo(data.settings.logoUrl),
                              ),
                              const SizedBox(width: 18),
                              Flexible(
                                child: Text(
                                  data.settings.schoolName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .8,
                                    color: colors.$1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _title.text.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: colors.$1,
                            ),
                          ),
                          Container(
                            width: 150,
                            height: 2,
                            color: colors.$2,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          const Text(
                            'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                            style: TextStyle(fontSize: 10, letterSpacing: 1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            student?.fullName ?? 'Student Name',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: colors.$1,
                            ),
                          ),
                          Text(
                            className,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 70),
                            child: Text(
                              _description.text.isEmpty
                                  ? 'Achievement description will appear here.'
                                  : _description.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _categoryLabel(),
                            style: TextStyle(
                              fontSize: 17,
                              color: colors.$2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _sign(
                                'Achievement Date',
                                DateFormat(
                                  'dd MMM yyyy',
                                ).format(_achievementDate),
                                colors.$1,
                              ),
                              _sign(
                                _teacher.text.isEmpty
                                    ? 'Class Teacher'
                                    : _teacher.text,
                                'Teacher',
                                colors.$1,
                              ),
                              _sign(
                                data.settings.principalName.isEmpty
                                    ? 'Principal'
                                    : data.settings.principalName,
                                data.settings.principalDesignation,
                                colors.$1,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Certificate No: ${data.nextSerial}',
                                style: const TextStyle(fontSize: 9),
                              ),
                              Text(
                                'Issued: ${DateFormat('dd MMM yyyy').format(_issueDate)}',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _history(AppreciationCertificateLoaded data) => Padding(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: data.history.isEmpty
            ? const Center(
                child: Text('No appreciation certificates issued yet.'),
              )
            : ListView.separated(
                itemCount: data.history.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = data.history[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.workspace_premium_outlined),
                      ),
                      title: Text(
                        '${item.studentName} • ${item.categoryLabel}',
                      ),
                      subtitle: Text(
                        '${item.serialNumber} • ${item.classSection} • ${DateFormat('dd MMM yyyy').format(item.issueDate)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Reprint',
                        icon: const Icon(Icons.print_outlined),
                        onPressed: () =>
                            const AppreciationCertificatePdfService()
                                .printCertificate(item, data.settings),
                      ),
                    ),
                  );
                },
              ),
      ),
    ),
  );
  Widget _dateTile(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(DateFormat('dd MMM yyyy').format(value)),
    trailing: const Icon(Icons.calendar_month_outlined),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
  );
  Widget _sign(String name, String label, Color color) => SizedBox(
    width: 130,
    child: Column(
      children: [
        const SizedBox(height: 20),
        Container(height: 1, color: color),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.black54)),
      ],
    ),
  );

  Widget _schoolLogo(String url) {
    final fallback = Image.asset(
      'assets/images/logo.jpeg',
      fit: BoxFit.contain,
    );
    if (url.trim().isEmpty) return fallback;
    return Image.network(
      url.trim(),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  String _classSection(
    AppreciationCertificateLoaded data,
    StudentEntity student,
  ) {
    final className =
        data.classes.where((e) => e.id == student.classId).firstOrNull?.name ??
        student.classId;
    final sectionName =
        data.sections
            .where((e) => e.id == student.sectionId)
            .firstOrNull
            ?.name ??
        student.sectionId;
    return [
      className,
      sectionName,
    ].where((e) => e.trim().isNotEmpty).join(' - ');
  }

  String _categoryLabel() =>
      _category == AppreciationCategory.custom &&
          _customCategory.text.trim().isNotEmpty
      ? _customCategory.text.trim()
      : _category.label;
  AppreciationCertificateEntity _draft(AppreciationCertificateLoaded data) {
    final parts = _student == null
        ? const <String>[]
        : _classSection(data, _student!).split(' - ');
    return AppreciationCertificateEntity(
      id: sl<AppreciationCertificateRepository>().newId(),
      serialNumber: data.nextSerial,
      studentId: _student?.id ?? '',
      studentName: _student?.fullName ?? '',
      admissionNumber: _student?.admissionNo ?? '',
      rollNumber: _student?.rollNumber ?? '',
      className: parts.isEmpty ? '' : parts.first,
      sectionName: parts.length < 2 ? '' : parts.sublist(1).join(' - '),
      category: _category,
      categoryLabel: _categoryLabel(),
      title: _title.text.trim().isEmpty
          ? 'Certificate of Appreciation'
          : _title.text.trim(),
      description: _description.text.trim(),
      achievementDate: _achievementDate,
      issueDate: _issueDate,
      teacherName: _teacher.text.trim(),
      principalName: data.settings.principalName,
      theme: _theme,
      issuedAt: DateTime.now(),
    );
  }

  void _issue(AppreciationCertificateLoaded data) {
    context.read<AppreciationCertificateBloc>().add(
      SaveAppreciationCertificate(_draft(data)),
    );
  }

  Future<void> _print(AppreciationCertificateEntity value) =>
      const AppreciationCertificatePdfService().printCertificate(
        value,
        (context.read<AppreciationCertificateBloc>().state
                as AppreciationCertificateLoaded)
            .settings,
      );
  (Color, Color) _themeColors(AppreciationTheme theme) => switch (theme) {
    AppreciationTheme.blueGold => (
      const Color(0xFF123B72),
      const Color(0xFFC99A2E),
    ),
    AppreciationTheme.greenGold => (
      const Color(0xFF176B4D),
      const Color(0xFFC99A2E),
    ),
    AppreciationTheme.maroonGold => (
      const Color(0xFF7A2330),
      const Color(0xFFC99A2E),
    ),
  };
  String _suggestion(
    AppreciationCategory category,
    String name,
  ) => switch (category) {
    AppreciationCategory.academicExcellence =>
      'This certificate is proudly presented to $name in recognition of exceptional academic performance, unwavering dedication to learning, and a consistent pursuit of excellence. May this outstanding achievement inspire continued success.',
    AppreciationCategory.excellentProject =>
      'This certificate is proudly presented to $name for demonstrating remarkable creativity, thoughtful planning, and outstanding effort in completing an excellent project. The quality of this work reflects dedication, skill, and a true passion for learning.',
    AppreciationCategory.subjectAchievement =>
      'This certificate is proudly presented to $name in recognition of outstanding achievement, excellent understanding, and commendable performance in the selected subject. This success is a reflection of sincere effort and determination.',
    AppreciationCategory.artCreativity =>
      'This certificate is proudly presented to $name in appreciation of exceptional imagination, originality, and artistic talent. The outstanding work created is a wonderful expression of creativity, skill, and dedication.',
    AppreciationCategory.scienceExhibition =>
      'This certificate is proudly presented to $name for an excellent contribution to the Science Exhibition, demonstrating curiosity, innovative thinking, scientific understanding, and an admirable commitment to discovery.',
    AppreciationCategory.sportsAchievement =>
      'This certificate is proudly presented to $name in recognition of outstanding athletic achievement, disciplined effort, teamwork, and exemplary sportsmanship. This accomplishment reflects commitment, courage, and perseverance.',
    AppreciationCategory.goodConduct =>
      'This certificate is proudly presented to $name for consistently demonstrating exemplary conduct, kindness, respect, responsibility, and a positive attitude. Such behaviour is a valued example for the entire school community.',
    AppreciationCategory.leadership =>
      'This certificate is proudly presented to $name in recognition of outstanding leadership, responsible decision-making, confidence, and the ability to encourage and inspire others through positive example.',
    AppreciationCategory.regularAttendance =>
      'This certificate is proudly presented to $name in recognition of excellent attendance, punctuality, and consistent commitment throughout the academic session. Such regularity reflects admirable discipline and dedication.',
    AppreciationCategory.communityService =>
      'This certificate is proudly presented to $name in appreciation of meaningful community service, compassion, generosity, and a sincere willingness to help others. This valuable contribution has made a positive difference.',
    AppreciationCategory.specialAchievement =>
      'This certificate is proudly presented to $name in recognition of a remarkable achievement accomplished through dedication, perseverance, and outstanding effort. This success is worthy of appreciation and celebration.',
    AppreciationCategory.custom =>
      'This certificate is proudly presented to $name in recognition of commendable achievement, sincere dedication, and outstanding effort. This accomplishment reflects a positive attitude and a strong commitment to excellence.',
  };
}
