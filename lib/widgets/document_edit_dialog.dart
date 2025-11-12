import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';

// Document Edit Dialog
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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime? _issueDate;
  late DateTime? _expiryDate;
  late DateTime? _dueDate;
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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document name')),
      );
      return;
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
    );

    // Save to storage
    await widget.storageService.saveDocument(
      updatedDocument.id,
      updatedDocument.toJson(),
    );

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

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Edit Document',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Document Name',
                labelStyle: const TextStyle(color: Color(0xFF5E81F3)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5E81F3)),
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5E81F3)),
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
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF5E81F3)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5E81F3),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

