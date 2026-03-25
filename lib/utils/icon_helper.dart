import 'package:flutter/material.dart';

class IconHelper {
  static final Map<String, IconData> _iconMap = {
    'cottage_rounded': Icons.cottage_rounded,
    'directions_car_rounded': Icons.directions_car_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'theater_comedy_rounded': Icons.theater_comedy_rounded,
    'shopping_bag_rounded': Icons.shopping_bag_rounded,
    'favorite_rounded': Icons.favorite_rounded,
    'flight_takeoff_rounded': Icons.flight_takeoff_rounded,
    'school_rounded': Icons.school_rounded,
    'trending_up_rounded': Icons.trending_up_rounded,
    'pets_rounded': Icons.pets_rounded,
    'card_giftcard_rounded': Icons.card_giftcard_rounded,
    'shopping_cart_rounded': Icons.shopping_cart_rounded,
    'home_rounded': Icons.home_rounded,
    'flight_rounded': Icons.flight_rounded,
    'medication_rounded': Icons.medication_rounded,
    'fitness_center_rounded': Icons.fitness_center_rounded,
    'payment_rounded': Icons.payment_rounded,
    'savings_rounded': Icons.savings_rounded,
    'movie_rounded': Icons.movie_rounded,
    'work_rounded': Icons.work_rounded,
    'person_rounded': Icons.person_rounded,
    'category_rounded': Icons.category_rounded,
    'security_rounded': Icons.security_rounded,
    'subscriptions_rounded': Icons.subscriptions_rounded,
    'face_rounded': Icons.face_rounded,
    'family_restroom_rounded': Icons.family_restroom_rounded,
    'receipt_long_rounded': Icons.receipt_long_rounded,
    'receipt_rounded': Icons.receipt_rounded,
    'auto_awesome_rounded': Icons.auto_awesome_rounded,
    'home_repair_service_rounded': Icons.home_repair_service_rounded,
    'volunteer_activism_rounded': Icons.volunteer_activism_rounded,
    'flash_on_rounded': Icons.flash_on_rounded,
    'lunch_dining_rounded': Icons.lunch_dining_rounded,
    'local_activity_rounded': Icons.local_activity_rounded,
    'local_hospital_rounded': Icons.local_hospital_rounded,
    'payments_rounded': Icons.payments_rounded,
    'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
    'credit_card_rounded': Icons.credit_card_rounded,
    'account_balance_rounded': Icons.account_balance_rounded,
    'qr_code_scanner_rounded': Icons.qr_code_scanner_rounded,
    'bug_report_rounded': Icons.bug_report_rounded,

    // Legacy aliases kept for older saved category/payment icon names.
    'cottage': Icons.cottage_rounded,
    'directions_car': Icons.directions_car_rounded,
    'restaurant': Icons.restaurant_rounded,
    'theater_comedy': Icons.theater_comedy_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'favorite': Icons.favorite_rounded,
    'flight_takeoff': Icons.flight_takeoff_rounded,
    'school': Icons.school_rounded,
    'trending_up': Icons.trending_up_rounded,
    'pets': Icons.pets_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'home': Icons.home_rounded,
    'flight': Icons.flight_rounded,
    'medication': Icons.medication_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'payment': Icons.payment_rounded,
    'savings': Icons.savings_rounded,
    'movie': Icons.movie_rounded,
    'work': Icons.work_rounded,
    'person': Icons.person_rounded,
    'category': Icons.category_rounded,
    'security': Icons.security_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'face': Icons.face_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_rounded,
    'auto_awesome': Icons.auto_awesome_rounded,
    'home_repair_service': Icons.home_repair_service_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'flash_on': Icons.flash_on_rounded,
    'lunch_dining': Icons.lunch_dining_rounded,
    'local_activity': Icons.local_activity_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'payments': Icons.payments_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'credit_card': Icons.credit_card_rounded,
    'account_balance': Icons.account_balance_rounded,
    'qr_code_scanner': Icons.qr_code_scanner_rounded,
    'bug_report': Icons.bug_report_rounded,
  };

  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.category_rounded;
    return _iconMap[iconName] ?? Icons.category_rounded;
  }

  static String getIconName(IconData icon) {
    // This is a reverse lookup, which is inefficient but okay for small map
    for (var entry in _iconMap.entries) {
      if (entry.value.codePoint == icon.codePoint) {
        return entry.key;
      }
    }
    return 'category_rounded';
  }
}
