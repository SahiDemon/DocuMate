import 'package:flutter/material.dart';
import 'package:documate/screens/add_document_screen.dart';
import 'package:documate/screens/search_screen.dart';
import 'package:documate/screens/profile_screen.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/screens/all_documents_screen.dart';
import 'package:documate/services/firebase_auth_service.dart';
import 'package:documate/widgets/bottom_nav_bar.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/main.dart' as main_app;
import 'package:intl/intl.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    HomeContent(),
    const SearchScreen(),
    const AddDocumentScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        itemCount: _screens.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - (value.abs() * 0.5)).clamp(0.7, 1.0);
              }
              return Center(
                child: SizedBox(
                  height: Curves.easeInOut.transform(value) *
                      MediaQuery.of(context).size.height,
                  width: Curves.easeInOut.transform(value) *
                      MediaQuery.of(context).size.width,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                ),
              );
            },
            child: _screens[index],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
  final FirebaseAuthService _authService = FirebaseAuthService();
  String _displayName = 'User';
  String? _photoUrl;
  bool _isLoading = true;
  List<dynamic> _recentDocuments = [];
  List<dynamic> _expiringDocuments = [];
  List<Map<String, dynamic>> _customCategories = [];
  Map<String, int> _documentCounts = {
    'Identity': 0,
    'Bills': 0,
    'Medical': 0,
    'Insurance': 0,
    'Legal': 0,
    'Other': 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final user = _authService.getCurrentUser();
    if (user != null) {
      _displayName = user.displayName ?? user.email?.split('@').first ?? 'User';
      _photoUrl = user.photoURL;
    }
    _loadDocuments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload documents when app comes to foreground
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final docsMap = await main_app.storageService.getAllDocuments();
      final docs = docsMap.values.toList();

      // Sort by createdAt (most recent first)
      docs.sort((a, b) {
        final aDate = DateTime.parse(a['createdAt'] as String);
        final bDate = DateTime.parse(b['createdAt'] as String);
        return bDate.compareTo(aDate);
      });

      // Get recent documents (top 5)
      final recentDocs = docs.take(5).toList();

      // Find expiring documents (within 30 days)
      final now = DateTime.now();
      final expiringDocs = docs.where((doc) {
        if (doc['expiryDate'] != null) {
          try {
            final expiryDate = DateTime.parse(doc['expiryDate'] as String);
            final daysUntil = expiryDate.difference(now).inDays;
            return daysUntil > 0 && daysUntil <= 30;
          } catch (e) {
            return false;
          }
        }
        return false;
      }).toList();

      // Sort expiring docs by expiry date (soonest first)
      expiringDocs.sort((a, b) {
        final aDate = DateTime.parse(a['expiryDate'] as String);
        final bDate = DateTime.parse(b['expiryDate'] as String);
        return aDate.compareTo(bDate);
      });

      // Load custom categories
      final customCategories = await main_app.storageService.getSetting(
        'custom_categories',
        defaultValue: <Map<String, dynamic>>[],
      ) as List;
      
      // Count documents by category (including custom categories)
      final counts = <String, int>{
        'Identity': 0,
        'Bills': 0,
        'Medical': 0,
        'Insurance': 0,
        'Legal': 0,
        'Other': 0,
      };
      
      // Add custom categories to counts
      for (final customCat in customCategories) {
        final name = customCat['name'] as String;
        if (!counts.containsKey(name)) {
          counts[name] = 0;
        }
      }

      for (final doc in docs) {
        final category = doc['category'] as String? ?? 'Other';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      setState(() {
        _recentDocuments = recentDocs;
        _expiringDocuments = expiringDocs.take(3).toList();
        _documentCounts = counts;
        _customCategories = customCategories.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openDocument(Map<String, dynamic> documentData) {
    try {
      final document = DocumentModel.fromJson(documentData);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DocumentDetailsScreen(
            document: document,
            storageService: main_app.storageService,
          ),
        ),
      ).then((_) => _loadDocuments()); // Refresh on return
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF5E81F3).withOpacity(0.2),
                  backgroundImage:
                      _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF5E81F3))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFFE5E5E5),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Expiring Soon Section (MOVED TO TOP)
                          if (_expiringDocuments.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Expiring Soon',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AllDocumentsScreen(
                                          storageService: main_app.storageService,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._expiringDocuments.map((doc) {
                              final expiryDate = DateTime.parse(doc['expiryDate'] as String);
                              final daysUntil = expiryDate.difference(DateTime.now()).inDays;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.warning,
                                        color: Color(0xFFEF4444),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Expires in $daysUntil day${daysUntil != 1 ? 's' : ''}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],

                          // Recently Added Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recently Added',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_recentDocuments.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AllDocumentsScreen(
                                          storageService: main_app.storageService,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'See All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5E81F3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_recentDocuments.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(
                                    Icons.description_outlined,
                                    size: 64,
                                    color: Colors.grey[700],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No documents yet',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add your first document',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRecentCard(
                                    _recentDocuments[0]['name'] as String,
                                    'Recently added',
                                    Icons.description,
                                    const Color(0xFF5E81F3),
                                    onTap: () => _openDocument(_recentDocuments[0]),
                                  ),
                                ),
                                if (_recentDocuments.length > 1) ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildRecentCard(
                                      _recentDocuments[1]['name'] as String,
                                      'Recently added',
                                      Icons.receipt_long,
                                      const Color(0xFFFBBF24),
                                      onTap: () => _openDocument(_recentDocuments[1]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          const SizedBox(height: 24),

                          // Categories Section
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._buildAllCategories(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String title,
    String count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllCategories() {
    final List<Widget> categoryWidgets = [];
    
    // Default categories with their icons and colors
    final defaultCategories = [
      {'name': 'Identity', 'icon': Icons.badge, 'color': const Color(0xFF5E81F3)},
      {'name': 'Bills', 'icon': Icons.receipt_long, 'color': const Color(0xFF10B981)},
      {'name': 'Medical', 'icon': Icons.medical_services, 'color': const Color(0xFFF97316)},
      {'name': 'Insurance', 'icon': Icons.security, 'color': const Color(0xFFFBBF24)},
      {'name': 'Legal', 'icon': Icons.gavel, 'color': const Color(0xFFEC4899)},
    ];
    
    // Build default categories
    for (final cat in defaultCategories) {
      final name = cat['name'] as String;
      final icon = cat['icon'] as IconData;
      final color = cat['color'] as Color;
      
      categoryWidgets.add(
        _buildCategoryItem(
          name,
          '${_documentCounts[name] ?? 0} documents',
          icon,
          color,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AllDocumentsScreen(
                  storageService: main_app.storageService,
                  category: name,
                ),
              ),
            );
          },
        ),
      );
      categoryWidgets.add(const SizedBox(height: 12));
    }
    
    // Build custom categories
    for (final customCat in _customCategories) {
      final name = customCat['name'] as String;
      final iconCode = customCat['icon'] as int;
      final colorValue = customCat['color'] as int;
      
      categoryWidgets.add(
        _buildCategoryItem(
          name,
          '${_documentCounts[name] ?? 0} documents',
          IconData(iconCode, fontFamily: 'MaterialIcons'),
          Color(colorValue),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AllDocumentsScreen(
                  storageService: main_app.storageService,
                  category: name,
                ),
              ),
            );
          },
        ),
      );
      categoryWidgets.add(const SizedBox(height: 12));
    }
    
    return categoryWidgets;
  }
}
