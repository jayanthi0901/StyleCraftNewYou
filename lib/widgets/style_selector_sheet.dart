import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/hair_style.dart';
import '../providers/style_provider.dart';

/// Slide-up sheet that lets the user browse and select hairstyles.
/// Shows a category filter row at the top and a scrollable grid below.
class StyleSelectorSheet extends StatelessWidget {
  const StyleSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<StyleProvider>(),
        child: const StyleSelectorSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleProvider = context.watch<StyleProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.32,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ────────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // ── Title ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Choose Style',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Category chips ────────────────────────────────────────
              _CategoryRow(
                categories: styleProvider.categories,
                active: styleProvider.activeCategory ?? 'All',
                onSelect: styleProvider.selectCategory,
              ),
              const SizedBox(height: 12),

              // ── Style grid ────────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: styleProvider.filteredStyles.length,
                  itemBuilder: (context, i) {
                    final style = styleProvider.filteredStyles[i];
                    final isSelected =
                        style.id == styleProvider.selectedStyle?.id;
                    return _StyleCard(
                      style: style,
                      isSelected: isSelected,
                      onTap: () {
                        styleProvider.selectStyle(style);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<String> categories;
  final String active;
  final void Function(String) onSelect;

  const _CategoryRow({
    required this.categories,
    required this.active,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = cat == active;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final HairStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Image.asset(
                style.thumbnailAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.content_cut,
                      size: 40, color: Color(0xFFCBD5E1)),
                ),
              ),

              // Selected overlay
              if (isSelected)
                Container(
                  color: const Color(0xFF2563EB).withOpacity(0.18),
                ),

              // Bottom gradient + name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                  child: Text(
                    style.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Check badge
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
