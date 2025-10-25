import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:harvestflow/models/meeting.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final bool isPast;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onComplete,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = meeting.dateTime.isBefore(DateTime.now()) && !meeting.isCompleted && !isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                      meeting.isCompleted 
                          ? Icons.event_available
                          : isOverdue
                              ? Icons.warning
                              : Icons.event,
                      color: meeting.isCompleted
                          ? Colors.green
                          : isOverdue
                              ? Colors.red
                              : isPast
                                  ? Colors.grey
                                  : Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meeting.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: meeting.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('MMM d, y').format(meeting.dateTime)} at ${DateFormat('h:mm a').format(meeting.dateTime)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isOverdue ? Colors.red : null,
                                  fontWeight: isOverdue ? FontWeight.bold : null,
                                ),
                              ),
                            ],
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
                
                if (meeting.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    meeting.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(meeting, isOverdue).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(meeting, isOverdue),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(meeting, isOverdue),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Members count
                    if (meeting.memberIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '${meeting.memberIds.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // SMS status
                    Icon(
                      meeting.smsSent ? Icons.message : Icons.message_outlined,
                      size: 16,
                      color: meeting.smsSent ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meeting.smsSent ? 'SMS sent' : 'No SMS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: meeting.smsSent ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                if (isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'This meeting is overdue',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(Meeting meeting, bool isOverdue) {
    if (meeting.isCompleted) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isPast) return Colors.grey;
    return Colors.blue;
  }

  String _getStatusText(Meeting meeting, bool isOverdue) {
    if (meeting.isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (isPast) return 'Past';
    return 'Scheduled';
  }
}