import 'dart:io';
import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/theme/app_theme.dart';

class DocumentDetailsScreen extends StatefulWidget {
  final DocumentModel document;
  final StorageService storageService;

  const DocumentDetailsScreen({
    super.key,
    required this.document,
    required this.storageService,
  });

  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  late DocumentModel _document;
  final NotificationService _notificationService = NotificationService();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  DocumentModel? _linkedDocument;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _loadLinkedDocument();
  }

  Future<void> _loadLinkedDocument() async {
    if (_document.linkedDocumentId != null) {
      try {
        final linkedData = await widget.storageService
            .getDocument(_document.linkedDocumentId!);
        if (linkedData != null) {
          setState(() {
            _linkedDocument = DocumentModel.fromJson(linkedData);
          });
        }
      } catch (e) {
        print('Error loading linked document: $e');
      }
    }
  }

  List<String> get _allImages {
    final images = <String>[_document.imagePath];

    // Add additional images if available
    if (_document.imagePaths != null && _document.imagePaths!.isNotEmpty) {
      images.addAll(_document.imagePaths!);
    }

    // Add linked document image (back side)
    if (_linkedDocument != null) {
      images.add(_linkedDocument!.imagePath);
    }

    return images;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDocument,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image carousel
          Expanded(
            flex: 2,
            child: _buildImageCarousel(),
          ),

          // Document details
          Expanded(
            flex: 3,
            child: _buildDetailsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = _allImages;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemCount: images.length,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  File(images[index]),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            );
          },
        ),

        // Page indicator
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),

        // Side labels
        if (images.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentImageIndex == 0 ? 'Front' : 'Back',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      decoration: BoxDecoration(
        color: DocuMateTheme.darkTheme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoRow('Category', _document.category, Icons.category),
          if (_document.description != null)
            _buildInfoRow(
                'Description', _document.description!, Icons.description),
          const Divider(height: 32),
          if (_document.issueDate != null)
            _buildInfoRow(
              'Issue Date',
              _formatDate(_document.issueDate!),
              Icons.calendar_today,
            ),
          if (_document.expiryDate != null)
            _buildInfoRow(
              'Expiry Date',
              _formatDate(_document.expiryDate!),
              Icons.event,
              valueColor: _document.isExpired
                  ? Colors.red
                  : _document.isExpiringSoon
                      ? Colors.orange
                      : Colors.green,
            ),
          if (_document.dueDate != null)
            _buildInfoRow(
              'Due Date',
              _formatDate(_document.dueDate!),
              Icons.payment,
            ),
          if (_document.tags != null && _document.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _document.tags!
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.blue),
                      ))
                  .toList(),
            ),
          ],
          if (_document.extractedText != null &&
              _document.extractedText!.isNotEmpty) ...[
            const Divider(height: 32),
            ExpansionTile(
              title: const Text('Extracted Text',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.text_fields),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _document.extractedText!,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _buildReminderSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Switch(
                value: _document.hasReminder,
                onChanged: _toggleReminder,
                activeColor: Colors.blue,
              ),
            ],
          ),
          if (_document.hasReminder && _document.reminderDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next reminder: ${_formatDate(_document.reminderDate!)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleReminder(bool value) async {
    // TODO: Implement reminder toggle logic
    setState(() {
      _document = _document.copyWith(hasReminder: value);
    });
  }

  Future<void> _editDocument() async {
    // TODO: Navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${_document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.storageService.deleteDocument(_document.id);

      // Delete linked document if exists
      if (_linkedDocument != null) {
        await widget.storageService.deleteDocument(_linkedDocument!.id);
      }

      // Cancel notifications
      await _notificationService.cancelDocumentReminders(_document);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    }
  }
}
