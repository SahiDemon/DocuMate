import 'package:flutter/material.dart';
import 'package:documate/services/notification_service.dart';
import 'package:documate/services/storage_service.dart';
import 'package:documate/models/document_model.dart';
import 'package:documate/screens/document_details_screen.dart';
import 'package:documate/main.dart' as main_app;
import 'package:intl/intl.dart';

class NotificationsCenterScreen extends StatefulWidget {
  final StorageService storageService;

  const NotificationsCenterScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;

  List<Map<String, dynamic>> _upcomingNotifications = [];
  List<Map<String, dynamic>> _expiringDocuments = [];
  List<Map<String, dynamic>> _overdueDocuments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Get all documents
      final docsMap = await widget.storageService.getAllDocuments();
      final docs = docsMap.values.toList();

      final now = DateTime.now();
      final List<Map<String, dynamic>> expiring = [];
      final List<Map<String, dynamic>> overdue = [];

      for (final doc in docs) {
        if (doc['expiryDate'] != null) {
          try {
            final expiryDate = DateTime.parse(doc['expiryDate'] as String);
            final daysUntil = expiryDate.difference(now).inDays;

            if (daysUntil < 0) {
              // Overdue
              overdue.add({
                ...doc,
                'daysOverdue': daysUntil.abs(),
              });
            } else if (daysUntil <= 30) {
              // Expiring soon
              expiring.add({
                ...doc,
                'daysUntil': daysUntil,
              });
            }
          } catch (e) {
            debugPrint('Error parsing date for document: ${doc['name']}');
          }
        }

        if (doc['dueDate'] != null) {
          try {
            final dueDate = DateTime.parse(doc['dueDate'] as String);
            final daysUntil = dueDate.difference(now).inDays;

            if (daysUntil < 0) {
              overdue.add({
                ...doc,
                'daysOverdue': daysUntil.abs(),
                'isDueDate': true,
              });
            } else if (daysUntil <= 30) {
              expiring.add({
                ...doc,
                'daysUntil': daysUntil,
                'isDueDate': true,
              });
            }
          } catch (e) {
            debugPrint('Error parsing due date for document: ${doc['name']}');
          }
        }
      }

      // Sort by urgency
      expiring.sort(
          (a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));
      overdue.sort((a, b) =>
          (b['daysOverdue'] as int).compareTo(a['daysOverdue'] as int));

      // Get pending notification requests
      final pending = await _notificationService.getPendingNotifications();

      setState(() {
        _expiringDocuments = expiring;
        _overdueDocuments = overdue;
        _upcomingNotifications = pending.map((req) {
          return {
            'id': req.id,
            'title': req.title,
            'body': req.body,
            'payload': req.payload,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openDocument(Map<String, dynamic> documentData) {
    try {
      final document = DocumentModel.fromJson(documentData);
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => DocumentDetailsScreen(
                document: document,
                storageService: widget.storageService,
              ),
            ),
          )
          .then((_) => _loadNotifications());
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textTheme.bodyLarge?.color),
            tooltip: 'Refresh',
            onPressed: _loadNotifications,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodySmall?.color,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Expiring'),
                  if (_expiringDocuments.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_expiringDocuments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Overdue'),
                  if (_overdueDocuments.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_overdueDocuments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Scheduled'),
                  if (_upcomingNotifications.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_upcomingNotifications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExpiringTab(),
                _buildOverdueTab(),
                _buildScheduledTab(),
              ],
            ),
    );
  }

  Widget _buildExpiringTab() {
    if (_expiringDocuments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'All Good!',
        message: 'No documents expiring soon',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expiringDocuments.length,
      itemBuilder: (context, index) {
        final doc = _expiringDocuments[index];
        final daysUntil = doc['daysUntil'] as int;
        final isDueDate = doc['isDueDate'] == true;

        return _buildNotificationCard(
          icon: Icons.warning_amber,
          iconColor: _getUrgencyColor(daysUntil),
          title: doc['name'] as String,
          subtitle: isDueDate
              ? 'Due in $daysUntil day${daysUntil != 1 ? 's' : ''}'
              : 'Expires in $daysUntil day${daysUntil != 1 ? 's' : ''}',
          date: isDueDate
              ? DateTime.parse(doc['dueDate'] as String)
              : DateTime.parse(doc['expiryDate'] as String),
          onTap: () => _openDocument(doc),
        );
      },
    );
  }

  Widget _buildOverdueTab() {
    if (_overdueDocuments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'All Caught Up!',
        message: 'No overdue documents',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _overdueDocuments.length,
      itemBuilder: (context, index) {
        final doc = _overdueDocuments[index];
        final daysOverdue = doc['daysOverdue'] as int;
        final isDueDate = doc['isDueDate'] == true;

        return _buildNotificationCard(
          icon: Icons.error_outline,
          iconColor: const Color(0xFFDC2626),
          title: doc['name'] as String,
          subtitle: isDueDate
              ? 'Overdue by $daysOverdue day${daysOverdue != 1 ? 's' : ''}'
              : 'Expired $daysOverdue day${daysOverdue != 1 ? 's' : ''} ago',
          date: isDueDate
              ? DateTime.parse(doc['dueDate'] as String)
              : DateTime.parse(doc['expiryDate'] as String),
          onTap: () => _openDocument(doc),
        );
      },
    );
  }

  Widget _buildScheduledTab() {
    final theme = Theme.of(context);
    if (_upcomingNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No Scheduled Notifications',
        message: 'Documents with reminders will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingNotifications.length,
      itemBuilder: (context, index) {
        final notification = _upcomingNotifications[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] as String? ?? 'Notification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (notification['body'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required DateTime date,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(int daysUntil) {
    if (daysUntil <= 3) {
      return const Color(0xFFDC2626); // Red - Very urgent
    } else if (daysUntil <= 7) {
      return const Color(0xFFEF4444); // Orange-red - Urgent
    } else if (daysUntil <= 14) {
      return const Color(0xFFF97316); // Orange - Soon
    } else {
      return const Color(0xFFFBBF24); // Yellow - Upcoming
    }
  }
}
