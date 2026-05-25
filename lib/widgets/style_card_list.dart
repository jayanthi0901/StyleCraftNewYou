// ---------------------------------------------------------------------------
// style_card_list.dart
//
// The horizontal scrollable row of style cards under "POPULAR STYLES FOR YOU".
// Each card shows a thumbnail + name.  The selected card gets a blue border
// and a checkmark (matching the mockup).
//
// Fulfils User Stories 1 & 2: tapping a card activates its overlay.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/hair_style.dart';
import '../providers/consultation_provider.dart';

class StyleCardList extends StatelessWidget {
  const StyleCardList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();
    final styles   = provider.styles;
    final active   = provider.activeStyle;

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'POPULAR STYLES FOR YOU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                // Match badge from mockup
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${styles.length} Matches',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal card scroll ──────────────────────────────────────
          SizedBox(
            height: 165,
            child: styles.isEmpty
                ? const Center(
                    child: Text(
                      'No styles for this profile yet.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: styles.length,
                    itemBuilder: (_, i) => _StyleCard(
                      style: styles[i],
                      isActive: styles[i].id == active?.id,
                      onTap: () => provider.selectStyle(styles[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Individual card ───────────────────────────────────────────────────────────

class _StyleCard extends StatelessWidget {
  final HairStyle style;
  final bool isActive;
  final VoidCallback onTap;

  const _StyleCard({
    required this.style,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 115,
        margin: const EdgeInsets.only(right: 10, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo thumbnail with selection indicator ────────────────
            Stack(
              children: [
                // Thumbnail image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 115,
                    height: 130,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF4A90D9)
                            : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        style.thumbnailAsset,
                        fit: BoxFit.cover,
                        // Placeholder while image is loading or if asset is missing
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.face,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Blue checkmark badge when selected
                if (isActive)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A90D9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Style name under the card ───────────────────────────────
            Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF4A90D9) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
