import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? description;

  @HiveField(4)
  String imagePath;

  @HiveField(5)
  String? extractedText;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? issueDate;

  @HiveField(8)
  DateTime? expiryDate;

  @HiveField(9)
  DateTime? dueDate;

  @HiveField(10)
  bool hasReminder;

  @HiveField(11)
  DateTime? reminderDate;

  @HiveField(12)
  int? reminderDaysBefore;

  @HiveField(13)
  Map<String, dynamic>? metadata;

  @HiveField(14)
  List<String>? tags;

  @HiveField(15)
  bool isFavorite;

  @HiveField(16)
  List<String>? imagePaths;

  DocumentModel({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.imagePath,
    this.extractedText,
    required this.createdAt,
    this.issueDate,
    this.expiryDate,
    this.dueDate,
    this.hasReminder = false,
    this.reminderDate,
    this.reminderDaysBefore,
    this.metadata,
    this.tags,
    this.isFavorite = false,
    this.imagePaths,
  });

  // Check if document is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Check if document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  // Get days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  // Check if this document has a linked document (front/back)
  bool get hasLinkedDocument =>
      metadata != null &&
      (metadata!.containsKey('linkedFrontId') ||
          metadata!.containsKey('linkedBackId'));

  // Get linked document ID
  String? get linkedDocumentId {
    if (metadata == null) return null;
    return metadata!['linkedFrontId'] ?? metadata!['linkedBackId'];
  }

  // Check if this is front or back side
  String? get documentSide => metadata?['side'];

  // Check if document has multiple images
  bool get hasMultipleImages => imagePaths != null && imagePaths!.length > 1;

  // Get formatted expiry status
  String get expiryStatus {
    if (isExpired) return 'Expired';
    if (isExpiringSoon) {
      final days = daysUntilExpiry!;
      return 'Expires in $days day${days == 1 ? '' : 's'}';
    }
    return 'Valid';
  }

  // Copy with method for updating
  DocumentModel copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? imagePath,
    String? extractedText,
    DateTime? createdAt,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? dueDate,
    bool? hasReminder,
    DateTime? reminderDate,
    int? reminderDaysBefore,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    bool? isFavorite,
    List<String>? imagePaths,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      dueDate: dueDate ?? this.dueDate,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'createdAt': createdAt.toIso8601String(),
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'hasReminder': hasReminder,
      'reminderDate': reminderDate?.toIso8601String(),
      'reminderDaysBefore': reminderDaysBefore,
      'metadata': metadata,
      'tags': tags,
      'isFavorite': isFavorite,
      'imagePaths': imagePaths,
    };
  }

  // Create from JSON
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      imagePath: json['imagePath'],
      extractedText: json['extractedText'],
      createdAt: DateTime.parse(json['createdAt']),
      issueDate:
          json['issueDate'] != null ? DateTime.parse(json['issueDate']) : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      hasReminder: json['hasReminder'] ?? false,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'])
          : null,
      reminderDaysBefore: json['reminderDaysBefore'],
      metadata: json['metadata'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isFavorite: json['isFavorite'] ?? false,
      imagePaths: json['imagePaths'] != null
          ? List<String>.from(json['imagePaths'])
          : null,
    );
  }
}
