import 'package:flutter/material.dart';
import 'edit_category_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late List<Map<String, dynamic>> categories;

  @override
  void initState() {
    super.initState();
    categories = [
      {
        'name': 'Housing',
        'description': 'Rent, Mortgage, Repairs',
        'icon': Icons.cottage_rounded,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'name': 'Transportation',
        'description': 'Fuel, Service, Parking',
        'icon': Icons.directions_car_rounded,
        'color': const Color(0xFF4D96FF),
      },
      {
        'name': 'Food & Dining',
        'description': 'Groceries, Restaurants',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFFFD93D),
      },
      {
        'name': 'Entertainment',
        'description': 'Movies, Games, Events',
        'icon': Icons.theater_comedy_rounded,
        'color': const Color(0xFF9D4EDD),
      },
      {
        'name': 'Shopping',
        'description': 'Clothing, Electronics',
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFFF72585),
      },
      {
        'name': 'Health & Fitness',
        'description': 'Doctor, Gym, Pharmacy',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF06D6A0),
      },
      {
        'name': 'Travel',
        'description': 'Flights, Hotels, Airbnb',
        'icon': Icons.flight_takeoff_rounded,
        'color': const Color(0xFF4CC9F0),
      },
      {
        'name': 'Education',
        'description': 'Tuition, Books, Courses',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF5361FC),
      },
      {
        'name': 'Investments',
        'description': 'Stocks, Crypto, Savings',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF2EC4B6),
      },
      {
        'name': 'Pets',
        'description': 'Food, Vet, Toys',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFFE07A5F),
      },
      {
        'name': 'Gifts & Donations',
        'description': 'Birthdays, Charity',
        'icon': Icons.card_giftcard_rounded,
        'color': const Color(0xFFFB8B24),
      },
    ];
  }

  void _deleteCategory(int index, BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryName = categories[index]['name'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$categoryName"? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? const Color(0xFFd1d5db) : const Color(0xFF6b7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF6b7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        categories.removeAt(index);
      });
    }
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
                        'Manage Categories',
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

                        // Add New Category Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditCategoryScreen(),
                                ),
                              );
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
                              ).colorScheme.primary.withOpacity(0.3),
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

                        const SizedBox(height: 32),

                        // Section Header
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
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
                        ),

                        const SizedBox(height: 12),

                        // Categories List
                        ...categories.asMap().entries.map(
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
                          .withOpacity(0),
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
    Map<String, dynamic> category,
    int index,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2c3035) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category['color'],
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (category['color'] as Color).withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              category['icon'],
              color: category['name'] == 'Food & Dining'
                  ? const Color(0xFF5c4d12)
                  : Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category['description'],
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

          const SizedBox(width: 8),

          // Action buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditCategoryScreen(category: category),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF64748b)
                      : const Color(0xFF64748b),
                ),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
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
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
