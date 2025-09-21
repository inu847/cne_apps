import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cne_pos_apps/models/category_model.dart';
import 'package:cne_pos_apps/providers/category_provider.dart';
import '../config/api_config.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  
  const CategoryFormScreen({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
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
  
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final provider = Provider.of<CategoryProvider>(context, listen: false);
    bool success = false;
    
    try {
      if (isEditing) {
        // Update existing category
        final updatedCategory = Category(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          productsCount: widget.category!.productsCount,
          createdAt: widget.category!.createdAt,
          updatedAt: DateTime.now(),
        );
        success = await provider.updateCategory(widget.category!.id, updatedCategory);
      } else {
        // Create new category
        final newCategory = Category(
          id: 0, // Will be set by server
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          isActive: _isActive,
          productsCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        success = await provider.createCategory(newCategory);
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Kategori berhasil diperbarui' : 'Kategori berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Gagal menyimpan kategori'),
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
          isEditing ? 'Edit Kategori' : 'Tambah Kategori',
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
              onPressed: _saveCategory,
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
                      'Informasi Kategori',
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
                        hintText: 'Masukkan nama kategori',
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
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Kode Kategori *',
                        hintText: 'Masukkan kode kategori (contoh: CAT001)',
                        prefixIcon: Icon(Icons.qr_code, color: ApiConfig.primaryColor),
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
                        if (value.trim().length < 3) {
                          return 'Kode kategori minimal 3 karakter';
                        }
                        // Validasi format kode (hanya huruf dan angka)
                        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value.trim())) {
                          return 'Kode hanya boleh berisi huruf dan angka';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
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
            
            // Status Kategori
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
                      'Status Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ApiConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Aktif'),
                      subtitle: Text(
                        _isActive 
                            ? 'Kategori dapat digunakan untuk produk'
                            : 'Kategori tidak dapat digunakan untuk produk baru',
                        style: TextStyle(
                          color: _isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: ApiConfig.primaryColor,
                      secondary: Icon(
                        _isActive ? Icons.check_circle : Icons.cancel,
                        color: _isActive ? Colors.green : Colors.red,
                      ),
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
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ApiConfig.primaryColor,
                  foregroundColor: ApiConfig.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEditing ? Icons.update : Icons.save),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Perbarui Kategori' : 'Simpan Kategori',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informasi tambahan untuk edit
            if (isEditing)
              Card(
                elevation: 1,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ApiConfig.textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 16,
                            color: ApiConfig.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jumlah Produk: ${widget.category!.productsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ApiConfig.textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: ApiConfig.textColor.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dibuat: ${widget.category!.createdAt.day}/${widget.category!.createdAt.month}/${widget.category!.createdAt.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: ApiConfig.textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
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