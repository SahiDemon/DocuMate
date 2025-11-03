import 'package:flutter/material.dart';
import 'package:documate/theme/app_theme.dart';

enum DocumentCategory {
  identity,
  insurance,
  bills,
  medical,
  legal,
  other,
}

extension DocumentCategoryExtension on DocumentCategory {
  String get displayName {
    switch (this) {
      case DocumentCategory.identity:
        return 'ID & Identity';
      case DocumentCategory.insurance:
        return 'Insurance';
      case DocumentCategory.bills:
        return 'Bills & Utilities';
      case DocumentCategory.medical:
        return 'Medical & Health';
      case DocumentCategory.legal:
        return 'Legal Documents';
      case DocumentCategory.other:
        return 'Other Documents';
    }
  }

  String get key {
    return toString().split('.').last;
  }

  Color get color {
    switch (this) {
      case DocumentCategory.identity:
        return DocuMateTheme.categoryId;
      case DocumentCategory.insurance:
        return DocuMateTheme.categoryInsurance;
      case DocumentCategory.bills:
        return DocuMateTheme.categoryBills;
      case DocumentCategory.medical:
        return DocuMateTheme.categoryMedical;
      case DocumentCategory.legal:
        return DocuMateTheme.categoryLegal;
      case DocumentCategory.other:
        return DocuMateTheme.categoryOther;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentCategory.identity:
        return Icons.badge_outlined;
      case DocumentCategory.insurance:
        return Icons.shield_outlined;
      case DocumentCategory.bills:
        return Icons.receipt_long_outlined;
      case DocumentCategory.medical:
        return Icons.medical_services_outlined;
      case DocumentCategory.legal:
        return Icons.gavel_outlined;
      case DocumentCategory.other:
        return Icons.folder_outlined;
    }
  }

  String get description {
    switch (this) {
      case DocumentCategory.identity:
        return 'Driver\'s license, passport, ID cards';
      case DocumentCategory.insurance:
        return 'Health, car, home insurance documents';
      case DocumentCategory.bills:
        return 'Utility bills, receipts, invoices';
      case DocumentCategory.medical:
        return 'Prescriptions, medical records, reports';
      case DocumentCategory.legal:
        return 'Contracts, agreements, certificates';
      case DocumentCategory.other:
        return 'Miscellaneous documents';
    }
  }
}

// Static helper to convert string to category
DocumentCategory documentCategoryFromString(String value) {
  return DocumentCategory.values.firstWhere(
    (cat) => cat.key == value.toLowerCase(),
    orElse: () => DocumentCategory.other,
  );
}

// Pre-defined document types for each category
class DocumentTypes {
  static const Map<DocumentCategory, List<String>> types = {
    DocumentCategory.identity: [
      'Driver\'s License',
      'Passport',
      'National ID Card',
      'Voter ID',
      'Social Security Card',
      'Birth Certificate',
    ],
    DocumentCategory.insurance: [
      'Health Insurance Card',
      'Car Insurance',
      'Home Insurance',
      'Life Insurance',
      'Travel Insurance',
    ],
    DocumentCategory.bills: [
      'Electricity Bill',
      'Water Bill',
      'Gas Bill',
      'Internet Bill',
      'Phone Bill',
      'Receipt',
    ],
    DocumentCategory.medical: [
      'Prescription',
      'Medical Report',
      'Vaccination Record',
      'Lab Results',
      'Doctor\'s Note',
    ],
    DocumentCategory.legal: [
      'Contract',
      'Agreement',
      'Property Papers',
      'Marriage Certificate',
      'Will',
    ],
    DocumentCategory.other: [
      'Certificate',
      'Ticket',
      'Warranty',
      'Manual',
      'Other',
    ],
  };

  static List<String> getTypesForCategory(DocumentCategory category) {
    return types[category] ?? [];
  }
}
