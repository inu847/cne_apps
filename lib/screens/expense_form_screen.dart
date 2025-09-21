import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_category_provider.dart';
import '../models/expense_model.dart';
import '../config/api_config.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormScreen({Key? key, this.expense}) : super(key: key);

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  String _selectedPaymentMethod = 'cash';
  bool _isRecurring = false;
  String? _recurringFrequency;
  DateTime? _recurringEndDate;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeFormWithExpense();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseCategoryProvider>().fetchExpenseCategories();
    });
  }

  void _initializeFormWithExpense() {
    final expense = widget.expense!;
    _descriptionController.text = expense.description ?? '';
    _amountController.text = expense.amount.toString();
    _referenceController.text = expense.reference ?? '';
    _selectedDate = expense.date;
    _selectedCategoryId = expense.expenseCategoryId;
    _selectedPaymentMethod = expense.paymentMethod;
    _isRecurring = expense.isRecurring;
    _recurringFrequency = expense.recurringFrequency;
    _recurringEndDate = expense.recurringEndDate;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Dompet Kasir - POS | Edit Pengeluaran' : 'Dompet Kasir - POS | Tambah Pengeluaran',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ApiConfig.backgroundColor,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: ApiConfig.primaryColor,
        foregroundColor: ApiConfig.backgroundColor,
        elevation: 4,
        shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        actions: [
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              if (provider.isCreating || provider.isUpdating) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _submitForm(provider),
                  tooltip: 'Simpan',
                );
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informasi Pengeluaran
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildAmountField(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Detail Transaksi
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildPaymentMethodField(),
                    const SizedBox(height: 16),
                    _buildReferenceField(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Pengaturan Berulang
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan Berulang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRecurringSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                return _buildSubmitButton(provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Deskripsi *',
        hintText: 'Masukkan deskripsi pengeluaran',
        prefixIcon: Icon(Icons.description, color: ApiConfig.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Deskripsi tidak boleh kosong';
        }
        return null;
      },
      maxLines: 2,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Jumlah *',
        hintText: 'Masukkan jumlah pengeluaran',
        prefixIcon: Icon(Icons.attach_money, color: ApiConfig.primaryColor),
        prefixText: 'Rp ',
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
          return 'Jumlah tidak boleh kosong';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Jumlah harus berupa angka positif';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return Consumer<ExpenseCategoryProvider>(
      builder: (context, categoryProvider, child) {
        return DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'Kategori *',
            hintText: 'Pilih kategori pengeluaran',
            prefixIcon: Icon(Icons.category, color: ApiConfig.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
            ),
          ),
          items: categoryProvider.expenseCategories.map((category) {
            return DropdownMenuItem<int>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
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

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(),
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
          DateFormat('dd MMMM yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final paymentMethods = provider.getPaymentMethods();
        return DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          decoration: InputDecoration(
            labelText: 'Metode Pembayaran *',
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
              _selectedPaymentMethod = value!;
            });
          },
        );
      },
    );
  }

  Widget _buildReferenceField() {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: 'Referensi (Opsional)',
        hintText: 'Masukkan nomor referensi',
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

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Pengeluaran Berulang'),
          subtitle: const Text('Aktifkan jika pengeluaran ini berulang secara berkala'),
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value ?? false;
              if (!_isRecurring) {
                _recurringFrequency = null;
                _recurringEndDate = null;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              final frequencies = provider.getRecurringFrequencies();
              return DropdownButtonFormField<String>(
                value: _recurringFrequency,
                decoration: InputDecoration(
                  labelText: 'Frekuensi Berulang *',
                  hintText: 'Pilih frekuensi',
                  prefixIcon: Icon(Icons.repeat, color: ApiConfig.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                  ),
                ),
                items: frequencies.map((freq) {
                  return DropdownMenuItem<String>(
                    value: freq['value'],
                    child: Text(freq['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _recurringFrequency = value;
                  });
                },
                validator: _isRecurring ? (value) {
                  if (value == null) {
                    return 'Frekuensi berulang harus dipilih';
                  }
                  return null;
                } : null,
              );
            },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectRecurringEndDate(),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Tanggal Berakhir (Opsional)',
                prefixIcon: Icon(Icons.event_busy, color: ApiConfig.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                ),
              ),
              child: Text(
                _recurringEndDate != null
                    ? DateFormat('dd MMMM yyyy').format(_recurringEndDate!)
                    : 'Pilih tanggal berakhir',
                style: TextStyle(
                  fontSize: 16,
                  color: _recurringEndDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(ExpenseProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: provider.isCreating || provider.isUpdating
            ? null
            : () => _submitForm(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: ApiConfig.primaryColor,
          foregroundColor: ApiConfig.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: provider.isCreating || provider.isUpdating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ApiConfig.backgroundColor),
                ),
              )
            : Text(
                _isEditing ? 'Update Pengeluaran' : 'Simpan Pengeluaran',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectRecurringEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurringEndDate ?? _selectedDate.add(const Duration(days: 30)),
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _recurringEndDate = picked;
      });
    }
  }

  Future<void> _submitForm(ExpenseProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create Expense object
    final expense = Expense(
      id: widget.expense?.id ?? 0, // Will be ignored for create
      expenseCategoryId: _selectedCategoryId!,
      warehouseId: 1, // Default warehouse
      userId: 1, // Will be set by backend
      reference: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      date: _selectedDate,
      amount: double.parse(_amountController.text),
      paymentMethod: _selectedPaymentMethod,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      attachment: null,
      isRecurring: _isRecurring,
      recurringFrequency: _isRecurring ? _recurringFrequency : null,
      recurringEndDate: _isRecurring ? _recurringEndDate : null,
      isApproved: false,
      approvedBy: null,
      approvedAt: null,
      createdAt: DateTime.now(), // Will be set by backend
      updatedAt: DateTime.now(), // Will be set by backend
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateExpense(widget.expense!.id, expense);
    } else {
      success = await provider.createExpense(expense);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing 
              ? 'Pengeluaran berhasil diperbarui' 
              : 'Pengeluaran berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan pengeluaran'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}