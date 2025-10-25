import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:harvestflow/models/meeting.dart';
// import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/providers/meeting_provider.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/widgets/meeting_card.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            onPressed: () => ref.read(meetingNotifierProvider.notifier).loadMeetings(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: meetingsAsync.when(
        data: (meetings) {
          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No meetings scheduled',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the + button to schedule your first meeting'),
                ],
              ),
            );
          }

          // Separate upcoming and past meetings
          final now = DateTime.now();
          final upcomingMeetings = meetings.where((m) => 
            m.dateTime.isAfter(now) || m.dateTime.day == now.day).toList();
          final pastMeetings = meetings.where((m) => 
            m.dateTime.isBefore(now) && m.dateTime.day != now.day).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(meetingNotifierProvider.notifier).loadMeetings();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (upcomingMeetings.isNotEmpty) ...[
                    Text(
                      'Upcoming Meetings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...upcomingMeetings.map((meeting) => MeetingCard(
                      meeting: meeting,
                      onTap: () => _showMeetingDetails(context, ref, meeting),
                      onEdit: () => _showMeetingForm(context, ref, meeting),
                      onDelete: () => _deleteMeeting(context, ref, meeting),
                      onComplete: meeting.isCompleted 
                          ? null 
                          : () => _completeMeeting(context, ref, meeting),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  if (pastMeetings.isNotEmpty) ...[
                    Text(
                      'Past Meetings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    ...pastMeetings.map((meeting) => MeetingCard(
                      meeting: meeting,
                      onTap: () => _showMeetingDetails(context, ref, meeting),
                      onEdit: () => _showMeetingForm(context, ref, meeting),
                      onDelete: () => _deleteMeeting(context, ref, meeting),
                      isPast: true,
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
                  ref.read(meetingNotifierProvider.notifier).loadMeetings();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMeetingForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMeetingDetails(BuildContext context, WidgetRef ref, Meeting meeting) async {
    try {
      final members = await ref.read(memberListProvider.future);
      final meetingMembers = members.where((m) => meeting.memberIds.contains(m.id)).toList();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(meeting.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Date', value: DateFormat('EEEE, MMM d, y').format(meeting.dateTime)),
                _DetailRow(label: 'Time', value: DateFormat('h:mm a').format(meeting.dateTime)),
                _DetailRow(label: 'Description', value: meeting.description),
                _DetailRow(label: 'Status', value: meeting.isCompleted ? 'Completed' : 'Scheduled'),
                _DetailRow(label: 'SMS Sent', value: meeting.smsSent ? 'Yes' : 'No'),
                if (meetingMembers.isNotEmpty)
                  _DetailRow(
                    label: 'Members',
                    value: meetingMembers.map((m) => m.name).join(', '),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (!meeting.isCompleted)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _completeMeeting(context, ref, meeting);
                  },
                  child: const Text('Mark Complete'),
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showMeetingForm(context, ref, meeting);
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meeting details: $e')),
        );
      }
    }
  }

  void _showMeetingForm(BuildContext context, WidgetRef ref, [Meeting? meeting]) {
    showDialog(
      context: context,
      builder: (context) => _MeetingFormDialog(meeting: meeting),
    );
  }

  void _deleteMeeting(BuildContext context, WidgetRef ref, Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${meeting.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(meetingNotifierProvider.notifier).deleteMeeting(meeting.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meeting deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _completeMeeting(BuildContext context, WidgetRef ref, Meeting meeting) async {
    await ref.read(meetingNotifierProvider.notifier).completeMeeting(meeting.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meeting marked as completed')),
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

class _MeetingFormDialog extends ConsumerStatefulWidget {
  final Meeting? meeting;

  const _MeetingFormDialog({this.meeting});

  @override
  ConsumerState<_MeetingFormDialog> createState() => __MeetingFormDialogState();
}

class __MeetingFormDialogState extends ConsumerState<_MeetingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late List<int> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting?.title ?? '');
    _descriptionController = TextEditingController(text: widget.meeting?.description ?? '');
    _selectedDate = widget.meeting?.dateTime.toLocal() ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = widget.meeting != null 
        ? TimeOfDay.fromDateTime(widget.meeting!.dateTime.toLocal())
        : const TimeOfDay(hour: 10, minute: 0);
    _selectedMemberIds = widget.meeting?.memberIds ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(memberListProvider);

    return AlertDialog(
      title: Text(widget.meeting == null ? 'Schedule Meeting' : 'Edit Meeting'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
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
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(_selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 16),
              membersAsync.when(
                data: (members) => ExpansionTile(
                  leading: const Icon(Icons.people),
                  title: Text('Members (${_selectedMemberIds.length} selected)'),
                  children: members.map((member) {
                    final isSelected = _selectedMemberIds.contains(member.id);
                    return CheckboxListTile(
                      title: Text(member.name),
                      subtitle: Text(member.groupTag),
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedMemberIds.add(member.id!);
                          } else {
                            _selectedMemberIds.remove(member.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error loading members: $error'),
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
          onPressed: _saveMeeting,
          child: Text(widget.meeting == null ? 'Schedule' : 'Update'),
        ),
      ],
    );
  }

  void _saveMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final meeting = Meeting(
      id: widget.meeting?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dateTime: dateTime,
      memberIds: _selectedMemberIds,
      isCompleted: widget.meeting?.isCompleted ?? false,
      smsSent: widget.meeting?.smsSent ?? false,
    );

    try {
      if (widget.meeting == null) {
        await ref.read(meetingNotifierProvider.notifier).addMeeting(meeting);
      } else {
        await ref.read(meetingNotifierProvider.notifier).updateMeeting(meeting);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.meeting == null 
                ? 'Meeting scheduled successfully'
                : 'Meeting updated successfully',
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