/// Parsed document data with structured fields
class ParsedDocumentData {
  final DateTime? expiryDate;
  final DateTime? dueDate;
  final DateTime? issueDate;
  final String? documentNumber;
  final String? amount;
  final String? name;
  final Map<String, dynamic> additionalFields;
  final double confidence;

  ParsedDocumentData({
    this.expiryDate,
    this.dueDate,
    this.issueDate,
    this.documentNumber,
    this.amount,
    this.name,
    this.additionalFields = const {},
    this.confidence = 0.0,
  });

  bool get hasExpiryDate => expiryDate != null;
  bool get hasDueDate => dueDate != null;
  bool get hasAmount => amount != null;
}

/// Document parser for extracting structured data from OCR text
class DocumentParser {
  /// Parse OCR text based on document category
  static ParsedDocumentData parse(String ocrText, String category) {
    switch (category) {
      case 'Identity':
        return _parseIdentityDocument(ocrText);
      case 'Bills':
        return _parseBill(ocrText);
      case 'Medical':
        return _parseMedicalDocument(ocrText);
      case 'Insurance':
        return _parseInsuranceDocument(ocrText);
      case 'Legal':
        return _parseLegalDocument(ocrText);
      default:
        return _parseGenericDocument(ocrText);
    }
  }

  /// Parse identity documents (passport, license, ID)
  static ParsedDocumentData _parseIdentityDocument(String text) {
    DateTime? expiryDate;
    DateTime? issueDate;
    String? documentNumber;
    String? name;
    double confidence = 0.0;

    // Extract expiry date
    expiryDate = _extractExpiryDate(text);
    if (expiryDate != null) confidence += 0.3;

    // Extract issue date
    issueDate = _extractIssueDate(text);
    if (issueDate != null) confidence += 0.2;

    // Extract document number (various formats)
    documentNumber = _extractDocumentNumber(text);
    if (documentNumber != null) confidence += 0.3;

    // Extract name
    name = _extractName(text);
    if (name != null) confidence += 0.2;

    return ParsedDocumentData(
      expiryDate: expiryDate,
      issueDate: issueDate,
      documentNumber: documentNumber,
      name: name,
      confidence: confidence,
    );
  }

  /// Parse bill documents
  static ParsedDocumentData _parseBill(String text) {
    DateTime? dueDate;
    DateTime? issueDate;
    String? amount;
    String? documentNumber;
    double confidence = 0.0;

    // Extract due date
    dueDate = _extractDueDate(text);
    if (dueDate != null) confidence += 0.4;

    // Extract issue date
    issueDate = _extractIssueDate(text);
    if (issueDate != null) confidence += 0.2;

    // Extract amount
    amount = _extractAmount(text);
    if (amount != null) confidence += 0.3;

    // Extract account/bill number
    documentNumber = _extractAccountNumber(text);
    if (documentNumber != null) confidence += 0.1;

    return ParsedDocumentData(
      dueDate: dueDate,
      issueDate: issueDate,
      amount: amount,
      documentNumber: documentNumber,
      confidence: confidence,
    );
  }

  /// Parse medical documents
  static ParsedDocumentData _parseMedicalDocument(String text) {
    DateTime? issueDate;
    String? name;
    double confidence = 0.0;

    issueDate = _extractIssueDate(text);
    if (issueDate != null) confidence += 0.3;

    name = _extractName(text);
    if (name != null) confidence += 0.2;

    return ParsedDocumentData(
      issueDate: issueDate,
      name: name,
      confidence: confidence,
    );
  }

  /// Parse insurance documents
  static ParsedDocumentData _parseInsuranceDocument(String text) {
    DateTime? expiryDate;
    DateTime? issueDate;
    String? documentNumber;
    String? amount;
    double confidence = 0.0;

    expiryDate = _extractExpiryDate(text);
    if (expiryDate != null) confidence += 0.3;

    issueDate = _extractIssueDate(text);
    if (issueDate != null) confidence += 0.2;

    documentNumber = _extractPolicyNumber(text);
    if (documentNumber != null) confidence += 0.3;

    amount = _extractAmount(text);
    if (amount != null) confidence += 0.2;

    return ParsedDocumentData(
      expiryDate: expiryDate,
      issueDate: issueDate,
      documentNumber: documentNumber,
      amount: amount,
      confidence: confidence,
    );
  }

  /// Parse legal documents
  static ParsedDocumentData _parseLegalDocument(String text) {
    DateTime? issueDate;
    DateTime? expiryDate;
    double confidence = 0.0;

    issueDate = _extractIssueDate(text);
    if (issueDate != null) confidence += 0.3;

    expiryDate = _extractExpiryDate(text);
    if (expiryDate != null) confidence += 0.2;

    return ParsedDocumentData(
      issueDate: issueDate,
      expiryDate: expiryDate,
      confidence: confidence,
    );
  }

  /// Parse generic documents
  static ParsedDocumentData _parseGenericDocument(String text) {
    return ParsedDocumentData(
      issueDate: _extractIssueDate(text),
      confidence: 0.1,
    );
  }

  // ========== Date Extraction Methods ==========

  /// Extract expiry date from text
  static DateTime? _extractExpiryDate(String text) {
    final patterns = [
      RegExp(r'expir[ey].*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'valid\s+until.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'exp\.?\s*date.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'expires.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
    ];

    return _extractDateFromPatterns(text, patterns);
  }

  /// Extract due date from text
  static DateTime? _extractDueDate(String text) {
    final patterns = [
      RegExp(r'due\s+date.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'pay\s+by.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'payment\s+date.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'due.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
    ];

    return _extractDateFromPatterns(text, patterns);
  }

  /// Extract issue date from text
  static DateTime? _extractIssueDate(String text) {
    final patterns = [
      RegExp(r'issue\s+date.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'issued.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(r'date.*?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
    ];

    return _extractDateFromPatterns(text, patterns);
  }

  /// Extract date from regex patterns
  static DateTime? _extractDateFromPatterns(
      String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final dateStr = match.group(1);
        if (dateStr != null) {
          final date = _parseDate(dateStr);
          if (date != null) return date;
        }
      }
    }
    return null;
  }

  /// Parse date string to DateTime
  static DateTime? _parseDate(String dateStr) {
    // Try different date formats
    final formats = [
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2})'), // DD/MM/YY
      RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})'), // YYYY/MM/DD
    ];

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null && match.groupCount >= 3) {
        try {
          int day, month, year;

          if (match.group(1)!.length == 4) {
            // YYYY/MM/DD
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // DD/MM/YYYY or DD/MM/YY
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);

            // Handle 2-digit years
            if (year < 100) {
              year += year < 50 ? 2000 : 1900;
            }
          }

          return DateTime(year, month, day);
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  // ========== Field Extraction Methods ==========

  /// Extract document number (ID, passport, etc.)
  static String? _extractDocumentNumber(String text) {
    final patterns = [
      RegExp(
          r'(?:id|passport|license)\s*(?:no|number|#)?[\s:]*([A-Z0-9]{6,20})',
          caseSensitive: false),
      RegExp(r'(?:document|doc)\s*(?:no|number|#)?[\s:]*([A-Z0-9]{6,20})',
          caseSensitive: false),
      RegExp(r'\b([A-Z]{1,2}\d{6,15})\b'), // Format: AB1234567
    ];

    return _extractFromPatterns(text, patterns);
  }

  /// Extract account number from bill
  static String? _extractAccountNumber(String text) {
    final patterns = [
      RegExp(r'account\s*(?:no|number|#)?[\s:]*(\d{6,20})',
          caseSensitive: false),
      RegExp(r'bill\s*(?:no|number|#)?[\s:]*(\d{6,20})', caseSensitive: false),
      RegExp(r'customer\s*(?:no|number|id|#)?[\s:]*(\d{6,20})',
          caseSensitive: false),
    ];

    return _extractFromPatterns(text, patterns);
  }

  /// Extract policy number from insurance
  static String? _extractPolicyNumber(String text) {
    final patterns = [
      RegExp(r'policy\s*(?:no|number|#)?[\s:]*([A-Z0-9]{6,20})',
          caseSensitive: false),
    ];

    return _extractFromPatterns(text, patterns);
  }

  /// Extract amount from bill
  static String? _extractAmount(String text) {
    final patterns = [
      RegExp(r'total\s+amount.*?([₹\$€£]\s*[\d,]+\.?\d*)',
          caseSensitive: false),
      RegExp(r'amount\s+due.*?([₹\$€£]\s*[\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'total.*?([₹\$€£]\s*[\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'([₹\$€£]\s*[\d,]+\.?\d*)'), // Any currency amount
    ];

    return _extractFromPatterns(text, patterns);
  }

  /// Extract name from document
  static String? _extractName(String text) {
    final patterns = [
      RegExp(r'name[\s:]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
          caseSensitive: false),
      RegExp(r'patient[\s:]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
          caseSensitive: false),
    ];

    return _extractFromPatterns(text, patterns);
  }

  /// Extract string from regex patterns
  static String? _extractFromPatterns(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final value = match.group(1);
        if (value != null && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }
}
