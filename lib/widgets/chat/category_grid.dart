import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../models/category_model.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategoryTap;
  final bool showAsShops;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this. onCategoryTap,
    this.showAsShops = false,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _buildDefaultCategories();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:  4,
        crossAxisSpacing: 12,
        mainAxisSpacing:  12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length. clamp(0, 8),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }

  Widget _buildDefaultCategories() {
    final defaultCategories = [
      _DefaultCategory('Electrician', Iconsax.flash_1),
      _DefaultCategory('Plumber', Iconsax.drop),
      _DefaultCategory('Carpenter', Iconsax.ruler),
      _DefaultCategory('Painter', Iconsax.brush_1),
      _DefaultCategory('AC Repair', Iconsax. wind),
      _DefaultCategory('Tutor', Iconsax.book),
      _DefaultCategory('Cleaner', Iconsax.broom),
      _DefaultCategory('More', Iconsax.more),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing:  12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: defaultCategories.length,
      itemBuilder: (context, index) {
        final cat = defaultCategories[index];
        return _DefaultCategoryCard(
          name: cat.name,
          icon: cat.icon,
          onTap: () {
            // Create a dummy category for the callback
            final category = CategoryModel(
              id: index. toString(),
              name: cat.name,
              slug: cat.name.toLowerCase(),
              iconName: cat.name.toLowerCase(),
            );
            onCategoryTap(category);
          },
        );
      },
    );
  }
}

class _DefaultCategory {
  final String name;
  final IconData icon;

  _DefaultCategory(this.name, this.icon);
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.surfaceLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:  Icon(
                _getCategoryIcon(category.iconName),
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height:  8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize:  11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName. toLowerCase()) {
      case 'electrician':
      case 'flash': 
        return Iconsax. flash_1;
      case 'plumber':
      case 'drop':
        return Iconsax.drop;
      case 'carpenter':
      case 'hammer':
        return Iconsax.ruler;
      case 'painter':
      case 'brush':
        return Iconsax.brush_1;
      case 'ac': 
      case 'wind':
        return Iconsax.wind;
      case 'tutor': 
      case 'book':
        return Iconsax.book;
      case 'cleaner': 
      case 'cleaning':
        return Iconsax.broom;
      case 'beauty':
      case 'salon':
        return Iconsax.scissor;
      default:
        return Iconsax.category;
    }
  }
}

class _DefaultCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _DefaultCategoryCard({
    required this.name,
    required this.icon,
    required this. onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.surfaceLight,
          ),
        ),
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height:  8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow. ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}