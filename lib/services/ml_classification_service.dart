import 'package:documate/models/document_category.dart';

/// Classification result with confidence score
class ClassificationResult {
  final String category;
  final double confidence;
  final List<String> suggestedTags;
  final String? documentType;

  ClassificationResult({
    required this.category,
    required this.confidence,
    this.suggestedTags = const [],
    this.documentType,
  });
}

/// ML-based document classification service using keyword matching
class MLClassificationService {
  // Keyword dictionaries for each category with weighted scoring
  static const Map<String, Map<String, double>> _categoryKeywords = {
    'Identity': {
      'passport': 3.0,
      'license': 3.0,
      'driver': 2.5,
      'identity': 3.0,
      'id card': 3.0,
      'ssn': 2.5,
      'social security': 2.5,
      'voter': 2.0,
      'pan': 2.5,
      'aadhaar': 3.0,
      'aadhar': 3.0,
      'national id': 3.0,
      'citizenship': 2.0,
      'residence permit': 2.5,
      'visa': 2.0,
      'birth certificate': 2.5,
      'govt id': 2.5,
      'government id': 2.5,
    },
    'Bills': {
      'invoice': 3.0,
      'bill': 3.0,
      'due': 2.5,
      'payment': 2.0,
      'electricity': 2.5,
      'electric': 2.5,
      'water': 2.0,
      'gas': 2.0,
      'internet': 2.5,
      'phone': 2.0,
      'mobile': 2.0,
      'utility': 2.5,
      'credit card': 2.5,
      'statement': 2.0,
      'amount due': 3.0,
      'pay by': 2.5,
      'total amount': 2.0,
      'account number': 1.5,
      'billing': 2.5,
      'charge': 1.5,
    },
    'Medical': {
      'prescription': 3.0,
      'diagnosis': 3.0,
      'hospital': 2.5,
      'patient': 2.5,
      'doctor': 2.0,
      'clinic': 2.0,
      'vaccine': 2.5,
      'vaccination': 2.5,
      'medical': 2.5,
      'health': 2.0,
      'lab report': 3.0,
      'blood test': 2.5,
      'x-ray': 2.5,
      'mri': 2.5,
      'ct scan': 2.5,
      'medicine': 2.0,
      'pharmacy': 2.0,
      'treatment': 2.0,
      'surgery': 2.5,
    },
    'Insurance': {
      'policy': 3.0,
      'premium': 3.0,
      'coverage': 2.5,
      'insured': 2.5,
      'insurance': 3.0,
      'beneficiary': 2.0,
      'claim': 2.5,
      'health insurance': 3.0,
      'life insurance': 3.0,
      'car insurance': 3.0,
      'home insurance': 3.0,
      'travel insurance': 3.0,
      'policyholder': 2.5,
      'sum assured': 2.5,
      'deductible': 2.0,
    },
    'Legal': {
      'contract': 3.0,
      'agreement': 3.0,
      'deed': 2.5,
      'court': 2.0,
      'legal': 2.5,
      'attorney': 2.0,
      'lawyer': 2.0,
      'property': 2.0,
      'lease': 2.5,
      'rental': 2.0,
      'mortgage': 2.5,
      'will': 2.0,
      'testament': 2.5,
      'power of attorney': 3.0,
      'notary': 2.0,
      'affidavit': 2.5,
      'certificate': 1.5,
    },
  };

  // Document type specific keywords
  static const Map<String, List<String>> _documentTypeKeywords = {
    'Passport': ['passport', 'p<', 'nationality', 'place of birth'],
    'Driver License': [
      'driver',
      'license',
      'class',
      'restrictions',
      'endorsements'
    ],
    'ID Card': ['identity', 'id card', 'national id', 'citizen'],
    'Electricity Bill': [
      'electricity',
      'electric',
      'kwh',
      'units consumed',
      'meter'
    ],
    'Water Bill': ['water', 'water supply', 'gallons', 'consumption'],
    'Internet Bill': ['internet', 'broadband', 'data', 'mbps', 'wifi'],
    'Phone Bill': ['mobile', 'phone', 'cellular', 'calls', 'sms'],
    'Prescription': ['prescription', 'rx', 'dosage', 'medicine', 'pharmacy'],
    'Lab Report': ['lab', 'laboratory', 'test results', 'specimen', 'blood'],
    'Insurance Policy': ['policy number', 'premium', 'coverage', 'beneficiary'],
  };

  /// Classify document based on OCR extracted text
  ClassificationResult classify(String extractedText) {
    if (extractedText.isEmpty) {
      return ClassificationResult(
        category: 'Other',
        confidence: 0.0,
        suggestedTags: [],
      );
    }

    final lowerText = extractedText.toLowerCase();
    final scores = <String, double>{};

    // Calculate scores for each category
    for (final entry in _categoryKeywords.entries) {
      final category = entry.key;
      final keywords = entry.value;
      double score = 0.0;

      for (final kwEntry in keywords.entries) {
        final keyword = kwEntry.key.toLowerCase();
        final weight = kwEntry.value;

        // Count occurrences and apply weight
        final count = _countOccurrences(lowerText, keyword);
        score += count * weight;
      }

      scores[category] = score;
    }

    // Find category with highest score
    String bestCategory = 'Other';
    double bestScore = 0.0;

    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestCategory = entry.key;
      }
    }

    // Calculate confidence (normalize to 0-100%)
    final totalScore = scores.values.fold(0.0, (sum, score) => sum + score);
    final confidence = totalScore > 0 ? (bestScore / totalScore) * 100 : 0.0;

    // Detect specific document type
    final documentType = _detectDocumentType(lowerText);

    // Generate suggested tags based on detected keywords
    final suggestedTags = _generateTags(lowerText, bestCategory);

    return ClassificationResult(
      category: bestCategory,
      confidence: confidence,
      suggestedTags: suggestedTags,
      documentType: documentType,
    );
  }

  /// Detect specific document type
  String? _detectDocumentType(String lowerText) {
    double bestScore = 0.0;
    String? bestType;

    for (final entry in _documentTypeKeywords.entries) {
      final type = entry.key;
      final keywords = entry.value;
      double score = 0.0;

      for (final keyword in keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          score += 1.0;
        }
      }

      if (score > bestScore && score >= 2) {
        // Require at least 2 matching keywords
        bestScore = score;
        bestType = type;
      }
    }

    return bestType;
  }

  /// Generate suggested tags based on content
  List<String> _generateTags(String lowerText, String category) {
    final tags = <String>[];

    // Add category-specific tags
    if (category == 'Bills') {
      if (lowerText.contains('electricity') || lowerText.contains('electric')) {
        tags.add('Electricity');
      }
      if (lowerText.contains('water')) tags.add('Water');
      if (lowerText.contains('internet') || lowerText.contains('broadband')) {
        tags.add('Internet');
      }
      if (lowerText.contains('phone') || lowerText.contains('mobile')) {
        tags.add('Phone');
      }
      if (lowerText.contains('gas')) tags.add('Gas');
    } else if (category == 'Identity') {
      if (lowerText.contains('passport')) tags.add('Passport');
      if (lowerText.contains('license') || lowerText.contains('driver')) {
        tags.add('Driver License');
      }
      if (lowerText.contains('aadhaar') || lowerText.contains('aadhar')) {
        tags.add('Aadhaar');
      }
    } else if (category == 'Medical') {
      if (lowerText.contains('prescription')) tags.add('Prescription');
      if (lowerText.contains('lab') || lowerText.contains('test')) {
        tags.add('Lab Report');
      }
      if (lowerText.contains('vaccine') || lowerText.contains('vaccination')) {
        tags.add('Vaccination');
      }
    }

    // Add urgency tags
    if (lowerText.contains('urgent') || lowerText.contains('immediate')) {
      tags.add('Urgent');
    }
    if (lowerText.contains('expir') || lowerText.contains('due')) {
      tags.add('Time Sensitive');
    }

    return tags;
  }

  /// Count occurrences of a keyword in text
  int _countOccurrences(String text, String keyword) {
    if (keyword.isEmpty) return 0;
    int count = 0;
    int index = 0;

    while ((index = text.indexOf(keyword, index)) != -1) {
      count++;
      index += keyword.length;
    }

    return count;
  }

  /// Check if document requires multi-page capture (front + back)
  bool requiresMultiPageCapture(String category, String? documentType) {
    // Identity documents typically have front and back
    if (category == 'Identity') {
      final multiPageTypes = [
        'Driver License',
        'ID Card',
        'Passport',
        'Residence Permit',
        'Visa'
      ];
      return documentType != null && multiPageTypes.contains(documentType);
    }
    return false;
  }

  /// Get expected reminder intervals based on document category
  List<int> getDefaultReminderIntervals(String category) {
    switch (category) {
      case 'Identity':
      case 'Insurance':
        return [30, 7, 1]; // 30 days, 7 days, 1 day before expiry
      case 'Bills':
        return [7, 3, 1]; // 7 days, 3 days, 1 day before due date
      case 'Medical':
        return [14, 7, 1]; // 14 days, 7 days, 1 day before
      case 'Legal':
        return [30, 14, 7]; // 30 days, 14 days, 7 days before
      default:
        return [7, 3, 1];
    }
  }
}
