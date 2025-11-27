import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/main.dart' as main_app;

class SearchScreen extends StatefulWidget {
  final bool autoFocus;

  const SearchScreen({super.key, this.autoFocus = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];
  List<DocumentModel> _searchResults = [];
  List<DocumentModel> _allSearchResults = [];
  List<DocumentModel> _recentDocuments = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _selectedCategory;
  String _sortBy = 'date'; // date, name, category

  // Debouncing for auto-search
  DateTime? _lastSearchTime;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadRecentDocuments();
    _searchController.addListener(_onSearchChanged);

    // Auto-focus the search field if requested
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
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

  Future<void> _loadRecentDocuments() async {
    try {
      final docsMap = await main_app.storageService.getAllDocuments();
      final docs = docsMap.values.toList();

      // Sort by createdAt (most recent first)
      docs.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt'] as String);
        final bDate = DateTime.parse(b['createdAt'] as String);
        return bDate.compareTo(aDate);
      });

      // Get top 10 recent documents
      final recentDocs =
          docs.take(10).map((doc) => DocumentModel.fromJson(doc)).toList();

      setState(() {
        _recentDocuments = recentDocs;
      });
    } catch (e) {
      print('Error loading recent documents: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Auto-search with debouncing (wait 500ms after user stops typing)
    _lastSearchTime = DateTime.now();
    _lastSearchQuery = query;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastSearchQuery == query &&
          _lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!).inMilliseconds >= 500) {
        _performSearch(query);
      }
    });
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
        _allSearchResults = results;
        _applyFilters();
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

  void _applyFilters() {
    var filtered = List<DocumentModel>.from(_allSearchResults);

    // Apply category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((doc) => doc.category == _selectedCategory).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _searchResults = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          size: 20, color: theme.iconTheme.color),
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/home'),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Text(
                    'Search Documents',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.more_vert,
                          size: 20, color: theme.iconTheme.color),
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
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: theme.textTheme.bodyLarge,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for documents...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.hintColor,
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
              const SizedBox(height: 16),

              // Filters & Sort (when searching)
              if (_hasSearched) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter
                      _buildFilterChip(
                        'All',
                        _selectedCategory == null,
                        () {
                          setState(() {
                            _selectedCategory = null;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Identity',
                        _selectedCategory == 'Identity',
                        () {
                          setState(() {
                            _selectedCategory = _selectedCategory == 'Identity'
                                ? null
                                : 'Identity';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Bills',
                        _selectedCategory == 'Bills',
                        () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == 'Bills' ? null : 'Bills';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Medical',
                        _selectedCategory == 'Medical',
                        () {
                          setState(() {
                            _selectedCategory = _selectedCategory == 'Medical'
                                ? null
                                : 'Medical';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Insurance',
                        _selectedCategory == 'Insurance',
                        () {
                          setState(() {
                            _selectedCategory = _selectedCategory == 'Insurance'
                                ? null
                                : 'Insurance';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Legal',
                        _selectedCategory == 'Legal',
                        () {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == 'Legal' ? null : 'Legal';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      // Sort Button
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.primaryColor),
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() {
                              _sortBy = value;
                              _applyFilters();
                            });
                          },
                          color: theme.cardColor,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort,
                                  color: theme.primaryColor, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _sortBy == 'date'
                                    ? 'Date'
                                    : _sortBy == 'name'
                                        ? 'Name'
                                        : 'Category',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'date',
                              child: Text('Sort by Date',
                                  style: theme.textTheme.bodyMedium),
                            ),
                            PopupMenuItem(
                              value: 'name',
                              child: Text('Sort by Name',
                                  style: theme.textTheme.bodyMedium),
                            ),
                            PopupMenuItem(
                              value: 'category',
                              child: Text('Sort by Category',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent Searches
                      if (_recentSearches.isNotEmpty && !_hasSearched) ...[
                        Text(
                          'RECENT SEARCHES',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
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

                      // Recent Documents (when no search)
                      if (!_hasSearched && _recentDocuments.isNotEmpty) ...[
                        Text(
                          'RECENT DOCUMENTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._recentDocuments.map((doc) => _buildResultItem(doc)),
                      ],

                      // Search Results
                      if (_hasSearched) ...[
                        Text(
                          'SEARCH RESULTS (${_searchResults.length})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
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
                                  color: theme.disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.disabledColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._searchResults
                              .map((result) => _buildResultItem(result)),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: isSelected ? null : Border.all(color: theme.dividerColor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:
                  isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _removeRecentSearch(text),
              child: Icon(
                Icons.close,
                size: 18,
                color: theme.iconTheme.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(DocumentModel document) {
    final theme = Theme.of(context);
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
          color: theme.cardColor,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$timeText • ${document.category}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
