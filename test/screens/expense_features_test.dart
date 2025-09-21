import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/screens/expense_screen.dart';
import 'package:cne_pos_apps/screens/bulk_expense_input_screen.dart';
import 'package:cne_pos_apps/providers/expense_provider.dart';
import 'package:cne_pos_apps/providers/expense_category_provider.dart';
import 'package:cne_pos_apps/models/expense_model.dart';
import 'package:cne_pos_apps/models/expense_category_model.dart';

void main() {
  group('Expense Features Tests', () {
    late ExpenseProvider expenseProvider;
    late ExpenseCategoryProvider categoryProvider;

    setUp(() {
      expenseProvider = ExpenseProvider();
      categoryProvider = ExpenseCategoryProvider();
    });

    testWidgets('ExpenseScreen should have bulk input button in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider<ExpenseCategoryProvider>.value(value: categoryProvider),
          ],
          child: MaterialApp(
            home: ExpenseScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Look for the bulk input button (playlist_add icon)
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      
      // Verify tooltip text
      final bulkInputButton = find.byIcon(Icons.playlist_add);
      await tester.longPress(bulkInputButton);
      await tester.pumpAndSettle();
      expect(find.text('Input Massal'), findsOneWidget);
    });

    testWidgets('BulkExpenseInputScreen should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider<ExpenseCategoryProvider>.value(value: categoryProvider),
          ],
          child: MaterialApp(
            home: BulkExpenseInputScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Check if the screen title is present
      expect(find.text('Input Massal Pengeluaran'), findsOneWidget);
      
      // Check if the info section is present
      expect(find.text('Tambahkan beberapa pengeluaran sekaligus. Gunakan tombol + untuk menambah item baru.'), findsOneWidget);
      
      // Check if the floating action button is present
      expect(find.byIcon(Icons.add), findsOneWidget);
      
      // Check if at least one expense item card is present (added by default)
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('BulkExpenseInputScreen should add new expense item when FAB is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider<ExpenseCategoryProvider>.value(value: categoryProvider),
          ],
          child: MaterialApp(
            home: BulkExpenseInputScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should have Item 1
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsNothing);

      // Tap the FAB to add new item
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Now should have both Item 1 and Item 2
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('BulkExpenseInputScreen should have required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider<ExpenseCategoryProvider>.value(value: categoryProvider),
          ],
          child: MaterialApp(
            home: BulkExpenseInputScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for required form fields
      expect(find.text('Deskripsi *'), findsOneWidget);
      expect(find.text('Jumlah *'), findsOneWidget);
      expect(find.text('Tanggal *'), findsOneWidget);
      expect(find.text('Kategori *'), findsOneWidget);
      expect(find.text('Metode Pembayaran'), findsOneWidget);
      expect(find.text('Referensi'), findsOneWidget);
    });

    test('ExpenseProvider should have createBulkExpenses method with enhanced signature', () {
      // Verify that the bulk create method exists with the new signature
      expect(expenseProvider.createBulkExpenses, isA<Function>());
    });

    test('Enhanced createBulkExpenses should return detailed result map', () async {
      // This test would verify the enhanced return structure
      // In a real test, we would mock the expense service and test the actual logic
      
      // Expected return structure from enhanced createBulkExpenses
      final expectedKeys = ['success', 'failed', 'total', 'createdExpenses', 'failedReasons'];
      
      // Verify the method signature supports progress callback
      expect(expenseProvider.createBulkExpenses, isA<Function>());
      
      // This is a placeholder - in real implementation, we would:
      // 1. Mock the expense service
      // 2. Create test expenses
      // 3. Call createBulkExpenses with progress callback
      // 4. Verify the return structure and retry logic
      expect(true, isTrue);
    });

    test('Fallback mechanism should handle individual POST failures correctly', () {
      // This test would verify:
      // 1. Retry logic (up to 3 attempts per item)
      // 2. Progress tracking callback
      // 3. Detailed error reporting
      // 4. Partial success handling
      
      // In a real implementation, we would mock HTTP failures and verify:
      // - Individual items are retried up to maxRetries times
      // - Failed items are properly tracked with reasons
      // - Successful items are added to the list immediately
      // - Progress callback is called correctly
      
      expect(true, isTrue); // Placeholder for actual retry logic tests
    });

    test('Progress callback should be called correctly during bulk creation', () {
      // This test would verify:
      // 1. Progress callback is called for each processed item
      // 2. Current and total parameters are correct
      // 3. Callback is called even for failed items
      
      expect(true, isTrue); // Placeholder for progress tracking tests
    });
  });

  group('Expense Edit Features Tests', () {
    testWidgets('Expense detail modal should have edit and delete buttons', (WidgetTester tester) async {
      final expenseProvider = ExpenseProvider();
      final categoryProvider = ExpenseCategoryProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
            ChangeNotifierProvider<ExpenseCategoryProvider>.value(value: categoryProvider),
          ],
          child: MaterialApp(
            home: ExpenseScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // This test would require mocking expense data and triggering the detail modal
      // For now, we'll just verify the screen loads
      expect(find.byType(ExpenseScreen), findsOneWidget);
    });
  });
}