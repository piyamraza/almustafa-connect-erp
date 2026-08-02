import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/notice_repository.dart';
import '../../domain/services/notice_attachment_service.dart';

class NoticeFormPage extends StatefulWidget {
  const NoticeFormPage({
    super.key,
    required this.academicSession,
    this.existing,
  });

  final String academicSession;
  final NoticeEntity? existing;

  @override
  State<NoticeFormPage> createState() => _NoticeFormPageState();
}

class _NoticeFormPageState extends State<NoticeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _message;

  NoticePriority _priority = NoticePriority.normal;
  NoticeAudienceType _audience = NoticeAudienceType.wholeSchool;
  NoticeStatus _status = NoticeStatus.draft;
  DateTime? _publishAt;
  DateTime? _expireAt;
  bool _acknowledgementRequired = false;
  final Set<String> _classIds = {};
  final Set<String> _sectionIds = {};
  final List<NoticeAttachmentEntity> _attachments = [];
  List<dynamic> _classes = [];
  List<dynamic> _sections = [];
  bool _loading = true;
  bool _uploading = false;
  late final String _noticeId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _noticeId = existing?.id ?? sl<NoticeRepository>().generateId();
    _title = TextEditingController(text: existing?.title ?? '');
    _message = TextEditingController(text: existing?.message ?? '');
    _priority = existing?.priority ?? NoticePriority.normal;
    _audience = existing?.audienceType ?? NoticeAudienceType.wholeSchool;
    _status = existing?.status ?? NoticeStatus.draft;
    _publishAt = existing?.publishAt;
    _expireAt = existing?.expireAt;
    _acknowledgementRequired = existing?.acknowledgementRequired ?? false;
    _classIds.addAll(existing?.classIds ?? const []);
    _sectionIds.addAll(existing?.sectionIds ?? const []);
    _attachments.addAll(existing?.attachments ?? const []);
    _loadReferences();
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    final values = await Future.wait<Object?>([
      sl<AcademicStructureRepository>().getClasses(),
      sl<AcademicStructureRepository>().getSections(),
    ]);
    if (!mounted) return;
    setState(() {
      _classes = values[0] as List<dynamic>;
      _sections = values[1] as List<dynamic>;
      _loading = false;
    });
  }

  Future<void> _pickDate(bool publish) async {
    final value = await showManualDatePicker(
      context: context,
      initialDate: publish
          ? _publishAt ?? DateTime.now()
          : _expireAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null) return;
    setState(() {
      if (publish) {
        _publishAt = value;
      } else {
        _expireAt = value;
      }
    });
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final values = await sl<NoticeAttachmentService>().pickAndUpload(
        noticeId: _noticeId,
      );
      if (mounted) setState(() => _attachments.addAll(values));
    } catch (error) {
      _show(error.toString().replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removeAttachment(NoticeAttachmentEntity attachment) async {
    await sl<NoticeAttachmentService>().deleteAttachment(attachment);
    if (mounted) {
      setState(() => _attachments.remove(attachment));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_audience == NoticeAudienceType.selectedClasses && _classIds.isEmpty) {
      _show('Select at least one class.');
      return;
    }

    if (_status == NoticeStatus.scheduled && _publishAt == null) {
      _show('Scheduled notice requires a publish date.');
      return;
    }

    final now = DateTime.now();
    final old = widget.existing;

    Navigator.pop(
      context,
      NoticeEntity(
        id: _noticeId,
        academicSession: widget.academicSession,
        title: _title.text.trim(),
        message: _message.text.trim(),
        priority: _priority,
        audienceType: _audience,
        classIds: _classIds.toList(),
        sectionIds: _sectionIds.toList(),
        status: _status,
        publishAt: _publishAt,
        expireAt: _expireAt,
        acknowledgementRequired: _acknowledgementRequired,
        calendarEventId: old?.calendarEventId,
        attachments: _attachments,
        createdBy: old?.createdBy ?? 'Admin',
        updatedBy: 'Admin',
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
        publishedBy: _status == NoticeStatus.published
            ? old?.publishedBy ?? 'Admin'
            : old?.publishedBy,
        publishedAt: _status == NoticeStatus.published
            ? old?.publishedAt ?? now
            : old?.publishedAt,
      ),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()],
        title: Text(widget.existing == null ? 'Create Notice' : 'Edit Notice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Notice Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Notice Message',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Message is required'
                  : null,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _enumField<NoticePriority>(
                  'Priority',
                  _priority,
                  NoticePriority.values,
                  (value) => setState(() => _priority = value),
                ),
                _enumField<NoticeAudienceType>(
                  'Audience',
                  _audience,
                  NoticeAudienceType.values,
                  (value) => setState(() => _audience = value),
                ),
                _enumField<NoticeStatus>(
                  'Status',
                  _status,
                  NoticeStatus.values,
                  (value) => setState(() => _status = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_audience == NoticeAudienceType.selectedClasses)
              Wrap(
                spacing: 8,
                children: [
                  for (final item in _classes)
                    FilterChip(
                      label: Text(item.name.toString()),
                      selected: _classIds.contains(item.id.toString()),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _classIds.add(item.id.toString())
                              : _classIds.remove(item.id.toString());
                        });
                      },
                    ),
                ],
              ),
            if (_audience == NoticeAudienceType.selectedSections)
              Wrap(
                spacing: 8,
                children: [
                  for (final item in _sections)
                    FilterChip(
                      label: Text(item.name.toString()),
                      selected: _sectionIds.contains(item.id.toString()),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _sectionIds.add(item.id.toString())
                              : _sectionIds.remove(item.id.toString());
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _publishAt == null
                        ? 'Publish Date'
                        : 'Publish: ${_date(_publishAt!)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.event_busy),
                  label: Text(
                    _expireAt == null
                        ? 'Expiry Date'
                        : 'Expires: ${_date(_expireAt!)}',
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Acknowledgement Required'),
                    value: _acknowledgementRequired,
                    onChanged: (value) {
                      setState(() => _acknowledgementRequired = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Attachments (max 15 MB each)'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _uploading ? null : _upload,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select & Upload'),
                        ),
                      ],
                    ),
                    for (final attachment in _attachments)
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(attachment.fileName),
                        subtitle: Text(
                          '${attachment.fileType.toUpperCase()} • '
                          '${(attachment.fileSize / 1024).toStringAsFixed(1)} KB',
                        ),
                        trailing: IconButton(
                          onPressed: () => _removeAttachment(attachment),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Notice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _enumField<T extends Enum>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> onChanged,
  ) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values
            .map(
              (item) => DropdownMenuItem(value: item, child: Text(item.name)),
            )
            .toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
