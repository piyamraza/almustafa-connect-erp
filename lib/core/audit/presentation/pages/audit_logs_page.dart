import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../di/service_locator.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_repository.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final AuditRepository _repository = sl<AuditRepository>();
  final TextEditingController _searchController = TextEditingController();

  List<AuditLogEntity> _logs = const [];
  bool _loading = true;
  String? _errorMessage;
  String? _moduleFilter;
  AuditAction? _actionFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final values = await _repository.getLogs(
        module: _moduleFilter,
        fromDate: _fromDate,
        toDate: _toDate == null
            ? null
            : DateTime(
                _toDate!.year,
                _toDate!.month,
                _toDate!.day,
                23,
                59,
                59,
                999,
              ),
        limit: 500,
      );

      if (!mounted) return;

      setState(() {
        _logs = values;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  List<AuditLogEntity> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();

    final values = _logs.where((log) {
      if (_actionFilter != null && log.action != _actionFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      return log.module.toLowerCase().contains(query) ||
          log.recordId.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query) ||
          log.userName.toLowerCase().contains(query) ||
          log.userEmail.toLowerCase().contains(query) ||
          log.roleName.toLowerCase().contains(query);
    }).toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(values);
  }

  List<String> get _modules {
    final values =
        _logs
            .map((log) => log.module.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  Future<void> _pickFromDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null || !mounted) return;
    setState(() => _fromDate = value);
    await _load();
  }

  Future<void> _pickToDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null || !mounted) return;
    setState(() => _toDate = value);
    await _load();
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() {
      _moduleFilter = null;
      _actionFilter = null;
      _fromDate = null;
      _toDate = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _filters(),
          const Divider(height: 1),
          Expanded(child: _body(logs)),
        ],
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search user, record or description',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<String?>(
              initialValue: _moduleFilter,
              decoration: const InputDecoration(
                labelText: 'Module',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Modules'),
                ),
                ..._modules.map(
                  (value) => DropdownMenuItem<String?>(
                    value: value,
                    child: Text(value),
                  ),
                ),
              ],
              onChanged: (value) async {
                setState(() => _moduleFilter = value);
                await _load();
              },
            ),
          ),
          SizedBox(
            width: 210,
            child: DropdownButtonFormField<AuditAction?>(
              initialValue: _actionFilter,
              decoration: const InputDecoration(
                labelText: 'Action',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<AuditAction?>(
                  value: null,
                  child: Text('All Actions'),
                ),
                ...AuditAction.values.map(
                  (value) => DropdownMenuItem<AuditAction?>(
                    value: value,
                    child: Text(_actionLabel(value)),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _actionFilter = value),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickFromDate,
            icon: const Icon(Icons.date_range),
            label: Text(_fromDate == null ? 'From Date' : _date(_fromDate!)),
          ),
          OutlinedButton.icon(
            onPressed: _pickToDate,
            icon: const Icon(Icons.event),
            label: Text(_toDate == null ? 'To Date' : _date(_toDate!)),
          ),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _body(List<AuditLogEntity> logs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return const Center(
        child: Text('No audit logs match the selected filters.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _AuditLogCard(log: logs[index]),
    );
  }

  static String _actionLabel(AuditAction value) {
    return switch (value) {
      AuditAction.create => 'Create',
      AuditAction.update => 'Update',
      AuditAction.delete => 'Delete',
      AuditAction.restore => 'Restore',
      AuditAction.approve => 'Approve',
      AuditAction.reject => 'Reject',
      AuditAction.login => 'Login',
      AuditAction.logout => 'Logout',
      AuditAction.view => 'View',
      AuditAction.print => 'Print',
      AuditAction.export => 'Export',
      AuditAction.send => 'Send',
      AuditAction.collectPayment => 'Collect Payment',
      AuditAction.other => 'Other',
    };
  }

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    final user = log.userName.trim().isNotEmpty
        ? log.userName
        : log.userEmail.trim().isNotEmpty
        ? log.userEmail
        : log.userId;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Icon(_actionIcon(log.action))),
        title: Text(
          '${log.module} | ${_AuditLogsPageState._actionLabel(log.action)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$user | ${_dateTime(log.createdAt)}\n'
          'Record: ${log.recordId.isEmpty ? '-' : log.recordId}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (log.description.trim().isNotEmpty)
            _Detail(label: 'Description', value: log.description),
          _Detail(label: 'Role', value: log.roleName),
          _Detail(label: 'Session', value: log.sessionId),
          if (log.oldValues.isNotEmpty)
            _MapDetail(label: 'Previous Values', values: log.oldValues),
          if (log.newValues.isNotEmpty)
            _MapDetail(label: 'New Values', values: log.newValues),
        ],
      ),
    );
  }

  static IconData _actionIcon(AuditAction value) {
    return switch (value) {
      AuditAction.create => Icons.add_circle_outline,
      AuditAction.update => Icons.edit_outlined,
      AuditAction.delete => Icons.delete_outline,
      AuditAction.restore => Icons.restore,
      AuditAction.approve => Icons.check_circle_outline,
      AuditAction.reject => Icons.cancel_outlined,
      AuditAction.login => Icons.login,
      AuditAction.logout => Icons.logout,
      AuditAction.view => Icons.visibility_outlined,
      AuditAction.print => Icons.print_outlined,
      AuditAction.export => Icons.download_outlined,
      AuditAction.send => Icons.send_outlined,
      AuditAction.collectPayment => Icons.payments_outlined,
      AuditAction.other => Icons.history,
    };
  }

  static String _dateTime(DateTime value) {
    final date = _AuditLogsPageState._date(value);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: $value'),
      ),
    );
  }
}

class _MapDetail extends StatelessWidget {
  const _MapDetail({required this.label, required this.values});

  final String label;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SelectableText(
          '$label:\n'
          '${values.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n')}',
        ),
      ),
    );
  }
}
