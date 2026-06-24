import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class DrawerOnboardingOverlay extends StatefulWidget {
  final List<OnboardingItem> items;
  final VoidCallback onComplete;

  const DrawerOnboardingOverlay({
    super.key,
    required this.items,
    required this.onComplete,
  });

  @override
  State<DrawerOnboardingOverlay> createState() =>
      _DrawerOnboardingOverlayState();
}

class _DrawerOnboardingOverlayState extends State<DrawerOnboardingOverlay> {
  int currentIndex = 0;

  void _next() {
    if (currentIndex < widget.items.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= widget.items.length) {
      currentIndex = widget.items.length - 1;
    }

    final item = widget.items[currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate the actual width of the highlighted item
    final itemWidth =
        screenWidth - item.position.left - (item.position.right ?? 0);

    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // Clickable overlay to skip
          Positioned.fill(
            child: GestureDetector(
              onTap: _skip,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Highlighted area
          Positioned(
            left: item.position.left,
            top: item.position.top,
            width: itemWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: item.position.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: item.child,
              ),
            ),
          ),

          // Description card
          Positioned(
            left: 20,
            right: 20,
            top: item.position.top + item.position.height + 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Progress indicator
                        Row(
                          children: List.generate(
                            widget.items.length,
                            (index) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == currentIndex
                                    ? kPrimary
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),

                        // Buttons
                        Row(
                          children: [
                            TextButton(
                              onPressed: _skip,
                              child: Text(
                                'Skip',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kprimaryTextColor2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _next,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                currentIndex == widget.items.length - 1
                                    ? 'Done'
                                    : 'Next',
                                style: WorkSansAppTextStyles.medium.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final Widget child;
  final ItemPosition position;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.child,
    required this.position,
  });
}

class ItemPosition {
  final double left;
  final double top;
  final double? right;
  final double height;

  ItemPosition({
    required this.left,
    required this.top,
    this.right,
    required this.height,
  });
}
