class CurrencyFormatter {
  // Helper untuk format angka dengan pemisah ribuan
  static String formatCurrency(double value) {
    return 'Rp ${value.toInt().toString().replaceAllMapped(
          RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[0]}.',
        )}';
  }

  // Helper untuk format angka biasa dengan pemisah ribuan
  static String formatNumber(double value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'\d{1,3}(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[0]}.',
        );
  }
}