import 'package:flutter/material.dart';

class PageNavigation extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final Widget firstPage;
  final Widget secondPage;

  const PageNavigation({
    super.key,
    required this.pageController,
    required this.currentPage,
    required this.firstPage,
    required this.secondPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: currentPage == 0 ? 0.5 : 1.0,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAD0000)),
        ),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              firstPage,
              secondPage,
            ],
          ),
        ),
      ],
    );
  }
}
