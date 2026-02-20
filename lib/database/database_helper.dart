import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add soft delete columns
      await db.execute(
        'ALTER TABLE loans ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE ious ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE receivables ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE reimbursements ADD COLUMN is_deleted INTEGER DEFAULT 0',
      );
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');

    // 1. Currencies Table
    await db.execute('''
      CREATE TABLE currencies (
        currency_id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_code TEXT UNIQUE NOT NULL,
        currency_name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        decimal_places INTEGER DEFAULT 2,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_currencies_code ON currencies(currency_code)',
    );

    // 2. Users Table
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        country_code TEXT,
        avatar_path TEXT,
        theme_preference TEXT DEFAULT 'system',
        theme_color TEXT DEFAULT 'Emerald Green',
        primary_currency_id INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (primary_currency_id) REFERENCES currencies(currency_id) ON DELETE SET NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_users_email ON users(email)');
    await db.execute(
      'CREATE INDEX idx_users_currency ON users(primary_currency_id)',
    );

    // 3. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        color_hex TEXT,
        is_system INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        display_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_categories_user ON categories(user_id)');
    await db.execute(
      'CREATE INDEX idx_categories_active ON categories(user_id, is_active)',
    );

    // 4. Payment Methods Table
    await db.execute('''
      CREATE TABLE payment_methods (
        payment_method_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT,
        color_hex TEXT,
        account_number TEXT,
        is_active INTEGER DEFAULT 1,
        display_order INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_payment_methods_user ON payment_methods(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_payment_methods_active ON payment_methods(user_id, is_active)',
    );

    // 5. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER,
        payment_method_id INTEGER,
        amount REAL NOT NULL,
        currency_id INTEGER DEFAULT 1,
        note TEXT,
        transaction_date TEXT NOT NULL,
        is_split INTEGER DEFAULT 0,
        parent_transaction_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL,
        FOREIGN KEY (parent_transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
        FOREIGN KEY (currency_id) REFERENCES currencies(currency_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_user ON transactions(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_date ON transactions(user_id, transaction_date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON transactions(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_split ON transactions(parent_transaction_id)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_currency ON transactions(currency_id)',
    );

    // 6. Split Items Table
    await db.execute('''
      CREATE TABLE split_items (
        split_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category_id INTEGER,
        amount REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_split_items_transaction ON split_items(transaction_id)',
    );

    // 7. Loans Table
    await db.execute('''
      CREATE TABLE loans (
        loan_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        lender_name TEXT NOT NULL,
        loan_type TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        interest_rate REAL DEFAULT 0,
        tenure_value INTEGER,
        tenure_unit TEXT,
        start_date TEXT NOT NULL,
        due_date TEXT,
        total_paid REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_loans_user ON loans(user_id)');
    await db.execute('CREATE INDEX idx_loans_status ON loans(user_id, status)');
    await db.execute(
      'CREATE INDEX idx_loans_due_date ON loans(user_id, due_date)',
    );

    // 8. Loan Payments Table
    await db.execute('''
      CREATE TABLE loan_payments (
        loan_payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method_id INTEGER,
        principal_part REAL,
        interest_part REAL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_loan_payments_loan ON loan_payments(loan_id)',
    );
    await db.execute(
      'CREATE INDEX idx_loan_payments_date ON loan_payments(loan_id, payment_date DESC)',
    );

    // 9. Receivables Table
    await db.execute('''
      CREATE TABLE receivables (
        receivable_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipient_name TEXT NOT NULL,
        receivable_type TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        interest_rate REAL DEFAULT 0,
        expected_date TEXT,
        total_received REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_receivables_user ON receivables(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_receivables_status ON receivables(user_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_receivables_expected ON receivables(user_id, expected_date)',
    );

    // 10. Receivable Payments Table
    await db.execute('''
      CREATE TABLE receivable_payments (
        receivable_payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        receivable_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (receivable_id) REFERENCES receivables(receivable_id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_receivable_payments_receivable ON receivable_payments(receivable_id)',
    );
    await db.execute(
      'CREATE INDEX idx_receivable_payments_date ON receivable_payments(receivable_id, payment_date DESC)',
    );

    // 11. IOUs Table
    await db.execute('''
      CREATE TABLE ious (
        iou_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        creditor_name TEXT NOT NULL,
        amount REAL NOT NULL,
        reason TEXT,
        due_date TEXT,
        total_paid REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_ious_user ON ious(user_id)');
    await db.execute('CREATE INDEX idx_ious_status ON ious(user_id, status)');
    await db.execute('CREATE INDEX idx_ious_due ON ious(user_id, due_date)');

    // 12. IOU Payments Table
    await db.execute('''
      CREATE TABLE iou_payments (
        iou_payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        iou_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (iou_id) REFERENCES ious(iou_id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_iou_payments_iou ON iou_payments(iou_id)',
    );
    await db.execute(
      'CREATE INDEX idx_iou_payments_date ON iou_payments(iou_id, payment_date DESC)',
    );

    // 13. Reimbursements Table
    await db.execute('''
      CREATE TABLE reimbursements (
        reimbursement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        source_name TEXT NOT NULL,
        category TEXT,
        amount REAL NOT NULL,
        expected_date TEXT,
        total_reimbursed REAL DEFAULT 0,
        status TEXT DEFAULT 'active',
        notes TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reimbursements_user ON reimbursements(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_reimbursements_status ON reimbursements(user_id, status)',
    );
    await db.execute(
      'CREATE INDEX idx_reimbursements_expected ON reimbursements(user_id, expected_date)',
    );

    // 14. Reimbursement Payments Table
    await db.execute('''
      CREATE TABLE reimbursement_payments (
        reimbursement_payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        reimbursement_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (reimbursement_id) REFERENCES reimbursements(reimbursement_id) ON DELETE CASCADE,
        FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reimbursement_payments_reimbursement ON reimbursement_payments(reimbursement_id)',
    );
    await db.execute(
      'CREATE INDEX idx_reimbursement_payments_date ON reimbursement_payments(reimbursement_id, payment_date DESC)',
    );

    // Seed default data
    await _seedDefaultData(db);
  }

  Future<void> _seedDefaultData(Database db) async {
    // Seed currencies
    await db.insert('currencies', {
      'currency_code': 'INR',
      'currency_name': 'Indian Rupee',
      'symbol': '₹',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'USD',
      'currency_name': 'US Dollar',
      'symbol': '\$',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'EUR',
      'currency_name': 'Euro',
      'symbol': '€',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'GBP',
      'currency_name': 'British Pound',
      'symbol': '£',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'AED',
      'currency_name': 'UAE Dirham',
      'symbol': 'د.إ',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'AUD',
      'currency_name': 'Australian Dollar',
      'symbol': 'A\$',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'CAD',
      'currency_name': 'Canadian Dollar',
      'symbol': 'C\$',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'SGD',
      'currency_name': 'Singapore Dollar',
      'symbol': 'S\$',
      'decimal_places': 2,
    });
    await db.insert('currencies', {
      'currency_code': 'JPY',
      'currency_name': 'Japanese Yen',
      'symbol': '¥',
      'decimal_places': 0,
    });
    await db.insert('currencies', {
      'currency_code': 'CNY',
      'currency_name': 'Chinese Yuan',
      'symbol': '¥',
      'decimal_places': 2,
    });

    // Create default user
    await db.insert('users', {
      'name': 'User',
      'theme_preference': 'system',
      'theme_color': 'Emerald Green',
      'primary_currency_id': 1,
    });

    // Seed default categories for user_id = 1
    final categories = [
      {
        'name': 'Food & Dining',
        'description': 'Groceries, Restaurants, Takeout',
        'icon_name': 'restaurant_rounded',
        'color_hex': '#FFD93D',
        'display_order': 1,
      },
      {
        'name': 'Transportation',
        'description': 'Fuel, Public Transit, Parking',
        'icon_name': 'directions_car_rounded',
        'color_hex': '#4D96FF',
        'display_order': 2,
      },
      {
        'name': 'Shopping',
        'description': 'Clothing, Electronics, General',
        'icon_name': 'shopping_bag_rounded',
        'color_hex': '#F72585',
        'display_order': 3,
      },
      {
        'name': 'Housing',
        'description': 'Rent, Mortgage, Home Repairs',
        'icon_name': 'cottage_rounded',
        'color_hex': '#FF6B6B',
        'display_order': 4,
      },
      {
        'name': 'Utilities',
        'description': 'Electricity, Water, Gas, Internet',
        'icon_name': 'flash_on_rounded',
        'color_hex': '#06D6A0',
        'display_order': 5,
      },
      {
        'name': 'Entertainment',
        'description': 'Movies, Games, Events, Hobbies',
        'icon_name': 'theater_comedy_rounded',
        'color_hex': '#9D4EDD',
        'display_order': 6,
      },
      {
        'name': 'Health & Fitness',
        'description': 'Doctor, Gym, Pharmacy, Sports',
        'icon_name': 'favorite_rounded',
        'color_hex': '#06D6A0',
        'display_order': 7,
      },
      {
        'name': 'Education',
        'description': 'Tuition, Books, Courses, Training',
        'icon_name': 'school_rounded',
        'color_hex': '#5361FC',
        'display_order': 8,
      },
      {
        'name': 'Travel',
        'description': 'Flights, Hotels, Vacations',
        'icon_name': 'flight_takeoff_rounded',
        'color_hex': '#4CC9F0',
        'display_order': 9,
      },
      {
        'name': 'Insurance',
        'description': 'Health, Life, Vehicle, Property',
        'icon_name': 'security_rounded',
        'color_hex': '#8B5CF6',
        'display_order': 10,
      },
      {
        'name': 'Investments',
        'description': 'Stocks, Mutual Funds, Savings',
        'icon_name': 'trending_up_rounded',
        'color_hex': '#2EC4B6',
        'display_order': 11,
      },
      {
        'name': 'Subscriptions',
        'description': 'Netflix, Spotify, Apps, Memberships',
        'icon_name': 'subscriptions_rounded',
        'color_hex': '#F97316',
        'display_order': 12,
      },
      {
        'name': 'Personal Care',
        'description': 'Salon, Spa, Grooming',
        'icon_name': 'face_rounded',
        'color_hex': '#EC4899',
        'display_order': 13,
      },
      {
        'name': 'Gifts & Donations',
        'description': 'Birthdays, Charity, Contributions',
        'icon_name': 'card_giftcard_rounded',
        'color_hex': '#FB8B24',
        'display_order': 14,
      },
      {
        'name': 'Pets',
        'description': 'Food, Vet, Toys, Grooming',
        'icon_name': 'pets_rounded',
        'color_hex': '#E07A5F',
        'display_order': 15,
      },
      {
        'name': 'Kids & Family',
        'description': 'Childcare, School, Activities',
        'icon_name': 'family_restroom_rounded',
        'color_hex': '#FCA5A5',
        'display_order': 16,
      },
      {
        'name': 'Taxes',
        'description': 'Income Tax, Property Tax, GST',
        'icon_name': 'receipt_long_rounded',
        'color_hex': '#DC2626',
        'display_order': 17,
      },
      {
        'name': 'Business',
        'description': 'Office Supplies, Client Meetings',
        'icon_name': 'work_rounded',
        'color_hex': '#0EA5E9',
        'display_order': 18,
      },
      {
        'name': 'Miscellaneous',
        'description': 'Other Expenses',
        'icon_name': 'category_rounded',
        'color_hex': '#94A3B8',
        'display_order': 19,
      },
      {
        'name': 'Groceries',
        'description': 'Supermarket, Fresh Produce',
        'icon_name': 'shopping_cart_rounded',
        'color_hex': '#10B981',
        'display_order': 20,
      },
      {
        'name': 'Bills & EMIs',
        'description': 'Credit Cards, Loan EMIs, Bills',
        'icon_name': 'receipt_rounded',
        'color_hex': '#EF4444',
        'display_order': 21,
      },
      {
        'name': 'Beauty & Cosmetics',
        'description': 'Makeup, Skincare Products',
        'icon_name': 'auto_awesome_rounded',
        'color_hex': '#DB2777',
        'display_order': 22,
      },
      {
        'name': 'Home Improvement',
        'description': 'Furniture, Decor, Renovations',
        'icon_name': 'home_repair_service_rounded',
        'color_hex': '#D97706',
        'display_order': 23,
      },
      {
        'name': 'Charity & Religion',
        'description': 'Temple, Church, Donations',
        'icon_name': 'volunteer_activism_rounded',
        'color_hex': '#7C3AED',
        'display_order': 24,
      },
    ];

    for (final category in categories) {
      await db.insert('categories', {
        'user_id': 1,
        'name': category['name'],
        'description': category['description'],
        'icon_name': category['icon_name'],
        'color_hex': category['color_hex'],
        'is_system': 1,
        'display_order': category['display_order'],
      });
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
