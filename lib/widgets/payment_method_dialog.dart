import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method_model.dart';
import '../providers/payment_method_provider.dart';

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

  @override
  void initState() {
    super.initState();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
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
              Consumer<PaymentMethodProvider>(builder: (context, provider, child) {
                final methods = provider.paymentMethods;
                
                if (methods.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Tidak ada metode pembayaran yang tersedia'),
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metode pembayaran
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: methods.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final method = methods[index];
                          return RadioListTile<PaymentMethod>(
                            title: Text(method.name),
                            subtitle: Text(method.description),
                            value: method,
                            groupValue: _selectedMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedMethod = value;
                              });
                            },
                            activeColor: primaryColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Jumlah pembayaran
                    const Text(
                      'Jumlah Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tombol konfirmasi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedMethod == null
                            ? null
                            : () {
                                final amount = double.tryParse(_amountController.text) ?? widget.totalAmount;
                                widget.onPaymentSelected(_selectedMethod!, amount);
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('KONFIRMASI PEMBAYARAN'),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}