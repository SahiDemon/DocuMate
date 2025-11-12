import 'package:flutter/material.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/models/document_category.dart';
import 'package:intl/intl.dart';

class AllDocumentsScreen extends StatefulWidget {
  final StorageService storageService;
  final String? category;

  const AllDocumentsScreen({
    super.key,
    required this.storageService,
    this.category,
  });

  @override
  State<AllDocumentsScreen> createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends State<AllDocumentsScreen> {
  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // date, name, category

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final docsMap = await widget.storageService.getAllDocuments();
      final docs = docsMap.entries
          .map((e) => DocumentModel.fromJson(e.value))
          .toList();

      // Filter by category if specified
      final filtered = widget.category != null
          ? docs.where((doc) => doc.category == widget.category).toList()
          : docs;

      setState(() {
        _documents = filtered;
        _filteredDocuments = filtered;
        _isLoading = false;
      });

      _applySorting();
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDocuments = _documents;
      } else {
        _filteredDocuments = _documents.where((doc) {
          final searchLower = query.toLowerCase();
          return doc.name.toLowerCase().contains(searchLower) ||
              doc.category.toLowerCase().contains(searchLower) ||
              (doc.tags?.any((tag) => tag.toLowerCase().contains(searchLower)) ??
                  false) ||
              (doc.extractedText?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredDocuments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'name':
          _filteredDocuments.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'category':
          _filteredDocuments.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category != null
        ? '${widget.category} Documents'
        : 'All Documents';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              '${_filteredDocuments.length} document${_filteredDocuments.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _applySorting();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _sortBy == 'date'
                          ? const Color(0xFF5E81F3)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      size: 18,
                      color: _sortBy == 'name'
                          ? const Color(0xFF5E81F3)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'category',
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 18,
                      color: _sortBy == 'category'
                          ? const Color(0xFF5E81F3)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Category'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.4),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _filterDocuments('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterDocuments,
            ),
          ),

          // Documents list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5E81F3)),
                  )
                : _filteredDocuments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No documents found'
                                  : 'No documents yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDocuments.length,
                        itemBuilder: (context, index) {
                          return _buildDocumentCard(_filteredDocuments[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    final category = documentCategoryFromString(document.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.color.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: category.color, size: 28),
        ),
        title: Text(
          document.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              document.category,
              style: TextStyle(
                color: category.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, yyyy').format(document.createdAt),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            if (document.tags != null && document.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: document.tags!.take(3).map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E81F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFF5E81F3),
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.white.withOpacity(0.5),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentDetailsScreen(
                document: document,
                storageService: widget.storageService,
              ),
            ),
          ).then((_) => _loadDocuments());
        },
      ),
    );
  }
}

