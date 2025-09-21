import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/expense_category_model.dart';
import 'package:cne_pos_apps/providers/expense_category_provider.dart';
import '../config/api_config.dart';

class ExpenseCategoryFormScreen extends StatefulWidget {
  final ExpenseCategory? category;
  
  const ExpenseCategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<ExpenseCategoryFormScreen> createState() => _ExpenseCategoryFormScreenState();
}

class _ExpenseCategoryFormScreenState extends State<ExpenseCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  
  bool get isEditing => widget.category != null;
  
  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _codeController.text = widget.category!.code;
      _descriptionController.text = widget.category!.description ?? '';
      _isActive = widget.category!.isActive;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveExpenseCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<ExpenseCategoryProvider>(context, listen: false);
    bool success = false;
    
    try {
      if (isEditing) {
        // Update existing expense category
        final updatedCategory = ExpenseCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          userId: widget.category!.userId,
          createdAt: widget.category!.createdAt,
          updatedAt: DateTime.now(),
        );
        success = await provider.updateExpenseCategory(widget.category!.id, updatedCategory);
      } else {
        // Create new expense category
        final newCategory = ExpenseCategory(
          id: 0, // Will be set by server
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          userId: 0, // Will be set by server
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await provider.createExpenseCategory(newCategory);
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Kategori pengeluaran berhasil diperbarui' : 'Kategori pengeluaran berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan kategori pengeluaran'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Kategori Pengeluaran' : 'Tambah Kategori Pengeluaran',
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
          if (_isLoading)
            const Center(
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
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveExpenseCategory,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nama Kategori
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
                      'Informasi Kategori Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Kategori *',
                        hintText: 'Masukkan nama kategori pengeluaran',
                        prefixIcon: Icon(Icons.category, color: ApiConfig.primaryColor),
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
                          return 'Nama kategori harus diisi';
                        }
                        if (value.trim().length < 2) {
                          return 'Nama kategori minimal 2 karakter';
                        }
                        if (value.trim().length > 255) {
                          return 'Nama kategori maksimal 255 karakter';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Kode Kategori *',
                        hintText: 'Masukkan kode kategori (contoh: OFFICE)',
                        prefixIcon: Icon(Icons.code, color: ApiConfig.primaryColor),
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
                          return 'Kode kategori harus diisi';
                        }
                        if (value.trim().length < 2) {
                          return 'Kode kategori minimal 2 karakter';
                        }
                        if (value.trim().length > 50) {
                          return 'Kode kategori maksimal 50 karakter';
                        }
                        // Validasi format kode (hanya huruf, angka, dan underscore)
                        if (!RegExp(r'^[A-Z0-9_]+$').hasMatch(value.trim().toUpperCase())) {
                          return 'Kode hanya boleh berisi huruf, angka, dan underscore';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        // Auto convert to uppercase
                        final upperValue = value.toUpperCase();
                        if (value != upperValue) {
                          _codeController.value = _codeController.value.copyWith(
                            text: upperValue,
                            selection: TextSelection.collapsed(offset: upperValue.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Masukkan deskripsi kategori (opsional)',
                        prefixIcon: Icon(Icons.description, color: ApiConfig.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                        ),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Status Aktif
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
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      subtitle: Text(_isActive ? 'Kategori dapat digunakan' : 'Kategori tidak dapat digunakan'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: ApiConfig.primaryColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveExpenseCategory,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
                label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Kategori'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ApiConfig.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tombol Batal
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Batal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ApiConfig.primaryColor,
                  side: BorderSide(color: ApiConfig.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}