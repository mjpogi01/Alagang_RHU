import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/bulletin_post.dart';
import '../theme/app_theme.dart';

/// TikTok-style bulletin board: full-screen vertical feed of announcement posts.
class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  State<BulletinBoardScreen> createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  late PageController _pageController;

  static final List<BulletinPost> _posts = [
    BulletinPost(
      id: '1',
      title: 'Lian RHU',
      description: 'Libreng konsultasyon at bakuna tuwing Lunes–Biyernes. Dalhin ang inyong PhilHealth ID.',
      tags: ['Libre', 'Konsultasyon', 'Bakuna'],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      backgroundColor: 0xFF1A4F3E,
    ),
    BulletinPost(
      id: '2',
      title: 'Programang Pang-nutrisyon',
      description: 'Supplementation para sa mga buntis at batang 0–59 buwan. Magrehistro sa RHU.',
      tags: ['Nutrisyon', 'Buntis', 'Bata'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      backgroundColor: 0xFF2E7D32,
    ),
    BulletinPost(
      id: '3',
      title: 'Family Planning',
      description: 'Libreng pagpapayo at contraceptive. Lihim at respetado ang inyong pagpapasya.',
      tags: ['FamilyPlanning', 'Libre'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      backgroundColor: 0xFF5A9BC4,
    ),
    BulletinPost(
      id: '4',
      title: 'Dengue Awareness',
      description: '4S: Search & destroy, Self-protection, Seek early consultation, Say no to fogging. Iwasan ang tubig na naka-istambay.',
      tags: ['Dengue', '4S', 'Kalusugan'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      backgroundColor: 0xFF0D2B24,
    ),
    BulletinPost(
      id: '5',
      title: 'TB DOTS',
      description: 'Libreng gamot at pagsubaybay para sa TB. Magpa-screen sa pinakamalapit na health center.',
      tags: ['TB', 'LibrengGamot'],
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      backgroundColor: 0xFF6B4423,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (_) {},
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return _BulletinPageView(
                post: _posts[index],
                bottomPadding: AppTheme.floatingNavBarClearance + 24,
              );
            },
          ),
          // Top label
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingSm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Bulletin Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletinPageView extends StatelessWidget {
  const _BulletinPageView({
    required this.post,
    required this.bottomPadding,
  });

  final BulletinPost post;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final color = post.backgroundColor != null
        ? Color(post.backgroundColor!)
        : const Color(0xFF1A4F3E);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Optional: gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          // Left: title, description, tags
          Positioned(
            left: AppTheme.scale(context, AppTheme.spacingLg),
            right: AppTheme.scale(context, 80),
            bottom: bottomPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.2,
                      ),
                ),
                SizedBox(height: AppTheme.scale(context, 8)),
                Text(
                  post.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        height: 1.4,
                      ),
                ),
                if (post.tags.isNotEmpty) ...[
                  SizedBox(height: AppTheme.scale(context, 10)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: post.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (post.dateLabel.isNotEmpty) ...[
                  SizedBox(height: AppTheme.scale(context, 8)),
                  Text(
                    post.dateLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Right: action buttons (TikTok-style)
          Positioned(
            right: AppTheme.scale(context, AppTheme.spacingMd),
            bottom: bottomPadding + 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SideAction(
                  icon: Icons.favorite_border,
                  label: '',
                  onTap: () {},
                ),
                SizedBox(height: AppTheme.scale(context, 20)),
                _SideAction(
                  icon: Icons.chat_bubble_outline,
                  label: '',
                  onTap: () {},
                ),
                SizedBox(height: AppTheme.scale(context, 20)),
                _SideAction(
                  icon: Icons.bookmark_border,
                  label: '',
                  onTap: () {},
                ),
                SizedBox(height: AppTheme.scale(context, 20)),
                _SideAction(
                  icon: Icons.share_outlined,
                  label: 'I-share',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            padding: const EdgeInsets.all(10),
          ),
        ),
        if (label.isNotEmpty) ...[
          SizedBox(height: AppTheme.scale(context, 4)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
