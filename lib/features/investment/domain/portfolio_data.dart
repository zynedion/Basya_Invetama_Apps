class PortfolioData {
  const PortfolioData({required this.isGlobal, required this.items});
  final bool isGlobal;
  final List<PortfolioItem> items;
}

class PortfolioItem {
  PortfolioItem(Map<String, dynamic> source) : data = Map.unmodifiable(source);
  final Map<String, dynamic> data;
  String text(String key) => (data[key] as String?)?.trim() ?? '';
  int number(String key) => (data[key] as num).toInt();
  String get name => text('nama');
  int get lots => number('jumlah_lot');
  int get availableLots => number('lot_tersedia');
  int get price => number('harga_per_lot');
  Map get owner => data['owner'] is Map ? data['owner'] as Map : const {};
  String get ownerName => (owner['name'] as String?) ?? '';
  bool get selling => data['penjualan_diproses'] != null;
  bool get canPreviewSale => availableLots > 0 && price > 0;
}
