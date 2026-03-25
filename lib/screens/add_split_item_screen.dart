import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/profile_provider.dart';
import '../utils/color_helper.dart';
import '../utils/icon_helper.dart';
import 'manage_categories_screen.dart';

class AddSplitItemScreen extends StatefulWidget {
  final List<Category> categories;

  const AddSplitItemScreen({super.key, required this.categories});

  @override
  State<AddSplitItemScreen> createState() => _AddSplitItemScreenState();
}

class _AddSplitItemScreenState extends State<AddSplitItemScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  int _selectedCategoryIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;
    const maxVisibleCategories = 8;
    final visibleCategories = widget.categories
        .take(maxVisibleCategories)
        .toList();
    final selectedCategory =
        (_selectedCategoryIndex >= 0 &&
            _selectedCategoryIndex < widget.categories.length)
        ? widget.categories[_selectedCategoryIndex]
        : null;

    if (selectedCategory != null &&
        !visibleCategories.any(
          (category) => category.categoryId == selectedCategory.categoryId,
        )) {
      if (visibleCategories.length == maxVisibleCategories) {
        visibleCategories.removeLast();
      }
      visibleCategories.add(selectedCategory);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.1 : 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tertiaryColor.withValues(alpha: isDark ? 0.1 : 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24).copyWith(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBackButton(context, isDark),
                      Text(
                        'Add Item',
                        style:
                            Theme.of(context).appBarTheme.titleTextStyle ??
                            TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(width: 40), // Placeholder for alignment
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Amount Input
                          Text(
                            'AMOUNT',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  context
                                      .read<ProfileProvider>()
                                      .currencySymbol,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: 36,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  textAlign: TextAlign.center,
                                  autofocus: true,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontSize: 64,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.2),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Category Grid
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    'Category',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.categories.isEmpty
                                      ? null
                                      : () async {
                                          final pickedCategory =
                                              await Navigator.push<Category>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ManageCategoriesScreen(
                                                        isSelectionMode: true,
                                                      ),
                                                ),
                                              );

                                          if (pickedCategory == null ||
                                              !mounted) {
                                            return;
                                          }

                                          final selectedIndex = widget
                                              .categories
                                              .indexWhere(
                                                (category) =>
                                                    category.categoryId ==
                                                    pickedCategory.categoryId,
                                              );
                                          if (selectedIndex == -1) return;

                                          setState(() {
                                            _selectedCategoryIndex =
                                                selectedIndex;
                                          });
                                        },
                                  child: Text(
                                    'See all',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (widget.categories.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No categories available',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          else ...[
                            if (selectedCategory != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color:
                                            ColorHelper.fromHex(
                                              selectedCategory.colorHex,
                                            ).withValues(
                                              alpha: isDark ? 0.25 : 0.12,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        IconHelper.getIcon(
                                          selectedCategory.iconName,
                                        ),
                                        size: 18,
                                        color: isDark
                                            ? ColorHelper.fromHex(
                                                selectedCategory.colorHex,
                                              ).withValues(alpha: 0.9)
                                            : ColorHelper.fromHex(
                                                selectedCategory.colorHex,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedCategory.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      'Selected',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 24,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.7,
                                  ),
                              itemCount: visibleCategories.length,
                              itemBuilder: (context, index) {
                                return _buildCategoryItem(
                                  context,
                                  index,
                                  isDark,
                                  visibleCategories[index],
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Item Name Input
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                'Item Name',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _itemNameController,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 16),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      hintText: 'e.g. Coffee, Taxi, Dinner',
                                      hintStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 48,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0),
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: ElevatedButton(
                onPressed: _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Add to Split',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.add_circle_outline, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.arrow_back_rounded,
        color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    int index,
    bool isDark,
    Category category,
  ) {
    final isSelected = _selectedCategoryIndex == index;
    final color = ColorHelper.fromHex(category.colorHex);
    final icon = IconHelper.getIcon(category.iconName);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = widget.categories.indexWhere(
            (item) => item.categoryId == category.categoryId,
          );
        });
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? color : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                width: isSelected ? 4 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                else if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected
                  ? Colors.white
                  : (isDark ? color.withValues(alpha: 0.8) : color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _submitItem() {
    if (_amountController.text.isEmpty) return; // Simple validation
    if (widget.categories.isEmpty) return;

    final category = _selectedCategoryIndex >= 0
        ? widget.categories[_selectedCategoryIndex]
        : widget.categories.first;

    Navigator.pop(context, {
      'name': _itemNameController.text.isEmpty
          ? category.name
          : _itemNameController.text,
      'amount': _amountController.text,
      'categoryId': category.categoryId,
      'category': category.name,
      'icon': IconHelper.getIcon(category.iconName),
      'color': ColorHelper.fromHex(category.colorHex),
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }
}
