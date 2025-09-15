import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/petty_cash_provider.dart';
import '../models/petty_cash_model.dart';
import '../utils/format_utils.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class PettyCashDialog extends StatefulWidget {
  final String type; // 'opening' atau 'closing'
  final PettyCash? activePettyCash;
  final int? warehouseId;

  const PettyCashDialog({
    Key? key,
    required this.type,
    this.activePettyCash,
    this.warehouseId,
  }) : super(key: key);

  @override
  State<PettyCashDialog> createState() => _PettyCashDialogState();
}

class _PettyCashDialogState extends State<PettyCashDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Color palette
  static const Color primaryGreen = Color(0xFF03D26F);
  static const Color lightBlue = Color(0xFFEAF4F4);
  static const Color darkBlack = Color(0xFF161514);

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Set tanggal hari ini (tidak dapat diubah)
    _dateController.text = DateTime.now().toString().split(' ')[0]; // Format: YYYY-MM-DD
    
    if (widget.type == 'opening') {
      _nameController.text = 'Pembukaan Kas - ${DateTime.now().toString().split(' ')[0]}';
      _amountController.text = '0';
    } else if (widget.type == 'closing') {
      _nameController.text = 'Penutupan Kas - ${DateTime.now().toString().split(' ')[0]}';
      if (widget.activePettyCash != null) {
        _amountController.text = widget.activePettyCash!.amount.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _dialogTitle {
    return widget.type == 'opening' ? 'Buka Kas Kecil' : 'Tutup Kas Kecil';
  }

  String get _submitButtonText {
    return widget.type == 'opening' ? 'Buka Kas' : 'Tutup Kas';
  }

  Color get _submitButtonColor {
    return widget.type == 'opening' ? primaryGreen : Colors.red.shade600;
  }

  IconData _getIcon() {
    return widget.type == 'opening' ? Icons.account_balance_wallet : Icons.lock;
  }
  
  String get _title {
    return widget.type == 'opening' ? 'Buka Kas Kecil' : 'Tutup Kas Kecil';
  }
  
  String get _subtitle {
    return widget.type == 'opening'
        ? 'Masukkan jumlah kas awal untuk membuka kas'
        : 'Masukkan jumlah kas akhir untuk menutup kas';
  }
  
  Color get _iconBackgroundColor {
    return widget.type == 'opening' ? primaryGreen : Colors.red.shade600;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<PettyCashProvider>(context, listen: false);
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final notes = _notesController.text.trim();

    bool success = false;

    if (widget.type == 'opening') {
      success = await provider.openPettyCash(
        name: name,
        amount: amount,
        notes: notes.isNotEmpty ? notes : null,
        warehouseId: widget.warehouseId,
      );
    } else {
      success = await provider.closePettyCash(
        name: name,
        amount: amount,
        notes: notes.isNotEmpty ? notes : null,
        warehouseId: widget.warehouseId,
      );
    }

    print('PettyCashDialog: Submit result - success: $success');
    
    if (success) {
      print('PettyCashDialog: Success! Closing popup...');
      if (mounted) {
        print('PettyCashDialog: Widget mounted, calling Navigator.pop(true)');
        Navigator.of(context).pop(true);
        // SnackBar akan ditampilkan oleh parent widget setelah dialog tertutup
      } else {
        print('PettyCashDialog: Widget not mounted, cannot close popup');
      }
    } else {
      print('PettyCashDialog: Failed! Error: ${provider.error}');
      if (mounted) {
        _showErrorSnackBar(provider.error ?? 'Terjadi kesalahan');
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.type == 'opening' 
              ? 'Kas kecil berhasil dibuka' 
              : 'Kas kecil berhasil ditutup',
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final dialogWidth = isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9;
    final maxDialogWidth = isSmallScreen ? 400.0 : 500.0;
    
    return Consumer<PettyCashProvider>(
      builder: (context, provider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: screenSize.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFE3F2FD),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A4CAF50),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header yang tidak scroll
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, isSmallScreen ? 16 : 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _submitButtonColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIcon(),
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dialogTitle,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: darkBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.type == 'opening'
                                  ? 'Masukkan jumlah kas awal untuk memulai transaksi'
                                  : 'Masukkan jumlah kas akhir untuk menutup kas',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content yang bisa scroll
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, isSmallScreen ? 16 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [


                  // Status kas aktif (jika ada)
                  if (widget.activePettyCash != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Status Kas Aktif',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: darkBlack,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nama: ${widget.activePettyCash!.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Jumlah: ${FormatUtils.formatCurrency(widget.activePettyCash!.amount)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (widget.activePettyCash!.userName != null)
                            Text(
                              'Penanggung Jawab: ${widget.activePettyCash!.userName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Form fields
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Nama Kas',
                    hintText: 'Masukkan nama kas',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama kas tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _amountController,
                    labelText: widget.type == 'opening' ? 'Jumlah Kas Awal' : 'Jumlah Kas Akhir',
                    hintText: 'Masukkan jumlah kas',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jumlah kas tidak boleh kosong';
                      }
                      final amount = double.tryParse(value.trim());
                      if (amount == null || amount < 0) {
                        return 'Jumlah kas harus berupa angka positif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _dateController,
                    labelText: 'Tanggal',
                    hintText: 'Tanggal otomatis',
                    readOnly: true,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _notesController,
                    labelText: 'Catatan (Opsional)',
                    hintText: 'Masukkan catatan tambahan',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                        ],
                      ),
                    ),
                  ),
                ),
                
                // Action button yang tidak scroll
                Padding(
                  padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 16 : 20, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: _submitButtonText,
                      onPressed: provider.isLoading ? () {} : _handleSubmit,
                      backgroundColor: _submitButtonColor,
                      isLoading: provider.isLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Helper function untuk menampilkan dialog
Future<bool?> showPettyCashDialog({
  required BuildContext context,
  required String type,
  PettyCash? activePettyCash,
  int? warehouseId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PettyCashDialog(
      type: type,
      activePettyCash: activePettyCash,
      warehouseId: warehouseId,
    ),
  );
}