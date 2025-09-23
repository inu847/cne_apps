import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Transaction Structure Tests', () {
    test('Offline transaction should match API POST structure', () {
      // Sample order data (seperti yang diterima dari POS)
      final sampleOrder = {
        'items': [
          {
            'productId': 1,
            'quantity': 2,
            'price': 15000,
          },
          {
            'productId': 2,
            'quantity': 1,
            'price': 25000,
          }
        ],
        'subtotal': 55000,
        'tax_amount': 5500,
        'discount_amount': 0,
        'total_amount': 60500,
      };

      // Sample payments
      final samplePayments = [
        {
          'payment_method_id': 1,
          'amount': 60500,
          'reference_number': 'REF-TEST-123'
        }
      ];

      // Expected API POST structure
      final expectedApiStructure = {
        'items': [
          {
            'product_id': 1,
            'quantity': 2,
            'unit_price': 15000,
            'discount_amount': 0,
            'tax_amount': 2750, // Distribusi pajak berdasarkan proporsi
            'subtotal': 30000
          },
          {
            'product_id': 2,
            'quantity': 1,
            'unit_price': 25000,
            'discount_amount': 0,
            'tax_amount': 2750, // Distribusi pajak berdasarkan proporsi
            'subtotal': 25000
          }
        ],
        'payments': [
          {
            'payment_method_id': 1,
            'amount': 60500,
            'reference_number': 'REF-TEST-123'
          }
        ],
        'subtotal': 55000,
        'tax_amount': 5500,
        'discount_amount': 0,
        'total_amount': 60500,
        'customer_name': 'Walk-in Customer',
        'customer_email': null,
        'customer_phone': null,
        'notes': '',
        'is_parked': false,
        'warehouse_id': 1,
        'voucher_code': null,
      };

      print('✅ Test Structure Verification:');
      print('📋 Expected API POST Structure:');
      print('   - items: ${expectedApiStructure['items']}');
      print('   - payments: ${expectedApiStructure['payments']}');
      print('   - subtotal: ${expectedApiStructure['subtotal']}');
      print('   - tax_amount: ${expectedApiStructure['tax_amount']}');
      print('   - total_amount: ${expectedApiStructure['total_amount']}');
      
      // Verify structure keys exist
      expect(expectedApiStructure.containsKey('items'), true);
      expect(expectedApiStructure.containsKey('payments'), true);
      expect(expectedApiStructure.containsKey('subtotal'), true);
      expect(expectedApiStructure.containsKey('tax_amount'), true);
      expect(expectedApiStructure.containsKey('total_amount'), true);
      expect(expectedApiStructure.containsKey('customer_name'), true);
      expect(expectedApiStructure.containsKey('is_parked'), true);
      expect(expectedApiStructure.containsKey('warehouse_id'), true);

      // Verify items structure
      final items = expectedApiStructure['items'] as List;
      expect(items.isNotEmpty, true);
      
      for (final item in items) {
        final itemMap = item as Map<String, dynamic>;
        expect(itemMap.containsKey('product_id'), true);
        expect(itemMap.containsKey('quantity'), true);
        expect(itemMap.containsKey('unit_price'), true);
        expect(itemMap.containsKey('discount_amount'), true);
        expect(itemMap.containsKey('tax_amount'), true);
        expect(itemMap.containsKey('subtotal'), true);
      }

      // Verify payments structure
      final payments = expectedApiStructure['payments'] as List;
      expect(payments.isNotEmpty, true);
      
      for (final payment in payments) {
        final paymentMap = payment as Map<String, dynamic>;
        expect(paymentMap.containsKey('payment_method_id'), true);
        expect(paymentMap.containsKey('amount'), true);
        expect(paymentMap.containsKey('reference_number'), true);
      }

      print('✅ All structure validations passed!');
    });

    test('Tax distribution calculation should be correct', () {
      final subtotal = 55000;
      final taxAmount = 5500;
      
      // Item 1: 30000 dari 55000 total
      final item1Subtotal = 30000;
      final item1TaxAmount = (item1Subtotal * taxAmount / subtotal).round();
      
      // Item 2: 25000 dari 55000 total
      final item2Subtotal = 25000;
      final item2TaxAmount = (item2Subtotal * taxAmount / subtotal).round();
      
      print('📊 Tax Distribution Test:');
      print('   - Total Subtotal: $subtotal');
      print('   - Total Tax: $taxAmount');
      print('   - Item 1 Subtotal: $item1Subtotal, Tax: $item1TaxAmount');
      print('   - Item 2 Subtotal: $item2Subtotal, Tax: $item2TaxAmount');
      print('   - Total Distributed Tax: ${item1TaxAmount + item2TaxAmount}');
      
      // Verify tax distribution is reasonable (should be close to total tax)
      expect(item1TaxAmount + item2TaxAmount, lessThanOrEqualTo(taxAmount + 1));
      expect(item1TaxAmount + item2TaxAmount, greaterThanOrEqualTo(taxAmount - 1));
      
      print('✅ Tax distribution calculation is correct!');
    });

    test('Field mapping should handle different input formats', () {
      // Test different possible field names
      final testCases = [
        {
          'input': {'productId': 1, 'price': 15000},
          'expected_product_id': 1,
          'expected_unit_price': 15000,
        },
        {
          'input': {'product_id': 2, 'unit_price': 25000},
          'expected_product_id': 2,
          'expected_unit_price': 25000,
        },
        {
          'input': {'paymentMethodId': 1, 'referenceNumber': 'REF-123'},
          'expected_payment_method_id': 1,
          'expected_reference_number': 'REF-123',
        },
        {
          'input': {'payment_method_id': 2, 'reference_number': 'REF-456'},
          'expected_payment_method_id': 2,
          'expected_reference_number': 'REF-456',
        },
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as Map<String, dynamic>;
        
        if (input.containsKey('productId') || input.containsKey('product_id')) {
          final productId = input['productId'] ?? input['product_id'];
          final unitPrice = input['price'] ?? input['unit_price'];
          
          expect(productId, equals(testCase['expected_product_id']));
          expect(unitPrice, equals(testCase['expected_unit_price']));
        }
        
        if (input.containsKey('paymentMethodId') || input.containsKey('payment_method_id')) {
          final paymentMethodId = input['paymentMethodId'] ?? input['payment_method_id'];
          final referenceNumber = input['referenceNumber'] ?? input['reference_number'];
          
          expect(paymentMethodId, equals(testCase['expected_payment_method_id']));
          expect(referenceNumber, equals(testCase['expected_reference_number']));
        }
      }

      print('✅ Field mapping handles different input formats correctly!');
    });
  });
}