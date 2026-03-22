import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

/// Admin: edit slideshow contents (home screen carousel).
class AdminSlideshowScreen extends StatefulWidget {
  const AdminSlideshowScreen({super.key});

  @override
  State<AdminSlideshowScreen> createState() => _AdminSlideshowScreenState();
}

class _AdminSlideshowScreenState extends State<AdminSlideshowScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_SlideFormModel> _slides = [
    _SlideFormModel(title: 'Welcome to Alagang RHU'),
    _SlideFormModel(title: 'Primary care services'),
    _SlideFormModel(title: 'Upcoming activities'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = AppTheme.scale(context, AppTheme.spacingLg);
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'I-edit ang Slideshow'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminUI.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            AdminCard(
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentIndex = i),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        final hasImage = slide.imageUrlController.text.trim().isNotEmpty;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.white,
                            child: hasImage
                                ? Image.network(
                                    slide.imageUrlController.text.trim(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _PreviewFallback(title: slide.titleController.text),
                                  )
                                : _PreviewFallback(title: slide.titleController.text),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentIndex;
                      return Container(
                        width: isActive ? 10 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive ? AdminUI.indigo : AdminUI.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Slides',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AdminUI.textPrimary,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _slides.add(_SlideFormModel(title: 'Bagong slide'));
                    });
                    _pageController.animateToPage(
                      _slides.length - 1,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add slide'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._slides.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final slide = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Slide ${index + 1}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AdminUI.textPrimary,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AdminUI.red),
                              onPressed: _slides.length <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _slides.removeAt(index);
                                        _currentIndex = (_currentIndex.clamp(0, _slides.length - 1));
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: slide.titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Welcome to Alagang RHU',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: slide.subtitleController,
                          decoration: const InputDecoration(
                            labelText: 'Subtitle (optional)',
                            hintText: 'Short description under the title',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Slide image',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AdminUI.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: slide.imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL',
                            hintText: 'Paste image URL to show in slideshow',
                            prefixIcon: Icon(Icons.image_outlined),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Wire up to Supabase Storage / file picker.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image upload not yet connected. Paste an image URL for now.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_outlined),
                            label: const Text('Upload from device'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // TODO: Save to Supabase slideshow_slides.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saving slideshow is not wired to Supabase yet.')),
                  );
                },
                child: const Text('Save slideshow'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideFormModel {
  _SlideFormModel({String? title}) {
    titleController.text = title ?? '';
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.slideshow_outlined, size: 32, color: AdminUI.indigo),
          const SizedBox(height: 12),
          Text(
            title.isEmpty ? 'Preview ng slide' : title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminUI.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gamitin ang fields sa ibaba para palitan ang larawan at teksto ng slideshow.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminUI.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
