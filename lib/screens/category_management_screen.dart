import 'package:flutter/material.dart';
import 'package:documate/theme/app_theme.dart';
import 'package:documate/services/storage_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  final StorageService storageService;

  const CategoryManagementScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // Default categories that can't be deleted
  final List<String> _defaultCategories = [
    'Identity',
    'Bills',
    'Medical',
    'Insurance',
    'Legal',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final customCategories =
          await widget.storageService.getSetting('custom_categories',
              defaultValue: <Map<String, dynamic>>[]) as List;

      print('🔍 Loading categories...');
      print('📦 Custom categories from storage: $customCategories');
      print('📊 Custom categories length: ${customCategories.length}');

      final allCategories = [
        ..._defaultCategories.map((name) => {
              'name': name,
              'icon': _getDefaultIcon(name).codePoint,
              'color': _getDefaultColor(name).value,
              'isDefault': true,
            }),
        ...customCategories.map((cat) {
          final mapped = Map<String, dynamic>.from(cat as Map);
          return {...mapped, 'isDefault': false};
        }),
      ];

      print('✅ All categories count: ${allCategories.length}');

      setState(() {
        _categories = List<Map<String, dynamic>>.from(allCategories);
        _isLoading = false;
      });

      print('✓ Categories loaded successfully: ${_categories.length} total');
    } catch (e, stackTrace) {
      print('❌ Error loading categories: $e');
      print('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  IconData _getDefaultIcon(String category) {
    switch (category) {
      case 'Identity':
        return Icons.badge;
      case 'Bills':
        return Icons.receipt_long;
      case 'Medical':
        return Icons.medical_services;
      case 'Insurance':
        return Icons.security;
      case 'Legal':
        return Icons.gavel;
      default:
        return Icons.folder;
    }
  }

  Color _getDefaultColor(String category) {
    switch (category) {
      case 'Identity':
        return const Color(0xFF5E81F3);
      case 'Bills':
        return const Color(0xFF10B981);
      case 'Medical':
        return const Color(0xFFF97316);
      case 'Insurance':
        return const Color(0xFFFBBF24);
      case 'Legal':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _saveCustomCategories() async {
    final customCategories = _categories
        .where((cat) => cat['isDefault'] != true)
        .map((cat) => {
              'name': cat['name'],
              'icon': cat['icon'],
              'color': cat['color'],
            })
        .toList();

    await widget.storageService.saveSetting('custom_categories', customCategories);
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CategoryEditorDialog(),
    );

    if (result != null) {
      // Add to list first
      _categories.add({...result, 'isDefault': false});
      
      // Save and reload
      await _saveCustomCategories();
      await _loadCategories(); // Reload to ensure consistency
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${result['name']}" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _editCategory(int index) async {
    final category = _categories[index];
    
    if (category['isDefault'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be edited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CategoryEditorDialog(
        initialName: category['name'],
        initialIcon: category['icon'],
        initialColor: category['color'],
      ),
    );

    if (result != null) {
      setState(() {
        _categories[index] = {...result, 'isDefault': false};
      });
      await _saveCustomCategories();
    }
  }

  Future<void> _deleteCategory(int index) async {
    final category = _categories[index];

    if (category['isDefault'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default categories cannot be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Category?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${category['name']}"? Documents in this category will be moved to "Other".',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _categories.removeAt(index);
      });
      await _saveCustomCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Category deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Categories',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5E81F3)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryCard(category, index);
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _addCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E81F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final isDefault = category['isDefault'] == true;
    final iconData = IconData(category['icon'], fontFamily: 'MaterialIcons');
    final color = Color(category['color']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: color, size: 28),
        ),
        title: Text(
          category['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isDefault ? 'Default Category' : 'Custom Category',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editCategory(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(index),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  final String? initialName;
  final int? initialIcon;
  final int? initialColor;

  const _CategoryEditorDialog({
    this.initialName,
    this.initialIcon,
    this.initialColor,
  });

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.description,
    Icons.article,
    Icons.file_copy,
    Icons.note,
    Icons.assignment,
    Icons.business,
    Icons.work,
    Icons.school,
    Icons.local_hospital,
    Icons.fitness_center,
    Icons.sports,
    Icons.restaurant,
    Icons.local_grocery_store,
    Icons.shopping_cart,
    Icons.credit_card,
    Icons.account_balance,
    Icons.home,
    Icons.apartment,
    Icons.directions_car,
    Icons.flight,
    Icons.beach_access,
    Icons.pets,
    Icons.favorite,
    Icons.star,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF5E81F3),
    const Color(0xFF10B981),
    const Color(0xFFF97316),
    const Color(0xFFFBBF24),
    const Color(0xFFEC4899),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFEF4444),
    const Color(0xFF6366F1),
    const Color(0xFFF59E0B),
    const Color(0xFF14B8A6),
    const Color(0xFFA855F7),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon != null
        ? IconData(widget.initialIcon!, fontFamily: 'MaterialIcons')
        : Icons.folder;
    _selectedColor =
        widget.initialColor != null ? Color(widget.initialColor!) : _availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialName != null ? 'Edit Category' : 'New Category',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF5E81F3)),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon selector
              Text(
                'Select Icon',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5E81F3).withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF5E81F3)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Color selector
              Text(
                'Select Color',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_selectedIcon, color: _selectedColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preview',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _nameController.text.isEmpty
                                ? 'Category Name'
                                : _nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a category name'),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context, {
                          'name': _nameController.text.trim(),
                          'icon': _selectedIcon.codePoint,
                          'color': _selectedColor.value,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E81F3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

