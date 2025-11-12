import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR Service using Google ML Kit Text Recognition
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image file
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      print('❌ OCR Error: $e');
      return '';
    }
  }

  /// Extract text with detailed block information
  Future<OCRResult> extractTextDetailed(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final blocks = <TextBlockInfo>[];

      for (final block in recognizedText.blocks) {
        blocks.add(TextBlockInfo(
          text: block.text,
          confidence: block.recognizedLanguages.isNotEmpty
              ? 0.9 // ML Kit doesn't provide confidence, use default high value
              : 0.5,
          boundingBox: block.boundingBox,
        ));
      }

      return OCRResult(
        fullText: recognizedText.text,
        blocks: blocks,
        success: recognizedText.text.isNotEmpty,
      );
    } catch (e) {
      print('❌ OCR Error: $e');
      return OCRResult(
        fullText: '',
        blocks: [],
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Extract text from multiple images (for multi-page documents)
  Future<String> extractTextFromMultipleImages(List<String> imagePaths) async {
    final texts = <String>[];

    for (final imagePath in imagePaths) {
      final text = await extractText(imagePath);
      if (text.isNotEmpty) {
        texts.add(text);
      }
    }

    return texts.join('\n\n--- Page Break ---\n\n');
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// OCR Result with detailed information
class OCRResult {
  final String fullText;
  final List<TextBlockInfo> blocks;
  final bool success;
  final String? error;

  OCRResult({
    required this.fullText,
    required this.blocks,
    required this.success,
    this.error,
  });

  /// Get text with confidence above threshold
  String getTextWithMinConfidence(double minConfidence) {
    return blocks
        .where((block) => block.confidence >= minConfidence)
        .map((block) => block.text)
        .join('\n');
  }
}

/// Text block information
class TextBlockInfo {
  final String text;
  final double confidence;
  final Rect boundingBox;

  TextBlockInfo({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}
