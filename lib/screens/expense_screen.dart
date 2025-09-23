import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_category_provider.dart';
import '../models/expense_model.dart';
import '../config/api_config.dart';
import 'expense_form_screen.dart';
import 'bulk_expense_input_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isFilterExpanded = false;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedCategoryId;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().initialize();
      context.read<ExpenseCategoryProvider>().fetchExpenseCategories();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        context.read<ExpenseProvider>().loadMoreExpenses();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Menerapkan filter
  void _applyFilters() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    
    // Apply date filters
    if (_startDate != null && _endDate != null) {
      provider.setDateFilter(
        _startDate!.toIso8601String().split('T')[0],
        _endDate!.toIso8601String().split('T')[0],
      );
    }
    
    // Apply category filter
    if (_selectedCategoryId != null) {
      provider.setCategoryFilter(_selectedCategoryId);
    }
    
    // Apply payment method filter
    if (_selectedPaymentMethod != null) {
      provider.setPaymentMethodFilter(_selectedPaymentMethod);
    }
    
    setState(() {
      _isFilterExpanded = false;
    });
  }

  // Reset filter
  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedCategoryId = null;
      _selectedPaymentMethod = null;
    });
    
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.clearFilters();
  }

  // Membangun widget filter tanggal
  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dari Tanggal'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDate != null
                            ? DateFormat('dd/MM/yyyy').format(_startDate!)
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _startDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sampai Tanggal'),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _endDate != null
                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                            : 'Pilih Tanggal',
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Membangun widget filter kategori
  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori Pengeluaran'),
        const SizedBox(height: 4),
        Consumer<ExpenseCategoryProvider>(
          builder: (context, categoryProvider, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedCategoryId,
                  hint: const Text('Semua Kategori'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Kategori'),
                    ),
                    ...categoryProvider.expenseCategories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Membangun widget filter metode pembayaran
  Widget _buildPaymentMethodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Metode Pembayaran'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedPaymentMethod,
              hint: const Text('Semua Metode'),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua Metode'),
                ),
                DropdownMenuItem<String?>(
                  value: 'cash',
                  child: Text('Tunai'),
                ),
                DropdownMenuItem<String?>(
                  value: 'bank_transfer',
                  child: Text('Transfer Bank'),
                ),
                DropdownMenuItem<String?>(
                  value: 'credit_card',
                  child: Text('Kartu Kredit'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Membangun widget filter section
  Widget _buildFilterSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isFilterExpanded ? null : 0,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ApiConfig.backgroundColor,
              ApiConfig.backgroundColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ApiConfig.primaryColor.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: ApiConfig.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ApiConfig.primaryColor,
                          ApiConfig.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.filter_alt,
                      color: ApiConfig.backgroundColor,
                      size: isMobile ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Pengeluaran',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: ApiConfig.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDateFilter(),
              const SizedBox(height: 16),
              _buildCategoryFilter(),
              const SizedBox(height: 16),
              _buildPaymentMethodFilter(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ApiConfig.primaryColor, width: 2),
                      foregroundColor: ApiConfig.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ApiConfig.primaryColor,
                      foregroundColor: ApiConfig.backgroundColor,
                      elevation: 2,
                      shadowColor: ApiConfig.primaryColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 14,
                      ),
                    ),
                    child: Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dompet Kasir - POS | Manajemen Pengeluaran',
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
          IconButton(
            icon: Icon(
              Icons.playlist_add,
              color: ApiConfig.backgroundColor,
            ),
            onPressed: () => _navigateToBulkInput(),
            tooltip: 'Input Massal',
          ),
          Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              final hasActiveFilters = provider.startDate != null || 
                                    provider.endDate != null || 
                                    provider.selectedCategoryId != null || 
                                    provider.selectedPaymentMethod != null;
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      _isFilterExpanded ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: ApiConfig.backgroundColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                    tooltip: 'Filter',
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ApiConfig.backgroundColor,
            ),
            onPressed: () => context.read<ExpenseProvider>().refresh(),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.expenses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStatistics(provider),
              _buildFilterSection(),
              _buildActiveFilters(provider),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: provider.expenses.isEmpty
                      ? _buildEmptyState()
                      : _buildExpenseList(provider),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExpenseFormScreen(),
            ),
          );
        },
        backgroundColor: ApiConfig.primaryColor,
        child: Icon(Icons.add, color: ApiConfig.backgroundColor),
      ),
    );
  }

  Widget _buildStatistics(ExpenseProvider provider) {
    if (provider.statistics == null) return const SizedBox.shrink();

    final stats = provider.statistics!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ApiConfig.primaryColor, ApiConfig.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ApiConfig.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Pengeluaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(stats.summary.totalExpenses),
                  Icons.account_balance_wallet,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Jumlah',
                  '${stats.summary.totalCount} item',
                  Icons.receipt_long,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color.withOpacity(0.8)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengeluaran',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan pengeluaran pertama Anda',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(ExpenseProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.expenses.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.expenses.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final expense = provider.expenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showExpenseDetail(expense),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: expense.isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      expense.isApproved ? Icons.check_circle : Icons.pending,
                      color: expense.isApproved ? Colors.green.shade600 : Colors.orange.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description ?? 'Pengeluaran',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category, size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              expense.category?.name ?? 'Kategori tidak diketahui',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(expense.amount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (expense.paymentMethod.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expense.paymentMethod,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseDetail(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Detail Pengeluaran',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: ApiConfig.primaryColor),
                      onSelected: (value) {
                        Navigator.pop(context);
                        if (value == 'edit') {
                          _editExpense(expense);
                        } else if (value == 'delete') {
                          _deleteExpense(expense);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: ApiConfig.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailItem('Deskripsi', expense.description ?? '-'),
                      _buildDetailItem('Kategori', expense.category?.name ?? '-'),
                      _buildDetailItem('Jumlah', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(expense.amount)),
                      _buildDetailItem('Tanggal', DateFormat('dd MMMM yyyy').format(expense.date)),
                      _buildDetailItem('Metode Pembayaran', expense.paymentMethod),
                      _buildDetailItem('Status', expense.isApproved ? 'Disetujui' : 'Menunggu Persetujuan'),
                      if (expense.reference != null)
                        _buildDetailItem('Referensi', expense.reference!),
                      if (expense.isRecurring)
                        _buildDetailItem('Frekuensi Berulang', expense.recurringFrequency ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editExpense(expense);
                        },
                        icon: Icon(Icons.edit, color: ApiConfig.primaryColor),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ApiConfig.primaryColor,
                          side: BorderSide(color: ApiConfig.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteExpense(expense);
                        },
                        icon: Icon(Icons.delete, color: Colors.red.shade600),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade600),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBulkInput() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BulkExpenseInputScreen(),
      ),
    );

    if (result == true) {
      // Refresh data setelah bulk input berhasil
      context.read<ExpenseProvider>().refresh();
    }
  }

  void _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(expense: expense),
      ),
    );

    if (result == true) {
      // Refresh data setelah edit berhasil
      context.read<ExpenseProvider>().refresh();
    }
  }

  void _deleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengeluaran "${expense.description ?? 'Pengeluaran'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final provider = context.read<ExpenseProvider>();
              final success = await provider.deleteExpense(expense.id);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? 'Pengeluaran berhasil dihapus'
                        : 'Gagal menghapus pengeluaran',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final provider = context.read<ExpenseProvider>();
    final categoryProvider = context.read<ExpenseCategoryProvider>();
    
    // Initialize filter values
    DateTime? startDate = provider.startDate != null ? DateTime.parse(provider.startDate!) : DateTime.now();
    DateTime? endDate = provider.endDate != null ? DateTime.parse(provider.endDate!) : DateTime.now();
    int? selectedCategoryId = provider.selectedCategoryId;
    String? selectedPaymentMethod = provider.selectedPaymentMethod;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.filter_list, color: ApiConfig.primaryColor),
                const SizedBox(width: 8),
                const Text('Filter Pengeluaran'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range Section
                    const Text(
                      'Rentang Tanggal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Start Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
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
                            startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: ApiConfig.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tanggal Awal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    startDate != null 
                                        ? DateFormat('dd MMMM yyyy').format(startDate!)
                                        : 'Pilih tanggal awal',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // End Date
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
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
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: ApiConfig.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tanggal Akhir',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    endDate != null 
                                        ? DateFormat('dd MMMM yyyy').format(endDate!)
                                        : 'Pilih tanggal akhir',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Category Filter Section
                    const Text(
                      'Kategori Pengeluaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<ExpenseCategoryProvider>(
                      builder: (context, categoryProvider, child) {
                        return DropdownButtonFormField<int?>(
                          value: selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: 'Pilih Kategori',
                            prefixIcon: Icon(Icons.category, color: ApiConfig.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua Kategori'),
                            ),
                            ...categoryProvider.expenseCategories.map((category) {
                              return DropdownMenuItem<int?>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Payment Method Filter Section
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Pilih Metode Pembayaran',
                        prefixIcon: Icon(Icons.payment, color: ApiConfig.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Metode'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'cash',
                          child: Text('Tunai'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'bank_transfer',
                          child: Text('Transfer Bank'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'credit_card',
                          child: Text('Kartu Kredit'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Reset Button
              TextButton(
                onPressed: () {
                  setState(() {
                    startDate = DateTime.now();
                    endDate = DateTime.now();
                    selectedCategoryId = null;
                    selectedPaymentMethod = null;
                  });
                  provider.clearFilters();
                  Navigator.pop(context);
                },
                child: Text(
                  'Reset',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              
              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              
              // Apply Button
              ElevatedButton(
                onPressed: () {
                  // Apply filters
                  if (startDate != null && endDate != null) {
                    provider.setDateFilter(
                      startDate!.toIso8601String().split('T')[0],
                      endDate!.toIso8601String().split('T')[0],
                    );
                  }
                  
                  if (selectedCategoryId != null) {
                    provider.setCategoryFilter(selectedCategoryId);
                  } else {
                    provider.setCategoryFilter(null);
                  }
                  
                  if (selectedPaymentMethod != null) {
                    provider.setPaymentMethodFilter(selectedPaymentMethod);
                  } else {
                    provider.setPaymentMethodFilter(null);
                  }
                  
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ApiConfig.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveFilters(ExpenseProvider provider) {
    final List<Widget> filterChips = [];
    
    // Date range filter
    if (provider.startDate != null || provider.endDate != null) {
      String dateText = '';
      if (provider.startDate != null && provider.endDate != null) {
        if (provider.startDate == provider.endDate) {
          dateText = 'Tanggal: ${provider.startDate}';
        } else {
          dateText = 'Periode: ${provider.startDate} - ${provider.endDate}';
        }
      } else if (provider.startDate != null) {
        dateText = 'Dari: ${provider.startDate}';
      } else if (provider.endDate != null) {
        dateText = 'Sampai: ${provider.endDate}';
      }
      
      filterChips.add(
        Chip(
          label: Text(dateText),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            provider.setDateFilter(null, null);
          },
          backgroundColor: ApiConfig.primaryColor.withOpacity(0.1),
          deleteIconColor: ApiConfig.primaryColor,
        ),
      );
    }
    
    // Category filter
    if (provider.selectedCategoryId != null) {
      filterChips.add(
        Consumer<ExpenseCategoryProvider>(
          builder: (context, categoryProvider, child) {
            final category = categoryProvider.expenseCategories
                .where((cat) => cat.id == provider.selectedCategoryId)
                .firstOrNull;
            
            return Chip(
              label: Text('Kategori: ${category?.name ?? 'Kategori Tidak Diketahui'}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                provider.setCategoryFilter(null);
              },
              backgroundColor: ApiConfig.primaryColor.withOpacity(0.1),
              deleteIconColor: ApiConfig.primaryColor,
            );
          },
        ),
      );
    }
    
    // Payment method filter
    if (provider.selectedPaymentMethod != null) {
      filterChips.add(
        Chip(
          label: Text('Pembayaran: ${provider.selectedPaymentMethod}'),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            provider.setPaymentMethodFilter(null);
          },
          backgroundColor: ApiConfig.primaryColor.withOpacity(0.1),
          deleteIconColor: ApiConfig.primaryColor,
        ),
      );
    }
    
    if (filterChips.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Filter Aktif:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (filterChips.isNotEmpty)
                TextButton(
                  onPressed: () {
                    provider.setDateFilter(null, null);
                    provider.setCategoryFilter(null);
                    provider.setPaymentMethodFilter(null);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Hapus Semua',
                    style: TextStyle(
                      fontSize: 12,
                      color: ApiConfig.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: filterChips,
          ),
        ],
      ),
    );
  }
}