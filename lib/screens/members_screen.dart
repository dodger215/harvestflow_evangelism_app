import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/widgets/member_card.dart';
import 'package:harvestflow/services/contacts_service.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(filteredMembersProvider);
    final selectedGroup = ref.watch(selectedGroupFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String? value) {
              ref.read(selectedGroupFilterProvider.notifier).state = value;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Members'),
              ),
              ...GroupTags.all.map((tag) => PopupMenuItem(
                value: tag,
                child: Text(tag),
              )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (selectedGroup != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  Text(
                    'Filtered by: $selectedGroup',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedGroupFilterProvider.notifier).state = null;
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          selectedGroup != null 
                              ? 'No members in "$selectedGroup" group'
                              : 'No members yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('Tap the + button to add your first member'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.read(memberNotifierProvider.notifier).loadMembers();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return MemberCard(
                        member: member,
                        onTap: () => _showMemberDetails(context, ref, member),
                        onEdit: () => _showMemberForm(context, ref, member),
                        onDelete: () => _deleteMember(context, ref, member),
                        onSaveToContacts: () => _saveToContacts(context, member),
                      );
                    },
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
                        ref.read(memberNotifierProvider.notifier).loadMembers();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMemberForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMemberDetails(BuildContext context, WidgetRef ref, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Phone', value: member.phone),
            _DetailRow(label: 'Address', value: member.address),
            _DetailRow(label: 'Group', value: member.groupTag),
            _DetailRow(label: 'Notes', value: member.notes),
            _DetailRow(label: 'Added', value: DateFormat('MMM d, y').format(member.createdAt)),
            if (member.lastContact != null)
              _DetailRow(label: 'Last Contact', value: DateFormat('MMM d, y').format(member.lastContact!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMemberForm(context, ref, member);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showMemberForm(BuildContext context, WidgetRef ref, [Member? member]) {
    showDialog(
      context: context,
      builder: (context) => _MemberFormDialog(member: member),
    );
  }

  void _deleteMember(BuildContext context, WidgetRef ref, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(memberNotifierProvider.notifier).deleteMember(member.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${member.name} deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveToContacts(BuildContext context, Member member) async {
    final success = await DeviceContactsService.saveToContacts(member);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '${member.name} saved to contacts'
                : 'Failed to save contact. Please check permissions.',
          ),
        ),
      );
    }
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

class _MemberFormDialog extends ConsumerStatefulWidget {
  final Member? member;

  const _MemberFormDialog({this.member});

  @override
  ConsumerState<_MemberFormDialog> createState() => __MemberFormDialogState();
}

class __MemberFormDialogState extends ConsumerState<_MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _addressController = TextEditingController(text: widget.member?.address ?? '');
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
    _selectedGroup = widget.member?.groupTag ?? GroupTags.newConvert;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.member == null ? 'Add Member' : 'Edit Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) => value?.isEmpty == true ? 'Phone is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              decoration: const InputDecoration(
                labelText: 'Group',
                prefixIcon: Icon(Icons.group),
              ),
              items: GroupTags.all.map((tag) => DropdownMenuItem(
                value: tag,
                child: Text(tag),
              )).toList(),
              onChanged: (value) => setState(() => _selectedGroup = value!),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMember,
          child: Text(widget.member == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    final member = Member(
      id: widget.member?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      groupTag: _selectedGroup,
      createdAt: widget.member?.createdAt ?? DateTime.now(),
      lastContact: widget.member?.lastContact,
    );

    try {
      if (widget.member == null) {
        await ref.read(memberNotifierProvider.notifier).addMember(member);
      } else {
        await ref.read(memberNotifierProvider.notifier).updateMember(member);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.member == null 
                ? '${member.name} added successfully'
                : '${member.name} updated successfully',
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