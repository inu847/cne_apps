import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method_model.dart';
import '../providers/payment_method_provider.dart';
import '../utils/format_utils.dart';

class PaymentMethodDialog extends StatefulWidget {
  final double totalAmount;
  final Function(PaymentMethod, double) onPaymentSelected;

  const PaymentMethodDialog({
    Key? key,
    required this.totalAmount,
    required this.onPaymentSelected,
  }) : super(key: key);

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  PaymentMethod? _selectedMethod;
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  double _paidAmount = 0.0;
  
  // Getter untuk menghitung kembalian
  double get _changeAmount {
    return _paidAmount - widget.totalAmount;
  }
  
  // Shortcut nominal untuk Cash
  final List<int> _cashShortcuts = [10000, 20000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _paidAmount = widget.totalAmount;
    _amountController.text = widget.totalAmount.toString();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    final provider = Provider.of<PaymentMethodProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final result = await provider.fetchPaymentMethods(isActive: true);
      
      if (!result) {
        setState(() {
          _error = provider.error ?? 'Gagal memuat metode pembayaran';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 520 : MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan background
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Memuat metode pembayaran...'),
                            ],
                          ),
                        ),
                      )
                    else if (_error != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPaymentMethods,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Consumer<PaymentMethodProvider>(
                        builder: (context, provider, child) {
                          final methods = provider.paymentMethods;
                          
                          if (methods.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.payment_outlined, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('Tidak ada metode pembayaran yang tersedia'),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Metode pembayaran
                              const Text(
                                'Pilih Metode Pembayaran',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              
                              // Grid layout untuk metode pembayaran
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final isMobile = screenWidth < 600;
                                  final isTablet = screenWidth >= 600 && screenWidth < 900;
                                  
                                  int crossAxisCount;
                                  double childAspectRatio;
                                  double spacing;
                                  
                                  if (isMobile) {
                                    crossAxisCount = screenWidth < 400 ? 1 : 2;
                                    childAspectRatio = screenWidth < 400 ? 3.5 : 2.2;
                                    spacing = 8;
                                  } else if (isTablet) {
                                    crossAxisCount = 2;
                                    childAspectRatio = 2.8;
                                    spacing = 12;
                                  } else {
                                    crossAxisCount = 2;
                                    childAspectRatio = 2.5;
                                    spacing = 12;
                                  }
                                  
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      childAspectRatio: childAspectRatio,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                    ),
                                    itemCount: methods.length > 4 ? 4 : methods.length, // Batasi hanya 4 metode
                                    itemBuilder: (context, index) {
                                  final method = methods[index];
                                  final isSelected = _selectedMethod == method;
                                  
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedMethod = method;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? primaryColor : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected ? primaryColor : Colors.grey.shade400,
                                                      width: 2,
                                                    ),
                                                    color: isSelected ? primaryColor : Colors.transparent,
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    method.name,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: isSelected ? primaryColor : Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              method.description,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected ? primaryColor.withOpacity(0.8) : Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                 },
                               );
                                 },
                               ),
                               const SizedBox(height: 20),
                              
                              // Jumlah pembayaran
                               Container(
                                 padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Pembayaran',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Belanja:',
                                          style: TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                        Text(
                                          '${FormatUtils.formatCurrency(widget.totalAmount.toInt())}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Tampilkan fitur Cash jika metode Cash dipilih
                                    if (_selectedMethod?.code.toLowerCase() == 'cash') ...[
                                      // Shortcut nominal untuk Cash
                                      const Text(
                                        'Pilih Nominal Uang',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _cashShortcuts.map((amount) {
                                          final isSelected = _paidAmount == amount.toDouble();
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                _paidAmount = amount.toDouble();
                                                _amountController.text = amount.toString();
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isSelected ? primaryColor : Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isSelected ? primaryColor : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                '${FormatUtils.formatCurrency(amount)}',
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Display jumlah bayar (read-only)
                                      const Text(
                                        'Jumlah Bayar',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          '${FormatUtils.formatCurrency(_paidAmount.toInt())}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Display kembalian
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _changeAmount >= 0 ? Colors.green.shade200 : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _changeAmount >= 0 ? 'Kembalian:' : 'Kurang:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: _changeAmount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                            Text(
                                              '${FormatUtils.formatCurrency(_changeAmount.abs().toInt())}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _changeAmount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      // Input biasa untuk metode pembayaran lain
                                      const Text(
                                        'Jumlah Bayar',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        onChanged: (value) {
                                          setState(() {
                                            _paidAmount = double.tryParse(value) ?? widget.totalAmount;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          prefixText: 'Rp ',
                                          prefixStyle: TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.w600),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: primaryColor, width: 2),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Tombol konfirmasi
                               SizedBox(
                                 width: double.infinity,
                                 height: MediaQuery.of(context).size.width < 600 ? 48 : 52,
                                child: ElevatedButton(
                                  onPressed: _selectedMethod == null
                                      ? null
                                      : () {
                                          // Validasi untuk metode Cash
                                          if (_selectedMethod!.code.toLowerCase() == 'cash' && _paidAmount < widget.totalAmount) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Jumlah pembayaran tidak boleh kurang dari total belanja'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                          
                                          final amount = _paidAmount;
                                          Navigator.pop(context); // Tutup dialog terlebih dahulu
                                          widget.onPaymentSelected(_selectedMethod!, amount); // Panggil callback setelah dialog ditutup
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    disabledForegroundColor: Colors.grey.shade500,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.payment, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'KONFIRMASI PEMBAYARAN',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
    );
  }
}