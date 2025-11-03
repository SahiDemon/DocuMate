import 'package:flutter/material.dart';
import 'package:documate/theme/app_theme.dart';
import 'package:documate/models/document_category.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/screens/document_capture_screen.dart';
import 'package:documate/services/image_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  AnimationController? _animationController;
  final ScrollController _scrollController = ScrollController();
  final ImageService _imageService = ImageService();
  double _topBarOpacity = 0.0;

  // Dummy data for now
  final List<DocumentModel> _recentDocuments = [];
  final Map<DocumentCategory, int> _documentCounts = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animationController?.forward();

    _scrollController.addListener(() {
      if (_scrollController.offset >= 24) {
        if (_topBarOpacity != 1.0) {
          setState(() => _topBarOpacity = 1.0);
        }
      } else if (_scrollController.offset <= 24 &&
          _scrollController.offset >= 0) {
        if (_topBarOpacity != _scrollController.offset / 24) {
          setState(() => _topBarOpacity = _scrollController.offset / 24);
        }
      } else if (_scrollController.offset <= 0) {
        if (_topBarOpacity != 0.0) {
          setState(() => _topBarOpacity = 0.0);
        }
      }
    });

    _loadDocuments();
  }

  void _loadDocuments() {
    // TODO: Load from Hive database
    // For now, initialize with empty counts
    for (var category in DocumentCategory.values) {
      _documentCounts[category] = 0;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocuMateTheme.primaryDark,
      body: Stack(
        children: [
          _buildMainContent(),
          _buildAppBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddDocument,
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
    );
  }

  Widget _buildMainContent() {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 100,
      ),
      children: [
        _buildQuickStats(),
        const SizedBox(height: 24),
        _buildSectionTitle('Categories', 'Manage'),
        _buildCategoriesGrid(),
        const SizedBox(height: 24),
        _buildSectionTitle('Recent Documents', 'View All'),
        _buildRecentDocuments(),
        const SizedBox(height: 24),
        _buildSectionTitle('Expiring Soon', 'View All'),
        _buildExpiringDocuments(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: DocuMateTheme.primaryDark.withOpacity(_topBarOpacity),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2 * _topBarOpacity),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DocuMate',
                    style: DocuMateTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: DocuMateTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
                color: DocuMateTheme.textSecondary,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                color: DocuMateTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              DocuMateTheme.accentBlue,
              DocuMateTheme.accentPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: DocuMateTheme.accentBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total Docs', '0', Icons.description),
            _buildStatDivider(),
            _buildStatItem('Expiring', '0', Icons.warning_amber),
            _buildStatDivider(),
            _buildStatItem('Categories', '6', Icons.category),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: DocuMateTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DocuMateTheme.bodySmall.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: DocuMateTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: DocuMateTheme.labelMedium.copyWith(
                color: DocuMateTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: DocumentCategory.values.map((category) {
          return _buildCategoryCard(category);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(DocumentCategory category) {
    final count = _documentCounts[category] ?? 0;
    return InkWell(
      onTap: () => _onCategoryTap(category),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: DocuMateTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  Text(
                    '$count',
                    style: DocuMateTheme.headlineSmall.copyWith(
                      color: category.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                category.displayName,
                style: DocuMateTheme.titleSmall.copyWith(
                  color: DocuMateTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDocuments() {
    if (_recentDocuments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 80,
              color: DocuMateTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: DocuMateTheme.bodyLarge.copyWith(
                color: DocuMateTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by adding your first document',
              style: DocuMateTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentDocuments.length,
      itemBuilder: (context, index) {
        return _buildDocumentCard(_recentDocuments[index]);
      },
    );
  }

  Widget _buildExpiringDocuments() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: DocuMateTheme.success,
          ),
          const SizedBox(height: 16),
          Text(
            'All documents are up to date',
            style: DocuMateTheme.bodyLarge.copyWith(
              color: DocuMateTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DocuMateTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: DocuMateTheme.getCategoryColor(document.category)
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            documentCategoryFromString(document.category).icon,
            color: DocuMateTheme.getCategoryColor(document.category),
          ),
        ),
        title: Text(
          document.name,
          style: DocuMateTheme.titleMedium,
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(document.createdAt),
          style: DocuMateTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  void _onAddDocument() {
    // TODO: Navigate to add document screen
    showModalBottomSheet(
      context: context,
      backgroundColor: DocuMateTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddDocumentSheet(),
    );
  }

  Widget _buildAddDocumentSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add New Document',
              style: DocuMateTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DocuMateTheme.accentBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt,
                    color: DocuMateTheme.accentBlue),
              ),
              title: const Text('Scan with Camera'),
              subtitle: const Text('Capture document with OCR'),
              onTap: () {
                Navigator.pop(context);
                _openCamera();
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DocuMateTheme.accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library,
                    color: DocuMateTheme.accentPurple),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing image'),
              onTap: () {
                Navigator.pop(context);
                _openGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryTap(DocumentCategory category) {
    // TODO: Navigate to category screen
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DocumentCaptureScreen(),
      ),
    );

    if (result != null) {
      // Document was captured
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document captured successfully!'),
          backgroundColor: DocuMateTheme.success,
        ),
      );
    }
  }

  Future<void> _openGallery() async {
    try {
      final image = await _imageService.pickFromGallery();
      if (image != null && mounted) {
        // Navigate to capture screen with the selected image
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DocumentCaptureScreen(),
          ),
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document added successfully!'),
              backgroundColor: DocuMateTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DocuMateTheme.error,
          ),
        );
      }
    }
  }
}
