import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/data/services/user_account_service_impl.dart';
import '../../../access_control/domain/entities/user_account_entity.dart';
import '../../../communication/domain/entities/chat_message_entity.dart';
import '../../../communication/domain/entities/chat_thread_entity.dart';
import '../../../communication/presentation/bloc/chat_bloc.dart';
import '../../../communication/presentation/bloc/chat_event.dart';
import '../../../communication/presentation/bloc/chat_state.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';

class ParentChatPage extends StatelessWidget {
  const ParentChatPage({
    super.key,
    required this.parent,
    required this.student,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    final parentUserId = parent.userId.trim();

    if (parentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This parent account is not linked with a login user yet. '
              'Create or link the parent login account before opening chat.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<ChatBloc>()..add(LoadChatThreads(parentUserId)),
      child: _ParentChatView(
        parent: parent,
        student: student,
        parentUserId: parentUserId,
      ),
    );
  }
}

class _ParentChatView extends StatefulWidget {
  const _ParentChatView({
    required this.parent,
    required this.student,
    required this.parentUserId,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String parentUserId;

  @override
  State<_ParentChatView> createState() => _ParentChatViewState();
}

class _ParentChatViewState extends State<_ParentChatView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        final text = switch (state) {
          ChatThreadsLoaded(:final message, :final error) => error ?? message,
          ChatThreadLoaded(:final message, :final error) => error ?? message,
          _ => null,
        };

        if (text != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        }
      },
      builder: (context, state) {
        if (state is ChatInitial || state is ChatLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ChatFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Messages')),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is ChatThreadLoaded) {
          return _ParentThreadView(
            state: state,
            parent: widget.parent,
            student: widget.student,
          );
        }

        final loaded = state as ChatThreadsLoaded;
        final normalizedQuery = _query.trim().toLowerCase();
        final threads =
            loaded.threads
                .where((thread) {
                  if (thread.type != ChatThreadType.teacherParent ||
                      thread.isArchived) {
                    return false;
                  }

                  if (normalizedQuery.isEmpty) return true;

                  final teacherName = _otherParticipantName(
                    thread,
                  ).toLowerCase();
                  return thread.title.toLowerCase().contains(normalizedQuery) ||
                      thread.lastMessage.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      teacherName.contains(normalizedQuery);
                })
                .toList(growable: false)
              ..sort(
                (a, b) => (b.lastMessageAt ?? b.updatedAt).compareTo(
                  a.lastMessageAt ?? a.updatedAt,
                ),
              );

        return Scaffold(
          appBar: AppBar(title: Text('${widget.student.fullName} Messages')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createTeacherThread(context),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('New Message'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: 'Search Conversations',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: threads.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            normalizedQuery.isEmpty
                                ? 'No parent-teacher conversations found.'
                                : 'No conversation matches your search.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<ChatBloc>().add(
                            LoadChatThreads(widget.parentUserId),
                          );
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: threads.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final thread = threads[index];
                            final otherName = _otherParticipantName(thread);
                            final updated =
                                thread.lastMessageAt ?? thread.updatedAt;

                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.school_outlined),
                                ),
                                title: Text(
                                  thread.title.trim().isEmpty
                                      ? otherName
                                      : thread.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  thread.lastMessage.trim().isEmpty
                                      ? 'Start conversation'
                                      : thread.lastMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _shortDate(updated),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 15,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  context.read<ChatBloc>().add(
                                    OpenChatThread(
                                      thread: thread,
                                      userId: widget.parentUserId,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _otherParticipantName(ChatThreadEntity thread) {
    for (final entry in thread.participantNames.entries) {
      if (entry.key != widget.parentUserId && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    return 'Teacher';
  }

  Future<void> _createTeacherThread(BuildContext context) async {
    List<UserAccountEntity> teachers;

    try {
      final accounts = await UserAccountServiceImpl().listChatParticipants();
      teachers =
          accounts
              .where(
                (account) =>
                    account.uid.trim().isNotEmpty &&
                    account.uid != widget.parentUserId &&
                    account.isActive &&
                    !account.disabled &&
                    account.roleName.toLowerCase().contains('teacher'),
              )
              .toList(growable: false)
            ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teachers could not be loaded: $error')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (teachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active teacher chat account is available.'),
        ),
      );
      return;
    }

    final searchController = TextEditingController();
    UserAccountEntity? selected;
    var query = '';

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalized = query.trim().toLowerCase();
          final visible = teachers
              .where((teacher) {
                return normalized.isEmpty ||
                    teacher.displayName.toLowerCase().contains(normalized) ||
                    teacher.username.toLowerCase().contains(normalized) ||
                    teacher.email.toLowerCase().contains(normalized);
              })
              .toList(growable: false);

          return AlertDialog(
            title: const Text('Select Teacher'),
            content: SizedBox(
              width: 560,
              height: 390,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setDialogState(() => query = value),
                    decoration: const InputDecoration(
                      labelText: 'Search Teacher',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('No teacher found.'))
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final teacher = visible[index];
                              final isSelected = selected?.uid == teacher.uid;
                              final displayName =
                                  teacher.displayName.trim().isEmpty
                                  ? teacher.username
                                  : teacher.displayName.trim();

                              return ListTile(
                                selected: isSelected,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(displayName),
                                subtitle: Text(
                                  teacher.email.isEmpty
                                      ? teacher.username
                                      : teacher.email,
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle)
                                    : null,
                                onTap: () =>
                                    setDialogState(() => selected = teacher),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: selected == null
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Start Chat'),
              ),
            ],
          );
        },
      ),
    );

    await WidgetsBinding.instance.endOfFrame;
    searchController.dispose();

    if (create != true || selected == null || !context.mounted) return;

    final teacher = selected!;
    final teacherName = teacher.displayName.trim().isEmpty
        ? teacher.username
        : teacher.displayName.trim();
    final now = DateTime.now();

    context.read<ChatBloc>().add(
      CreateChatThreadRequested(
        ChatThreadEntity(
          id: 'parent_teacher_${widget.parentUserId}_${teacher.uid}_${widget.student.id}',
          type: ChatThreadType.teacherParent,
          participantIds: [widget.parentUserId, teacher.uid],
          participantNames: {
            widget.parentUserId: widget.parent.fullName,
            teacher.uid: teacherName,
          },
          createdBy: widget.parentUserId,
          createdAt: now,
          updatedAt: now,
          title: '$teacherName - ${widget.student.fullName}',
        ),
      ),
    );
  }
}

class _ParentThreadView extends StatefulWidget {
  const _ParentThreadView({
    required this.state,
    required this.parent,
    required this.student,
  });

  final ChatThreadLoaded state;
  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  State<_ParentThreadView> createState() => _ParentThreadViewState();
}

class _ParentThreadViewState extends State<_ParentThreadView> {
  final _messageController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _attachmentNameController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showAttachmentFields = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant _ParentThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.messages.length != widget.state.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _attachmentUrlController.dispose();
    _attachmentNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.thread.title.trim().isEmpty
              ? 'Parent-Teacher Chat'
              : state.thread.title,
        ),
      ),
      body: Column(
        children: [
          if (state.isProcessing) const LinearProgressIndicator(),
          Expanded(
            child: state.messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final mine = message.senderId == state.userId;
                      final showDate =
                          index == 0 ||
                          !_sameDay(
                            state.messages[index - 1].createdAt,
                            message.createdAt,
                          );

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Chip(
                                label: Text(_longDate(message.createdAt)),
                              ),
                            ),
                          Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 460),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!mine)
                                        Text(
                                          message.senderName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                        ),
                                      if (message.text.trim().isNotEmpty) ...[
                                        if (!mine) const SizedBox(height: 4),
                                        Text(message.text),
                                      ],
                                      if (message.attachmentUrl.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _openAttachment(
                                            context,
                                            message.attachmentUrl,
                                          ),
                                          icon: const Icon(Icons.attach_file),
                                          label: Text(
                                            message.attachmentName.isEmpty
                                                ? 'Open Attachment'
                                                : message.attachmentName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _time(message.createdAt),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          if (mine) ...[
                                            const SizedBox(width: 5),
                                            Icon(
                                              message.readBy.length > 1
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 15,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  if (_showAttachmentFields) ...[
                    TextField(
                      controller: _attachmentUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Attachment URL',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _attachmentNameController,
                      decoration: const InputDecoration(
                        labelText: 'Attachment Name',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      IconButton(
                        tooltip: _showAttachmentFields
                            ? 'Hide Attachment'
                            : 'Add Attachment',
                        onPressed: () {
                          setState(
                            () =>
                                _showAttachmentFields = !_showAttachmentFields,
                          );
                        },
                        icon: Icon(
                          _showAttachmentFields
                              ? Icons.close
                              : Icons.attach_file,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state.isProcessing
                            ? null
                            : () => _send(context),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(BuildContext context) {
    final text = _messageController.text.trim();
    final attachmentUrl = _attachmentUrlController.text.trim();
    final attachmentName = _attachmentNameController.text.trim();

    if (text.isEmpty && attachmentUrl.isEmpty) return;

    final now = DateTime.now();

    context.read<ChatBloc>().add(
      SendChatMessageRequested(
        ChatMessageEntity(
          id: 'chat_message_${now.microsecondsSinceEpoch}',
          threadId: widget.state.thread.id,
          senderId: widget.state.userId,
          senderName: widget.parent.fullName,
          type: attachmentUrl.isEmpty
              ? ChatMessageType.text
              : ChatMessageType.document,
          text: text,
          createdAt: now,
          readBy: [widget.state.userId],
          attachmentUrl: attachmentUrl,
          attachmentName: attachmentName,
        ),
      ),
    );

    _messageController.clear();
    _attachmentUrlController.clear();
    _attachmentNameController.clear();
    setState(() => _showAttachmentFields = false);
  }

  Future<void> _openAttachment(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment could not be opened.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _time(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _shortDate(DateTime value) {
  final now = DateTime.now();
  if (_sameDay(now, value)) return _time(value);

  final yesterday = now.subtract(const Duration(days: 1));
  if (_sameDay(yesterday, value)) return 'Yesterday';

  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}';
}

String _longDate(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
