# ExpenseTrackerAIFlutter - Codebase Summary

This document summarizes the current codebase structure and implemented product features so future AI sessions can quickly understand what exists.

## 1) Tech Stack and Architecture

- Framework: Flutter (`MaterialApp`), portrait mode only
- State management: `provider`
- Local database: `sqflite` (SQLite) with migrations
- AI integration: `google_generative_ai` (Gemini)
- Speech input: `speech_to_text`
- Receipt image input: `image_picker`
- Persistence/settings: `shared_preferences`
- Data export/import: CSV/XLSX + backup/restore

App entry:
- `lib/main.dart`
- Launch screen and initialization: `lib/screens/splash_screen.dart`

Core providers:
- `ThemeProvider` (`lib/providers/theme_provider.dart`)
- `ProfileProvider` (`lib/providers/profile_provider.dart`)
- `ChatProvider` (`lib/providers/chat_provider.dart`)
- `ExpenseProvider` exists but is demo-style in-memory sample data (`lib/providers/expense_provider.dart`)

## 2) Navigation and Main Surfaces

Main shell:
- `HomeScreen` with bottom tabs:
  - Dashboard
  - All Transactions
  - Budget
  - Profile
- File: `lib/screens/home_screen.dart`

Quick add paths from Home:
- Add expense (single tap on center +)
- AI quick menu (double-tap on center +):
  - Text/Voice AI (`NaturalLanguageEntryScreen`)
  - Receipt AI (`ScanReceiptScreen`)

## 3) Data Layer Overview

DB helper:
- `lib/database/database_helper.dart`
- Current schema version: `8`

Main tables (high level):
- Core: `users`, `currencies`, `profiles`, `categories`, `payment_methods`, `transactions`, `split_items`, `budgets`, `ai_history`
- Debt/asset tracking:
  - `loans`, `loan_payments`
  - `ious`, `iou_payments`
  - `receivables`, `receivable_payments`
  - `reimbursements`, `reimbursement_payments`

Service layer:
- `lib/database/services/*`
- Notable services:
  - `transaction_service.dart`
  - `split_transaction_service.dart`
  - `analytics_service.dart`
  - `all_transactions_service.dart`
  - `budget_service.dart`
  - `ai_service.dart`
  - domain services for loan/iou/receivable/reimbursement/profile/user/category/payment method

## 4) Implemented Features

### A. Expense Tracking

- Create simple expense
- Edit/delete expense
- Payment method and category selection
- Date and note support
- Recent expenses on dashboard
- Full transaction list with pagination and type filters

Key files:
- `lib/screens/add_expense_screen.dart`
- `lib/screens/edit_expense_screen.dart`
- `lib/screens/transaction_details_screen.dart`
- `lib/screens/all_transactions_screen.dart`
- `lib/database/services/transaction_service.dart`
- `lib/database/services/all_transactions_service.dart`

### B. Split Expense Support

- Add expense as split bill
- Add/remove line items (name/category/amount)
- Validate split total == parent total
- Dedicated split expense detail/edit screens
- Split persistence through `split_items`

Key files:
- `lib/screens/add_expense_screen.dart`
- `lib/screens/add_split_item_screen.dart`
- `lib/screens/split_expense_detail_screen.dart`
- `lib/screens/edit_split_expense_screen.dart`
- `lib/database/services/split_transaction_service.dart`

### C. AI-Assisted Expense Entry

1) Natural language parsing:
- Text/voice prompt -> parse amount/category/payment/date/note
- Opens prefilled Add Expense screen

2) Receipt parsing:
- Image -> parse amount/category/payment/date/note
- Opens prefilled Add Expense screen

3) Split detection in AI parsing:
- AI prompt supports `is_split` + `split_items`
- Output normalization logic aligns categories/payment methods and totals
- Add Expense can receive initial split mode/items

Key files:
- `lib/screens/natural_language_entry_screen.dart`
- `lib/screens/scan_receipt_screen.dart`
- `lib/database/services/ai_service.dart`
- `lib/screens/add_expense_screen.dart`

### D. AI Financial Therapist + AI History

- Chat interface with financial context
- Context built from spending, categories, budgets, and recent transactions
- AI chat/voice/receipt interactions saved to AI history table
- History per profile with retention culling

Key files:
- `lib/screens/financial_therapist_screen.dart`
- `lib/providers/chat_provider.dart`
- `lib/screens/ai_history_screen.dart`
- `lib/database/services/ai_history_service.dart`
- `lib/database/services/ai_service.dart`

### E. Calendar + Analytics

- Expense calendar heatmap by day
- Day drill-down transaction list
- Detailed category spending analytics (donut + category cards)
- Monthly comparison and payment correlation screens

Key files:
- `lib/screens/expense_calendar_screen.dart`
- `lib/screens/detailed_spending_analytics_screen.dart`
- `lib/screens/monthly_comparison_screen.dart`
- `lib/screens/payment_correlation_screen.dart`
- `lib/database/services/analytics_service.dart`

### F. Budgeting

- Monthly category budgets
- Budget setup/edit
- Budget carry-over behavior for months with no explicit budgets
- Monthly spent vs budget summaries

Key files:
- `lib/screens/budget_screen.dart`
- `lib/screens/set_budget_screen.dart`
- `lib/database/services/budget_service.dart`

### G. Debt and Receivables Management

- Liabilities and loans
- IOUs (money owed by user)
- Receivables and reimbursements (money owed to user)
- Payment history and progress updates

Key files:
- `lib/screens/liabilities_loans_screen.dart`
- `lib/screens/loan_detail_screen.dart`
- `lib/screens/iou_detail_screen.dart`
- `lib/screens/money_owed_screen.dart`
- `lib/screens/receivable_detail_screen.dart`
- `lib/screens/reimbursement_detail_screen.dart`
- `lib/database/services/loan_service.dart`
- `lib/database/services/iou_service.dart`
- `lib/database/services/receivable_service.dart`
- `lib/database/services/reimbursement_service.dart`

### H. Profile / Region / Currency / Theme

- Multi-profile support (region-based profiles)
- Profile switching, profile-aware records
- Currency symbol by active profile
- Theme mode and theme color selection

Key files:
- `lib/screens/region_currency_screen.dart`
- `lib/screens/edit_region_profile_screen.dart`
- `lib/providers/profile_provider.dart`
- `lib/providers/theme_provider.dart`
- `lib/screens/theme_selection_screen.dart`

### I. Data Management

- Backup (share/save)
- Restore database from file
- Report export (CSV/XLSX) with options and filters

Key files:
- `lib/screens/import_export_screen.dart`
- `lib/screens/export_report_screen.dart`
- `lib/database/services/data_management_service.dart`

## 5) Key Models

Located in `lib/models/`:
- `transaction.dart`, `split_item.dart`, `transaction_item.dart`
- `category.dart`, `payment_method.dart`, `budget.dart`
- `loan.dart`, `loan_payment.dart`
- `iou.dart`, `iou_payment.dart`
- `receivable.dart`, `receivable_payment.dart`
- `reimbursement.dart`, `reimbursement_payment.dart`
- `profile.dart`, `currency.dart`, `user.dart`
- `ai_history.dart`, `chat_message.dart`

## 6) Important Implementation Notes (for future AI context)

- Most core queries are profile-aware (`profile_id`), but check each screen/service before adding new logic.
- Some screens still contain temporary hardcoded user usage:
  - `lib/screens/detailed_spending_analytics_screen.dart` uses `const userId = 1`
  - `lib/screens/export_report_screen.dart` loads categories with `getAllCategories(1)`
- `ExpenseProvider` is not the primary source of persisted transaction data.
- AI history keeps latest 50 entries per profile (`AIHistoryService`).
- Split parent transactions are treated as top-level (`parent_transaction_id IS NULL`), with item detail in `split_items`.
- Home quick AI menu is currently hidden behind double-tap interaction on center add button.

## 7) Suggested Reading Order for New AI Sessions

1. `lib/main.dart`
2. `lib/screens/splash_screen.dart`
3. `lib/screens/home_screen.dart`
4. `lib/database/database_helper.dart`
5. `lib/database/services/transaction_service.dart`
6. `lib/database/services/split_transaction_service.dart`
7. `lib/database/services/analytics_service.dart`
8. `lib/database/services/ai_service.dart`
9. `lib/screens/add_expense_screen.dart`
10. `lib/screens/all_transactions_screen.dart`
11. `lib/screens/budget_screen.dart`
12. `lib/screens/profile_screen.dart`

---
Last updated: 2026-02-27
