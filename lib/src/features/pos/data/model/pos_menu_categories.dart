import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class PosMenuCategory {
  const PosMenuCategory({required this.name, required this.icon});

  final String name;
  final List<List<dynamic>> icon;
}

class PosMenuCategories {
  const PosMenuCategories._();

  static const List<PosMenuCategory> all = [
    PosMenuCategory(name: 'Appetizers', icon: HugeIcons.strokeRoundedNoodles),
    PosMenuCategory(
      name: 'Main Course',
      icon: HugeIcons.strokeRoundedServingFood,
    ),
    PosMenuCategory(
      name: 'Beverages',
      icon: HugeIcons.strokeRoundedSoftDrink01,
    ),
    PosMenuCategory(name: 'Desserts', icon: HugeIcons.strokeRoundedCakeSlice),
    PosMenuCategory(name: 'Sides', icon: HugeIcons.strokeRoundedFrenchFries01),
    PosMenuCategory(name: 'Breakfast', icon: HugeIcons.strokeRoundedEggFried),
    PosMenuCategory(name: 'Lunch', icon: HugeIcons.strokeRoundedSun02),
    PosMenuCategory(name: 'Dinner', icon: HugeIcons.strokeRoundedMoon02),
    PosMenuCategory(name: 'Soups', icon: HugeIcons.strokeRoundedRiceBowl01),
    PosMenuCategory(name: 'Salads', icon: HugeIcons.strokeRoundedSalad),
    PosMenuCategory(name: 'Rice', icon: HugeIcons.strokeRoundedRiceBowl02),
    PosMenuCategory(name: 'Pasta', icon: HugeIcons.strokeRoundedSpaghetti),
    PosMenuCategory(name: 'Pizza', icon: HugeIcons.strokeRoundedPizza01),
    PosMenuCategory(name: 'Burgers', icon: HugeIcons.strokeRoundedHamburger01),
    PosMenuCategory(name: 'Sandwiches', icon: HugeIcons.strokeRoundedBread04),
    PosMenuCategory(name: 'Wraps', icon: HugeIcons.strokeRoundedHotdog),
    PosMenuCategory(name: 'Tacos', icon: HugeIcons.strokeRoundedTaco01),
    PosMenuCategory(name: 'Grilled', icon: HugeIcons.strokeRoundedSteak),
    PosMenuCategory(
      name: 'Chicken',
      icon: HugeIcons.strokeRoundedChickenThighs,
    ),
    PosMenuCategory(name: 'Seafood', icon: HugeIcons.strokeRoundedFishFood),
    PosMenuCategory(
      name: 'Vegetarian',
      icon: HugeIcons.strokeRoundedVegetarianFood,
    ),
    PosMenuCategory(name: 'Drinks', icon: HugeIcons.strokeRoundedDrink),
    PosMenuCategory(name: 'Coffee', icon: HugeIcons.strokeRoundedCoffee02),
    PosMenuCategory(name: 'Bakery', icon: HugeIcons.strokeRoundedCroissant),
    PosMenuCategory(name: 'Snacks', icon: HugeIcons.strokeRoundedPopcorn),
    PosMenuCategory(name: 'Combos', icon: HugeIcons.strokeRoundedPackage02),
    PosMenuCategory(name: 'Kids Menu', icon: HugeIcons.strokeRoundedKid),
    PosMenuCategory(
      name: "Chef's Specials",
      icon: HugeIcons.strokeRoundedChefHat,
    ),
    PosMenuCategory(name: 'Seasonal', icon: HugeIcons.strokeRoundedLeaf01),
    PosMenuCategory(
      name: 'More',
      icon: HugeIcons.strokeRoundedMoreHorizontalCircle01,
    ),
  ];

  static List<String> get names => all
      .where((category) => category.name != 'More')
      .map((category) => category.name)
      .toList();

  static PosMenuCategory byName(String name) {
    final normalized = name.trim().toLowerCase();
    return all.firstWhere(
      (category) => category.name.toLowerCase() == normalized,
      orElse: () => all.last,
    );
  }
}

class PosMenuCategoryIcon extends StatelessWidget {
  const PosMenuCategoryIcon({
    super.key,
    required this.category,
    required this.color,
    this.size = 24,
    this.strokeWidth = 1.7,
  });

  final String category;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: PosMenuCategories.byName(category).icon,
      color: color,
      size: size,
      strokeWidth: strokeWidth,
    );
  }
}
