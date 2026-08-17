import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../../access_control/data/services/user_account_service_impl.dart';
import '../../../access_control/domain/entities/user_account_entity.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

bool _isInternalChatRole(String roleName) {
  final role = roleName.trim().toLowerCase();
  return role.contains('admin') || role.contains('teacher');
}

Future<void> _confirmRemoveConversation(
  BuildContext context, {
  required String threadId,
  required String userId,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove conversation?'),
      content: const Text(
        'This conversation will be removed from your chat list. '
        'The other participant will keep their copy.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<ChatBloc>().add(
      RemoveChatThreadRequested(threadId: threadId, userId: userId),
    );
  }
}

class InAppChatPage extends StatelessWidget {
  const InAppChatPage({
    super.key,
    this.initialThreadId,
    this.userIdOverride,
    this.userNameOverride,
    this.teacherMode = false,
  });

  final String? initialThreadId;
  final String? userIdOverride;
  final String? userNameOverride;
  final bool teacherMode;

  @override
  Widget build(BuildContext context) {
    final user = sl<GetCurrentUserUseCase>()();
    final userId = userIdOverride?.trim().isNotEmpty == true
        ? userIdOverride!.trim()
        : user?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<ChatBloc>()..add(LoadChatThreads(userId)),
      child: _InAppChatView(
        initialThreadId: initialThreadId,
        userId: userId,
        userName: userNameOverride?.trim().isNotEmpty == true
            ? userNameOverride!.trim()
            : user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Current User',
        teacherMode: teacherMode,
      ),
    );
  }
}

class _InAppChatView extends StatefulWidget {
  const _InAppChatView({
    this.initialThreadId,
    required this.userId,
    required this.userName,
    required this.teacherMode,
  });

  final String? initialThreadId;
  final String userId;
  final String userName;
  final bool teacherMode;

  @override
  State<_InAppChatView> createState() => _InAppChatViewState();
}

class _InAppChatViewState extends State<_InAppChatView> {
  bool _openedInitialThread = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        String? text;
        if (state is ChatThreadsLoaded) {
          text = state.error ?? state.message;
        } else if (state is ChatThreadLoaded) {
          text = state.error ?? state.message;
        }

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
            appBar: AppBar(
              title: const Text('In-App Chat'),
              actions: const [DashboardNavigationButton()],
            ),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is ChatThreadLoaded) {
          return _ThreadView(state: state);
        }

        final data = state as ChatThreadsLoaded;
        final initialThreadId = widget.initialThreadId?.trim() ?? '';
        if (!_openedInitialThread && initialThreadId.isNotEmpty) {
          _openedInitialThread = true;
          final matches = data.threads.where(
            (thread) => thread.id == initialThreadId,
          );
          if (matches.isNotEmpty) {
            final thread = matches.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<ChatBloc>().add(
                OpenChatThread(thread: thread, userId: widget.userId),
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This conversation is no longer available.'),
                ),
              );
            });
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('In-App Chat'),
            actions: const [DashboardNavigationButton()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createThread(context),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('New Conversation'),
          ),
          body: data.threads.isEmpty
              ? const Center(child: Text('No conversations found.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: data.threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final thread = data.threads[index];

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.forum_outlined),
                        ),
                        title: Text(
                          thread.title.isEmpty ? 'Conversation' : thread.title,
                        ),
                        subtitle: Text(
                          thread.lastMessage.isEmpty
                              ? thread.type.name
                              : thread.lastMessage,
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Conversation options',
                          onSelected: (value) {
                            if (value == 'remove') {
                              _confirmRemoveConversation(
                                context,
                                threadId: thread.id,
                                userId: widget.userId,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline),
                                  SizedBox(width: 10),
                                  Text('Remove from my chats'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          context.read<ChatBloc>().add(
                            OpenChatThread(
                              thread: thread,
                              userId: widget.userId,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _createThread(BuildContext context) async {
    final currentUserId = widget.userId;
    List<UserAccountEntity> accounts;

    try {
      final allAccounts = await UserAccountServiceImpl().listChatParticipants();
      accounts = allAccounts
          .where(
            (account) =>
                account.uid.isNotEmpty &&
                account.uid != currentUserId &&
                account.isActive &&
                !account.disabled &&
                (widget.teacherMode
                    ? account.roleName.toLowerCase().contains('admin')
                    : _isInternalChatRole(account.roleName)),
          )
          .toList();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Users could not be loaded: '
              '${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final searchController = TextEditingController();
    final titleController = TextEditingController();
    UserAccountEntity? selectedAccount;
    String? roleFilter;
    var query = '';

    final roles =
        accounts
            .map((account) => account.roleName.trim())
            .where((role) => role.isNotEmpty && role != 'Not Assigned')
            .toSet()
            .toList()
          ..sort();

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final normalizedQuery = query.trim().toLowerCase();
          final visibleAccounts = accounts.where((account) {
            final roleMatches =
                roleFilter == null || account.roleName == roleFilter;
            final queryMatches =
                normalizedQuery.isEmpty ||
                account.displayName.toLowerCase().contains(normalizedQuery) ||
                account.username.toLowerCase().contains(normalizedQuery) ||
                account.email.toLowerCase().contains(normalizedQuery) ||
                account.roleName.toLowerCase().contains(normalizedQuery);
            return roleMatches && queryMatches;
          }).toList();

          return AlertDialog(
            scrollable: true,
            title: const Text('New Conversation'),
            content: SizedBox(
              width: 620,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<String?>(
                          initialValue: roleFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'User Type',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Users'),
                            ),
                            ...roles.map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                  role,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) => setDialogState(() {
                            roleFilter = value;
                            selectedAccount = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) =>
                              setDialogState(() => query = value),
                          decoration: const InputDecoration(
                            labelText: 'Search by name',
                            hintText: 'Name, username or email',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: visibleAccounts.isEmpty
                        ? const Center(
                            child: Text('No active chat account found.'),
                          )
                        : ListView.separated(
                            itemCount: visibleAccounts.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final account = visibleAccounts[index];
                              final selected =
                                  selectedAccount?.uid == account.uid;
                              return ListTile(
                                selected: selected,
                                selectedTileColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: .45),
                                leading: CircleAvatar(
                                  child: Text(
                                    account.displayName.trim().isEmpty
                                        ? '?'
                                        : account.displayName
                                              .trim()[0]
                                              .toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  account.displayName.trim().isEmpty
                                      ? account.username
                                      : account.displayName,
                                ),
                                subtitle: Text(
                                  '${account.roleName} | '
                                  '${account.email.isEmpty ? account.username : account.email}',
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check_circle)
                                    : null,
                                onTap: () => setDialogState(
                                  () => selectedAccount = account,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Conversation Title (Optional)',
                      prefixIcon: Icon(Icons.title),
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
                onPressed: selectedAccount == null
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

    final title = titleController.text.trim();
    final participant = selectedAccount;
    await WidgetsBinding.instance.endOfFrame;
    searchController.dispose();
    titleController.dispose();

    if (create == true && participant != null && context.mounted) {
      final now = DateTime.now();
      final participantName = participant.displayName.trim().isEmpty
          ? participant.username
          : participant.displayName.trim();

      context.read<ChatBloc>().add(
        CreateChatThreadRequested(
          ChatThreadEntity(
            id: 'chat_${now.microsecondsSinceEpoch}',
            type: ChatThreadType.adminTeacher,
            participantIds: [currentUserId, participant.uid],
            participantNames: {
              currentUserId: widget.userName,
              participant.uid: participantName,
            },
            createdBy: currentUserId,
            createdAt: now,
            updatedAt: now,
            title: title.isEmpty ? participantName : title,
          ),
        ),
      );
    }
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView({required this.state});

  final ChatThreadLoaded state;

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _messageController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _attachmentNameController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _attachmentUrlController.dispose();
    _attachmentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.thread.title.isEmpty ? 'Conversation' : state.thread.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Remove from my chats',
            onPressed: state.isProcessing
                ? null
                : () => _confirmRemoveConversation(
                    context,
                    threadId: state.thread.id,
                    userId: state.userId,
                  ),
            icon: const Icon(Icons.delete_outline),
          ),
          const DashboardNavigationButton(),
        ],
      ),
      body: Column(
        children: [
          if (state.isProcessing) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.messages.length,
              itemBuilder: (context, index) {
                final message = state.messages[index];
                final mine = message.senderId == state.userId;

                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            if (message.text.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(message.text),
                            ],
                            if (message.attachmentUrl.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                message.attachmentName.isEmpty
                                    ? message.attachmentUrl
                                    : message.attachmentName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              '${message.createdAt.hour.toString().padLeft(2, '0')}:'
                              '${message.createdAt.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                  TextField(
                    controller: _attachmentUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Attachment URL (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _attachmentNameController,
                    decoration: const InputDecoration(
                      labelText: 'Attachment Name (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
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
    final now = DateTime.now();
    final hasAttachment = _attachmentUrlController.text.trim().isNotEmpty;

    context.read<ChatBloc>().add(
      SendChatMessageRequested(
        ChatMessageEntity(
          id: 'chat_message_${now.microsecondsSinceEpoch}',
          threadId: widget.state.thread.id,
          senderId: widget.state.userId,
          senderName:
              widget.state.thread.participantNames[widget.state.userId] ??
              'User',
          type: hasAttachment ? ChatMessageType.document : ChatMessageType.text,
          text: _messageController.text.trim(),
          createdAt: now,
          readBy: [widget.state.userId],
          attachmentUrl: _attachmentUrlController.text.trim(),
          attachmentName: _attachmentNameController.text.trim(),
        ),
      ),
    );

    _messageController.clear();
    _attachmentUrlController.clear();
    _attachmentNameController.clear();
  }
}
