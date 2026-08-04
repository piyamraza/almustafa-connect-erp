[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_chat_phase2g_part1_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $s=Full $p
  if(Test-Path $s){
    $d=Join-Path $backup $p
    New-Item -ItemType Directory -Force -Path (Split-Path $d -Parent)|Out-Null
    Copy-Item $s $d -Force
  }
}
function WriteText([string]$p,[string]$t){
  $f=Full $p
  New-Item -ItemType Directory -Force -Path (Split-Path $f -Parent)|Out-Null
  [IO.File]::WriteAllText($f,$t.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$page='lib/features/parent_portal/presentation/pages/parent_chat_page.dart'
$dashboard='lib/features/parent_portal/presentation/pages/parent_portal_dashboard_page.dart'

foreach($f in @($page,$dashboard)){BackupFile $f}

WriteText $page @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class _ParentChatView extends StatelessWidget {
  const _ParentChatView({
    required this.parent,
    required this.student,
    required this.parentUserId,
  });

  final ParentAccountEntity parent;
  final StudentEntity student;
  final String parentUserId;

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
            parent: parent,
            student: student,
          );
        }

        final loaded = state as ChatThreadsLoaded;
        final threads = loaded.threads
            .where((thread) => thread.type == ChatThreadType.teacherParent)
            .toList(growable: false)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Scaffold(
          appBar: AppBar(
            title: Text('${student.fullName} Messages'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createTeacherThread(context),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('New Message'),
          ),
          body: threads.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No parent-teacher conversations found.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: threads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    final otherName = _otherParticipantName(thread);

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.school_outlined),
                        ),
                        title: Text(
                          thread.title.trim().isEmpty
                              ? otherName
                              : thread.title,
                        ),
                        subtitle: Text(
                          thread.lastMessage.trim().isEmpty
                              ? 'Start conversation'
                              : thread.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.read<ChatBloc>().add(
                                OpenChatThread(
                                  thread: thread,
                                  userId: parentUserId,
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

  String _otherParticipantName(ChatThreadEntity thread) {
    for (final entry in thread.participantNames.entries) {
      if (entry.key != parentUserId && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    return 'Teacher';
  }

  Future<void> _createTeacherThread(BuildContext context) async {
    List<UserAccountEntity> teachers;

    try {
      final accounts = await UserAccountServiceImpl().listChatParticipants();
      teachers = accounts
          .where(
            (account) =>
                account.uid.trim().isNotEmpty &&
                account.uid != parentUserId &&
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
          final visible = teachers.where((teacher) {
            return normalized.isEmpty ||
                teacher.displayName.toLowerCase().contains(normalized) ||
                teacher.username.toLowerCase().contains(normalized) ||
                teacher.email.toLowerCase().contains(normalized);
          }).toList(growable: false);

          return AlertDialog(
            title: const Text('Select Teacher'),
            content: SizedBox(
              width: 560,
              height: 390,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (value) =>
                        setDialogState(() => query = value),
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
                              final isSelected =
                                  selected?.uid == teacher.uid;
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
                                onTap: () => setDialogState(
                                  () => selected = teacher,
                                ),
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
              id: 'parent_teacher_${parentUserId}_${teacher.uid}_${student.id}',
              type: ChatThreadType.teacherParent,
              participantIds: [parentUserId, teacher.uid],
              participantNames: {
                parentUserId: parent.fullName,
                teacher.uid: teacherName,
              },
              createdBy: parentUserId,
              createdAt: now,
              updatedAt: now,
              title: '$teacherName - ${student.fullName}',
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

  @override
  void dispose() {
    _messageController.dispose();
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
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final mine = message.senderId == state.userId;

                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 440),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  if (message.text.trim().isNotEmpty) ...[
                                    if (!mine) const SizedBox(height: 4),
                                    Text(message.text),
                                  ],
                                  const SizedBox(height: 5),
                                  Text(
                                    _time(message.createdAt),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
              child: Row(
                children: [
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
                    onPressed:
                        state.isProcessing ? null : () => _send(context),
                    icon: const Icon(Icons.send),
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
    if (text.isEmpty) return;

    final now = DateTime.now();

    context.read<ChatBloc>().add(
          SendChatMessageRequested(
            ChatMessageEntity(
              id: 'chat_message_${now.microsecondsSinceEpoch}',
              threadId: widget.state.thread.id,
              senderId: widget.state.userId,
              senderName: widget.parent.fullName,
              type: ChatMessageType.text,
              text: text,
              createdAt: now,
              readBy: [widget.state.userId],
            ),
          ),
        );

    _messageController.clear();
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
'@

$text=[IO.File]::ReadAllText((Full $dashboard)).Replace("`r`n","`n")

$import="import 'parent_chat_page.dart';"
if(-not $text.Contains($import)){
  $anchor="import 'parent_fee_page.dart';"
  if(-not $text.Contains($anchor)){throw 'Dashboard import anchor not found.'}
  $text=$text.Replace($anchor,"$anchor`n$import")
}

$moduleAnchor="      ('Teacher Remarks', Icons.comment_outlined),"
if(-not $text.Contains("('Messages', Icons.chat_bubble_outline)")){
  if(-not $text.Contains($moduleAnchor)){throw 'Module list anchor not found.'}
  $text=$text.Replace(
    $moduleAnchor,
    "      ('Messages', Icons.chat_bubble_outline),`n$moduleAnchor"
  )
}

$timelineAnchor=@'
                  if (module.$1 == 'Timeline') {
'@

$messageBlock=@'
                  if (module.$1 == 'Messages') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentChatPage(
                          parent: parent,
                          student: student,
                        ),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Timeline') {
'@

if(-not $text.Contains("if (module.`$1 == 'Messages')")){
  if(-not $text.Contains($timelineAnchor)){
    throw 'Timeline navigation anchor not found.'
  }
  $text=$text.Replace($timelineAnchor,$messageBlock)
}

WriteText $dashboard $text

dart format $page $dashboard
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/parent_portal lib/features/communication --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent Communication Phase 2G Part 1 completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
