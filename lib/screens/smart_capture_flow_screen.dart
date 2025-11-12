import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/ocr_service.dart';
import 'package:documate/services/ml_classification_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/search_index_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:documate/utils/document_parser.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/theme/app_theme.dart';
import 'package:documate/models/document_category.dart';

class SmartCaptureFlowScreen extends StatefulWidget {
  final StorageService storageService;
  final CloudSyncService cloudSyncService;

  const SmartCaptureFlowScreen({
    super.key,
    required this.storageService,
    required this.cloudSyncService,
  });

  @override
  State<SmartCaptureFlowScreen> createState() => _SmartCaptureFlowScreenState();
}

class _SmartCaptureFlowScreenState extends State<SmartCaptureFlowScreen> {
  final OCRService _ocrService = OCRService();
  final MLClassificationService _mlService = MLClassificationService();
  final NotificationService _notificationService = NotificationService();
  final SearchIndexService _searchIndexService = SearchIndexService();

  bool _isProcessing = false;
  String? _frontImagePath;
  String? _backImagePath;
  String _extractedText = '';
  ClassificationResult? _classification;
  ParsedDocumentData? _parsedData;
  bool _needsBackSide = false;
  bool _frontCaptured = false;

  // Editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Other';
  List<String> _tags = [];
  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dueDate;
  bool _enableReminders = true;

  @override
  void initState() {
    super.initState();
    _startCapture();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _startCapture() async {
    await _captureDocument(isFront: true);
  }

  Future<void> _captureDocument({required bool isFront}) async {
    setState(() => _isProcessing = true);

    try {
      // Use edge detection to capture document
      String? imagePath;

      bool success = await EdgeDetection.detectEdge(
        '/storage/emulated/0/Pictures/documate_scanned.jpg',
        canUseGallery: true,
      );

      if (success) {
        imagePath = '/storage/emulated/0/Pictures/documate_scanned.jpg';
      }

      if (imagePath != null) {
        if (isFront) {
          _frontImagePath = imagePath;
          await _processImage(imagePath);

          // Check if we need back side
          if (_needsBackSide && mounted) {
            final captureBack = await _showBackSideCaptureDialog();
            if (captureBack == true) {
              await _captureDocument(isFront: false);
            } else {
              setState(() => _frontCaptured = true);
            }
          } else {
            setState(() => _frontCaptured = true);
          }
        } else {
          _backImagePath = imagePath;
          // Process back side OCR
          final backText = await _ocrService.extractText(imagePath);
          setState(() {
            _extractedText += '\n\n--- Back Side ---\n\n$backText';
            _frontCaptured = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document capture cancelled')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error capturing document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        Navigator.pop(context);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      // Extract text with OCR
      final ocrText = await _ocrService.extractText(imagePath);

      if (ocrText.isEmpty) {
        if (mounted) {
          _showNoTextDialog();
        }
      }

      setState(() => _extractedText = ocrText);

      // Classify document
      final classification = _mlService.classify(ocrText);
      setState(() => _classification = classification);

      // Parse structured data
      final parsed = DocumentParser.parse(ocrText, classification.category);
      setState(() => _parsedData = parsed);

      // Auto-fill fields
      _selectedCategory = classification.category;
      _tags = classification.suggestedTags;
      _issueDate = parsed.issueDate;
      _expiryDate = parsed.expiryDate;
      _dueDate = parsed.dueDate;

      // Generate document name
      String docName = classification.documentType ?? classification.category;
      if (parsed.documentNumber != null) {
        docName += ' - ${parsed.documentNumber}';
      }
      _nameController.text = docName;

      // Check if category requires multi-page capture
      _needsBackSide = _mlService.requiresMultiPageCapture(
        classification.category,
        classification.documentType,
      );

      // Show confidence warning if low
      if (classification.confidence < 60 && mounted) {
        _showLowConfidenceDialog();
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing error: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _showBackSideCaptureDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture Back Side?'),
        content: Text(
          'This appears to be a ${_classification?.documentType ?? "document"} which typically has information on both sides. Would you like to capture the back side?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Capture Back'),
          ),
        ],
      ),
    );
  }

  void _showLowConfidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Classification Confidence'),
        content: Text(
          'The document type detection has ${_classification!.confidence.toStringAsFixed(0)}% confidence. Please verify the category and details below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNoTextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Text Detected'),
        content: const Text(
          'OCR could not extract any text from this image. You can still save the document, but you\'ll need to enter details manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDocument() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document name')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      final frontDoc = DocumentModel(
        id: documentId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        imagePath: _frontImagePath!,
        extractedText: _extractedText,
        createdAt: DateTime.now(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        dueDate: _dueDate,
        tags: _tags.isNotEmpty ? _tags : null,
        hasReminder:
            _enableReminders && (_expiryDate != null || _dueDate != null),
        metadata: _backImagePath != null
            ? {'side': 'front', 'hasBackSide': true}
            : null,
        imagePaths:
            _backImagePath != null ? [_frontImagePath!, _backImagePath!] : null,
      );

      // Schedule notifications if enabled
      List<int> notificationIds = [];
      if (_enableReminders && (_expiryDate != null || _dueDate != null)) {
        notificationIds = await _notificationService.scheduleDocumentReminders(
          document: frontDoc,
        );
      }

      // Add notification IDs to metadata
      final metadata = frontDoc.metadata ?? {};
      metadata['notificationIds'] = notificationIds;
      final finalDoc = frontDoc.copyWith(metadata: metadata);

      // Save to storage
      await widget.storageService.saveDocument(documentId, finalDoc.toJson());

      // Add to search index
      await _searchIndexService.addDocumentToIndex(finalDoc);

      // Trigger cloud sync if enabled
      final backupEnabled = await widget.cloudSyncService.isBackupEnabled();
      if (backupEnabled) {
        widget.cloudSyncService.uploadBackup().catchError((e) {
          print('Background sync error: $e');
          return false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document saved successfully!')),
        );

        // Navigate to document details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentDetailsScreen(
              document: finalDoc,
              storageService: widget.storageService,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving document: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing || !_frontCaptured) {
      return Scaffold(
        backgroundColor: DocuMateTheme.darkTheme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _frontCaptured
                    ? 'Processing document...'
                    : 'Capturing document...',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DocuMateTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confirm Document Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveDocument,
            child: const Text('SAVE', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image preview
          if (_frontImagePath != null) _buildImagePreview(),

          const SizedBox(height: 24),

          // Classification info
          if (_classification != null) _buildClassificationBanner(),

          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Document Name *',
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
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
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
            items:
                ['Identity', 'Bills', 'Medical', 'Insurance', 'Legal', 'Other']
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
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date fields
          _buildDateField('Issue Date', _issueDate, (date) {
            setState(() => _issueDate = date);
          }),
          const SizedBox(height: 12),
          _buildDateField('Expiry Date', _expiryDate, (date) {
            setState(() => _expiryDate = date);
          }),
          const SizedBox(height: 12),
          _buildDateField('Due Date', _dueDate, (date) {
            setState(() => _dueDate = date);
          }),

          const SizedBox(height: 16),

          // Tags
          _buildTagsSection(),

          const SizedBox(height: 16),

          // Reminder toggle
          SwitchListTile(
            title: const Text('Enable Reminders',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(
              _expiryDate == null && _dueDate == null
                  ? 'Set an expiry or due date to enable reminders'
                  : 'Get notified before expiry/due date',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _enableReminders,
            onChanged: _expiryDate != null || _dueDate != null
                ? (value) => setState(() => _enableReminders = value)
                : null,
            activeColor: Colors.blue,
          ),

          const SizedBox(height: 24),

          // Extracted text (expandable)
          if (_extractedText.isNotEmpty)
            ExpansionTile(
              title: const Text('Extracted Text',
                  style: TextStyle(color: Colors.white)),
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _extractedText,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.file(
              File(_frontImagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
            if (_backImagePath != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '2 Pages',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationBanner() {
    final confidence = _classification!.confidence;
    final color = confidence >= 80
        ? Colors.green
        : confidence >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _classification!.documentType ?? 'Auto-detected',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${confidence.toStringAsFixed(0)}% confidence',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? value, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
        ),
        child: Text(
          value != null
              ? '${value.day}/${value.month}/${value.year}'
              : 'Not set',
          style: TextStyle(
            color: value != null ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.blue),
                  deleteIconColor: Colors.blue,
                )),
            ActionChip(
              label: const Text('+ Add Tag'),
              onPressed: _addTag,
              backgroundColor: Colors.grey[800],
              labelStyle: const TextStyle(color: Colors.blue),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter tag'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
    }
  }
}
