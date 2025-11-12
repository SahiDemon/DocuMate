import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/ocr_service.dart';
import 'package:documate/services/ml_classification_service.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/services/search_index_service.dart';
import 'package:documate/services/cloud_sync_service.dart';
import 'package:documate/utils/document_parser.dart';
import 'package:documate/utils/smart_date_detector.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/screens/improved_capture_screen.dart';
import 'package:documate/screens/smart_document_scanner_screen.dart';
import 'package:camera/camera.dart';
import 'package:documate/theme/app_theme.dart';
import 'package:documate/models/document_category.dart';
import 'package:documate/main.dart' as main_app;

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

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
  // Use global initialized services instead of creating new instances
  late final NotificationService _notificationService = main_app.notificationService;
  late final SearchIndexService _searchIndexService = main_app.searchIndexService;

  bool _isProcessing = false;
  String? _frontImagePath;
  String? _backImagePath;
  String _extractedText = '';
  ClassificationResult? _classification;
  bool _needsBackSide = false;
  bool _frontCaptured = false;

  // Editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Other';
  List<String> _tags = [];
  List<String> _suggestedTags = [];
  List<String> _availableCategories = ['Identity', 'Bills', 'Medical', 'Insurance', 'Legal', 'Other'];
  DateTime? _issueDate;
  DateTime? _expiryDate;
  DateTime? _dueDate;
  bool _enableReminders = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _startCapture();
  }

  Future<void> _loadCategories() async {
    try {
      final customCategories = await widget.storageService.getSetting(
        'custom_categories',
        defaultValue: <Map<String, dynamic>>[],
      ) as List;

      final List<String> categories = [
        'Identity',
        'Bills',
        'Medical',
        'Insurance',
        'Legal',
        'Other',
        ...customCategories.map((cat) => cat['name'] as String),
      ];

      setState(() {
        _availableCategories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
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
      // Get available cameras
      final cameras = await availableCameras();
      
      // Use the smart document scanner with ML Kit
      final String? imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => SmartDocumentScannerScreen(
            isFront: isFront,
            cameras: cameras,
          ),
        ),
      );

      if (imagePath != null) {
        if (isFront) {
          _frontImagePath = imagePath;
          await _processImage(imagePath);

          // Check if we need back side
          if (_needsBackSide && mounted) {
            final result = await _showBackSideCaptureDialog();
            if (result == 'back' || result == 'more') {
              await _captureDocument(isFront: false);
              
              // If "more" was selected, keep asking
              if (result == 'more') {
                while (mounted) {
                  final continueCapture = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text(
                        'Capture Another Page?',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Would you like to capture another page?',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Done', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5E81F3),
                          ),
                          child: const Text('Capture More'),
                        ),
                      ],
                    ),
                  );
                  
                  if (continueCapture == true) {
                    await _captureDocument(isFront: false);
                  } else {
                    break;
                  }
                }
              }
            }
            setState(() => _frontCaptured = true);
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

      // Detect dates smartly
      final detectedDates = SmartDateDetector.detectDates(ocrText);
      
      // If dates detected, ask user to confirm
      if (detectedDates.isNotEmpty && mounted) {
        final dateResult = await SmartDateDetector.showDateSelectionDialog(
          context: context,
          detectedDates: detectedDates,
        );
        
        if (dateResult != null) {
          _issueDate = dateResult.issueDate;
          _expiryDate = dateResult.expiryDate;
          _dueDate = dateResult.dueDate;
          // Custom dates can be stored in metadata if needed
        } else {
          // User skipped, use parsed dates as fallback
          _issueDate = parsed.issueDate;
          _expiryDate = parsed.expiryDate;
          _dueDate = parsed.dueDate;
        }
      } else {
        // No dates detected, use parsed dates
        _issueDate = parsed.issueDate;
        _expiryDate = parsed.expiryDate;
        _dueDate = parsed.dueDate;
      }

      // Auto-fill category
      _selectedCategory = classification.category;
      
      // Generate smart tags
      _suggestedTags = _extractSmartTags(ocrText, classification.category);
      
      // Auto-add high-confidence tags
      if (classification.confidence > 75) {
        _tags = classification.suggestedTags;
      }

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

  Future<String?> _showBackSideCaptureDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Capture More Pages?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This appears to be a ${_classification?.documentType ?? "document"} which typically has information on both sides. Would you like to capture additional pages?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'skip'),
            child: Text(
              'Skip',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81F3).withOpacity(0.3),
            ),
            child: const Text(
              'Capture Back',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'more'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E81F3),
            ),
            child: const Text('Capture More'),
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

  List<String> _extractSmartTags(String text, String category) {
    final tags = <String>{};
    final lowerText = text.toLowerCase();
    
    // Common important keywords
    final keywords = {
      'passport', 'license', 'id', 'identity', 'card',
      'insurance', 'policy', 'coverage', 'claim',
      'bill', 'invoice', 'payment', 'receipt', 'due',
      'medical', 'health', 'prescription', 'doctor', 'hospital',
      'legal', 'contract', 'agreement', 'deed', 'will',
      'tax', 'return', 'form', 'official',
      'bank', 'statement', 'account', 'credit', 'debit',
      'employment', 'salary', 'payslip', 'work',
      'education', 'degree', 'diploma',
      'property', 'lease', 'rent', 'mortgage',
      'travel', 'visa', 'ticket', 'booking',
      'vehicle', 'registration', 'driving',
    };
    
    // Extract matching keywords
    for (final keyword in keywords) {
      if (lowerText.contains(keyword)) {
        tags.add(keyword.capitalize());
      }
    }
    
    // Add category-specific tags
    tags.add(category);
    
    // Extract dates as tags
    final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
    if (dateRegex.hasMatch(text)) {
      final year = DateTime.now().year;
      if (lowerText.contains(year.toString())) {
        tags.add(year.toString());
      }
    }
    
    // Extract numbers that might be important (IDs, amounts)
    final numberRegex = RegExp(r'\b\d{6,}\b');
    final numbers = numberRegex.allMatches(text);
    if (numbers.length == 1) {
      tags.add('ID: ${numbers.first.group(0)}');
    }
    
    // Limit to 8 suggestions
    return tags.take(8).toList();
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
      try {
        final backupEnabled = await widget.cloudSyncService.isBackupEnabled();
        print('📊 Backup enabled: $backupEnabled');
        
        if (backupEnabled) {
          print('🔄 Starting automatic backup...');
          final success = await widget.cloudSyncService.uploadBackup();
          if (success) {
            print('✅ Automatic backup completed successfully');
          } else {
            print('⚠️ Automatic backup failed');
          }
        } else {
          print('ℹ️ Backup disabled, skipping automatic sync');
        }
      } catch (e, stackTrace) {
        print('❌ Background sync error: $e');
        print('Stack trace: $stackTrace');
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5E81F3).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: Color(0xFF5E81F3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF5E81F3),
              ),
              items: _availableCategories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              size: 18,
                              color: const Color(0xFF5E81F3),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              cat,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
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

          // Smart Reminder Section
          _buildReminderSection(),

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

  Widget _buildReminderSection() {
    final hasRelevantDate = _expiryDate != null || _dueDate != null;
    final shouldAutoEnable = hasRelevantDate && _classification != null && _classification!.confidence > 70;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _enableReminders
            ? const Color(0xFF5E81F3).withOpacity(0.1)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _enableReminders
              ? const Color(0xFF5E81F3).withOpacity(0.3)
              : Colors.grey[800]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: _enableReminders ? const Color(0xFF5E81F3) : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Reminders',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _enableReminders,
                onChanged: hasRelevantDate
                    ? (value) => setState(() => _enableReminders = value)
                    : null,
                activeColor: const Color(0xFF5E81F3),
              ),
            ],
          ),
          
          if (!hasRelevantDate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set an expiry or due date to enable smart reminders',
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (shouldAutoEnable && _enableReminders) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-reminders enabled',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You\'ll be notified 30, 7, and 1 day(s) before the date',
                          style: TextStyle(
                            color: Colors.green.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasRelevantDate && _enableReminders) ...[
            const SizedBox(height: 12),
            Text(
              'Notification Schedule',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...[
              {'days': 30, 'label': '30 days before'},
              {'days': 7, 'label': '7 days before'},
              {'days': 1, 'label': '1 day before'},
            ].map((reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 16,
                        color: const Color(0xFF5E81F3).withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reminder['label'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
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
    // Filter suggested tags to exclude already added tags
    final availableSuggestions = _suggestedTags
        .where((tag) => !_tags.contains(tag))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_tags.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_tags.length}',
                  style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Added tags
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                  backgroundColor: const Color(0xFF5E81F3).withOpacity(0.2),
                  labelStyle: const TextStyle(color: Color(0xFF5E81F3)),
                  deleteIconColor: const Color(0xFF5E81F3),
                  deleteIcon: const Icon(Icons.close, size: 18),
                )).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Suggested tags
        if (availableSuggestions.isNotEmpty) ...[
          Text(
            'Suggested Tags',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...availableSuggestions.map((tag) => ActionChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(tag),
                      ],
                    ),
                    onPressed: () {
                      setState(() {
                        _tags.add(tag);
                      });
                    },
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green, fontSize: 12),
                    side: BorderSide(color: Colors.green.withOpacity(0.3)),
                  )),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        // Manual add button
        OutlinedButton.icon(
          onPressed: _addTag,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Custom Tag'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.7),
            side: BorderSide(color: Colors.grey[700]!),
          ),
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
