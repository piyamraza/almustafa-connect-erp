import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<DateTime?> showManualDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _ManualDateDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: helpText ?? 'Enter Date',
    ),
  );
}

Future<DateTimeRange?> showManualDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  String? helpText,
  String? saveText,
}) {
  final today = _clampDate(DateTime.now(), firstDate, lastDate);
  final initial = initialDateRange ?? DateTimeRange(start: today, end: today);
  return showDialog<DateTimeRange>(
    context: context,
    builder: (_) => _ManualDateRangeDialog(
      initialRange: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      title: helpText ?? 'Enter Date Range',
      saveText: saveText ?? 'Apply',
    ),
  );
}

class _ManualDateDialog extends StatefulWidget {
  const _ManualDateDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  @override
  State<_ManualDateDialog> createState() => _ManualDateDialogState();
}

class _ManualDateDialogState extends State<_ManualDateDialog> {
  late final _DateControllers _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = _DateControllers(widget.initialDate);
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  void _submit() {
    final result = _date.parse(widget.firstDate, widget.lastDate);
    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }
    Navigator.pop(context, result.date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Date', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _DateFields(controllers: _date, onSubmitted: _submit),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Allowed: ${_format(widget.firstDate)} to ${_format(widget.lastDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}

class _ManualDateRangeDialog extends StatefulWidget {
  const _ManualDateRangeDialog({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.saveText,
  });

  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String saveText;

  @override
  State<_ManualDateRangeDialog> createState() =>
      _ManualDateRangeDialogState();
}

class _ManualDateRangeDialogState extends State<_ManualDateRangeDialog> {
  late final _DateControllers _start;
  late final _DateControllers _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start = _DateControllers(widget.initialRange.start);
    _end = _DateControllers(widget.initialRange.end);
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _submit() {
    final start = _start.parse(widget.firstDate, widget.lastDate);
    final end = _end.parse(widget.firstDate, widget.lastDate);
    final error = start.error ?? end.error;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (end.date!.isBefore(start.date!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }
    Navigator.pop(context, DateTimeRange(start: start.date!, end: end.date!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start Date',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _DateFields(controllers: _start),
            const SizedBox(height: 18),
            const Text(
              'End Date',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _DateFields(controllers: _end, onSubmitted: _submit),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.saveText)),
      ],
    );
  }
}

class _DateFields extends StatelessWidget {
  const _DateFields({required this.controllers, this.onSubmitted});

  final _DateControllers controllers;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _NumberField(
            label: 'Day',
            hint: 'DD',
            maxLength: 2,
            controller: controllers.day,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NumberField(
            label: 'Month',
            hint: 'MM',
            maxLength: 2,
            controller: controllers.month,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NumberField(
            label: 'Year',
            hint: 'YYYY',
            maxLength: 4,
            controller: controllers.year,
            onSubmitted: onSubmitted,
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.controller,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final int maxLength;
  final TextEditingController controller;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: label == 'Day',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DateControllers {
  _DateControllers(DateTime date)
      : day = TextEditingController(text: '${date.day}'),
        month = TextEditingController(text: '${date.month}'),
        year = TextEditingController(text: '${date.year}');

  final TextEditingController day;
  final TextEditingController month;
  final TextEditingController year;

  _ParsedDate parse(DateTime firstDate, DateTime lastDate) {
    final dayValue = int.tryParse(day.text.trim());
    final monthValue = int.tryParse(month.text.trim());
    final yearValue = int.tryParse(year.text.trim());
    if (dayValue == null || monthValue == null || yearValue == null) {
      return const _ParsedDate(error: 'Enter day, month and year.');
    }
    if (monthValue < 1 || monthValue > 12) {
      return const _ParsedDate(error: 'Month must be between 1 and 12.');
    }
    final date = DateTime(yearValue, monthValue, dayValue);
    if (dayValue < 1 ||
        date.year != yearValue ||
        date.month != monthValue ||
        date.day != dayValue) {
      return const _ParsedDate(error: 'Enter a valid calendar date.');
    }
    final normalizedFirst = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final normalizedLast = DateTime(lastDate.year, lastDate.month, lastDate.day);
    if (date.isBefore(normalizedFirst) || date.isAfter(normalizedLast)) {
      return _ParsedDate(
        error: 'Date must be between ${_format(normalizedFirst)} and ${_format(normalizedLast)}.',
      );
    }
    return _ParsedDate(date: date);
  }

  void dispose() {
    day.dispose();
    month.dispose();
    year.dispose();
  }
}

class _ParsedDate {
  const _ParsedDate({this.date, this.error});
  final DateTime? date;
  final String? error;
}

String _format(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

DateTime _clampDate(DateTime value, DateTime firstDate, DateTime lastDate) {
  if (value.isBefore(firstDate)) return firstDate;
  if (value.isAfter(lastDate)) return lastDate;
  return value;
}
