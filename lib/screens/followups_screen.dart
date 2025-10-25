import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:harvestflow/models/followup.dart';
import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/providers/followup_provider.dart';
import 'package:harvestflow/providers/member_provider.dart';

class FollowUpsScreen extends ConsumerWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpsAsync = ref.watch(followUpNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        actions: [
          IconButton(
            onPressed: () => ref.read(followUpNotifierProvider.notifier).loadFollowUps(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: followUpsAsync.when(
        data: (followUps) {
          if (followUps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.checklist, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No follow-ups scheduled',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to add your first follow-up'),
                ],
              ),
            );
          }

          // Group follow-ups by status
          final overdue = followUps.where((f) => f.isOverdue).toList();
          final pending = followUps.where((f) => !f.isCompleted && !f.isOverdue).toList();
          final completed = followUps.where((f) => f.isCompleted).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(followUpNotifierProvider.notifier).loadFollowUps();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overdue.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Overdue (${overdue.length})',
                      color: Colors.red,
                      icon: Icons.warning,
                    ),
                    const SizedBox(height: 16),
                    ...overdue.map((followUp) => _FollowUpCard(
                      followUp: followUp,
                      isOverdue: true,
                      onTap: () => _showFollowUpDetails(context, ref, followUp),
                      onComplete: () => _completeFollowUp(context, ref, followUp),
                      onEdit: () => _showFollowUpForm(context, ref, followUp),
                      onDelete: () => _deleteFollowUp(context, ref, followUp),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  if (pending.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Pending (${pending.length})',
                      color: Colors.orange,
                      icon: Icons.schedule,
                    ),
                    const SizedBox(height: 16),
                    ...pending.map((followUp) => _FollowUpCard(
                      followUp: followUp,
                      onTap: () => _showFollowUpDetails(context, ref, followUp),
                      onComplete: () => _completeFollowUp(context, ref, followUp),
                      onEdit: () => _showFollowUpForm(context, ref, followUp),
                      onDelete: () => _deleteFollowUp(context, ref, followUp),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  if (completed.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Completed (${completed.length})',
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(height: 16),
                    ...completed.map((followUp) => _FollowUpCard(
                      followUp: followUp,
                      isCompleted: true,
                      onTap: () => _showFollowUpDetails(context, ref, followUp),
                      onEdit: () => _showFollowUpForm(context, ref, followUp),
                      onDelete: () => _deleteFollowUp(context, ref, followUp),
                    )),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(followUpNotifierProvider.notifier).loadFollowUps();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFollowUpForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFollowUpDetails(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    final member = await ref.read(databaseServiceProvider).getMemberById(followUp.memberId);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Follow-up: ${followUp.type}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Member', value: member?.name ?? 'Unknown'),
              _DetailRow(label: 'Type', value: followUp.type),
              _DetailRow(label: 'Due Date', value: DateFormat('EEEE, MMM d, y').format(followUp.dueDate)),
              _DetailRow(label: 'Status', value: followUp.isCompleted ? 'Completed' : 'Pending'),
              _DetailRow(label: 'Created', value: DateFormat('MMM d, y').format(followUp.createdAt)),
              if (followUp.notes.isNotEmpty)
                _DetailRow(label: 'Notes', value: followUp.notes),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (!followUp.isCompleted)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completeFollowUp(context, ref, followUp);
                },
                child: const Text('Mark Complete'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showFollowUpForm(context, ref, followUp);
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      );
    }
  }

  void _showFollowUpForm(BuildContext context, WidgetRef ref, [FollowUp? followUp]) {
    showDialog(
      context: context,
      builder: (context) => _FollowUpFormDialog(followUp: followUp),
    );
  }

  void _completeFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp) async {
    await ref.read(followUpNotifierProvider.notifier).completeFollowUp(followUp.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Follow-up marked as completed')),
    );
  }

  void _deleteFollowUp(BuildContext context, WidgetRef ref, FollowUp followUp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Follow-up'),
        content: const Text('Are you sure you want to delete this follow-up?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(followUpNotifierProvider.notifier).deleteFollowUp(followUp.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Follow-up deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _FollowUpCard extends ConsumerWidget {
  final FollowUp followUp;
  final bool isOverdue;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FollowUpCard({
    required this.followUp,
    this.isOverdue = false,
    this.isCompleted = false,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Member?>(
      future: ref.read(databaseServiceProvider).getMemberById(followUp.memberId),
      builder: (context, snapshot) {
        final member = snapshot.data;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isOverdue 
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCompleted 
                              ? Icons.check_circle
                              : isOverdue
                                  ? Icons.warning
                                  : Icons.schedule,
                          color: isCompleted
                              ? Colors.green
                              : isOverdue
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member?.name ?? 'Loading...',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                followUp.type,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'complete':
                                onComplete?.call();
                                break;
                              case 'edit':
                                onEdit?.call();
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            if (onComplete != null)
                              const PopupMenuItem(
                                value: 'complete',
                                child: Row(
                                  children: [
                                    Icon(Icons.check, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Mark Complete'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isOverdue ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${DateFormat('MMM d, y').format(followUp.dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue ? Colors.red : null,
                            fontWeight: isOverdue ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                    
                    if (followUp.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        followUp.notes,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUpFormDialog extends ConsumerStatefulWidget {
  final FollowUp? followUp;

  const _FollowUpFormDialog({this.followUp});

  @override
  ConsumerState<_FollowUpFormDialog> createState() => __FollowUpFormDialogState();
}

class __FollowUpFormDialogState extends ConsumerState<_FollowUpFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedType;
  int? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.followUp?.notes ?? '');
    _selectedDate = widget.followUp?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedType = widget.followUp?.type ?? FollowUpTypes.weekly;
    _selectedMemberId = widget.followUp?.memberId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberListProvider);

    return AlertDialog(
      title: Text(widget.followUp == null ? 'Add Follow-up' : 'Edit Follow-up'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              membersAsync.when(
                data: (members) => DropdownButtonFormField<int>(
                  value: _selectedMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Member',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: members.map((member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.name),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedMemberId = value),
                  validator: (value) => value == null ? 'Member is required' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading members: $error'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: FollowUpTypes.all.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Due Date'),
                subtitle: Text(DateFormat('EEEE, MMM d, y').format(_selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveFollowUp,
          child: Text(widget.followUp == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveFollowUp() async {
    if (!_formKey.currentState!.validate()) return;

    final followUp = FollowUp(
      id: widget.followUp?.id,
      memberId: _selectedMemberId!,
      type: _selectedType,
      dueDate: _selectedDate,
      notes: _notesController.text.trim(),
      createdAt: widget.followUp?.createdAt ?? DateTime.now(),
      isCompleted: widget.followUp?.isCompleted ?? false,
    );

    try {
      final member = await ref.read(databaseServiceProvider).getMemberById(_selectedMemberId!);
      final memberName = member?.name ?? 'Member';
      
      if (widget.followUp == null) {
        await ref.read(followUpNotifierProvider.notifier).addFollowUp(followUp, memberName);
      } else {
        await ref.read(followUpNotifierProvider.notifier).updateFollowUp(followUp, memberName);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.followUp == null 
                ? 'Follow-up added successfully'
                : 'Follow-up updated successfully',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}