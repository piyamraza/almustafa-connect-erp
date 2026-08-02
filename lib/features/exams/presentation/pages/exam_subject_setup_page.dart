import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../bloc/exam_subject_setup_bloc.dart';
import '../bloc/exam_subject_setup_event.dart';
import '../bloc/exam_subject_setup_state.dart';
import 'exam_subject_setup_form_page.dart';

class ExamSubjectSetupPage extends StatelessWidget {
  const ExamSubjectSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamSubjectSetupBloc>(
      create: (_) => sl<ExamSubjectSetupBloc>()..add(const LoadExamSubjectSetups()),
      child: const _SubjectSetupView(),
    );
  }
}

class _SubjectSetupView extends StatefulWidget {
  const _SubjectSetupView();

  @override
  State<_SubjectSetupView> createState() => _SubjectSetupViewState();
}

class _SubjectSetupViewState extends State<_SubjectSetupView> {
  final _searchController = TextEditingController();
  String? _examId;
  String? _classId;
  String? _sectionId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<ExamSubjectSetupBloc>().add(
      FilterExamSubjectSetups(
        query: _searchController.text,
        examId: _examId,
        classId: _classId,
        sectionId: _sectionId,
      ),
    );
  }

  Future<void> _openForm(
    ExamSubjectSetupLoaded options, {
    ExamSubjectSetupEntity? setup,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ExamSubjectSetupBloc>(),
          child: ExamSubjectSetupFormPage(options: options, setup: setup),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ExamSubjectSetupEntity setup) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Subject Setup'),
        content: Text('Delete the ${setup.subjectName} configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      context.read<ExamSubjectSetupBloc>().add(DeleteExamSubjectSetupEvent(setup.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Exam Subject Setup')),
      floatingActionButton: BlocBuilder<ExamSubjectSetupBloc, ExamSubjectSetupState>(
        builder: (context, state) {
          if (state is! ExamSubjectSetupLoaded) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openForm(state),
            icon: const Icon(Icons.add),
            label: const Text('Add Subjects'),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ExamSubjectSetupBloc, ExamSubjectSetupState>(
          listener: (context, state) {
            final message = state is ExamSubjectSetupError
                ? state.message
                : state is ExamSubjectSetupLoaded
                    ? state.successMessage
                    : null;
            if (message != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
            }
          },
          builder: (context, state) {
            if (state is ExamSubjectSetupInitial || state is ExamSubjectSetupLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ExamSubjectSetupError) {
              return Center(
                child: FilledButton(
                  onPressed: () => context.read<ExamSubjectSetupBloc>().add(const RefreshExamSubjectSetups()),
                  child: const Text('Try Again'),
                ),
              );
            }
            final data = state as ExamSubjectSetupLoaded;
            final sections = _classId == null ? const <String>[] : data.sectionsFor(_classId!);
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Search subject setups...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FilterDrop(
                      label: 'Exam',
                      value: _examId,
                      items: data.exams.map((exam) => _Choice(exam.id, exam.name)).toList(),
                      onChanged: (value) {
                        setState(() => _examId = value);
                        _applyFilters();
                      },
                    ),
                    _FilterDrop(
                      label: 'Class',
                      value: _classId,
                      items: data.classes.map((value) => _Choice(value, value)).toList(),
                      onChanged: (value) {
                        setState(() {
                          _classId = value;
                          _sectionId = null;
                        });
                        _applyFilters();
                      },
                    ),
                    _FilterDrop(
                      label: 'Section',
                      value: _sectionId,
                      items: sections.map((value) => _Choice(value, value)).toList(),
                      onChanged: (value) {
                        setState(() => _sectionId = value);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<ExamSubjectSetupBloc>().add(const RefreshExamSubjectSetups()),
                    child: data.setups.isEmpty
                        ? ListView(children: const [SizedBox(height: 220, child: Center(child: Text('No subject setups found.')))])
                        : ListView.separated(
                            itemCount: data.setups.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final setup = data.setups[index];
                              return Card(
                                child: ListTile(
                                  onTap: () => _openForm(data, setup: setup),
                                  title: Text(setup.subjectName),
                                  subtitle: Text('${setup.examName} • ${setup.className}-${setup.sectionName}\nTotal: ${setup.totalMarks} • Passing: ${setup.passingMarks}'),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                    spacing: 2,
                                    children: [
                                      Chip(label: Text(setup.isActive ? 'Active' : 'Inactive')),
                                      IconButton(onPressed: () => _openForm(data, setup: setup), icon: const Icon(Icons.edit_outlined)),
                                      IconButton(onPressed: () => _confirmDelete(setup), icon: const Icon(Icons.delete_outline)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Choice { const _Choice(this.id, this.name); final String id; final String name; }
class _FilterDrop extends StatelessWidget { const _FilterDrop({required this.label,required this.value,required this.items,required this.onChanged}); final String label; final String? value; final List<_Choice> items; final ValueChanged<String?> onChanged; @override Widget build(BuildContext context)=>SizedBox(width:220,child:DropdownButtonFormField<String>(initialValue:items.any((item)=>item.id==value)?value:null,isExpanded:true,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:[const DropdownMenuItem(value:null,child:Text('All')),...items.map((item)=>DropdownMenuItem(value:item.id,child:Text(item.name,overflow:TextOverflow.ellipsis)))],onChanged:onChanged)); }
