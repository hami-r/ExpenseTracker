import 'package:flutter/material.dart';
import 'edit_category_screen.dart';
import '../models/category.dart';
import '../database/services/category_service.dart';
import '../database/services/user_service.dart';
import '../utils/icon_helper.dart';
import '../utils/color_helper.dart';
import '../widgets/delete_confirmation_dialog.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final bool isSelectionMode;

  const ManageCategoriesScreen({super.key, this.isSelectionMode = false});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  List<Category> categories = [];
  bool _isLoading = true;
  final CategoryService _categoryService = CategoryService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _userService.getCurrentUser();
    if (user != null) {
      final loadedCategories = await _categoryService.getAllCategories(
        user.userId!,
      );
      if (mounted) {
        setState(() {
          categories = loadedCategories;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.trim().isEmpty) return categories;
    final q = _searchQuery.trim().toLowerCase();
    return categories.where((category) {
      final name = category.name.toLowerCase();
      final description = (category.description ?? '').toLowerCase();
      return name.contains(q) || description.contains(q);
    }).toList();
  }

  void _deleteCategory(int index, BuildContext context) async {
    final category = categories[index];
    final categoryName = category.name;

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Delete Category',
      message:
          'Are you sure you want to delete "$categoryName"? This action cannot be undone.',
    );

    if (confirmed && category.categoryId != null) {
      await _categoryService.deactivateCategory(category.categoryId!);
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? const Color(0xFFe5e7eb)
                              : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        widget.isSelectionMode
                            ? 'Select Category'
                            : 'Manage Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Add New Category Button (manage mode only)
                        if (!widget.isSelectionMode)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditCategoryScreen(),
                                  ),
                                );
                                _loadData(); // Refresh after return
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_rounded, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add New Category',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (widget.isSelectionMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1a2c26)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0f172a),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search categories',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748b)
                                      : const Color(0xFF94a3b8),
                                ),
                                icon: Icon(
                                  Icons.search_rounded,
                                  color: isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF64748b),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Section Header
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ALL CATEGORIES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF9ca3af),
                                ),
                              ),
                              Text(
                                '${_filteredCategories.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Categories List
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_filteredCategories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No categories found',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF94a3b8)
                                      : const Color(0xFF64748b),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._filteredCategories.asMap().entries.map(
                            (entry) => Builder(
                              builder: (context) => _buildCategoryCard(
                                entry.value,
                                entry.key,
                                isDark,
                                context,
                              ),
                            ),
                          ),

                        const SizedBox(height: 48),

                        // Bottom indicator
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFd1d5db),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom gradient fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 48,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark
                              ? const Color(0xFF131f17)
                              : const Color(0xFFf6f8f7))
                          .withValues(alpha: 0),
                      (isDark
                          ? const Color(0xFF131f17)
                          : const Color(0xFFf6f8f7)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    Category category,
    int index,
    bool isDark,
    BuildContext context,
  ) {
    final color = ColorHelper.fromHex(category.colorHex);
    final icon = IconHelper.getIcon(category.iconName);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2c3035) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.isSelectionMode
            ? () {
                Navigator.pop(context, category);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),

              const SizedBox(width: 16),

              // Name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (category.description != null &&
                        category.description!.isNotEmpty)
                      Text(
                        category.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9ca3af)
                              : const Color(0xFF9ca3af),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              if (!widget.isSelectionMode) ...[
                const SizedBox(width: 8),

                // Action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditCategoryScreen(category: category),
                          ),
                        );
                        _loadData();
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF64748b)
                            : const Color(0xFF64748b),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFf1f5f9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _deleteCategory(index, context),
                      icon: const Icon(
                        Icons.delete_rounded,
                        size: 20,
                        color: Color(0xFFef4444),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFef4444,
                        ).withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
