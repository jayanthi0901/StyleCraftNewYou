// ---------------------------------------------------------------------------
// profile_filter_bar.dart
//
// The four dropdown chips at the top of the screen:
//   Face Shape | Occasion | Hair Length | Change Type
//
// When the stylist changes any value the ConsultationProvider updates the
// style list and reloads the saved opacity for that profile.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/styles_data.dart';
import '../providers/consultation_provider.dart';

class ProfileFilterBar extends StatelessWidget {
  const ProfileFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConsultationProvider>();
    final profile  = provider.profile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FilterChip(
            label: 'FACE SHAPE',
            value: profile.faceShape,
            options: kFaceShapes,
            onChanged: provider.setFaceShape,
          ),
          _FilterChip(
            label: 'OCCASION',
            value: profile.occasion,
            options: kOccasions,
            onChanged: provider.setOccasion,
          ),
          _FilterChip(
            label: 'HAIR LENGTH',
            value: profile.hairLength,
            options: kHairLengths,
            onChanged: provider.setHairLength,
          ),
          _FilterChip(
            label: 'CHANGE TYPE',
            value: profile.changeType,
            options: kChangeTypes,
            onChanged: provider.setChangeType,
          ),
        ],
      ),
    );
  }
}

// ── Individual dropdown chip ──────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _OptionSheet(
        title: label,
        options: options,
        selected: value,
        onSelected: (v) {
          onChanged(v);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Bottom-sheet option picker ────────────────────────────────────────────────

class _OptionSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...options.map((opt) => ListTile(
          title: Text(opt),
          trailing: opt == selected
              ? const Icon(Icons.check, color: Color(0xFF4A90D9))
              : null,
          onTap: () => onSelected(opt),
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}
