// Data model
class MenuItem {
  final int id;
  final String name;
  final int price;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
  });
}
