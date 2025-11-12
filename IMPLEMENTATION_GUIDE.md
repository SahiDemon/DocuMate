# DocuMate Smart Document Scanner - Implementation Guide

## ✅ COMPLETED IMPLEMENTATIONS

### 1. **Packages Added** (`pubspec.yaml`)
- ✅ `edge_detection: ^1.1.0` - OpenCV-based document edge detection
- ✅ Regenerated Hive adapter for updated DocumentModel

### 2. **Core Services Created**

#### `lib/services/ml_classification_service.dart` ✅
- Keyword-based document classification with confidence scoring
- Categories: Identity, Bills, Medical, Insurance, Legal
- Document type detection (Passport, Driver License, Bills, etc.)
- Auto-tag generation based on content
- Multi-page capture detection
- Default reminder interval suggestions per category

#### `lib/services/ocr_service.dart` ✅
- Google ML Kit Text Recognition integration
- Single and multi-page OCR extraction
- Detailed block-level text extraction with bounding boxes
- Error handling for failed OCR

#### `lib/utils/document_parser.dart` ✅
- Structured field extraction from OCR text using regex
- Extracts: expiry dates, due dates, issue dates, amounts, document numbers, names
- Category-specific parsing (Identity, Bills, Medical, Insurance, Legal)
- Confidence scoring for extracted data

#### `lib/services/notification_service.dart` ✅
- Flutter Local Notifications integration
- Individual notification scheduling (not background worker)
- Smart scheduling based on document type (expiry vs due date)
- Multiple reminder intervals (e.g., 30d, 7d, 1d before)
- Configurable notification time (default 9 AM)
- Notification cancellation for updated/deleted documents
- Permission handling for Android 13+

#### `lib/services/search_index_service.dart` ✅
- Fast indexed search using word tokenization
- Searches across: name, description, extracted text, tags, category
- AND/OR search logic
- Stop word filtering
- Incremental index updates
- Persistent storage in Hive

### 3. **Updated Data Model**

#### `lib/models/document_model.dart` ✅
- Added `dueDate` field (HiveField 9) for bill payments
- Added `imagePaths` field (HiveField 16) for multiple images
- Added helper methods:
  - `hasLinkedDocument` - Check if front/back linked
  - `linkedDocumentId` - Get linked document ID
  - `documentSide` - Get front/back indicator
  - `hasMultipleImages` - Check for multi-image docs
- Updated `copyWith`, `toJson`, `fromJson` methods
- Hive adapter regenerated

### 4. **UI Screens Created**

#### `lib/screens/notification_settings_screen.dart` ✅
- Enable/disable notifications toggle
- Sound and vibration settings
- Notification time picker (when to receive reminders)
- Category-specific reminder intervals (Identity: 30,7,1 days, Bills: 7,3,1 days, etc.)
- Persistent settings via StorageService

#### `lib/screens/document_details_screen.dart` ✅
- Image carousel with PageView (front/back images)
- Zoomable images with InteractiveViewer
- Page indicators for multi-image docs
- Side labels (Front/Back)
- Document info display: category, dates, tags
- Expandable extracted text section
- Reminder toggle
- Edit and delete functionality (stubs)
- Linked document support (loads front+back)

---

## 🚧 PENDING IMPLEMENTATIONS

### 1. **Smart Capture Flow Screen** ⏳
**File to create**: `lib/screens/smart_capture_flow_screen.dart`

**Requirements**:
1. Integrate `edge_detection` package
2. Real-time document corner detection
3. Auto-capture when stable boundaries detected
4. Perspective correction and image enhancement
5. OCR extraction after capture
6. ML classification to determine document type
7. If Identity doc detected → prompt for back side capture
8. Field extraction and validation
9. Show preview with editable fields
10. Auto-suggest category, tags, reminder settings
11. Save to Hive with `storageService.saveDocument()`
12. Schedule notifications if expiry/due date present
13. Update search index
14. Handle linked documents (front/back pairs)

**Dependencies**:
- OCRService
- MLClassificationService
- DocumentParser
- NotificationService
- SearchIndexService
- StorageService

### 2. **Update Home Screen with Real Data** ⏳
**File to update**: `lib/screens/new_home_screen.dart`

**Changes needed**:
```dart
// Remove mock data
// final _recentDocuments = [];
// final _documentCounts = {'Identity': 0, 'Bills': 0, ...};

// Replace with:
Future<void> _loadDocuments() async {
  final docs = await storageService.getAllDocuments();
  final documentList = docs.values.map((d) => DocumentModel.fromJson(d)).toList();
  
  setState(() {
    _recentDocuments = documentList
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
      ..take(5).toList();
    
    _documentCounts = {
      'Identity': documentList.where((d) => d.category == 'Identity').length,
      'Bills': documentList.where((d) => d.category == 'Bills').length,
      // ... etc
    };
  });
}
```

### 3. **Update Search Screen with Indexed Search** ⏳
**File to update**: `lib/screens/new_home_screen.dart` (SearchScreen widget)

**Changes needed**:
```dart
final searchIndexService = SearchIndexService();

Future<void> _performSearch(String query) async {
  final docIds = await searchIndexService.search(query);
  
  final results = <DocumentModel>[];
  for (final id in docIds) {
    final data = await storageService.getDocument(id);
    if (data != null) {
      results.add(DocumentModel.fromJson(data));
    }
  }
  
  setState(() => _searchResults = results);
}
```

### 4. **Add Notification Permission Request** ⏳
**File to update**: `lib/screens/splash_screen.dart` or `lib/screens/onboarding_screen.dart`

**On first launch** (after onboarding):
```dart
final notificationService = NotificationService();
await notificationService.initialize();

// Request permission
final granted = await notificationService.requestPermission();
if (!granted) {
  // Show explanation dialog
}
```

### 5. **Add Settings Navigation** ⏳
**Files to update**:
- `lib/screens/new_home_screen.dart` (ProfileScreen)
- `lib/main.dart` (add route)

**Add to ProfileScreen**:
```dart
ListTile(
  leading: Icon(Icons.notifications),
  title: Text('Notification Settings'),
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => NotificationSettingsScreen(
      storageService: storageService,
    ),
  )),
),
```

**Add to main.dart routes**:
```dart
'/notification-settings': (context) => NotificationSettingsScreen(
  storageService: storageService,
),
'/document-details': (context) => DocumentDetailsScreen(...),
```

### 6. **Update AddDocumentScreen with Edge Detection** ⏳
**File to update**: `lib/screens/add_document_screen.dart`

**Replace camera logic with**:
```dart
import 'package:edge_detection/edge_detection.dart';

Future<void> _captureDocument() async {
  try {
    String? imagePath = await EdgeDetection.detectEdge;
    
    if (imagePath != null) {
      // imagePath is already cropped and perspective-corrected
      await _processDocument(imagePath);
    }
  } catch (e) {
    print('Edge detection error: $e');
  }
}

Future<void> _processDocument(String imagePath) async {
  // 1. OCR extraction
  final ocrService = OCRService();
  final ocrText = await ocrService.extractText(imagePath);
  
  // 2. Classify document
  final mlService = MLClassificationService();
  final classification = mlService.classify(ocrText);
  
  // 3. Parse fields
  final parsed = DocumentParser.parse(ocrText, classification.category);
  
  // 4. Navigate to smart capture flow for confirmation
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => SmartCaptureFlowScreen(
      imagePath: imagePath,
      ocrText: ocrText,
      classification: classification,
      parsedData: parsed,
    ),
  ));
}
```

### 7. **Initialize Search Index on App Startup** ⏳
**File to update**: `lib/main.dart`

**In `main()` function**:
```dart
// After initializing storage service
final searchIndexService = SearchIndexService();
await searchIndexService.initialize();

// Rebuild index if empty (first launch)
final stats = searchIndexService.getStats();
if (stats['totalWords'] == 0) {
  await searchIndexService.rebuildIndex();
}
```

---

## 📋 INTEGRATION CHECKLIST

### High Priority
- [ ] Create `SmartCaptureFlowScreen` with edge detection
- [ ] Update `AddDocumentScreen` to use edge detection
- [ ] Update `HomeScreen` to load real documents from Hive
- [ ] Update `SearchScreen` with indexed search
- [ ] Add notification permission request on first launch
- [ ] Add settings navigation to ProfileScreen
- [ ] Add routes in main.dart
- [ ] Initialize SearchIndexService on startup

### Medium Priority
- [ ] Implement edit document functionality in DocumentDetailsScreen
- [ ] Implement reminder toggle functionality
- [ ] Create interval editor dialog in NotificationSettingsScreen
- [ ] Add document export functionality (PDF generation)
- [ ] Add sharing functionality

### Low Priority
- [ ] Add statistics dashboard in HomeScreen
- [ ] Implement batch document upload
- [ ] Add document versioning
- [ ] Implement OCR language selection
- [ ] Add custom reminder intervals UI

---

## 🎯 WORKFLOW: How It All Works Together

### Document Capture Flow:
1. User opens **AddDocumentScreen** → taps capture
2. **Edge Detection** activates → auto-detects document corners → crops & enhances
3. **OCR Service** extracts text from image
4. **ML Classification Service** analyzes text → determines category + document type
5. If **Identity doc** detected → **SmartCaptureFlowScreen** prompts for back side
6. **Document Parser** extracts structured fields (expiry, due date, amounts, etc.)
7. **SmartCaptureFlowScreen** shows preview with editable fields
8. User confirms/edits → document saved to **StorageService** (encrypted)
9. **Notification Service** schedules reminders based on expiry/due date
10. **SearchIndexService** adds document to search index
11. **CloudSyncService** uploads backup (if enabled)
12. Navigate to **DocumentDetailsScreen** or back to home

### Search Flow:
1. User types query in **SearchScreen**
2. **SearchIndexService** tokenizes query → looks up in index
3. Returns matching document IDs
4. Load documents from **StorageService** (decrypted)
5. Display results with highlighted snippets

### Notification Flow:
1. When document saved with expiry/due date
2. **NotificationService** calculates reminder dates (e.g., 30d, 7d, 1d before)
3. Schedules individual notifications using `flutter_local_notifications`
4. Stores notification IDs in `document.metadata['notificationIds']`
5. When notification triggers → user taps → navigate to **DocumentDetailsScreen**
6. If document updated/deleted → cancel old notifications

### Settings Flow:
1. User navigates to **NotificationSettingsScreen** from ProfileScreen
2. Toggles notification preferences → saved to **StorageService** (encrypted)
3. Changes apply immediately to all documents
4. If notifications disabled → cancel all scheduled notifications

---

## 🔧 TESTING COMMANDS

```powershell
# Install dependencies
flutter pub get

# Regenerate Hive adapters (after model changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Clear app data (Android)
adb shell pm clear com.sahidemon.documate

# Test notification permissions (Android 13+)
adb shell pm grant com.sahidemon.documate android.permission.POST_NOTIFICATIONS
```

---

## 📝 CONFIGURATION NOTES

### Edge Detection Setup:
- Requires camera permission
- Native OpenCV library (no additional setup on Android/iOS)
- Returns cropped, perspective-corrected image

### Notification Channel Setup:
- Channel ID: `documate_reminders`
- Channel Name: `Document Reminders`
- Importance: High
- Supports sound, vibration, badge

### Search Index Storage:
- Hive box: `search_index`
- Key: word (lowercase)
- Value: List<String> (document IDs)
- Rebuild on first launch or when empty

### Reminder Defaults:
- **Identity/Insurance**: 30, 7, 1 days before expiry
- **Bills**: 7, 3, 1 days before due date
- **Medical**: 14, 7, 1 days before
- **Legal**: 30, 14, 7 days before
- **Default Time**: 9:00 AM

---

## 🐛 KNOWN ISSUES / TODOs

1. **Edit document functionality** - Currently shows "Coming soon" message
2. **Interval editor dialog** - NotificationSettingsScreen needs custom dialog
3. **Retry OCR button** - DocumentDetailsScreen should allow re-running OCR if failed
4. **Manual category selection** - If ML confidence < 60%, show category picker
5. **Document number validation** - Parser regex may need refinement for specific ID formats
6. **Multi-language OCR** - Currently detects all languages, may need language selector
7. **Cloud sync trigger** - Need to call `cloudSyncService.uploadBackup()` after document save

---

## 📞 INTEGRATION POINTS

### In SmartCaptureFlowScreen (to be created):
```dart
// After user confirms document:
final documentId = uuid.v4();
final notificationIds = await notificationService.scheduleDocumentReminders(
  document: newDocument,
);

newDocument = newDocument.copyWith(
  metadata: {
    ...newDocument.metadata ?? {},
    'notificationIds': notificationIds,
  },
);

await storageService.saveDocument(documentId, newDocument.toJson());
await searchIndexService.addDocumentToIndex(newDocument);

if (await cloudSyncService.isBackupEnabled()) {
  cloudSyncService.uploadBackup(); // Fire and forget
}
```

### In HomeScreen _loadDocuments():
```dart
@override
void initState() {
  super.initState();
  _loadDocuments();
}

Future<void> _loadDocuments() async {
  setState(() => _isLoading = true);
  
  final docsMap = await storageService.getAllDocuments();
  final docs = docsMap.values.map((d) => DocumentModel.fromJson(d)).toList();
  
  setState(() {
    _allDocuments = docs;
    _recentDocuments = docs
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
      ..take(5).toList();
    
    _documentCounts = {
      'Identity': docs.where((d) => d.category == 'Identity').length,
      'Bills': docs.where((d) => d.category == 'Bills').length,
      'Medical': docs.where((d) => d.category == 'Medical').length,
      'Insurance': docs.where((d) => d.category == 'Insurance').length,
      'Legal': docs.where((d) => d.category == 'Legal').length,
      'Other': docs.where((d) => d.category == 'Other').length,
    };
    
    _isLoading = false;
  });
}
```

---

## ✨ SUMMARY

### What's Working:
✅ Encrypted local storage (AES-256)
✅ Cloud backup to Google Drive
✅ OCR text extraction
✅ ML document classification
✅ Field parsing (dates, amounts, numbers)
✅ Notification scheduling system
✅ Fast indexed search
✅ Multi-image document support
✅ Notification settings UI
✅ Document details with carousel

### What Needs Implementation:
⏳ Smart capture flow screen with edge detection
⏳ Connect UI to Hive database
⏳ Initialize services on app startup
⏳ Add navigation routes
⏳ Request notification permissions
⏳ Update AddDocumentScreen with edge detection

### Estimated Remaining Work:
- **Smart Capture Flow Screen**: 2-3 hours
- **UI Integration**: 1-2 hours
- **Testing & Bug Fixes**: 1-2 hours
- **Total**: 4-7 hours

---

**All services and core logic are ready. The main task is creating the SmartCaptureFlowScreen and wiring up the existing screens to use the new services.**
