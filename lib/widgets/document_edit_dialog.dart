import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:intl/intl.dart';

class DocumentEditDialog extends StatefulWidget {
  final DocumentModel document;
  final StorageService storageService;

  const DocumentEditDialog({
    super.key,
    required this.document,
    required this.storageService,
  });

  @override
  State<DocumentEditDialog> createState() => _DocumentEditDialogState();
}

class _DocumentEditDialogState extends State<DocumentEditDialog> {
  final NotificationService _notificationService = NotificationService();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime? _issueDate;
  late DateTime? _expiryDate;
  late DateTime? _dueDate;
  late bool _hasReminder;
  late List<int> _customReminderIntervals;
  
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document.name);
    _descriptionController = TextEditingController(text: widget.document.description ?? '');
    _selectedCategory = widget.document.category;
    _issueDate = widget.document.issueDate;
    _expiryDate = widget.document.expiryDate;
    _dueDate = widget.document.dueDate;
    _hasReminder = widget.document.hasReminder;
    
    // Load custom reminder intervals if they exist
    _customReminderIntervals = [];
    if (widget.document.metadata != null && 
        widget.document.metadata!.containsKey('customReminderIntervals')) {
      _customReminderIntervals = List<int>.from(
        widget.document.metadata!['customReminderIntervals'] as List
      );
    }
    
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final customCategories = await widget.storageService.getSetting(
      'custom_categories',
      defaultValue: <Map<String, dynamic>>[],
    ) as List;

    setState(() {
      _categories = [
        'Identity',
        'Bills',
        'Medical',
        'Insurance',
        'Legal',
        'Other',
        ...customCategories.map((cat) => cat['name'] as String),
      ];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? initialDate;
    if (type == 'issue') {
      initialDate = _issueDate;
    } else if (type == 'expiry') {
      initialDate = _expiryDate;
    } else {
      initialDate = _dueDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5E81F3),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'issue') {
          _issueDate = picked;
        } else if (type == 'expiry') {
          _expiryDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _editCustomIntervals() async {
    // Load default intervals if custom not set
    if (_customReminderIntervals.isEmpty) {
      final defaultIntervals = await widget.storageService.getSetting(
        'default_reminder_intervals',
        defaultValue: [30, 7, 1],
      ) as List;
      _customReminderIntervals = defaultIntervals.cast<int>();
    }

    final intervals = List<int>.from(_customReminderIntervals);
    
    await showDialog(
      context: context,
      builder: (context) => _CustomIntervalsDialog(
        intervals: intervals,
        onSave: (newIntervals) {
          setState(() {
            _customReminderIntervals = newIntervals;
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document name')),
      );
      return;
    }

    // Prepare metadata
    final metadata = Map<String, dynamic>.from(widget.document.metadata ?? {});
    
    // Save custom intervals if set
    if (_customReminderIntervals.isNotEmpty) {
      metadata['customReminderIntervals'] = _customReminderIntervals;
    }

    final updatedDocument = widget.document.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      category: _selectedCategory,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      dueDate: _dueDate,
      hasReminder: _hasReminder,
      metadata: metadata,
    );

    // Save to storage
    await widget.storageService.saveDocument(
      updatedDocument.id,
      updatedDocument.toJson(),
    );

    // Cancel old notifications
    await _notificationService.cancelDocumentReminders(widget.document);

    // Schedule new notifications if reminder is enabled
    if (_hasReminder && (_expiryDate != null || _dueDate != null)) {
      final scheduledIds = await _notificationService.scheduleDocumentReminders(
        document: updatedDocument,
        customIntervals: _customReminderIntervals.isNotEmpty 
            ? _customReminderIntervals 
            : null,
      );
      
      // Update metadata with notification IDs
      metadata['notificationIds'] = scheduledIds;
      final finalDocument = updatedDocument.copyWith(metadata: metadata);
      await widget.storageService.saveDocument(
        finalDocument.id,
        finalDocument.toJson(),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(updatedDocument);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
        backgroundColor: Color(0xFF1E1E1E),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF5E81F3)),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFF5E81F3)),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Document',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Document Name *',
                        labelStyle: const TextStyle(color: Color(0xFF5E81F3)),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF5E81F3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: Color(0xFF5E81F3)),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF5E81F3)),
                        ),
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: const TextStyle(color: Color(0xFF5E81F3)),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF5E81F3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dates Section
                    Text(
                      'DATES',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Issue Date
                    _buildDateField(
                      'Issue Date',
                      _issueDate,
                      () => _selectDate(context, 'issue'),
                      Icons.calendar_today,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 12),

                    // Expiry Date
                    _buildDateField(
                      'Expiry Date',
                      _expiryDate,
                      () => _selectDate(context, 'expiry'),
                      Icons.event_busy,
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 12),

                    // Due Date
                    _buildDateField(
                      'Due Date',
                      _dueDate,
                      () => _selectDate(context, 'due'),
                      Icons.event_available,
                      const Color(0xFFFBBF24),
                    ),
                    const SizedBox(height: 24),

                    // Reminder Section
                    Text(
                      'REMINDERS',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reminder Toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E81F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Color(0xFF5E81F3),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Enable Reminders',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Get notified before expiry/due date',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _hasReminder,
                                onChanged: (_expiryDate != null || _dueDate != null)
                                    ? (value) {
                                        setState(() => _hasReminder = value);
                                      }
                                    : null,
                                activeColor: const Color(0xFF5E81F3),
                              ),
                            ],
                          ),
                          if (_hasReminder) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _editCustomIntervals,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Color(0xFF5E81F3),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Custom Intervals',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _customReminderIntervals.isEmpty
                                                ? 'Using default intervals'
                                                : _customReminderIntervals.map((d) => '${d}d').join(', '),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (!(_expiryDate != null || _dueDate != null)) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange[300],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Set an expiry or due date to enable reminders',
                                    style: TextStyle(
                                      color: Colors.orange[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E81F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    VoidCallback onTap,
    IconData icon,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null 
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Not set',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    if (label == 'Issue Date') {
                      _issueDate = null;
                    } else if (label == 'Expiry Date') {
                      _expiryDate = null;
                    } else {
                      _dueDate = null;
                    }
                  });
                },
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// Custom Intervals Dialog (simplified version from settings)
class _CustomIntervalsDialog extends StatefulWidget {
  final List<int> intervals;
  final Function(List<int>) onSave;

  const _CustomIntervalsDialog({
    required this.intervals,
    required this.onSave,
  });

  @override
  State<_CustomIntervalsDialog> createState() => _CustomIntervalsDialogState();
}

class _CustomIntervalsDialogState extends State<_CustomIntervalsDialog> {
  late List<int> _intervals;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _intervals = List<int>.from(widget.intervals);
    _intervals.sort((a, b) => b.compareTo(a));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addInterval() {
    final value = int.tryParse(_controller.text);
    if (value != null && value > 0 && value <= 365) {
      if (!_intervals.contains(value)) {
        setState(() {
          _intervals.add(value);
          _intervals.sort((a, b) => b.compareTo(a));
          _controller.clear();
        });
      }
    }
  }

  void _removeInterval(int value) {
    setState(() {
      _intervals.remove(value);
    });
  }

  void _save() {
    widget.onSave(_intervals);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Reminder Intervals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Days before',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addInterval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_intervals.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _intervals.map((interval) {
                  return Chip(
                    label: Text('$interval days', style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF1E1E1E),
                    deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onDeleted: () => _removeInterval(interval),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E81F3)),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
