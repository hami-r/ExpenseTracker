import 'package:flutter/material.dart';

class EditCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? category;

  const EditCategoryScreen({super.key, this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  late IconData _selectedIcon;

  final List<Color> colors = [
    const Color(0xFF28bd98),
    const Color(0xFFFAD231),
    const Color(0xFFFA897B),
    const Color(0xFF6CCFF6),
    const Color(0xFFB29BDE),
    const Color(0xFFFF8042),
  ];

  final List<IconData> icons = [
    Icons.shopping_cart_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.flight_rounded,
    Icons.medication_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.payment_rounded,
    Icons.savings_rounded,
    Icons.school_rounded,
    Icons.movie_rounded,
  ];

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?['name'] ?? '',
    );
    _selectedColor = widget.category?['color'] ?? colors[0];
    _selectedIcon = widget.category?['icon'] ?? icons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(isDark ? 0.1 : 0.4),
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
                    Theme.of(
                      context,
                    ).colorScheme.tertiary.withOpacity(isDark ? 0.1 : 0.3),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        isEditMode ? 'Edit Category' : 'Add Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Input
                        _buildLabel('Name', isDark),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF25282c)
                                : const Color(0xFFf2f5f4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            suffixIcon: Icon(
                              Icons.edit_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Color Picker
                        _buildLabel('Color', isDark),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: colors.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color;
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: color.withOpacity(0.3),
                                          width: 4,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Icon Grid
                        _buildLabel('Icon', isDark),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: icons.length,
                          itemBuilder: (context, index) {
                            final icon = icons[index];
                            final isSelected = _selectedIcon == icon;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF25282c)
                                      : const Color(0xFFf2f5f4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  icon,
                                  size: 30,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : (isDark
                                            ? const Color(0xFF9ca3af)
                                            : const Color(0xFF6b7280)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Save Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF131f17) : const Color(0xFFf6f8f7))
                        .withOpacity(0),
                    (isDark
                        ? const Color(0xFF131f17)
                        : const Color(0xFFf6f8f7)),
                    (isDark
                        ? const Color(0xFF131f17)
                        : const Color(0xFFf6f8f7)),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: () {
                    // Save logic here
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Save Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 20),
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

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
        ),
      ),
    );
  }
}
