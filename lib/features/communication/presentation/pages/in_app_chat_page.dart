import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/chat_thread_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class InAppChatPage extends StatelessWidget {
  const InAppChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<GetCurrentUserUseCase>()();

    return BlocProvider(
      create: (_) => sl<ChatBloc>()..add(LoadChatThreads(user?.uid ?? '')),
      child: const _InAppChatView(),
    );
  }
}

class _InAppChatView extends StatelessWidget {
  const _InAppChatView();

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
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          final user = sl<GetCurrentUserUseCase>()();

                          context.read<ChatBloc>().add(
                            OpenChatThread(
                              thread: thread,
                              userId: user?.uid ?? '',
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
    final participantIdController = TextEditingController();
    final participantNameController = TextEditingController();
    final titleController = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Conversation'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: participantIdController,
                decoration: const InputDecoration(
                  labelText: 'Participant User ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: participantNameController,
                decoration: const InputDecoration(
                  labelText: 'Participant Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Conversation Title',
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
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (create == true && context.mounted) {
      final user = sl<GetCurrentUserUseCase>()();
      final now = DateTime.now();
      final currentUserId = user?.uid ?? '';

      context.read<ChatBloc>().add(
        CreateChatThreadRequested(
          ChatThreadEntity(
            id: 'chat_${now.microsecondsSinceEpoch}',
            type: ChatThreadType.custom,
            participantIds: [
              currentUserId,
              participantIdController.text.trim(),
            ],
            participantNames: {
              currentUserId: 'Current User',
              participantIdController.text.trim(): participantNameController
                  .text
                  .trim(),
            },
            createdBy: currentUserId,
            createdAt: now,
            updatedAt: now,
            title: titleController.text.trim(),
          ),
        ),
      );
    }

    participantIdController.dispose();
    participantNameController.dispose();
    titleController.dispose();
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
        actions: const [DashboardNavigationButton()],
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
