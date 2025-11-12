import 'package:hive/hive.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';

/// Search index entry
class SearchIndexEntry {
  final String word;
  final Set<String> documentIds;

  SearchIndexEntry(this.word, this.documentIds);

  Map<String, dynamic> toJson() => {
        'word': word,
        'documentIds': documentIds.toList(),
      };

  factory SearchIndexEntry.fromJson(Map<String, dynamic> json) {
    return SearchIndexEntry(
      json['word'],
      Set<String>.from(json['documentIds']),
    );
  }
}

/// Fast document search service using indexed word lookup
class SearchIndexService {
  static final SearchIndexService _instance = SearchIndexService._internal();
  factory SearchIndexService() => _instance;
  SearchIndexService._internal();

  final StorageService _storageService = StorageService();
  final Map<String, Set<String>> _index = {};
  bool _initialized = false;

  /// Initialize search index
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadIndex();
    _initialized = true;
    print('✓ SearchIndexService initialized');
  }

  /// Load index from storage
  Future<void> _loadIndex() async {
    try {
      final box = await Hive.openBox('search_index');
      _index.clear();

      for (final key in box.keys) {
        final data = box.get(key);
        if (data is List) {
          _index[key] = Set<String>.from(data);
        }
      }

      print('✓ Loaded search index with ${_index.length} words');
    } catch (e) {
      print('⚠️ Error loading search index: $e');
    }
  }

  /// Save index to storage
  Future<void> _saveIndex() async {
    try {
      final box = await Hive.openBox('search_index');
      await box.clear();

      for (final entry in _index.entries) {
        await box.put(entry.key, entry.value.toList());
      }

      print('✓ Saved search index');
    } catch (e) {
      print('❌ Error saving search index: $e');
    }
  }

  /// Rebuild entire index from all documents
  Future<void> rebuildIndex() async {
    print('🔄 Rebuilding search index...');
    _index.clear();

    final documentsMap = await _storageService.getAllDocuments();
    final documents = documentsMap.values
        .map((data) => DocumentModel.fromJson(data))
        .toList();

    for (final doc in documents) {
      await addDocumentToIndex(doc);
    }

    await _saveIndex();
    print('✓ Rebuilt search index with ${_index.length} words');
  }

  /// Add document to index
  Future<void> addDocumentToIndex(DocumentModel document) async {
    final words = _tokenizeDocument(document);

    for (final word in words) {
      if (!_index.containsKey(word)) {
        _index[word] = {};
      }
      _index[word]!.add(document.id);
    }
  }

  /// Remove document from index
  Future<void> removeDocumentFromIndex(String documentId) async {
    // Remove document ID from all words
    for (final wordSet in _index.values) {
      wordSet.remove(documentId);
    }

    // Remove empty entries
    _index.removeWhere((word, docIds) => docIds.isEmpty);

    await _saveIndex();
  }

  /// Update document in index
  Future<void> updateDocumentInIndex(DocumentModel document) async {
    await removeDocumentFromIndex(document.id);
    await addDocumentToIndex(document);
    await _saveIndex();
  }

  /// Search documents by query
  Future<List<String>> search(String query) async {
    if (!_initialized) await initialize();

    if (query.trim().isEmpty) return [];

    // Tokenize query
    final queryWords = _tokenizeText(query.toLowerCase());

    if (queryWords.isEmpty) return [];

    // Find documents matching all query words (AND logic)
    Set<String>? matchingDocs;

    for (final word in queryWords) {
      final docsWithWord = _index[word];

      if (docsWithWord == null || docsWithWord.isEmpty) {
        // No documents contain this word
        return [];
      }

      if (matchingDocs == null) {
        matchingDocs = Set.from(docsWithWord);
      } else {
        matchingDocs = matchingDocs.intersection(docsWithWord);
      }

      // Early exit if no matches
      if (matchingDocs.isEmpty) return [];
    }

    return matchingDocs?.toList() ?? [];
  }

  /// Search with OR logic (any word matches)
  Future<List<String>> searchOr(String query) async {
    if (!_initialized) await initialize();

    if (query.trim().isEmpty) return [];

    final queryWords = _tokenizeText(query.toLowerCase());
    final matchingDocs = <String>{};

    for (final word in queryWords) {
      final docsWithWord = _index[word];
      if (docsWithWord != null) {
        matchingDocs.addAll(docsWithWord);
      }
    }

    return matchingDocs.toList();
  }

  /// Tokenize document into searchable words
  Set<String> _tokenizeDocument(DocumentModel document) {
    final words = <String>{};

    // Add words from name
    words.addAll(_tokenizeText(document.name.toLowerCase()));

    // Add words from description
    if (document.description != null) {
      words.addAll(_tokenizeText(document.description!.toLowerCase()));
    }

    // Add words from extracted text
    if (document.extractedText != null) {
      words.addAll(_tokenizeText(document.extractedText!.toLowerCase()));
    }

    // Add words from tags
    if (document.tags != null) {
      for (final tag in document.tags!) {
        words.addAll(_tokenizeText(tag.toLowerCase()));
      }
    }

    // Add category
    words.addAll(_tokenizeText(document.category.toLowerCase()));

    return words;
  }

  /// Tokenize text into individual words
  Set<String> _tokenizeText(String text) {
    // Remove special characters and split by whitespace
    final cleaned = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words = cleaned.split(RegExp(r'\s+'));

    // Filter out short words and common stop words
    return words
        .where((word) => word.length >= 2 && !_isStopWord(word))
        .toSet();
  }

  /// Check if word is a common stop word
  bool _isStopWord(String word) {
    const stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'can',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
    };

    return stopWords.contains(word);
  }

  /// Get index statistics
  Map<String, dynamic> getStats() {
    return {
      'totalWords': _index.length,
      'totalMappings': _index.values.fold(0, (sum, set) => sum + set.length),
    };
  }

  /// Clear index
  Future<void> clearIndex() async {
    _index.clear();
    await _saveIndex();
    print('🗑️ Cleared search index');
  }
}
