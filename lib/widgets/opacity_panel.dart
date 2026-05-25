// ---------------------------------------------------------------------------
// opacity_panel.dart
//
// The floating white card that lets the stylist adjust overlay strength.
// Matches the mockup: slider + Low / Med / High chips + "Set as default" tick.
//
// Fulfils User Story 3: stylist sets opacity once, app remembers it.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/consultation_provider.dart';

class OpacityPanel extends StatefulWidget {
  const OpacityPanel({super.key});

  @override
  State<OpacityPanel> createState() => _OpacityPanelState();
}

class _OpacityPanelState extends State<OpacityPanel> {
  // Local checkbox state – resets when panel rebuilds (that's fine)
  bool _setAsDefault = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();
    final opacity  = provider.opacity;

    // Determine which preset button is closest to current opacity
    String _activePreset() {
      if (opacity <= 0.42) return 'Low';
      if (opacity <= 0.67) return 'Med';
      return 'High';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Row(
            children: [
              // Sparkle icon
              const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4A90D9)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Overlay Opacity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Percentage label
              Text(
                '${(opacity * 100).round()}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A90D9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Slider ───────────────────────────────────────────────────────
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4A90D9),
              inactiveTrackColor: const Color(0xFFD0E4F7),
              thumbColor: const Color(0xFF4A90D9),
              overlayColor: const Color(0xFF4A90D9).withOpacity(0.2),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (v) => provider.setOpacity(v),
            ),
          ),

          const SizedBox(height: 8),

          // ── Bottom row: preset chips + Set as default ─────────────────
          Row(
            children: [
              // Low / Med / High chips
              ..._buildPresetChips(_activePreset(), provider),

              const Spacer(),

              // "Set as default" checkbox
              GestureDetector(
                onTap: () async {
                  setState(() => _setAsDefault = !_setAsDefault);
                  if (_setAsDefault) {
                    await provider.saveOpacityAsDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opacity saved for ${provider.profile.faceShape} / '
                            '${provider.profile.changeType}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _setAsDefault,
                        activeColor: const Color(0xFF4A90D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) async {
                          setState(() => _setAsDefault = v ?? false);
                          if (v == true) {
                            await provider.saveOpacityAsDefault();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Set as default',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPresetChips(String active, ConsultationProvider provider) {
    return ['Low', 'Med', 'High'].map((label) {
      final isActive = label == active;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => provider.setOpacityPreset(label),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEAF3FD) : Colors.transparent,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF4A90D9)
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF4A90D9) : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
