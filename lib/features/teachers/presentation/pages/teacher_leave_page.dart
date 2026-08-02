import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

class TeacherLeavePage extends StatefulWidget {
  const TeacherLeavePage({super.key});
  @override
  State<TeacherLeavePage> createState() => _TeacherLeavePageState();
}

class _TeacherLeavePageState extends State<TeacherLeavePage> {
  final _reasonController = TextEditingController();
  final List<_LeaveRequest> _requests = [];
  String _type = 'Casual Leave';
  DateTimeRange? _range;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null) setState(() => _range = range);
  }

  void _applyLeave() {
    if (_range == null || _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select leave dates and enter a reason.')),
      );
      return;
    }
    setState(() {
      _requests.add(_LeaveRequest(type: _type, range: _range!, reason: _reasonController.text.trim()));
      _reasonController.clear();
      _range = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Leave Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Leave type', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave')),
                        DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
                        DropdownMenuItem(value: 'Annual Leave', child: Text('Annual Leave')),
                      ],
                      onChanged: (value) => setState(() => _type = value ?? _type),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: _selectRange, icon: const Icon(Icons.date_range), label: Text(_range == null ? 'Select leave dates' : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year} - ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}')),
                    const SizedBox(height: 12),
                    TextField(controller: _reasonController, maxLines: 2, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _applyLeave, icon: const Icon(Icons.send), label: const Text('Apply Leave'))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: _requests.isEmpty
                    ? const Center(child: Text('No leave requests yet.'))
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _requests[index];
                          return ListTile(title: Text(item.type), subtitle: Text('${item.reason}\n${item.range.start.day}/${item.range.start.month} - ${item.range.end.day}/${item.range.end.month}'), isThreeLine: true, trailing: Chip(label: Text(item.status)));
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveRequest {
  _LeaveRequest({required this.type, required this.range, required this.reason});
  final String type;
  final DateTimeRange range;
  final String reason;
  String get status => 'Pending';
}
