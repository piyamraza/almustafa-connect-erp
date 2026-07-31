import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/result_export_request.dart';
import '../bloc/results_export_bloc.dart';
import '../bloc/results_export_event.dart';
import '../bloc/results_export_state.dart';

class ResultsExportActions extends StatelessWidget {
  const ResultsExportActions({
    required this.request,
    this.enableExcel = true,
    this.compact = false,
    super.key,
  });

  final ResultExportRequest request;
  final bool enableExcel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsExportBloc>(),
      child: _ResultsExportActionsView(
        request: request,
        enableExcel: enableExcel,
        compact: compact,
      ),
    );
  }
}

class _ResultsExportActionsView extends StatelessWidget {
  const _ResultsExportActionsView({
    required this.request,
    required this.enableExcel,
    required this.compact,
  });

  final ResultExportRequest request;
  final bool enableExcel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResultsExportBloc, ResultsExportState>(
      listener: (context, state) {
        final message = switch (state) {
          ResultsExportSuccess(:final message) => message,
          ResultsExportFailure(:final message) => message,
          _ => null,
        };
        if (message == null) return;
        final isError = state is ResultsExportFailure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        );
      },
      builder: (context, state) {
        final busy = state is ResultsExportInProgress;
        return PopupMenuButton<ResultExportAction>(
          tooltip: busy ? 'Preparing export...' : 'Export, print or share',
          enabled: !busy && request.results.isNotEmpty,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : compact
              ? const Icon(Icons.more_vert)
              : const Icon(Icons.ios_share_outlined),
          onSelected: (action) => context.read<ResultsExportBloc>().add(
            RunResultsExport(action: action, request: request),
          ),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: ResultExportAction.exportPdf,
              child: ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('Export PDF'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (enableExcel)
              const PopupMenuItem(
                value: ResultExportAction.exportExcel,
                child: ListTile(
                  leading: Icon(Icons.table_view_outlined),
                  title: Text('Export Excel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: ResultExportAction.print,
              child: ListTile(
                leading: Icon(Icons.print_outlined),
                title: Text('Print'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: ResultExportAction.sharePdf,
              child: ListTile(
                leading: Icon(Icons.share_outlined),
                title: Text('Share PDF'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (enableExcel)
              const PopupMenuItem(
                value: ResultExportAction.shareExcel,
                child: ListTile(
                  leading: Icon(Icons.ios_share_outlined),
                  title: Text('Share Excel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        );
      },
    );
  }
}
