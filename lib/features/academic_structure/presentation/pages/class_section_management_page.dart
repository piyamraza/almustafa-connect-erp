import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/academic_class_entity.dart';
import '../../domain/entities/section_entity.dart';
import '../../domain/repositories/academic_structure_repository.dart';
import 'class_subjects_page.dart';

class ClassSectionManagementPage extends StatefulWidget {
  const ClassSectionManagementPage({super.key});

  @override
  State<ClassSectionManagementPage> createState() => _ClassSectionManagementPageState();
}

class _ClassSectionManagementPageState extends State<ClassSectionManagementPage> {
  final AcademicStructureRepository _repository = sl<AcademicStructureRepository>();
  late Future<List<AcademicClassEntity>> _classesFuture;
  late Future<List<SectionEntity>> _sectionsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _classesFuture = _repository.getClasses();
    _sectionsFuture = _repository.getSections();
  }

  Future<void> _saveClass({AcademicClassEntity? existing}) async {
    final controller = TextEditingController(text: existing?.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Class' : 'Edit Class'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Class name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final now = DateTime.now();
    try {
      await _repository.saveClass(AcademicClassEntity(
        id: existing?.id ?? _repository.generateClassId(),
        name: name,
        isActive: existing?.isActive ?? true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ));
      if (mounted) setState(_reload);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _manageSections(AcademicClassEntity academicClass) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _SectionsPage(academicClass: academicClass, repository: _repository),
    ));
    if (mounted) setState(_reload);
  }

  Future<void> _manageSubjects(AcademicClassEntity academicClass) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ClassSubjectsPage(
          academicClass: academicClass,
          repository: _repository,
        ),
      ),
    );
  }

  Future<void> _deleteClass(AcademicClassEntity academicClass) async {
    final approved = await _confirm('Delete ${academicClass.name}?');
    if (!approved) return;
    try {
      await _repository.deleteClass(academicClass.id);
      if (mounted) setState(_reload);
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Please Confirm'), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])) ?? false;
  }

  void _showError(Object error) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _saveClass, icon: const Icon(Icons.add), label: const Text('Add Class')),
      body: FutureBuilder<List<AcademicClassEntity>>(
        future: _classesFuture,
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classSnapshot.hasError) {
            return Center(child: Text(classSnapshot.error.toString()));
          }

          final classes = classSnapshot.data ?? const <AcademicClassEntity>[];
          if (classes.isEmpty) {
            return const Center(child: Text('No classes added yet.'));
          }

          return FutureBuilder<List<SectionEntity>>(
            future: _sectionsFuture,
            builder: (context, sectionSnapshot) {
              final allSections = sectionSnapshot.data ?? const <SectionEntity>[];
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final academicClass = classes[index];
                  final classSections = allSections
                      .where((section) => section.classId == academicClass.id)
                      .toList();

                  return _ClassCard(
                    academicClass: academicClass,
                    sections: classSections,
                    onManageSections: () => _manageSections(academicClass),
                    onManageSubjects: () => _manageSubjects(academicClass),
                    onEdit: () => _saveClass(existing: academicClass),
                    onDelete: () => _deleteClass(academicClass),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.academicClass,
    required this.sections,
    required this.onManageSections,
    required this.onManageSubjects,
    required this.onEdit,
    required this.onDelete,
  });

  final AcademicClassEntity academicClass;
  final List<SectionEntity> sections;
  final VoidCallback onManageSections;
  final VoidCallback onManageSubjects;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusLabel = academicClass.isActive ? 'Active' : 'Inactive';
    final details = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(academicClass.name, style: Theme.of(context).textTheme.titleSmall),
        Text(
          statusLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: academicClass.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
        ),
        if (sections.isNotEmpty)
          Text('Sections', style: Theme.of(context).textTheme.labelMedium)
        else
          Text(
            'No sections added',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ...sections.map(
          (section) => Chip(
            avatar: const Icon(Icons.view_module_outlined, size: 14),
            label: Text(section.name),
            labelStyle: Theme.of(context).textTheme.labelMedium,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            backgroundColor: section.isActive
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );

    final actions = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        TextButton.icon(
          onPressed: onManageSections,
          icon: const Icon(Icons.account_tree_outlined, size: 18),
          label: const Text('Manage Sections'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        TextButton.icon(
          onPressed: onManageSubjects,
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Subjects'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        IconButton(
          onPressed: onEdit,
          tooltip: 'Edit class',
          icon: const Icon(Icons.edit_outlined, size: 20),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Delete class',
          icon: const Icon(Icons.delete_outline, size: 20),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 16),
                  actions,
                ],
              );
            }

            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [details, actions],
            );
          },
        ),
      ),
    );
  }
}

class _SectionsPage extends StatefulWidget {
  const _SectionsPage({required this.academicClass, required this.repository});
  final AcademicClassEntity academicClass;
  final AcademicStructureRepository repository;
  @override State<_SectionsPage> createState() => _SectionsPageState();
}

class _SectionsPageState extends State<_SectionsPage> {
  late Future<List<SectionEntity>> _future;
  @override void initState(){super.initState();_reload();}
  void _reload() {
    _future = widget.repository.getSections();
  }
  Future<void> _save([SectionEntity? existing]) async { final controller=TextEditingController(text:existing?.name);final name=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:Text(existing==null?'Add Section':'Edit Section'),content:TextField(controller:controller,autofocus:true,decoration:const InputDecoration(labelText:'Section name')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,controller.text.trim()),child:const Text('Save'))]));if(name==null||name.isEmpty)return;final now=DateTime.now();try{await widget.repository.saveSection(SectionEntity(id:existing?.id??widget.repository.generateSectionId(),classId:widget.academicClass.id,name:name,isActive:existing?.isActive??true,createdAt:existing?.createdAt??now,updatedAt:now));if(mounted)setState(_reload);}catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('${widget.academicClass.name} Sections')),floatingActionButton:FloatingActionButton.extended(onPressed:_save,icon:const Icon(Icons.add),label:const Text('Add Section')),body:FutureBuilder<List<SectionEntity>>(future:_future,builder:(context,snapshot){if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());final sections=(snapshot.data??const <SectionEntity>[]).where((value)=>value.classId==widget.academicClass.id).toList();return sections.isEmpty?const Center(child:Text('No sections added yet.')):ListView.builder(itemCount:sections.length,itemBuilder:(context,index){final section=sections[index];return ListTile(title:Text(section.name),trailing:Wrap(children:[IconButton(onPressed:()=>_save(section),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()async{await widget.repository.deleteSection(section.id);if(mounted)setState(_reload);},icon:const Icon(Icons.delete_outline))]));});}));}
