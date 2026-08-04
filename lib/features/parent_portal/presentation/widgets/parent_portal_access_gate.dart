import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/services/parent_context_service.dart';

class ParentPortalAccessGate extends StatefulWidget {
  const ParentPortalAccessGate({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    ParentContextService parentContext,
  )
  builder;

  @override
  State<ParentPortalAccessGate> createState() => _ParentPortalAccessGateState();
}

class _ParentPortalAccessGateState extends State<ParentPortalAccessGate> {
  late final ParentContextService _parentContext;

  @override
  void initState() {
    super.initState();
    _parentContext = sl<ParentContextService>();
    _parentContext.addListener(_handleChanged);
    _load();
  }

  @override
  void dispose() {
    _parentContext.removeListener(_handleChanged);
    super.dispose();
  }

  Future<void> _load() async {
    await _parentContext.loadCurrentParent();
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_parentContext.isLoading && !_parentContext.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_parentContext.hasParentAccount || !_parentContext.canAccessPortal) {
      return _ParentAccessMessage(
        message:
            _parentContext.errorMessage ??
            'Parent Portal access is not available.',
        onRetry: () => _parentContext.loadCurrentParent(forceRefresh: true),
      );
    }

    return widget.builder(context, _parentContext);
  }
}

class _ParentAccessMessage extends StatelessWidget {
  const _ParentAccessMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.lock_person_outlined,
                  size: 54,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Parent Portal Access',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
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
}
