import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/main.dart' as main_app;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<DocumentModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadRecentSearches() async {
    // Load recent searches from storage
    final searches = await main_app.storageService.getSetting(
      'recent_searches',
      defaultValue: <String>[],
    );
    setState(() {
      _recentSearches = List<String>.from(searches as List);
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Rebuild index if empty (first search)
      final stats = main_app.searchIndexService.getStats();
      if (stats['totalWords'] == 0) {
        setState(() => _isSearching = true);
        await main_app.searchIndexService.rebuildIndex();
      }

      // Search using SearchIndexService
      final docIds = await main_app.searchIndexService.search(query.trim());

      // Load documents from storage
      final results = <DocumentModel>[];
      for (final id in docIds.take(20)) {
        // Limit to 20 results
        final data = await main_app.storageService.getDocument(id);
        if (data != null) {
          results.add(DocumentModel.fromJson(data));
        }
      }

      // Save to recent searches
      if (!_recentSearches.contains(query.trim())) {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
        await main_app.storageService.saveSetting(
          'recent_searches',
          _recentSearches,
        );
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _removeRecentSearch(String search) async {
    setState(() {
      _recentSearches.remove(search);
    });
    await main_app.storageService.saveSetting(
      'recent_searches',
      _recentSearches,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: const Color(0xFFE5E5E5),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Text(
                    'Search Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.015,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      color: const Color(0xFFE5E5E5),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Input
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for documents...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.4),
                    ),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent Searches
                      if (_recentSearches.isNotEmpty && !_hasSearched) ...[
                        Text(
                          'RECENT SEARCHES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _recentSearches
                              .map((search) => _buildSearchChip(search))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Search Results
                      if (_hasSearched) ...[
                        Text(
                          'SEARCH RESULTS (${_searchResults.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_searchResults.isEmpty && !_isSearching)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._searchResults
                              .map((result) => _buildResultItem(result))
                              .toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _removeRecentSearch(text),
              child: Icon(
                Icons.close,
                size: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(DocumentModel document) {
    final icon = document.category == 'Identity'
        ? Icons.badge
        : document.category == 'Bills'
            ? Icons.receipt_long
            : document.category == 'Medical'
                ? Icons.medical_services
                : document.category == 'Insurance'
                    ? Icons.security
                    : Icons.description;

    final color = document.category == 'Identity'
        ? const Color(0xFF5E81F3)
        : document.category == 'Bills'
            ? const Color(0xFF10B981)
            : document.category == 'Medical'
                ? const Color(0xFFF97316)
                : document.category == 'Insurance'
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF5E81F3);

    final daysAgo = DateTime.now().difference(document.createdAt).inDays;
    final timeText = daysAgo == 0
        ? 'Today'
        : daysAgo == 1
            ? 'Yesterday'
            : '$daysAgo days ago';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentDetailsScreen(
              document: document,
              storageService: main_app.storageService,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$timeText • ${document.category}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class DocumentResult {
  final String name;
  final String date;
  final String size;
  final IconData icon;

  DocumentResult({
    required this.name,
    required this.date,
    required this.size,
    required this.icon,
  });
}
