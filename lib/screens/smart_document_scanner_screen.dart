import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

/// Smart Document Scanner using Google ML Kit
/// Features:
/// - Automatic document edge detection
/// - Auto-capture when document is detected
/// - Professional cropping and enhancement
/// - Support for both front and back sides
class SmartDocumentScannerScreen extends StatefulWidget {
  final bool isFront;
  final List<CameraDescription>? cameras;

  const SmartDocumentScannerScreen({
    super.key,
    required this.isFront,
    this.cameras,
  });

  @override
  State<SmartDocumentScannerScreen> createState() =>
      _SmartDocumentScannerScreenState();
}

class _SmartDocumentScannerScreenState
    extends State<SmartDocumentScannerScreen> {
  DocumentScanner? _documentScanner;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // Initialize ML Kit Document Scanner
    // This provides native document scanning UI with automatic edge detection
    _documentScanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full, // Full mode with automatic edge detection
        pageLimit: 1, // Single page at a time
        isGalleryImport: true, // Allow import from gallery
      ),
    );
  }

  Future<void> _scanDocument() async {
    if (_documentScanner == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Start scanning with ML Kit
      final result = await _documentScanner!.scanDocument();

      // User cancelled or no result
      if (result.images.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      // Process the scanned document
      if (result.images.isNotEmpty) {
        final scannedImage = result.images.first;
        
        // Save to permanent location
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String side = widget.isFront ? 'front' : 'back';
        final String permanentPath =
            '${appDir.path}/documents/${side}_$timestamp.jpg';

        final Directory docDir = Directory('${appDir.path}/documents');
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        // Copy the scanned image to permanent location
        final File permanentFile = await File(scannedImage).copy(permanentPath);

        setState(() => _isProcessing = false);

        // Show success and return
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.isFront ? "Front" : "Back"} side scanned successfully',
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Return the scanned image path
          Navigator.of(context).pop(permanentFile.path);
        }
      }
    } catch (e) {
      print('Error scanning document: $e');
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanning error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background with instruction
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E81F3).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF5E81F3).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.document_scanner,
                        size: 80,
                        color: Color(0xFF5E81F3),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.isFront
                          ? 'Scan Front Side'
                          : 'Scan Back Side',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The scanner will automatically detect document edges\nand capture when ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Scan button
                    if (!_isProcessing)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5E81F3), Color(0xFF3E63DD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E81F3).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _scanDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt, size: 28),
                          label: const Text(
                            'Start Scanning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Loading indicator
                    if (_isProcessing)
                      Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5E81F3),
                            ),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Processing document...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // Info card at bottom
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5E81F3).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFFBBF24),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Place document on a flat surface with good lighting for best results',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

