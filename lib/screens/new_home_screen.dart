import 'package:flutter/material.dart';
import 'package:documate/screens/add_document_screen.dart';
import 'package:documate/screens/search_screen.dart';
import 'package:documate/screens/profile_screen.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/screens/all_documents_screen.dart';
import 'package:documate/screens/notifications_center_screen.dart';
import 'package:documate/services/firebase_auth_service.dart';
import 'package:documate/widgets/bottom_nav_bar.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/main.dart' as main_app;
import 'package:documate/theme/theme_provider.dart';
import 'package:provider/provider.dart';
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
    const HomeContent(),
    const SearchScreen(autoFocus: true),
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
  const HomeContent({super.key});

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
  int _notificationCount = 0;

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
    if (mounted) {
      setState(() => _isLoading = true);
    }

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

      // Initialize counts for custom categories
      for (var category in customCategories) {
        counts[category['name']] = 0;
      }

      for (var doc in docs) {
        final category = doc['category'] as String;
        if (counts.containsKey(category)) {
          counts[category] = (counts[category] ?? 0) + 1;
        } else {
          counts['Other'] = (counts['Other'] ?? 0) + 1;
        }
      }

      // Load unread notifications count
      final notifications = await main_app.storageService.getSetting(
        'notifications',
        defaultValue: [],
      ) as List;
      final unreadCount = notifications.where((n) => n['read'] == false).length;

      if (mounted) {
        setState(() {
          _recentDocuments = recentDocs;
          _expiringDocuments = expiringDocs;
          _documentCounts = counts;
          _customCategories = List<Map<String, dynamic>>.from(customCategories);
          _notificationCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openDocument(Map<String, dynamic> document) {
    try {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => DocumentDetailsScreen(
                document: DocumentModel.fromJson(document),
                storageService: main_app.storageService,
              ),
            ),
          )
          .then((_) => _loadDocuments()); // Refresh on return
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
    final theme = Theme.of(context);
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
                  backgroundColor: theme.primaryColor.withOpacity(0.2),
                  backgroundImage:
                      _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? Icon(Icons.person, color: theme.primaryColor)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        _displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => NotificationsCenterScreen(
                              storageService: main_app.storageService,
                            ),
                          ),
                        )
                        .then((_) => _loadDocuments());
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: theme.iconTheme.color,
                          size: 22,
                        ),
                      ),
                      if (_notificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              _notificationCount > 99
                                  ? '99+'
                                  : '$_notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            GestureDetector(
              onTap: () {
                // Navigate to search screen by changing bottom nav index
                final newHomeState =
                    context.findAncestorStateOfType<_NewHomeScreenState>();
                if (newHomeState != null) {
                  newHomeState._pageController.animateToPage(
                    1, // Index for SearchScreen
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: theme.iconTheme.color?.withOpacity(0.4),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search documents...',
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                                Text(
                                  'Expiring Soon',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllDocumentsScreen(
                                          storageService:
                                              main_app.storageService,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._expiringDocuments.map((doc) {
                              final expiryDate =
                                  DateTime.parse(doc['expiryDate'] as String);
                              final daysUntil =
                                  expiryDate.difference(DateTime.now()).inDays;
                              return GestureDetector(
                                onTap: () => _openDocument(doc),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.error
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.error
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.warning,
                                          color: theme.colorScheme.error,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc['name'] as String,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .textTheme.bodyLarge?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Expires in $daysUntil day${daysUntil != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: theme.iconTheme.color
                                            ?.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                          ],

                          // Recently Added Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Added',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (_recentDocuments.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AllDocumentsScreen(
                                          storageService:
                                              main_app.storageService,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'See All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
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
                                    color: theme.disabledColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No documents yet',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add your first document',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
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
                                    theme.primaryColor,
                                    onTap: () =>
                                        _openDocument(_recentDocuments[0]),
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
                                      onTap: () =>
                                          _openDocument(_recentDocuments[1]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          const SizedBox(height: 24),

                          // Categories Section
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
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
    final theme = Theme.of(context);
    final isCompact = context.watch<ThemeProvider>().compactView;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            isCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 32 : 40,
              height: isCompact ? 32 : 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isCompact ? 20 : 24),
            ),
            SizedBox(height: isCompact ? 8 : 10),
            Text(
              title,
              style: TextStyle(
                fontSize: isCompact ? 13 : 14,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isCompact ? 2 : 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: theme.textTheme.bodySmall?.color,
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
    final theme = Theme.of(context);
    // Get compact view setting from ThemeProvider
    final isCompact = context.watch<ThemeProvider>().compactView;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            isCompact ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 40 : 48,
              height: isCompact ? 40 : 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: isCompact ? 24 : 30),
            ),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.5),
              size: isCompact ? 20 : 24,
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
      {
        'name': 'Identity',
        'icon': Icons.badge,
        'color': const Color(0xFF5E81F3)
      },
      {
        'name': 'Bills',
        'icon': Icons.receipt_long,
        'color': const Color(0xFF10B981)
      },
      {
        'name': 'Medical',
        'icon': Icons.medical_services,
        'color': const Color(0xFFF97316)
      },
      {
        'name': 'Insurance',
        'icon': Icons.security,
        'color': const Color(0xFFFBBF24)
      },
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

      final categoryIcon = IconData(iconCode, fontFamily: 'MaterialIcons');
      final categoryColor = Color(colorValue);
      categoryWidgets.add(
        _buildCategoryItem(
          name,
          '${_documentCounts[name] ?? 0} documents',
          categoryIcon,
          categoryColor,
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
