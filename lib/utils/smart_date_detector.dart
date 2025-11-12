import 'package:flutter/material.dart';

/// Smart date detector for document OCR text
/// Detects and categorizes dates, then asks user for confirmation
class SmartDateDetector {
  /// Detect all dates in the text
  static List<DetectedDate> detectDates(String text) {
    final dates = <DetectedDate>[];
    final now = DateTime.now();

    // Common date patterns
    final patterns = [
      // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
      RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})'),
      // Month DD, YYYY or DD Month YYYY
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        try {
          DateTime? date;
          
          if (pattern.pattern.contains('Jan|Feb|Mar')) {
            // Month name format
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!.toLowerCase();
            final year = int.parse(match.group(3)!);
            final month = _monthToNumber(monthStr);
            if (month != null) {
              date = DateTime(year, month, day);
            }
          } else if (match.group(1)!.length == 4) {
            // YYYY-MM-DD format
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            date = DateTime(year, month, day);
          } else {
            // DD/MM/YYYY format
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            date = DateTime(year, month, day);
          }

          if (date != null && _isValidDate(date)) {
            final isPast = date.isBefore(now);
            final isFuture = date.isAfter(now);
            final isVeryOld = now.difference(date).inDays > 365 * 2;
            final isVeryFar = date.difference(now).inDays > 365 * 10;

            // Suggest date type based on context
            DateType suggestedType = DateType.custom;
            if (isPast && !isVeryOld) {
              suggestedType = DateType.issueDate;
            } else if (isFuture && !isVeryFar) {
              suggestedType = DateType.expiryDate;
            }

            dates.add(DetectedDate(
              date: date,
              rawText: match.group(0)!,
              suggestedType: suggestedType,
              isPast: isPast,
              isFuture: isFuture,
            ));
          }
        } catch (e) {
          // Invalid date, skip
          continue;
        }
      }
    }

    // Remove duplicates (dates detected by multiple patterns)
    final uniqueDates = <DateTime, DetectedDate>{};
    for (final detectedDate in dates) {
      uniqueDates[detectedDate.date] = detectedDate;
    }

    return uniqueDates.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static int? _monthToNumber(String month) {
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
      'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
      'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    return months[month];
  }

  static bool _isValidDate(DateTime date) {
    // Date should be reasonable (not too far in past or future)
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year + 50);
    return date.isAfter(minDate) && date.isBefore(maxDate);
  }

  /// Show dialog to ask user about detected dates
  static Future<DateSelectionResult?> showDateSelectionDialog({
    required BuildContext context,
    required List<DetectedDate> detectedDates,
  }) async {
    if (detectedDates.isEmpty) return null;

    return showDialog<DateSelectionResult>(
      context: context,
      builder: (context) => _DateSelectionDialog(detectedDates: detectedDates),
    );
  }
}

/// Detected date information
class DetectedDate {
  final DateTime date;
  final String rawText;
  final DateType suggestedType;
  final bool isPast;
  final bool isFuture;

  DetectedDate({
    required this.date,
    required this.rawText,
    required this.suggestedType,
    required this.isPast,
    required this.isFuture,
  });
}

/// Type of date
enum DateType {
  issueDate,
  expiryDate,
  dueDate,
  birthday,
  custom,
}

/// Result of date selection
class DateSelectionResult {
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? dueDate;
  final Map<String, DateTime> customDates;

  DateSelectionResult({
    this.issueDate,
    this.expiryDate,
    this.dueDate,
    this.customDates = const {},
  });
}

/// Dialog for selecting dates
class _DateSelectionDialog extends StatefulWidget {
  final List<DetectedDate> detectedDates;

  const _DateSelectionDialog({required this.detectedDates});

  @override
  State<_DateSelectionDialog> createState() => _DateSelectionDialogState();
}

class _DateSelectionDialogState extends State<_DateSelectionDialog> {
  final Map<int, DateType> _selections = {};
  final Map<int, String> _customLabels = {};

  @override
  void initState() {
    super.initState();
    // Pre-select suggested types
    for (int i = 0; i < widget.detectedDates.length; i++) {
      _selections[i] = widget.detectedDates[i].suggestedType;
    }
  }

  void _confirm() {
    DateTime? issueDate;
    DateTime? expiryDate;
    DateTime? dueDate;
    final customDates = <String, DateTime>{};

    for (int i = 0; i < widget.detectedDates.length; i++) {
      final date = widget.detectedDates[i].date;
      final type = _selections[i];

      switch (type) {
        case DateType.issueDate:
          issueDate = date;
          break;
        case DateType.expiryDate:
          expiryDate = date;
          break;
        case DateType.dueDate:
          dueDate = date;
          break;
        case DateType.birthday:
          customDates['Birthday'] = date;
          break;
        case DateType.custom:
          final label = _customLabels[i] ?? 'Custom Date ${i + 1}';
          customDates[label] = date;
          break;
        default:
          break;
      }
    }

    Navigator.of(context).pop(DateSelectionResult(
      issueDate: issueDate,
      expiryDate: expiryDate,
      dueDate: dueDate,
      customDates: customDates,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5E81F3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF5E81F3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detected Dates',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We found ${widget.detectedDates.length} date(s) in your document. Please confirm what each date represents:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ...widget.detectedDates.asMap().entries.map((entry) {
              final index = entry.key;
              final detectedDate = entry.value;
              return _buildDateItem(index, detectedDate);
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Skip',
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5E81F3),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _buildDateItem(int index, DetectedDate detectedDate) {
    final dateStr = '${detectedDate.date.day}/${detectedDate.date.month}/${detectedDate.date.year}';
    final selectedType = _selections[index] ?? DateType.custom;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5E81F3).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: detectedDate.isPast
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    color: detectedDate.isPast ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  detectedDate.isPast ? 'Past Date' : 'Future Date',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: detectedDate.isPast
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DateType>(
            value: selectedType,
            dropdownColor: const Color(0xFF2A2A2A),
            decoration: InputDecoration(
              labelText: 'Date Type',
              labelStyle: const TextStyle(color: Color(0xFF5E81F3), fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: const [
              DropdownMenuItem(
                value: DateType.issueDate,
                child: Text('Issue Date'),
              ),
              DropdownMenuItem(
                value: DateType.expiryDate,
                child: Text('Expiry Date'),
              ),
              DropdownMenuItem(
                value: DateType.dueDate,
                child: Text('Due Date'),
              ),
              DropdownMenuItem(
                value: DateType.birthday,
                child: Text('Birthday'),
              ),
              DropdownMenuItem(
                value: DateType.custom,
                child: Text('Custom Date'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selections[index] = value;
                });
              }
            },
          ),
          if (selectedType == DateType.custom) ...[
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter custom label (e.g., "Registration Date")',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              onChanged: (value) {
                _customLabels[index] = value;
              },
            ),
          ],
        ],
      ),
    );
  }
}

