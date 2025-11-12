import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:documate/main.dart' show cameras;
import 'package:documate/theme/app_theme.dart';

class ImprovedCaptureScreen extends StatefulWidget {
  final bool isFront;

  const ImprovedCaptureScreen({
    super.key,
    this.isFront = true,
  });

  @override
  State<ImprovedCaptureScreen> createState() => _ImprovedCaptureScreenState();
}

class _ImprovedCaptureScreenState extends State<ImprovedCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _capturedImagePath;
  bool _showCropScreen = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Crop points (normalized 0-1)
  Offset _topLeft = const Offset(0.1, 0.2);
  Offset _topRight = const Offset(0.9, 0.2);
  Offset _bottomLeft = const Offset(0.1, 0.8);
  Offset _bottomRight = const Offset(0.9, 0.8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras == null || cameras!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera available')),
      );
      return;
    }

    _controller = CameraController(
      cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile image = await _controller!.takePicture();
      
      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String side = widget.isFront ? 'front' : 'back';
      final String permanentPath = '${appDir.path}/documents/${side}_$timestamp.jpg';
      
      final Directory docDir = Directory('${appDir.path}/documents');
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }

      final File permanentFile = await File(image.path).copy(permanentPath);

      setState(() {
        _capturedImagePath = permanentFile.path;
        _isCapturing = false;
      });
    } catch (e) {
      print('Error capturing image: $e');
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        // Save to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String side = widget.isFront ? 'front' : 'back';
        final String permanentPath = '${appDir.path}/documents/${side}_$timestamp.jpg';
        
        final Directory docDir = Directory('${appDir.path}/documents');
        if (!await docDir.exists()) {
          await docDir.create(recursive: true);
        }

        final File permanentFile = await File(image.path).copy(permanentPath);

        setState(() => _capturedImagePath = permanentFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  void _retakeImage() {
    setState(() => _capturedImagePath = null);
  }

  void _confirmImage() {
    if (_capturedImagePath != null) {
      Navigator.of(context).pop(_capturedImagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImagePath != null) {
      return _buildPreviewScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF5E81F3)),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.isFront ? 'Front Side' : 'Back Side',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the layout
                ],
              ),
            ),
          ),

          // Capture guide overlay
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),

          // Instruction text
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Position document within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery button
                    _buildControlButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: _pickFromGallery,
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureImage,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.grey
                                : const Color(0xFF5E81F3),
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                    ),

                    // Placeholder for symmetry
                    const SizedBox(width: 64),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen() {
    if (_showCropScreen) {
      return _buildCropScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image preview
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(_capturedImagePath!),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _retakeImage,
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Retake',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Preview',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80), // Balance
                ],
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Crop button
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF5E81F3).withOpacity(0.3),
                                  const Color(0xFF5E81F3).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF5E81F3),
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _showCropScreen = true),
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5E81F3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.crop_rotate,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Crop & Adjust',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Retake button
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _retakeImage,
                              borderRadius: BorderRadius.circular(16),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Confirm button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5E81F3),
                            Color(0xFF4A6FE8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E81F3).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _confirmImage,
                          borderRadius: BorderRadius.circular(16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 28, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Use This Photo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with crop overlay
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  child: Stack(
                    children: [
                      Image.file(
                        File(_capturedImagePath!),
                        fit: BoxFit.contain,
                      ),
                      CustomPaint(
                        painter: CropOverlayPainter(
                          topLeft: _topLeft,
                          topRight: _topRight,
                          bottomLeft: _bottomLeft,
                          bottomRight: _bottomRight,
                        ),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      // Corner handles
                      ..._buildCropHandles(constraints),
                    ],
                  ),
                );
              },
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _showCropScreen = false),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E81F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF5E81F3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.crop, color: Color(0xFF5E81F3), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Adjust Crop',
                          style: TextStyle(
                            color: Color(0xFF5E81F3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
          ),

          // Bottom apply button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _applyCrop,
                  icon: const Icon(Icons.done),
                  label: const Text('Apply Crop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E81F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCropHandles(BoxConstraints constraints) {
    final handles = [
      {'pos': _topLeft, 'onPan': (Offset delta) => setState(() => _topLeft += delta)},
      {'pos': _topRight, 'onPan': (Offset delta) => setState(() => _topRight += delta)},
      {'pos': _bottomLeft, 'onPan': (Offset delta) => setState(() => _bottomLeft += delta)},
      {'pos': _bottomRight, 'onPan': (Offset delta) => setState(() => _bottomRight += delta)},
    ];

    return handles.map((handle) {
      final pos = handle['pos'] as Offset;
      final onPan = handle['onPan'] as Function(Offset);
      
      return Positioned(
        left: pos.dx * constraints.maxWidth - 15,
        top: pos.dy * constraints.maxHeight - 15,
        child: GestureDetector(
          onPanUpdate: (details) {
            onPan(Offset(
              details.delta.dx / constraints.maxWidth,
              details.delta.dy / constraints.maxHeight,
            ));
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF5E81F3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> _applyCrop() async {
    try {
      final File imageFile = File(_capturedImagePath!);
      final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Convert normalized coordinates to pixel coordinates
      final double imgWidth = originalImage.width.toDouble();
      final double imgHeight = originalImage.height.toDouble();

      final pts = [
        img.Point((_topLeft.dx * imgWidth).round(), (_topLeft.dy * imgHeight).round()),
        img.Point((_topRight.dx * imgWidth).round(), (_topRight.dy * imgHeight).round()),
        img.Point((_bottomRight.dx * imgWidth).round(), (_bottomRight.dy * imgHeight).round()),
        img.Point((_bottomLeft.dx * imgWidth).round(), (_bottomLeft.dy * imgHeight).round()),
      ];

      // Find bounding box
      int minX = pts.map((p) => p.xi).reduce((a, b) => a < b ? a : b).clamp(0, originalImage.width);
      int maxX = pts.map((p) => p.xi).reduce((a, b) => a > b ? a : b).clamp(0, originalImage.width);
      int minY = pts.map((p) => p.yi).reduce((a, b) => a < b ? a : b).clamp(0, originalImage.height);
      int maxY = pts.map((p) => p.yi).reduce((a, b) => a > b ? a : b).clamp(0, originalImage.height);

      // Ensure valid dimensions
      final cropWidth = (maxX - minX).clamp(10, originalImage.width);
      final cropHeight = (maxY - minY).clamp(10, originalImage.height);

      // Crop image
      final croppedImage = img.copyCrop(
        originalImage,
        x: minX,
        y: minY,
        width: cropWidth,
        height: cropHeight,
      );

      // Enhance image quality for better OCR
      final enhancedImage = img.adjustColor(
        croppedImage,
        contrast: 1.2,
        saturation: 0.8,
      );

      // Save cropped image with high quality
      final croppedBytes = img.encodeJpg(enhancedImage, quality: 95);
      await imageFile.writeAsBytes(croppedBytes);

      print('✓ Image cropped and saved: ${imageFile.path}');
      print('  Original: ${originalImage.width}x${originalImage.height}');
      print('  Cropped: ${cropWidth}x${cropHeight}');

      setState(() => _showCropScreen = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Crop applied successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error applying crop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  CropOverlayPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert normalized coordinates to pixels
    final tl = Offset(topLeft.dx * size.width, topLeft.dy * size.height);
    final tr = Offset(topRight.dx * size.width, topRight.dy * size.height);
    final bl = Offset(bottomLeft.dx * size.width, bottomLeft.dy * size.height);
    final br = Offset(bottomRight.dx * size.width, bottomRight.dy * size.height);

    // Draw semi-transparent overlay outside crop area
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final cropPath = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cropPath),
      overlayPaint,
    );

    // Draw crop border
    final borderPaint = Paint()
      ..color = const Color(0xFF5E81F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(cropPath, borderPaint);

    // Draw corner lines
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(tl, Offset(tl.dx + cornerLength, tl.dy), cornerPaint);
    canvas.drawLine(tl, Offset(tl.dx, tl.dy + cornerLength), cornerPaint);

    // Top-right corner
    canvas.drawLine(tr, Offset(tr.dx - cornerLength, tr.dy), cornerPaint);
    canvas.drawLine(tr, Offset(tr.dx, tr.dy + cornerLength), cornerPaint);

    // Bottom-left corner
    canvas.drawLine(bl, Offset(bl.dx + cornerLength, bl.dy), cornerPaint);
    canvas.drawLine(bl, Offset(bl.dx, bl.dy - cornerLength), cornerPaint);

    // Bottom-right corner
    canvas.drawLine(br, Offset(br.dx - cornerLength, br.dy), cornerPaint);
    canvas.drawLine(br, Offset(br.dx, br.dy - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CropOverlayPainter oldDelegate) => true;
}

