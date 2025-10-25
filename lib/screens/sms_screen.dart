import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harvestflow/models/sms_template.dart';
import 'package:harvestflow/models/member.dart';
import 'package:harvestflow/providers/settings_provider.dart';
import 'package:harvestflow/providers/member_provider.dart';
import 'package:harvestflow/services/sms_service.dart';

class SMSScreen extends ConsumerStatefulWidget {
  const SMSScreen({super.key});

  @override
  ConsumerState<SMSScreen> createState() => _SMSScreenState();
}

class _SMSScreenState extends ConsumerState<SMSScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  final List<int> _selectedMemberIds = [];
  String? _selectedGroupTag;
  SMSTemplate? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Messaging'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send SMS', icon: Icon(Icons.send)),
            Tab(text: 'Templates', icon: Icon(Icons.text_snippet)),
            Tab(text: 'Bulk SMS', icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendSMSTab(),
          _buildTemplatesTab(),
          _buildBulkSMSTab(),
        ],
      ),
    );
  }

  Widget _buildSendSMSTab() {
    final settings = ref.watch(appSettingsProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.arkEselApiKey.isEmpty)
            Card(
              color: Colors.orange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Please configure your ArkESel API key in Settings to send SMS.'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                      child: const Text('Settings'),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          Text(
            'Send Individual SMS',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _recipientController,
            decoration: const InputDecoration(
              labelText: 'Recipient Phone Number',
              prefixIcon: Icon(Icons.phone),
              hintText: '233XXXXXXXXX',
            ),
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Template selection
          Consumer(
            builder: (context, ref, child) {
              final templatesAsync = ref.watch(smsTemplatesProvider);
              return templatesAsync.when(
                data: (templates) => DropdownButtonFormField<SMSTemplate>(
                  value: _selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Select Template (Optional)',
                    prefixIcon: Icon(Icons.text_snippet),
                  ),
                  items: [
                    const DropdownMenuItem<SMSTemplate>(
                      value: null,
                      child: Text('No template'),
                    ),
                    ...templates.map((template) => DropdownMenuItem(
                      value: template,
                      child: Text(template.name),
                    )),
                  ],
                  onChanged: (template) {
                    setState(() {
                      _selectedTemplate = template;
                      if (template != null) {
                        _messageController.text = template.content;
                      }
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text('Error loading templates: $error'),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 160,
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: settings.arkEselApiKey.isNotEmpty ? _sendIndividualSMS : null,
              icon: const Icon(Icons.send),
              label: const Text('Send SMS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick send to members
          Text(
            'Quick Send to Members',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Consumer(
            builder: (context, ref, child) {
              final membersAsync = ref.watch(memberListProvider);
              return membersAsync.when(
                data: (members) => Column(
                  children: members.map((member) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(member.name[0].toUpperCase()),
                      ),
                      title: Text(member.name),
                      subtitle: Text(member.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _quickSendToMember(member),
                      ),
                      onTap: () {
                        _recipientController.text = member.phone;
                        _showQuickMessageDialog(member);
                      },
                    ),
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Error loading members: $error'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final templatesAsync = ref.watch(smsTemplateNotifierProvider);
        
        return templatesAsync.when(
          data: (templates) => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _showTemplateForm(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Template'),
                  ),
                );
              }
              
              final template = templates[index - 1];
              return Card(
                child: ExpansionTile(
                  title: Text(template.name),
                  subtitle: Text(template.category),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(template.content),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _useTemplate(template),
                                child: const Text('Use Template'),
                              ),
                              TextButton(
                                onPressed: () => _showTemplateForm(context, ref, template),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                onPressed: () => _deleteTemplate(context, ref, template),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildBulkSMSTab() {
    final settings = ref.watch(appSettingsProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk SMS',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Group selection
          Consumer(
            builder: (context, ref, child) {
              return DropdownButtonFormField<String>(
                value: _selectedGroupTag,
                decoration: const InputDecoration(
                  labelText: 'Send to Group',
                  prefixIcon: Icon(Icons.group),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select members individually'),
                  ),
                  ...GroupTags.all.map((tag) => DropdownMenuItem(
                    value: tag,
                    child: Text('All in $tag'),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroupTag = value;
                    if (value != null) {
                      _selectedMemberIds.clear();
                    }
                  });
                },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Individual member selection (if no group selected)
          if (_selectedGroupTag == null)
            Consumer(
              builder: (context, ref, child) {
                final membersAsync = ref.watch(memberListProvider);
                return membersAsync.when(
                  data: (members) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Members (${_selectedMemberIds.length} selected)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...members.map((member) => CheckboxListTile(
                        title: Text(member.name),
                        subtitle: Text('${member.phone} • ${member.groupTag}'),
                        value: _selectedMemberIds.contains(member.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedMemberIds.add(member.id!);
                            } else {
                              _selectedMemberIds.remove(member.id);
                            }
                          });
                        },
                      )),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error loading members: $error'),
                );
              },
            ),
          
          const SizedBox(height: 16),
          
          // Template selection for bulk
          Consumer(
            builder: (context, ref, child) {
              final templatesAsync = ref.watch(smsTemplatesProvider);
              return templatesAsync.when(
                data: (templates) => DropdownButtonFormField<SMSTemplate>(
                  value: _selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Select Template',
                    prefixIcon: Icon(Icons.text_snippet),
                  ),
                  items: templates.map((template) => DropdownMenuItem(
                    value: template,
                    child: Text(template.name),
                  )).toList(),
                  onChanged: (template) {
                    setState(() {
                      _selectedTemplate = template;
                      if (template != null) {
                        _messageController.text = template.content;
                      }
                    });
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => Text('Error loading templates: $error'),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 160,
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: settings.arkEselApiKey.isNotEmpty ? _sendBulkSMS : null,
              icon: const Icon(Icons.send),
              label: Text(
                _selectedGroupTag != null 
                    ? 'Send to All in $_selectedGroupTag'
                    : 'Send to Selected Members (${_selectedMemberIds.length})',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendIndividualSMS() async {
    if (_recipientController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient and message')),
      );
      return;
    }

    final settings = ref.read(appSettingsProvider);
    final smsService = SMSService();
    
    final success = await smsService.sendSMS(
      recipient: _recipientController.text,
      message: _messageController.text,
      apiKey: settings.arkEselApiKey,
      sender: settings.smsSender,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'SMS sent successfully!' : 'Failed to send SMS'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _recipientController.clear();
      _messageController.clear();
      _selectedTemplate = null;
    }
  }

  void _sendBulkSMS() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    List<String> recipients = [];
    
    if (_selectedGroupTag != null) {
      final members = await ref.read(membersByGroupProvider(_selectedGroupTag!).future);
      recipients = members.map((m) => m.phone).toList();
    } else if (_selectedMemberIds.isNotEmpty) {
      final allMembers = await ref.read(memberListProvider.future);
      recipients = allMembers
          .where((m) => _selectedMemberIds.contains(m.id))
          .map((m) => m.phone)
          .toList();
    }

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recipients selected')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk SMS'),
        content: Text('Send message to ${recipients.length} recipients?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final settings = ref.read(appSettingsProvider);
    final smsService = SMSService();

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending SMS messages...'),
          ],
        ),
      ),
    );

    final results = await smsService.sendBulkSMS(
      recipients: recipients,
      message: _messageController.text,
      apiKey: settings.arkEselApiKey,
      sender: settings.smsSender,
    );

    Navigator.pop(context); // Close progress dialog

    final successCount = results.where((r) => r).length;
    final failureCount = results.length - successCount;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent: $successCount, Failed: $failureCount'),
        backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
      ),
    );

    if (successCount > 0) {
      _messageController.clear();
      _selectedTemplate = null;
      _selectedMemberIds.clear();
      _selectedGroupTag = null;
    }
  }

  void _quickSendToMember(Member member) {
    _recipientController.text = member.phone;
    _showQuickMessageDialog(member);
  }

  void _showQuickMessageDialog(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send SMS to ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phone: ${member.phone}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 160,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendIndividualSMS();
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _useTemplate(SMSTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _messageController.text = template.content;
    });
    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${template.name}" loaded')),
    );
  }

  void _showTemplateForm(BuildContext context, WidgetRef ref, [SMSTemplate? template]) {
    showDialog(
      context: context,
      builder: (context) => _TemplateFormDialog(template: template),
    );
  }

  void _deleteTemplate(BuildContext context, WidgetRef ref, SMSTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete template "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(smsTemplateNotifierProvider.notifier).deleteTemplate(template.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TemplateFormDialog extends ConsumerStatefulWidget {
  final SMSTemplate? template;

  const _TemplateFormDialog({this.template});

  @override
  ConsumerState<_TemplateFormDialog> createState() => __TemplateFormDialogState();
}

class __TemplateFormDialogState extends ConsumerState<_TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contentController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _contentController = TextEditingController(text: widget.template?.content ?? '');
    _selectedCategory = widget.template?.category ?? SMSTemplateCategories.followUp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.template == null ? 'Add Template' : 'Edit Template'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Template Name'),
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: SMSTemplateCategories.all.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Message Content',
                alignLabelWithHint: true,
                hintText: 'Use {name}, {date}, {time} for variables',
              ),
              maxLines: 4,
              maxLength: 160,
              validator: (value) => value?.isEmpty == true ? 'Content is required' : null,
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
          onPressed: _saveTemplate,
          child: Text(widget.template == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  void _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final template = SMSTemplate(
      id: widget.template?.id,
      name: _nameController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
    );

    try {
      if (widget.template == null) {
        await ref.read(smsTemplateNotifierProvider.notifier).addTemplate(template);
      } else {
        await ref.read(smsTemplateNotifierProvider.notifier).updateTemplate(template);
      }
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.template == null 
                ? 'Template added successfully'
                : 'Template updated successfully',
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