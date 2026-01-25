import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_date_picker.dart';

class EditReimbursementScreen extends StatefulWidget {
  const EditReimbursementScreen({super.key});

  @override
  State<EditReimbursementScreen> createState() =>
      _EditReimbursementScreenState();
}

class _EditReimbursementScreenState extends State<EditReimbursementScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '1250',
  );
  final TextEditingController _recipientController = TextEditingController(
    text: 'Office Lunch',
  );
  final TextEditingController _noteController = TextEditingController();

  String _selectedCategory = 'office';
  DateTime _selectedDate = DateTime(2026, 1, 20);

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    CustomDatePicker.show(
      context,
      initialDate: _selectedDate,
      onDateSelected: (DateTime picked) {
        setState(() {
          _selectedDate = picked;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131f17)
          : const Color(0xFFf6f8f7),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTotalAmountSection(isDark),
                        const SizedBox(height: 24),
                        _buildRecipientSection(isDark),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _buildCategorySection(isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDateSection(context, isDark)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildNoteSection(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24).copyWith(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1a2c26) : Colors.white,
              shape: const CircleBorder(),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFe2e8f0),
              ),
            ),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isDark ? const Color(0xFFcbd5e1) : const Color(0xFF475569),
            ),
          ),
          Text(
            'Edit Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
            ),
          ),
          const SizedBox(width: 40), // Placeholder for alignment
        ],
      ),
    );
  }

  Widget _buildTotalAmountSection(bool isDark) {
    return Column(
      children: [
        Text(
          'TOTAL AMOUNT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: isDark
                ? const Color(0xFF34d399)
                : const Color(0xFF059669).withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0f172a),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF334155).withOpacity(0.5)
                        : const Color(0xFFe2e8f0),
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipientSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'RECIPIENT / ITEM NAME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.transparent, // Placeholder for focus border
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: isDark
                    ? const Color(0xFF94a3b8)
                    : const Color(0xFF94a3b8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _recipientController,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0f172a),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g. Office Lunch or Amazon Refund',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFcbd5e1),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1e293b)
                      : const Color(0xFFf8fafc),
                  padding: const EdgeInsets.all(6),
                ),
                icon: Icon(
                  Icons.contacts_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'CATEGORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ),
        Container(
          height: 60, // Fixed height to match date picker
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const SizedBox(), // Hide default icon
              selectedItemBuilder: (context) {
                return ['office', 'refund', 'medical', 'travel'].map((
                  String value,
                ) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF94a3b8)
                            : const Color(0xFF94a3b8),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            value[0].toUpperCase() + value.substring(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0f172a),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: ['office', 'refund', 'medical', 'travel']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value[0].toUpperCase() + value.substring(1),
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0f172a),
                        ),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'EXPECTED BY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a2c26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94a3b8)
                      : const Color(0xFF94a3b8),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0f172a),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ADD NOTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF94a3b8) : const Color(0xFF64748b),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1a2c26) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0f172a),
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add a description or reason...',
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFcbd5e1),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
