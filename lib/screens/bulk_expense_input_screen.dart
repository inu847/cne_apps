import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_category_provider.dart';
import '../models/expense_model.dart';
import '../models/expense_category_model.dart' as category_model;
import '../config/api_config.dart';
import '../services/auth_service.dart';

class BulkExpenseInputScreen extends StatefulWidget {
  const BulkExpenseInputScreen({Key? key}) : super(key: key);

  @override
  State<BulkExpenseInputScreen> createState() => _BulkExpenseInputScreenState();
}

class _BulkExpenseInputScreenState extends State<BulkExpenseInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  List<ExpenseItem> _expenseItems = [];
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseCategoryProvider>().fetchExpenseCategories();
      _addNewExpenseItem();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var item in _expenseItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewExpenseItem() {
    setState(() {
      _expenseItems.add(ExpenseItem());
    });
  }

  void _removeExpenseItem(int index) {
    if (_expenseItems.length > 1) {
      setState(() {
        _expenseItems[index].dispose();
        _expenseItems.removeAt(index);
      });
    }
  }

  void _duplicateExpenseItem(int index) {
    final originalItem = _expenseItems[index];
    setState(() {
      _expenseItems.insert(index + 1, ExpenseItem.fromExpenseItem(originalItem));
    });
  }

  Future<void> _submitBulkExpenses() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Mengirim Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Mengirim pengeluaran satu per satu...\nMohon tunggu sebentar.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Progress: 0/${_expenseItems.where((item) => item.isValid()).length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      
      if (user == null) {
        throw Exception('User tidak ditemukan');
      }

      final provider = context.read<ExpenseProvider>();
      
      // Prepare list of valid expenses
      List<Expense> validExpenses = [];
      for (var item in _expenseItems) {
        if (item.isValid()) {
          // Validate and parse amount more safely
          String amountText = item.amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
          double? parsedAmount = double.tryParse(amountText);
          
          if (parsedAmount == null || parsedAmount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Amount tidak valid untuk item: ${item.descriptionController.text}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
            return;
          }

          // Validate required fields more thoroughly
          if (item.selectedCategoryId == null || item.selectedCategoryId! <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kategori harus dipilih untuk item: ${item.descriptionController.text}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
            return;
          }

          if (item.selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tanggal harus dipilih untuk item: ${item.descriptionController.text}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
            return;
          }

          final expense = Expense(
            id: 0,
            userId: user.id,
            warehouseId: user.warehouseId ?? 1,
            expenseCategoryId: item.selectedCategoryId!,
            description: item.descriptionController.text.trim(),
            amount: parsedAmount,
            date: item.selectedDate!,
            paymentMethod: item.selectedPaymentMethod ?? 'cash',
            reference: item.referenceController.text.trim().isNotEmpty 
                ? item.referenceController.text.trim() 
                : null,
            isRecurring: false,
            isApproved: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          validExpenses.add(expense);
        }
      }

      // Use bulk create method with progress callback
      final result = await provider.createBulkExpenses(
        validExpenses,
        onProgress: (current, total) {
          // Update progress dialog
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Mengirim Data'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: current / total,
                        valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Mengirim pengeluaran satu per satu...\nMohon tunggu sebentar.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Progress: $current/$total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      );

      // Close progress dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      final successCount = result['success'] ?? 0;
      final failCount = result['failed'] ?? 0;
      final total = result['total'] ?? 0;
      final failedReasons = result['failedReasons'] as List<String>? ?? [];

      if (mounted) {
        // Show detailed result dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                failCount == 0 ? 'Berhasil!' : 'Selesai dengan Peringatan',
                style: TextStyle(
                  color: failCount == 0 ? Colors.green : Colors.orange,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total item: $total'),
                  Text('Berhasil: $successCount', style: TextStyle(color: Colors.green)),
                  if (failCount > 0) ...[
                    Text('Gagal: $failCount', style: TextStyle(color: Colors.red)),
                    SizedBox(height: 8),
                    if (failedReasons.isNotEmpty) ...[
                      Text('Detail kegagalan:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Container(
                        height: 100,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: failedReasons.map((reason) => 
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  reason,
                                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                                ),
                              )
                            ).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (successCount > 0) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close progress dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Input Massal Pengeluaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _expenseItems.any((item) => item.isValid()) 
                ? _submitBulkExpenses 
                : null,
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: ApiConfig.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ApiConfig.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tambahkan beberapa pengeluaran sekaligus. Gunakan tombol + untuk menambah item baru.',
                      style: TextStyle(
                        color: ApiConfig.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _expenseItems.length,
                itemBuilder: (context, index) {
                  return _buildExpenseItemCard(index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewExpenseItem,
        backgroundColor: ApiConfig.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Item Baru',
      ),
    );
  }

  Widget _buildExpenseItemCard(int index) {
    final item = _expenseItems[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ApiConfig.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Item ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) {
                    if (value == 'duplicate') {
                      _duplicateExpenseItem(index);
                    } else if (value == 'delete') {
                      _removeExpenseItem(index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Duplikat'),
                        ],
                      ),
                    ),
                    if (_expenseItems.length > 1)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDescriptionField(item),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAmountField(item)),
                const SizedBox(width: 12),
                Expanded(child: _buildDateField(item)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCategoryField(item)),
                const SizedBox(width: 12),
                Expanded(child: _buildPaymentMethodField(item)),
              ],
            ),
            const SizedBox(height: 16),
            _buildReferenceField(item),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(ExpenseItem item) {
    return TextFormField(
      controller: item.descriptionController,
      decoration: InputDecoration(
        labelText: 'Deskripsi *',
        prefixIcon: Icon(Icons.description, color: ApiConfig.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Deskripsi harus diisi';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(ExpenseItem item) {
    return TextFormField(
      controller: item.amountController,
      decoration: InputDecoration(
        labelText: 'Jumlah *',
        prefixIcon: Icon(Icons.attach_money, color: ApiConfig.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Jumlah harus diisi';
        }
        final amount = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
        if (amount == null || amount <= 0) {
          return 'Jumlah harus valid';
        }
        return null;
      },
      onChanged: (value) {
        // Format currency input
        if (value.isNotEmpty) {
          final number = value.replaceAll(RegExp(r'[^\d]'), '');
          if (number.isNotEmpty) {
            final formatted = NumberFormat('#,###').format(int.parse(number));
            item.amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        }
      },
    );
  }

  Widget _buildDateField(ExpenseItem item) {
    return InkWell(
      onTap: () => _selectDate(item),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Tanggal *',
          prefixIcon: Icon(Icons.calendar_today, color: ApiConfig.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
          ),
        ),
        child: Text(
          item.selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(item.selectedDate!)
              : 'Pilih tanggal',
          style: TextStyle(
            color: item.selectedDate != null ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField(ExpenseItem item) {
    return Consumer<ExpenseCategoryProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<int>(
          value: item.selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Kategori *',
            prefixIcon: Icon(Icons.category, color: ApiConfig.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
            ),
          ),
          items: provider.expenseCategories.map<DropdownMenuItem<int>>((category_model.ExpenseCategory category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              item.selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Kategori harus dipilih';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodField(ExpenseItem item) {
    // Use the same payment methods as defined in ExpenseService
    final paymentMethods = [
      {'value': 'cash', 'label': 'Tunai'},
      {'value': 'bank_transfer', 'label': 'Transfer Bank'},
      {'value': 'credit_card', 'label': 'Kartu Kredit'},
    ];
    
    return DropdownButtonFormField<String>(
      value: item.selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Metode Pembayaran',
        prefixIcon: Icon(Icons.payment, color: ApiConfig.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
        ),
      ),
      items: paymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method['value'],
          child: Text(method['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          item.selectedPaymentMethod = value;
        });
      },
    );
  }

  Widget _buildReferenceField(ExpenseItem item) {
    return TextFormField(
      controller: item.referenceController,
      decoration: InputDecoration(
        labelText: 'Referensi',
        prefixIcon: Icon(Icons.receipt, color: ApiConfig.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
        ),
      ),
    );
  }

  Future<void> _selectDate(ExpenseItem item) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: item.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ApiConfig.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        item.selectedDate = picked;
      });
    }
  }
}

class ExpenseItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();
  
  DateTime? selectedDate;
  int? selectedCategoryId;
  String? selectedPaymentMethod = 'cash';

  ExpenseItem() {
    selectedDate = DateTime.now();
  }

  ExpenseItem.fromExpenseItem(ExpenseItem other) {
    descriptionController.text = other.descriptionController.text;
    amountController.text = other.amountController.text;
    referenceController.text = other.referenceController.text;
    selectedDate = other.selectedDate;
    selectedCategoryId = other.selectedCategoryId;
    selectedPaymentMethod = other.selectedPaymentMethod;
  }

  bool isValid() {
    // Check if description is not empty
    if (descriptionController.text.trim().isEmpty) return false;
    
    // Check if amount is not empty and is a valid number > 0
    String amountText = amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;
    
    // Check if date is selected
    if (selectedDate == null) return false;
    
    // Check if category is selected and valid
    if (selectedCategoryId == null || selectedCategoryId! <= 0) return false;
    
    // Check if payment method is selected
    if (selectedPaymentMethod == null || selectedPaymentMethod!.isEmpty) return false;
    
    return true;
  }

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
    referenceController.dispose();
  }
}